import 'package:caferesto/features/shop/screens/product_details/product_detail.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../features/shop/controllers/product/cart_controller.dart';
import '../../../../../features/shop/models/produit_model.dart';
import '../../../../../utils/constants/colors.dart';

class ProductCardAddToCartButton extends StatelessWidget {
  const ProductCardAddToCartButton({
    super.key,
    required this.product,
  });

  final ProduitModel product;

  bool get isSingleProduct {
    return product.productType == 'single';
  }

  @override
  Widget build(BuildContext context) {
    final cartController = CartController.instance;
    return Obx(() {
      final productQuantityInCart =
          cartController.getProductQuantityInCart(product.id);

      return Container(
        height: 32,
        width: productQuantityInCart > 0 ? 80 : 32, 
        decoration: BoxDecoration(
          color: productQuantityInCart > 0
              ? AppColors.primary
              : AppColors.dark.withAlpha((255 * 0.8).toInt()),
          borderRadius: BorderRadius.circular(12),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: productQuantityInCart > 0
              ? _buildCounterWidget(
                  context, cartController, productQuantityInCart)
              : _buildAddButton(context, cartController),
        ),
      );
    });
  }

  Widget _buildAddButton(BuildContext context, CartController cartController) {
    return GestureDetector(
      onTap: () => _handleAddToCart(cartController),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Icon(
            Icons.add_rounded,
            color: Colors.white,
            size: 18,
          ),
        ),
      ),
    );
  }

  Widget _buildCounterWidget(
      BuildContext context, CartController cartController, int quantity) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // BOUTON DÉCRÉMENTER - Toujours visible quand quantité >= 1
          GestureDetector(
            onTap: () => _handleDecrement(cartController),
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Center(
                child: Icon(
                  Icons.remove_rounded,
                  color: Colors.white,
                  size: 14,
                ),
              ),
            ),
          ),

          // QUANTITÉ
          Container(
            constraints: const BoxConstraints(minWidth: 20),
            child: Text(
              quantity.toString(),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
          ),

          // BOUTON INCREMENTER
          GestureDetector(
            onTap: () => _handleIncrement(cartController),
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Center(
                child: Icon(
                  Icons.add_rounded,
                  color: Colors.white,
                  size: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleAddToCart(CartController cartController) {
    if (isSingleProduct) {
      final cartItem = cartController.productToCartItem(product, 1);
      cartController.addOneToCart(cartItem);
    } else {
      Get.to(() => ProductDetailScreen(product: product));
    }
  }

  void _handleIncrement(CartController cartController) {
    if (isSingleProduct) {
      final cartItem = cartController.productToCartItem(product, 1);
      cartController.addOneToCart(cartItem);
    }
  }

  void _handleDecrement(CartController cartController) {
    if (isSingleProduct) {
      final cartItem = cartController.productToCartItem(product, 1);
      cartController.removeOneFromCart(cartItem);
    }
  }
}
