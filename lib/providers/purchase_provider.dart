import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants.dart';
import '../services/purchase_service.dart';

const String _adsRemovedKey = 'adsRemoved';

/// Sentinel used by [PurchaseState.copyWith] to distinguish between
/// "errorMessage not provided" and "errorMessage explicitly set to null".
const Object _undefinedError = Object();

/// Immutable state for the in-app purchase feature.
class PurchaseState {
  final bool adsRemoved;
  final bool isLoading;
  final bool isPurchasing;
  final String? errorMessage;

  const PurchaseState({
    this.adsRemoved = false,
    this.isLoading = true,
    this.isPurchasing = false,
    this.errorMessage,
  });

  PurchaseState copyWith({
    bool? adsRemoved,
    bool? isLoading,
    bool? isPurchasing,
    // Use the sentinel to distinguish "not provided" from explicit null.
    Object? errorMessage = _undefinedError,
  }) {
    return PurchaseState(
      adsRemoved: adsRemoved ?? this.adsRemoved,
      isLoading: isLoading ?? this.isLoading,
      isPurchasing: isPurchasing ?? this.isPurchasing,
      errorMessage: identical(errorMessage, _undefinedError)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}

/// Manages the in-app purchase state for removing ads.
class PurchaseNotifier extends StateNotifier<PurchaseState> {
  final PurchaseService _service;
  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;

  PurchaseNotifier({PurchaseService? service})
      : _service = service ?? const PurchaseService(),
        super(const PurchaseState()) {
    _init();
  }

  Future<void> _init() async {
    // Load persisted "ads removed" state immediately.
    final prefs = await SharedPreferences.getInstance();
    final adsRemoved = prefs.getBool(_adsRemovedKey) ?? false;

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

      if (details.productID == removeAdsProductId) {
        if (details.status == PurchaseStatus.purchased ||
            details.status == PurchaseStatus.restored) {
          await _persistAdsRemoved(true);
        } else if (details.status == PurchaseStatus.error) {
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
  Future<void> restorePurchases() async {
    state = state.copyWith(isPurchasing: true, errorMessage: null);
    try {
      await _service.restorePurchases();
      // Results arrive via the stream.
    } catch (e) {
      PurchaseService.log('restorePurchases error: $e');
      state = state.copyWith(
        isPurchasing: false,
        errorMessage: e.toString(),
      );
    }
  }

  @override
  void dispose() {
    _purchaseSubscription?.cancel();
    super.dispose();
  }
}

/// Global provider for the in-app purchase state.
final purchaseProvider =
    StateNotifierProvider<PurchaseNotifier, PurchaseState>(
  (ref) => PurchaseNotifier(),
);
