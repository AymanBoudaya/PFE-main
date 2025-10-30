import 'package:get/get.dart';

import '../../models/product_variation_model.dart';

class VariationController extends GetxController {

  /// Variables
  final RxMap<String, dynamic> selectedAttributes = <String, dynamic>{}.obs;
  final RxString variationStockStatus = ''.obs;
  final Rx<ProductVariationModel> selectedVariation =
      ProductVariationModel.empty().obs;

  /// -- Check if selected attributes match variation attributes
  RxString selectedSize = ''.obs;
  RxDouble selectedPrice = 0.0.obs;

  void selectVariation(String size, double price) {
    selectedSize.value = size;
    selectedPrice.value = price;

    // Create or update the variation model
    selectedVariation.value = ProductVariationModel(
      id: size, // or a unique combination if needed
      attributeValues: {'size': size},
      price: price,
      salePrice: 0.0,
      stock: 10, // example or dynamic value
    );
  }

  void clearVariation() {
    selectedSize.value = '';
    selectedPrice.value = 0.0;
  }

  @override
  void onClose() {
    // Nettoyage automatique quand le contrôleur est supprimé
    clearVariation();
    super.onClose();
  }

  /// -- Get available attribute values based on stock
  Set<String?> getAttributesAvailabilityInVariation(
      List<ProductVariationModel> variations, String attributeName) {
    return variations
        .where((variation) =>
            variation.attributeValues[attributeName] != null &&
            variation.attributeValues[attributeName]!.isNotEmpty &&
            variation.stock > 0)
        .map((variation) => variation.attributeValues[attributeName])
        .toSet();
  }

  String getVariationPrice() {
    return (selectedVariation.value.salePrice > 0
            ? selectedVariation.value.salePrice
            : selectedVariation.value.price)
        .toString();
  }

  /// -- Update stock status text
  void getProductVariationStockStatus() {
    variationStockStatus.value =
        selectedVariation.value.stock > 0 ? 'En Stock' : 'Hors Stock';
  }

  /// -- Reset all selections
  void resetSelectedAttributes() {
    selectedAttributes.clear();
    variationStockStatus.value = '';
    selectedVariation.value = ProductVariationModel.empty();
  }
}
