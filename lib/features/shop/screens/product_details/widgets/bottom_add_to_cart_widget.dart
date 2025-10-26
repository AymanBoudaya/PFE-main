import 'package:caferesto/common/widgets/icons/t_circular_icon.dart';
import 'package:caferesto/features/shop/controllers/product/cart_controller.dart';
import 'package:caferesto/features/shop/screens/cart/cart.dart';
import 'package:caferesto/utils/constants/colors.dart';
import 'package:caferesto/utils/constants/sizes.dart';
import 'package:caferesto/utils/helpers/helper_functions.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import '../../../models/produit_model.dart';
import '../product_detail.dart';

class TBottomAddToCart extends StatelessWidget {
  const TBottomAddToCart({super.key, required this.product});
  final ProduitModel product;

  bool get isSingleProduct => product.productType == 'single';

  @override
  Widget build(BuildContext context) {
    final controller = CartController.instance;
    final dark = THelperFunctions.isDarkMode(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.defaultSpace,
        vertical: AppSizes.defaultSpace / 2,
      ),
      decoration: BoxDecoration(
        color: dark ? AppColors.darkerGrey : AppColors.light,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(AppSizes.cardRadiusLg),
          topRight: Radius.circular(AppSizes.cardRadiusLg),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Obx(() {
        final productQuantityInCart =
            controller.getProductQuantityInCart(product.id);
        final quantity = productQuantityInCart;

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // ---- Decrement Button ----
            _buildQuantityButton(
              context,
              icon: Icons.remove_rounded,
              onPressed:
                  quantity > 0 ? () => _handleDecrement(controller) : null,
              isEnabled: quantity > 0,
            ),

            // ---- Main Quantity Button ----
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.sm),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: quantity > 0
                        ? _getActiveButtonGradient()
                        : _getInactiveButtonGradient(),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: quantity > 0
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ]
                        : [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => _handleMainButtonAction(controller),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Button Content
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 300),
                                child: quantity > 0
                                    ? Container(
                                        key: const ValueKey('cart_with_badge'),
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.2),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.shopping_cart_checkout_rounded,
                                          color: Colors.white,
                                          size: 22,
                                        ),
                                      )
                                    : Icon(
                                        Icons.add_shopping_cart_rounded,
                                        color: Colors.white,
                                        size: 22,
                                        key: const ValueKey('cart_icon'),
                                      ),
                              ),
                              const SizedBox(width: 12),
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 300),
                                child: quantity > 0
                                    ? Text(
                                        quantity.toString(),
                                        key: ValueKey('quantity_$quantity'),
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineSmall
                                            ?.copyWith(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                      )
                                    : Text(
                                        isSingleProduct
                                            ? 'Ajouter au panier'
                                            : 'Choisir les options',
                                        key: const ValueKey('add_to_cart'),
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                              ),
                            ],
                          ),

                          // Active Indicator
                          if (quantity > 0)
                            Positioned(
                              right: 20,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 500),
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.white.withOpacity(0.6),
                                      blurRadius: 8,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ---- Increment Button ----
            _buildQuantityButton(
              context,
              icon: Icons.add_rounded,
              onPressed: () => _handleIncrement(controller),
              isEnabled: true,
            ),
          ],
        );
      }),
    );
  }

  Widget _buildQuantityButton(
    BuildContext context, {
    required IconData icon,
    required VoidCallback? onPressed,
    required bool isEnabled,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color:
            isEnabled ? AppColors.primary : AppColors.darkGrey.withOpacity(0.3),
        shape: BoxShape.circle,
        boxShadow: isEnabled
            ? [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isEnabled ? onPressed : null,
          borderRadius: BorderRadius.circular(24),
          child: Center(
            child: Icon(
              icon,
              color: isEnabled ? Colors.white : AppColors.darkGrey,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }

  LinearGradient _getActiveButtonGradient() {
    return LinearGradient(
      colors: [
        AppColors.primary,
        AppColors.primary.withOpacity(0.8),
        AppColors.primary,
      ],
      stops: const [0.0, 0.5, 1.0],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  LinearGradient _getInactiveButtonGradient() {
    return LinearGradient(
      colors: [
        AppColors.darkGrey.withOpacity(0.8),
        AppColors.darkGrey.withOpacity(0.6),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  void _handleMainButtonAction(CartController controller) {
    if (isSingleProduct) {
      final currentQuantity = controller.getProductQuantityInCart(product.id);
      if (currentQuantity == 0) {
        // First time adding - add one to cart
        final cartItem = controller.productToCartItem(product, 1);
        controller.addOneToCart(cartItem);
      } else {
        // Already in cart - navigate to cart or show success
        Get.to(() => const CartScreen()); // Or any other action
      }
    } else {
      // For non-single products, navigate to detail screen
      Get.to(() => ProductDetailScreen(product: product));
    }
  }

  void _handleIncrement(CartController controller) {
    if (isSingleProduct) {
      final cartItem = controller.productToCartItem(product, 1);
      controller.addOneToCart(cartItem);
    }
  }

  void _handleDecrement(CartController controller) {
    if (isSingleProduct) {
      final cartItem = controller.productToCartItem(product, 1);
      controller.removeOneFromCart(cartItem);
    }
  }
}
