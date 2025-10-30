import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../../../../utils/constants/enums.dart';
import '../../../../utils/popups/loaders.dart';
import '../../models/cart_item_model.dart';
import '../../models/produit_model.dart';
import 'variation_controller.dart';

class CartController extends GetxController {
  static CartController get instance => Get.find();

  RxInt cartItemsCount = 0.obs;
  RxDouble totalCartPrice = 0.0.obs;
  final RxMap<String, int> tempQuantityMap = <String, int>{}.obs;
  RxList<CartItemModel> cartItems = <CartItemModel>[].obs;
  final variationController = Get.put(VariationController());

  CartController() {
    loadCartItems();
  }

  void updateVariation(String productId, String newSize, double newPrice) {
    int index = cartItems.indexWhere((item) => item.productId == productId);
    if (index >= 0) {
      cartItems[index] = cartItems[index].copyWith(
        selectedVariation: {
          'size': newSize,
          'price': newPrice.toString(),
        },
        price: newPrice,
      );
    }
    updateCartTotals();
  }

  bool canAddProduct(ProduitModel product) {
    // Si le panier est vide, tout est autorisé
    if (cartItems.isEmpty) return true;

    // Récupère l'établissement du premier produit du panier
    final currentEtablissementId = cartItems.first.etablissementId;
    print('Current Etablissement ID in cart: $currentEtablissementId');
    print('Current Etablissement ID in cart: ${product.etablissementId}');
    // Vérifie si l'établissement du produit correspond
    if (product.etablissementId == currentEtablissementId) {
      return true;
    } else {
      // Refuser si ce n'est pas le même établissement
      TLoaders.customToast(
        message:
            "Vous ne pouvez pas ajouter des produits de plusieurs établissements.",
      );
      return false;
    }
  }

  // --- Helper methods --------------------------------------------------------

  bool hasSelectedVariant() {
    final variation = variationController.selectedVariation.value;
    return variation.id.isNotEmpty && variation.attributeValues.isNotEmpty;
  }

  String _getKey(ProduitModel product) {
    final variationId = product.productType == 'variable'
        ? variationController.selectedVariation.value.id
        : "";
    return '${product.id}-$variationId';
  }

  // --- Quantity Management ---------------------------------------------------

  void updateTempQuantity(ProduitModel product, int quantity) {
    final key = _getKey(product);
    if (quantity <= 0) {
      tempQuantityMap.remove(key); // remove entry when 0
    } else {
      tempQuantityMap[key] = quantity;
    }
  }

  int getTempQuantity(ProduitModel product) {
    final key = _getKey(product);
    // Use temp if exists, else fallback to actual cart quantity
    return tempQuantityMap[key] ?? getExistingQuantity(product);
  }

  int getExistingQuantity(ProduitModel product) {
    if (product.productType == ProductType.single.toString()) {
      return getProductQuantityInCart(product.id);
    } else {
      final variationId = variationController.selectedVariation.value.id;
      return variationId.isNotEmpty
          ? getVariationQuantityInCart(product.id, variationId)
          : 0;
    }
  }

  // --- Add / Remove from Cart -----------------------------------------------

  void addToCart(ProduitModel product) {
    if (!canAddProduct(product)) return; // Vérification ajoutée ici

    final quantity = getTempQuantity(product);

    // Prevent adding if 0
    if (quantity < 1) {
      TLoaders.customToast(message: 'Veuillez choisir une quantité');
      return;
    }

    if (product.productType == ProductType.variable.toString() &&
        variationController.selectedVariation.value.id.isEmpty) {
      TLoaders.customToast(message: 'Veuillez choisir une variante');
      return;
    }

    if (product.productType == ProductType.variable.toString()) {
      if (variationController.selectedVariation.value.stock < 1) {
        TLoaders.customToast(message: 'Produit hors stock');
        return;
      }
    } else if (product.stockQuantity < 1) {
      TLoaders.customToast(message: 'Produit hors stock');
      return;
    }

    final selectedCartItem = productToCartItem(product, quantity);
    final index = cartItems.indexWhere((cartItem) =>
        cartItem.productId == selectedCartItem.productId &&
        cartItem.variationId == selectedCartItem.variationId);

    if (index >= 0) {
      // update existing item quantity
      cartItems[index].quantity = selectedCartItem.quantity;
    } else {
      // add new
      cartItems.add(selectedCartItem);
    }

    updateCart();
    TLoaders.customToast(message: 'Produit ajouté au panier');
  }

  CartItemModel productToCartItem(ProduitModel product, int quantity) {
    if (product.productType == ProductType.single.toString()) {
      variationController.resetSelectedAttributes();
    }

    final variation = variationController.selectedVariation.value;
    final isVariation = variation.id.isNotEmpty;
    final price = isVariation
        ? (variation.salePrice > 0 ? variation.salePrice : variation.price)
        : (product.salePrice > 0.0 ? product.salePrice : product.price);

    return CartItemModel(
      productId: product.id,
      title: product.name,
      price: price,
      image: isVariation ? variation.image : product.imageUrl,
      quantity: quantity,
      variationId: variation.id,
      brandName: product.etablissement?.name ?? 'Inconnu',
      selectedVariation: isVariation ? variation.attributeValues : null,
      etablissementId: product.etablissementId,
      product: product,
    );
  }

  // --- Cart Management -------------------------------------------------------

  void updateCart() {
    updateCartTotals();
    saveCartItems();
    cartItems.refresh();
  }

  void addOneToCart(CartItemModel item) {
    final index = cartItems.indexWhere((cartItem) =>
        cartItem.productId == item.productId &&
        cartItem.variationId == item.variationId);

    if (index >= 0) {
      cartItems[index].quantity++;
    } else {
      cartItems.add(item);
    }
    updateCart();
  }

  void removeOneFromCart(CartItemModel item) {
    final index = cartItems.indexWhere((cartItem) =>
        cartItem.productId == item.productId &&
        cartItem.variationId == item.variationId);

    if (index >= 0) {
      if (cartItems[index].quantity > 1) {
        cartItems[index].quantity--;
      } else {
        removeFromCartDialog(index);
      }
      updateCart();
    }
  }

  void removeFromCartDialog(int index) {
    Get.defaultDialog(
      title: 'Confirmation',
      middleText: 'Voulez-vous vraiment supprimer ce produit du panier?',
      textConfirm: 'Oui',
      textCancel: 'Non',
      onConfirm: () {
        cartItems.removeAt(index);
        updateCart();
        TLoaders.customToast(message: 'Produit supprimé du panier');
        Get.back();
      },
      onCancel: () => Get.back(),
    );
  }

  // --- Totals & Storage ------------------------------------------------------

  void updateCartTotals() {
    double calculatedTotalPrice = 0.0;
    int calculatedcartItemsCount = 0;
    for (var item in cartItems) {
      calculatedTotalPrice += (item.price) * item.quantity.toDouble();
      calculatedcartItemsCount += item.quantity;
    }
    totalCartPrice.value = calculatedTotalPrice;
    cartItemsCount.value = calculatedcartItemsCount;
  }

  void saveCartItems() async {
    final cartItemStrings = cartItems.map((item) => item.toJson()).toList();
    await GetStorage().write('cartItems', cartItemStrings);
  }

  void loadCartItems() async {
    final cartItemStrings = GetStorage().read<List<dynamic>>('cartItems');
    if (cartItemStrings != null) {
      cartItems.assignAll(cartItemStrings
          .map((item) => CartItemModel.fromJson(item as Map<String, dynamic>)));
      updateCartTotals();
    }
  }

  // --- Get Quantities --------------------------------------------------------

  int getProductQuantityInCart(String productId) {
    return cartItems
        .where((item) => item.productId == productId)
        .fold(0, (sum, el) => sum + el.quantity);
  }

  int getVariationQuantityInCart(String productId, String variationId) {
    final foundItem = cartItems.firstWhereOrNull(
      (item) => item.productId == productId && item.variationId == variationId,
    );
    return foundItem?.quantity ?? 0;
  }

  void clearCart() {
    tempQuantityMap.clear();
    cartItems.clear();
    updateCart();
  }

  bool canProceedToCheckout() {
    if (cartItems.isEmpty) return false;

    for (final item in cartItems) {
      if (item.quantity <= 0) return false; // prevent checkout if 0 qty
      final product = item.product;
      if (product != null && product.productType == 'variable') {
        if (item.selectedVariation == null || item.selectedVariation!.isEmpty) {
          return false;
        }
      }
    }
    return true;
  }

  int getProductQuantity(String productId) {
    final item = cartItems.firstWhereOrNull((e) => e.productId == productId);
    return item?.quantity ?? 0;
  }
}
