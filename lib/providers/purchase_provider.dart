import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_profile.dart';
import 'profile_provider.dart';
import '../services/profile_service.dart';
import '../services/purchase_service.dart';

/// SharedPreferences key for the ads-removed (Founder Aquarist) flag.
const String adsRemovedKey = 'adsRemoved';

// Private alias kept for backward compatibility within this file.
const String _adsRemovedKey = adsRemovedKey;

/// Sentinel used by [PurchaseState.copyWith] to distinguish between
/// "errorMessage not provided" and "errorMessage explicitly set to null".
const Object _undefinedError = Object();

/// How long to wait for the store to deliver restore events before declaring
/// that no prior purchase exists.
const Duration _restoreTimeout = Duration(seconds: 8);

/// Outcome of a restore-purchases request.
enum RestoreOutcome {
  /// No restore has been attempted, or the outcome has been consumed.
  none,

  /// A previous purchase was found and ads have been removed.
  success,

  /// The restore completed but no previous purchase was found.
  notFound,
}

/// Immutable state for the in-app purchase feature.
class PurchaseState {
  final bool adsRemoved;
  final bool isLoading;
  final bool isPurchasing;
  final String? errorMessage;
  final RestoreOutcome restoreOutcome;

  const PurchaseState({
    this.adsRemoved = false,
    this.isLoading = true,
    this.isPurchasing = false,
    this.errorMessage,
    this.restoreOutcome = RestoreOutcome.none,
  });

  PurchaseState copyWith({
    bool? adsRemoved,
    bool? isLoading,
    bool? isPurchasing,
    // Use the sentinel to distinguish "not provided" from explicit null.
    Object? errorMessage = _undefinedError,
    RestoreOutcome? restoreOutcome,
  }) {
    return PurchaseState(
      adsRemoved: adsRemoved ?? this.adsRemoved,
      isLoading: isLoading ?? this.isLoading,
      isPurchasing: isPurchasing ?? this.isPurchasing,
      errorMessage: identical(errorMessage, _undefinedError)
          ? this.errorMessage
          : errorMessage as String?,
      restoreOutcome: restoreOutcome ?? this.restoreOutcome,
    );
  }

  /// Whether the user has Founder Aquarist status.
  ///
  /// Founder Aquarists have purchased any product in [founderProductIds] which
  /// currently includes the "remove ads" lifetime purchase.  Add new product
  /// IDs to [founderProductIds] in `constants.dart` to extend this status.
  bool get isFounder => adsRemoved;
}

/// Manages the in-app purchase state for removing ads.
class PurchaseNotifier extends StateNotifier<PurchaseState> {
  final PurchaseService _service;
  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;
  StreamSubscription<User?>? _authStateSubscription;
  StreamSubscription<UserProfile?>? _cloudProfileSubscription;

  /// True while we are waiting for restore stream events to arrive.
  bool _pendingRestore = false;

  /// Fires after a short timeout to declare "no purchase found" if the
  /// restore stream never delivers our product.
  Timer? _restoreTimer;
  bool _hasPersistedFounderState = false;
  bool _isHandlingCloudFounderUpdate = false;
  bool _isSyncingFounderToCloud = false;

  PurchaseNotifier({PurchaseService? service})
    : _service = service ?? const PurchaseService(),
      super(const PurchaseState()) {
    _init();
  }

  Future<void> _init() async {
    // Load persisted "ads removed" state immediately.
    final prefs = await SharedPreferences.getInstance();
    final adsRemoved = prefs.getBool(_adsRemovedKey) ?? kDebugMode;
    _hasPersistedFounderState = prefs.containsKey(_adsRemovedKey);

    state = state.copyWith(adsRemoved: adsRemoved, isLoading: false);

    _authStateSubscription = FirebaseAuth.instance.authStateChanges().listen(
      _handleAuthStateChanged,
    );
    await _handleAuthStateChanged(FirebaseAuth.instance.currentUser);

    // Start listening to purchase stream updates.
    _purchaseSubscription = _service.purchaseStream.listen(
      _handlePurchaseUpdates,
      onError: (Object error) {
        PurchaseService.log('Purchase stream error: $error');
        state = state.copyWith(
          isPurchasing: false,
          errorMessage: error.toString(),
        );
      },
    );
  }

  Future<void> _handleAuthStateChanged(User? user) async {
    await _cloudProfileSubscription?.cancel();
    _cloudProfileSubscription = null;
    if (user == null) return;

    if (state.adsRemoved && _hasPersistedFounderState) {
      try {
        await ProfileService.backfillFounderEntitlementForExistingFounder(
          hasLocalFounderEntitlement: true,
        );
        await _syncFounderToCloud(source: 'local_purchase_sync');
      } catch (e) {
        PurchaseService.log('Initial founder cloud sync failed: $e');
      }
    }

    _cloudProfileSubscription = ProfileService.currentUserProfileStream().listen(
      (profile) {
        _handleCloudProfileUpdate(profile);
      },
      onError: (Object error) {
        PurchaseService.log('Cloud founder profile stream error: $error');
      },
    );
  }

  Future<void> _handleCloudProfileUpdate(UserProfile? profile) async {
    if (profile == null) return;
    if (_isHandlingCloudFounderUpdate) return;
    _isHandlingCloudFounderUpdate = true;
    try {
      if (profile.founderEntitled && !state.adsRemoved) {
        await _persistAdsRemoved(true, syncCloud: false);
        return;
      }

      // Conflict strategy: local purchase state is the source of truth, so if
      // cloud says non-founder but the local paid state is founder, push
      // founder=true back to cloud.
      if (shouldBackfillFounderProfile(
            localFounder: state.adsRemoved,
            cloudFounder: profile.founderEntitled,
          ) &&
          _hasPersistedFounderState) {
        await _syncFounderToCloud(source: 'local_purchase_sync');
        return;
      }
    } catch (e) {
      PurchaseService.log('Cloud founder update handling error: $e');
    } finally {
      _isHandlingCloudFounderUpdate = false;
    }
  }

  Future<void> _syncFounderToCloud({required String source}) async {
    if (_isSyncingFounderToCloud) return;
    _isSyncingFounderToCloud = true;
    try {
      await ProfileService.updateFounderEntitlement(true, source: source);
    } finally {
      _isSyncingFounderToCloud = false;
    }
  }

  Future<void> _handlePurchaseUpdates(
    List<PurchaseDetails> purchaseDetailsList,
  ) async {
    for (final details in purchaseDetailsList) {
      PurchaseService.log(
        'Purchase update: ${details.productID} status=${details.status}',
      );

      if (details.productID.contains('remove_ads')) {
        if (details.status == PurchaseStatus.purchased ||
            details.status == PurchaseStatus.restored) {
          // Persist and update state. For a restore, also record the outcome.
          final isRestore =
              _pendingRestore && details.status == PurchaseStatus.restored;
          if (isRestore) {
            _pendingRestore = false;
            _restoreTimer?.cancel();
          }
          await _persistAdsRemoved(true);
          if (isRestore) {
            state = state.copyWith(restoreOutcome: RestoreOutcome.success);
          }
        } else if (details.status == PurchaseStatus.error) {
          if (_pendingRestore) {
            _pendingRestore = false;
            _restoreTimer?.cancel();
          }
          state = state.copyWith(
            isPurchasing: false,
            errorMessage: details.error?.message ?? 'Purchase failed',
          );
        }
      }

      // Always complete purchases that are pending completion.
      if (details.pendingCompletePurchase) {
        await _service.completePurchase(details);
      }
    }

    // Clear purchasing flag after processing the batch.
    state = state.copyWith(isPurchasing: false);
  }

  Future<void> _persistAdsRemoved(bool value, {bool syncCloud = true}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_adsRemovedKey, value);
    _hasPersistedFounderState = true;
    state = state.copyWith(adsRemoved: value, isPurchasing: false);

    if (syncCloud && value) {
      await _syncFounderToCloud(source: 'purchase');
    }
  }

  /// Initiates the purchase flow for the "remove ads" product.
  Future<void> buyRemoveAds() async {
    state = state.copyWith(isPurchasing: true, errorMessage: null);

    final available = await _service.isAvailable;
    if (!available) {
      state = state.copyWith(
        isPurchasing: false,
        errorMessage: 'Store not available on this device.',
      );
      return;
    }

    final response = await _service.queryRemoveAdsProduct();
    if (response.error != null) {
      PurchaseService.log(
        'queryProductDetails error: code=${response.error!.code} '
        'message=${response.error!.message} '
        'details=${response.error!.details}',
      );
    }

    if (response.productDetails.isEmpty) {
      state = state.copyWith(
        isPurchasing: false,
        errorMessage: 'Product not found. Please try again later.',
      );
      return;
    }

    try {
      await _service.buyNonConsumable(response.productDetails.first);
      // Purchase result arrives via the stream; keep isPurchasing = true.
    } catch (e) {
      PurchaseService.log('buyNonConsumable error: $e');
      state = state.copyWith(isPurchasing: false, errorMessage: e.toString());
    }
  }

  /// Restores previously completed purchases.
  ///
  /// Sets [RestoreOutcome.success] when a prior purchase is found, or
  /// [RestoreOutcome.notFound] if nothing is restored within the timeout.
  Future<void> restorePurchases() async {
    state = state.copyWith(
      isPurchasing: true,
      errorMessage: null,
      restoreOutcome: RestoreOutcome.none,
    );
    _pendingRestore = true;
    _restoreTimer?.cancel();

    try {
      await _service.restorePurchases();

      // Give the store up to 8 seconds to deliver stream events.
      // If nothing arrives for our product, declare "not found".
      _restoreTimer = Timer(_restoreTimeout, () {
        if (_pendingRestore) {
          _pendingRestore = false;
          state = state.copyWith(
            isPurchasing: false,
            restoreOutcome: RestoreOutcome.notFound,
          );
        }
      });
    } catch (e) {
      PurchaseService.log('restorePurchases error: $e');
      _pendingRestore = false;
      _restoreTimer?.cancel();
      state = state.copyWith(isPurchasing: false, errorMessage: e.toString());
    }
  }

  /// Resets [RestoreOutcome] back to [RestoreOutcome.none] once the UI has
  /// consumed and displayed the outcome.
  void clearRestoreOutcome() {
    state = state.copyWith(restoreOutcome: RestoreOutcome.none);
  }

  @override
  void dispose() {
    _restoreTimer?.cancel();
    _purchaseSubscription?.cancel();
    _authStateSubscription?.cancel();
    _cloudProfileSubscription?.cancel();
    super.dispose();
  }
}

/// Global provider for the in-app purchase state.
final purchaseProvider = StateNotifierProvider<PurchaseNotifier, PurchaseState>(
  (ref) => PurchaseNotifier(),
);

/// Debug-only provider that forces Founder Aquarist status without a real
/// purchase. Only meaningful in debug builds ([kDebugMode]); always `false`
/// in release builds. Reset on every cold start.
final debugForceFounderProvider = StateProvider<bool>((ref) => false);

bool shouldBackfillFounderProfile({
  required bool localFounder,
  required bool cloudFounder,
}) => localFounder && !cloudFounder;

bool computeFounderAccess({
  required bool purchasedFounder,
  required bool cloudFounder,
  required bool debugForcedFounder,
  required bool debugMode,
}) {
  final effectiveFounder = purchasedFounder || cloudFounder;
  if (debugMode) return effectiveFounder || debugForcedFounder;
  return effectiveFounder;
}

/// The effective Founder Aquarist status for the current user.
///
/// In debug builds, this is `true` when either:
///   - the user has actually purchased a founder product ([PurchaseState.isFounder]), or
///   - the [debugForceFounderProvider] override is enabled.
/// In release builds, this only reflects the real purchase state.
final isFounderProvider = Provider<bool>((ref) {
  final purchasedFounder = ref.watch(purchaseProvider).isFounder;
  final cloudFounderAsync = ref.watch(currentUserProfileProvider);
  final cloudFounder = cloudFounderAsync.when(
    data: (profile) => profile?.founderEntitled ?? false,
    loading: () => purchasedFounder,
    error: (_, __) => purchasedFounder,
  );
  final debugForcedFounder = ref.watch(debugForceFounderProvider);
  return computeFounderAccess(
    purchasedFounder: purchasedFounder,
    cloudFounder: cloudFounder,
    debugForcedFounder: debugForcedFounder,
    debugMode: kDebugMode,
  );
});
