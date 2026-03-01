import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants.dart';
import '../services/purchase_service.dart';

const String _adsRemovedKey = 'adsRemoved';

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
}

/// Manages the in-app purchase state for removing ads.
class PurchaseNotifier extends StateNotifier<PurchaseState> {
  final PurchaseService _service;
  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;

  /// True while we are waiting for restore stream events to arrive.
  bool _pendingRestore = false;

  /// Fires after a short timeout to declare "no purchase found" if the
  /// restore stream never delivers our product.
  Timer? _restoreTimer;

  PurchaseNotifier({PurchaseService? service})
      : _service = service ?? const PurchaseService(),
        super(const PurchaseState()) {
    _init();
  }

  Future<void> _init() async {
    // Load persisted "ads removed" state immediately.
    final prefs = await SharedPreferences.getInstance();
    final adsRemoved = prefs.getBool(_adsRemovedKey) ?? kDebugMode;

    state = state.copyWith(adsRemoved: adsRemoved, isLoading: false);

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

  Future<void> _handlePurchaseUpdates(
      List<PurchaseDetails> purchaseDetailsList) async {
    for (final details in purchaseDetailsList) {
      PurchaseService.log(
          'Purchase update: ${details.productID} status=${details.status}');

      if (details.productID.contains('remove_ads')) {
        if (details.status == PurchaseStatus.purchased ||
            details.status == PurchaseStatus.restored) {
          // Persist and update state. For a restore, also record the outcome.
          final isRestore = _pendingRestore &&
              details.status == PurchaseStatus.restored;
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

  Future<void> _persistAdsRemoved(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_adsRemovedKey, value);
    state = state.copyWith(adsRemoved: value, isPurchasing: false);
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
          'details=${response.error!.details}');
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
      state = state.copyWith(
        isPurchasing: false,
        errorMessage: e.toString(),
      );
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
      state = state.copyWith(
        isPurchasing: false,
        errorMessage: e.toString(),
      );
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
    super.dispose();
  }
}

/// Global provider for the in-app purchase state.
final purchaseProvider =
    StateNotifierProvider<PurchaseNotifier, PurchaseState>(
  (ref) => PurchaseNotifier(),
);
