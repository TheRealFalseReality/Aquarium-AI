import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:fish_ai/services/remote_config_service.dart';

/// Wraps the [InAppPurchase] plugin and exposes a thin API used by
/// [PurchaseNotifier].
///
/// The default constructor calls through to [InAppPurchase.instance].
/// Subclass this for unit testing.
class PurchaseService {
  const PurchaseService();

  InAppPurchase get _iap => InAppPurchase.instance;

  /// Returns a stream of purchase updates that should be listened to for the
  /// lifetime of the app.
  Stream<List<PurchaseDetails>> get purchaseStream => _iap.purchaseStream;

  /// Returns `true` when the underlying billing client is available.
  Future<bool> get isAvailable => _iap.isAvailable();

  /// Queries the store for the early supporter lifetime product details.
  /// The product ID is read from [RemoteConfigService.earlySupporterProductId]
  /// so it can be updated via Firebase Remote Config without an app update.
  Future<ProductDetailsResponse> queryRemoveAdsProduct() {
    return _iap
        .queryProductDetails({RemoteConfigService.earlySupporterProductId});
  }

  /// Initiates a non-consumable purchase for [productDetails].
  Future<bool> buyNonConsumable(ProductDetails productDetails) {
    final param = PurchaseParam(productDetails: productDetails);
    return _iap.buyNonConsumable(purchaseParam: param);
  }

  /// Asks the store to restore any previous purchases.
  Future<void> restorePurchases() => _iap.restorePurchases();

  /// Marks [purchaseDetails] as complete on the billing server.
  Future<void> completePurchase(PurchaseDetails purchaseDetails) =>
      _iap.completePurchase(purchaseDetails);

  /// Logs a debug message when in debug mode.
  static void log(String message) {
    if (kDebugMode) {
      debugPrint('[PurchaseService] $message');
    }
  }
}
