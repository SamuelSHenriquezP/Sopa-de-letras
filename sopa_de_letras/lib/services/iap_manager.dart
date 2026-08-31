import 'package:in_app_purchase/in_app_purchase.dart';

class IAPManager {
  static final InAppPurchase _iap = InAppPurchase.instance;
  static bool available = true;
  static List<ProductDetails> products = [];
  static const String _productId = 'sopa_sin_anuncios';

  static Future<void> initialize() async {
    available = await _iap.isAvailable();
    if (available) {
      const Set<String> ids = {_productId};
      final ProductDetailsResponse response = await _iap.queryProductDetails(
        ids,
      );
      products = response.productDetails;
    }
  }

  static void buyRemoveAds() {
    if (products.isNotEmpty) {
      final PurchaseParam purchaseParam = PurchaseParam(
        productDetails: products.first,
      );
      _iap.buyNonConsumable(purchaseParam: purchaseParam);
    }
  }
}
