import 'dart:async';

import 'package:fish_ai/constants.dart';
import 'package:fish_ai/providers/purchase_provider.dart';
import 'package:fish_ai/services/purchase_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ---------------------------------------------------------------------------
// Fake PurchaseService for unit testing
// ---------------------------------------------------------------------------

class _FakePurchaseService extends PurchaseService {
  final _controller = StreamController<List<PurchaseDetails>>.broadcast();
  bool storeAvailable = true;
  List<ProductDetails> products = [];
  bool buyThrows = false;
  bool restoreThrows = false;
  final List<PurchaseDetails> completed = [];

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => _controller.stream;

  @override
  Future<bool> get isAvailable async => storeAvailable;

  @override
  Future<ProductDetailsResponse> queryRemoveAdsProduct() async {
    return ProductDetailsResponse(
      productDetails: products,
      notFoundIDs: products.isEmpty ? [removeAdsProductId] : [],
      error: null,
    );
  }

  @override
  Future<bool> buyNonConsumable(ProductDetails productDetails) async {
    if (buyThrows) throw Exception('billing unavailable');
    return true;
  }

  @override
  Future<void> restorePurchases() async {
    if (restoreThrows) throw Exception('restore failed');
  }

  @override
  Future<void> completePurchase(PurchaseDetails purchaseDetails) async {
    completed.add(purchaseDetails);
  }

  void emitPurchases(List<PurchaseDetails> purchases) {
    _controller.add(purchases);
  }

  void closeStream() => _controller.close();
}

// ---------------------------------------------------------------------------
// Stub PurchaseDetails for testing
// ---------------------------------------------------------------------------

class _StubPurchaseDetails extends PurchaseDetails {
  _StubPurchaseDetails({
    required String productID,
    required PurchaseStatus status,
  }) : super(
          productID: productID,
          purchaseID: 'test-purchase-id',
          verificationData: PurchaseVerificationData(
            localVerificationData: 'local',
            serverVerificationData: 'server',
            source: 'test',
          ),
          transactionDate: '1234567890',
          status: status,
        );

  @override
  bool get pendingCompletePurchase =>
      status == PurchaseStatus.purchased ||
      status == PurchaseStatus.restored;
}

class _FakeProductDetails extends ProductDetails {
  _FakeProductDetails()
      : super(
          id: removeAdsProductId,
          title: 'Remove Ads',
          description: 'Remove all ads',
          price: '\$0.99',
          rawPrice: 0.99,
          currencyCode: 'USD',
          currencySymbol: '\$',
        );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakePurchaseService fakeService;
  late ProviderContainer container;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    fakeService = _FakePurchaseService();
  });

  tearDown(() {
    container.dispose();
    fakeService.closeStream();
  });

  ProviderContainer makeContainer() {
    return ProviderContainer(
      overrides: [
        purchaseProvider.overrideWith(
          (ref) => PurchaseNotifier(service: fakeService),
        ),
      ],
    );
  }

  group('PurchaseState', () {
    test('default values are correct', () {
      const state = PurchaseState();
      expect(state.adsRemoved, isFalse);
      expect(state.isLoading, isTrue);
      expect(state.isPurchasing, isFalse);
      expect(state.errorMessage, isNull);
    });

    test('copyWith updates only specified fields', () {
      const state = PurchaseState();
      final updated = state.copyWith(adsRemoved: true, isLoading: false);
      expect(updated.adsRemoved, isTrue);
      expect(updated.isLoading, isFalse);
      expect(updated.isPurchasing, isFalse);
      expect(updated.errorMessage, isNull);
    });

    test('copyWith preserves errorMessage when not provided', () {
      const state = PurchaseState(errorMessage: 'oops');
      final updated = state.copyWith(adsRemoved: false);
      expect(updated.errorMessage, equals('oops'));
    });

    test('copyWith clears errorMessage when explicitly null', () {
      const state = PurchaseState(errorMessage: 'oops');
      final cleared = state.copyWith(errorMessage: null);
      expect(cleared.errorMessage, isNull);
    });
  });

  group('PurchaseNotifier – initial state', () {
    test('loads adsRemoved=false from empty SharedPreferences', () async {
      container = makeContainer();
      container.read(purchaseProvider.notifier);
      await Future.delayed(const Duration(milliseconds: 100));

      final state = container.read(purchaseProvider);
      expect(state.adsRemoved, isFalse);
      expect(state.isLoading, isFalse);
    });

    test('loads adsRemoved=true from SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({'adsRemoved': true});
      container = makeContainer();
      container.read(purchaseProvider.notifier);
      await Future.delayed(const Duration(milliseconds: 100));

      final state = container.read(purchaseProvider);
      expect(state.adsRemoved, isTrue);
      expect(state.isLoading, isFalse);
    });
  });

  group('PurchaseNotifier – purchase stream handling', () {
    test('sets adsRemoved=true on PurchaseStatus.purchased', () async {
      container = makeContainer();
      container.read(purchaseProvider.notifier);
      await Future.delayed(const Duration(milliseconds: 50));

      fakeService.emitPurchases([
        _StubPurchaseDetails(
          productID: removeAdsProductId,
          status: PurchaseStatus.purchased,
        ),
      ]);
      await Future.delayed(const Duration(milliseconds: 50));

      expect(container.read(purchaseProvider).adsRemoved, isTrue);
    });

    test('sets adsRemoved=true on PurchaseStatus.restored', () async {
      container = makeContainer();
      container.read(purchaseProvider.notifier);
      await Future.delayed(const Duration(milliseconds: 50));

      fakeService.emitPurchases([
        _StubPurchaseDetails(
          productID: removeAdsProductId,
          status: PurchaseStatus.restored,
        ),
      ]);
      await Future.delayed(const Duration(milliseconds: 50));

      expect(container.read(purchaseProvider).adsRemoved, isTrue);
    });

    test('ignores purchases for other product IDs', () async {
      container = makeContainer();
      container.read(purchaseProvider.notifier);
      await Future.delayed(const Duration(milliseconds: 50));

      fakeService.emitPurchases([
        _StubPurchaseDetails(
          productID: 'other_product',
          status: PurchaseStatus.purchased,
        ),
      ]);
      await Future.delayed(const Duration(milliseconds: 50));

      expect(container.read(purchaseProvider).adsRemoved, isFalse);
    });

    test('completes purchases with pendingCompletePurchase=true', () async {
      container = makeContainer();
      container.read(purchaseProvider.notifier);
      await Future.delayed(const Duration(milliseconds: 50));

      final purchase = _StubPurchaseDetails(
        productID: removeAdsProductId,
        status: PurchaseStatus.purchased,
      );

      fakeService.emitPurchases([purchase]);
      await Future.delayed(const Duration(milliseconds: 50));

      expect(fakeService.completed, contains(purchase));
    });
  });

  group('PurchaseNotifier – buyRemoveAds', () {
    test('sets error when store is not available', () async {
      fakeService.storeAvailable = false;
      container = makeContainer();
      container.read(purchaseProvider.notifier);
      await Future.delayed(const Duration(milliseconds: 50));

      await container.read(purchaseProvider.notifier).buyRemoveAds();

      final state = container.read(purchaseProvider);
      expect(state.isPurchasing, isFalse);
      expect(state.errorMessage, isNotNull);
    });

    test('sets error when product is not found in store', () async {
      // products list is empty by default → product not found
      container = makeContainer();
      container.read(purchaseProvider.notifier);
      await Future.delayed(const Duration(milliseconds: 50));

      await container.read(purchaseProvider.notifier).buyRemoveAds();

      final state = container.read(purchaseProvider);
      expect(state.isPurchasing, isFalse);
      expect(state.errorMessage, isNotNull);
    });

    test('sets error when buyNonConsumable throws', () async {
      fakeService.products = [_FakeProductDetails()];
      fakeService.buyThrows = true;
      container = makeContainer();
      container.read(purchaseProvider.notifier);
      await Future.delayed(const Duration(milliseconds: 50));

      await container.read(purchaseProvider.notifier).buyRemoveAds();

      final state = container.read(purchaseProvider);
      expect(state.isPurchasing, isFalse);
      expect(state.errorMessage, isNotNull);
    });
  });

  group('PurchaseNotifier – restorePurchases', () {
    test('does not set error on successful restore', () async {
      container = makeContainer();
      container.read(purchaseProvider.notifier);
      await Future.delayed(const Duration(milliseconds: 50));

      await container.read(purchaseProvider.notifier).restorePurchases();

      expect(container.read(purchaseProvider).errorMessage, isNull);
    });

    test('sets error when restorePurchases throws', () async {
      fakeService.restoreThrows = true;
      container = makeContainer();
      container.read(purchaseProvider.notifier);
      await Future.delayed(const Duration(milliseconds: 50));

      await container.read(purchaseProvider.notifier).restorePurchases();

      final state = container.read(purchaseProvider);
      expect(state.isPurchasing, isFalse);
      expect(state.errorMessage, isNotNull);
    });
  });
}
