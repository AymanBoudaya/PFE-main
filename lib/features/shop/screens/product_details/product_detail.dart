import 'package:caferesto/common/widgets/appbar/appbar.dart';
import 'package:caferesto/features/shop/controllers/product/favorites_controller.dart';
import 'package:caferesto/features/shop/controllers/product/share_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:readmore/readmore.dart';

import '../../../../utils/constants/colors.dart';
import '../../../../utils/constants/sizes.dart';
import '../../../../utils/device/device_utility.dart';
import '../../../../utils/helpers/helper_functions.dart';
import '../../controllers/product/panier_controller.dart';
import '../../models/produit_model.dart';
import '../cart/cart.dart';
import '../product_reviews/product_reviews.dart';
import 'widgets/product_attributes.dart';
import 'widgets/product_detail_image_slider.dart';
import 'widgets/product_meta_data.dart';

class ProductDetailScreen extends StatelessWidget {
  const ProductDetailScreen({super.key, required this.product});

  final ProduitModel product;

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    final isDesktop = TDeviceUtils.isDesktop(context);
    final isSmallScreen = MediaQuery.of(context).size.width < 380;

    return Scaffold(
      backgroundColor: dark ? AppColors.dark : AppColors.light,
      bottomNavigationBar: _buildBottomBar(context, dark, isSmallScreen),
      body: SafeArea(
        child: isDesktop ? _buildDesktopLayout(dark) : _buildMobileLayout(dark),
      ),
    );
  }

  Widget _buildDesktopLayout(bool dark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left side - Images
          Expanded(
            flex: 2,
            child: _buildProductImageSection(dark),
          ),

          const SizedBox(width: 40),

          // Right side - Details
          Expanded(
            flex: 1,
            child: SingleChildScrollView(
              child: _buildProductDetails(dark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(bool dark) {
    return SingleChildScrollView(
      child: Column(
        children: [
          /// 1 - Product Image Section
          _buildProductImageSection(dark),

          /// 2 - Product Details
          Padding(
            padding: const EdgeInsets.all(AppSizes.defaultSpace),
            child: _buildProductDetails(dark),
          ),
        ],
      ),
    );
  }

  Widget _buildProductImageSection(bool dark) {
    final hasImage = product.imageUrl != null && product.imageUrl!.isNotEmpty;

    return hasImage
        ? TProductImageSlider(product: product)
        : _buildTrendyImagePlaceholder(dark);
  }

  Widget _buildTrendyImagePlaceholder(bool dark) {
    return Scaffold(
      appBar: TAppBar(),
      body: Container(
        height: 400,
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: dark
                ? [Colors.grey.shade800, Colors.grey.shade900]
                : [Colors.grey.shade100, Colors.grey.shade200],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Background Pattern
            Positioned.fill(
              child: CustomPaint(
                painter: _ProductPlaceholderPainter(dark: dark),
              ),
            ),

            // Content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animated Icon
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: dark
                          ? Colors.green.shade800.withOpacity(0.3)
                          : Colors.green.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.photo_camera_rounded,
                      size: 40,
                      color:
                          dark ? Colors.green.shade300 : Colors.green.shade600,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Text
                  Text(
                    'Image non disponible',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: dark ? Colors.grey.shade300 : Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Subtitle
                  Text(
                    'Produit de qualité garantie',
                    style: TextStyle(
                      fontSize: 14,
                      color: dark ? Colors.grey.shade500 : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),

            // Decorative Elements
            Positioned(
              top: 20,
              right: 20,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Nouveau',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductDetails(bool dark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// Rating & Share
        _buildRatingShareRow(dark),

        const SizedBox(height: AppSizes.md),

        /// Product Meta Data
        TProductMetaData(product: product),

        const SizedBox(height: AppSizes.lg),

        /// Attributes for variable products
        if (product.productType == 'variable')
          TProductAttributes(product: product),

        const SizedBox(height: AppSizes.xl),

        /// Description
        _buildDescriptionSection(dark),

        const SizedBox(height: AppSizes.xl),

        /// Reviews Preview
        // _buildReviewsSection(dark),

        // const SizedBox(height: 100), // Space for bottom bar
      ],
    );
  }

  Widget _buildRatingShareRow(bool dark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        /// Rating
        Row(
          children: [
            Icon(Icons.star_rounded, color: Colors.amber, size: 20),
            const SizedBox(width: 4),
            Text(
              '4.8',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: dark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '(199 reviews)',
              style: TextStyle(
                color: dark ? Colors.grey.shade400 : Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
          ],
        ),

        /// Share & Favorite
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: dark ? Colors.grey.shade800 : Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: InkWell(
                onTap: () => ShareController.instance.shareProduct(product),
                child: Icon(
                  Icons.share_rounded,
                  size: 18,
                  color: dark ? Colors.grey.shade300 : Colors.grey.shade700,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Obx(() {
              final isFav =
                  FavoritesController.instance.isFavourite(product.id);
              return Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: dark ? Colors.grey.shade800 : Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                child: InkWell(
                  onTap: () => FavoritesController.instance
                      .toggleFavoriteProduct(product.id),
                  child: Icon(
                    isFav
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    size: 18,
                    color: isFav
                        ? Colors.red
                        : (dark ? Colors.grey.shade300 : Colors.grey.shade700),
                  ),
                ),
              );
            })
          ],
        ),
      ],
    );
  }

  Widget _buildDescriptionSection(bool dark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Description',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: dark ? Colors.white : Colors.black,
          ),
        ),
        const SizedBox(height: AppSizes.sm),
        ReadMoreText(
          product.description ??
              'Aucune description disponible pour ce produit.',
          trimLines: 3,
          trimMode: TrimMode.Line,
          trimCollapsedText: 'Voir plus',
          trimExpandedText: 'Voir moins',
          moreStyle: TextStyle(
            color: Colors.green.shade600,
            fontWeight: FontWeight.w600,
          ),
          lessStyle: TextStyle(
            color: Colors.green.shade600,
            fontWeight: FontWeight.w600,
          ),
          style: TextStyle(
            color: dark ? Colors.grey.shade300 : Colors.grey.shade700,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildReviewsSection(bool dark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: dark ? Colors.grey.shade900 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: dark ? Colors.grey.shade800 : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Avis des clients',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: dark ? Colors.white : Colors.black,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: dark
                      ? Colors.green.shade900.withOpacity(0.3)
                      : Colors.green.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: dark ? Colors.green.shade800 : Colors.green.shade100,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '4.8/5',
                      style: TextStyle(
                        color: dark
                            ? Colors.green.shade300
                            : Colors.green.shade800,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Basé sur 199 achats vérifiés',
            style: TextStyle(
              color: dark ? Colors.grey.shade400 : Colors.grey.shade600,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: () => Get.to(() => const ProductReviewsScreen()),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: dark ? Colors.grey.shade800 : Colors.grey.shade200,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Voir tous les avis',
                    style: TextStyle(
                      color: Colors.green.shade600,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Icon(Icons.arrow_forward_rounded,
                      size: 16, color: Colors.green.shade600),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, bool dark, bool isSmallScreen) {
    final isDesktop = TDeviceUtils.isDesktop(context);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 40 : AppSizes.defaultSpace,
        vertical: 16,
      ),
      decoration: BoxDecoration(
        color: dark ? AppColors.darkerGrey : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
        borderRadius: isDesktop
            ? BorderRadius.circular(20)
            : const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
      ),
      child: isDesktop
          ? _buildDesktopBottomBar(dark)
          : _buildMobileBottomBar(dark, isSmallScreen),
    );
  }

  Widget _buildDesktopBottomBar(bool dark) {
    return Row(
      children: [
        /// Price Display
        _buildPriceDisplay(dark),

        /// Quantity Controls
        _buildQuantityControls(dark),

        const SizedBox(width: 20),

        /// Add to Cart Button
        Expanded(
          flex: 2,
          child: _buildMainActionButton(false), // false for not small screen
        ),
      ],
    );
  }

  Widget _buildMobileBottomBar(bool dark, bool isSmallScreen) {
    return Row(
      children: [
        /// Price Display
        Expanded(
          child: _buildPriceDisplay(dark),
        ),

        /// Quantity Controls & Add to Cart
        Expanded(
          flex: 2,
          child: Row(
            children: [
              _buildQuantityControls(dark),
              const SizedBox(width: 8),
              Expanded(child: _buildMainActionButton(isSmallScreen)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPriceDisplay(bool dark) {
    final controller = CartController.instance;

    return Obx(() {
      final quantity = controller.getProductQuantityInCart(product.id);
      // Get sale price or regular price
      final unitPrice = product.salePrice ?? product.price;
      final totalPrice = unitPrice * quantity;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            quantity > 0 ? 'Total' : 'Prix',
            style: TextStyle(
              color: dark ? Colors.grey.shade400 : Colors.grey.shade600,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 2),
          // Show total price when items in cart, unit price when empty
          Text(
            quantity > 0
                ? '${totalPrice.toStringAsFixed(2)} DT'
                : '${unitPrice.toStringAsFixed(2)} DT',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.green.shade600,
            ),
          ),
        ],
      );
    });
  }

  Widget _buildQuantityControls(bool dark) {
    final controller = CartController.instance;

    return Obx(() {
      final quantity = controller.getProductQuantityInCart(product.id);

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: dark
              ? Colors.green.shade900.withOpacity(0.2)
              : Colors.green.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: dark ? Colors.green.shade800 : Colors.green.shade100,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            /// Decrement Button
            GestureDetector(
              onTap: quantity > 0 ? () => _handleDecrement(controller) : null,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: quantity > 0
                      ? (dark ? Colors.green.shade800 : Colors.green.shade100)
                      : (dark ? Colors.grey.shade800 : Colors.grey.shade100),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.remove_rounded,
                  size: 16,
                  color: quantity > 0
                      ? (dark ? Colors.green.shade200 : Colors.green.shade800)
                      : (dark ? Colors.grey.shade500 : Colors.grey.shade400),
                ),
              ),
            ),

            /// Quantity Display
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                quantity.toString(),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: dark ? Colors.white : Colors.black,
                ),
              ),
            ),

            /// Increment Button
            GestureDetector(
              onTap: () => _handleIncrement(controller),
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: dark ? Colors.green.shade800 : Colors.green.shade100,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color:
                          Colors.green.shade200.withOpacity(dark ? 0.3 : 0.5),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.add_rounded,
                  size: 16,
                  color: dark ? Colors.green.shade200 : Colors.green.shade800,
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildMainActionButton(bool isSmallScreen) {
    final controller = CartController.instance;

    return Obx(() {
      final quantity = controller.getProductQuantityInCart(product.id);
      final hasItems = quantity > 0;

      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _handleMainAction(controller),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: hasItems
                    ? [Colors.green.shade600, Colors.green.shade800]
                    : [Colors.green, Colors.green.shade700],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.shade300.withOpacity(0.5),
                  blurRadius: hasItems ? 15 : 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                /// Button Content - Responsive layout
                if (isSmallScreen && hasItems)
                  // Small screen with items - compact layout
                  Icon(
                    Icons.shopping_cart_checkout_rounded,
                    color: Colors.white,
                    size: 20,
                  )
                else if (isSmallScreen)
                  // Small screen without items - compact layout
                  Icon(
                    Icons.add_shopping_cart_rounded,
                    color: Colors.white,
                    size: 20,
                  )
                else
                  // Normal screen - full layout
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        hasItems
                            ? Icons.shopping_cart_checkout_rounded
                            : Icons.add_shopping_cart_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        hasItems
                            ? 'Commander ($quantity)'
                            : 'Ajouter au panier',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),

                /// Badge for small screen when items exist
                if (isSmallScreen && hasItems)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          quantity.toString(),
                          style: TextStyle(
                            color: Colors.green.shade800,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    });
  }

  void _handleMainAction(CartController controller) {
    if (!controller.canAddProduct(product)) return;

    if (product.productType == 'variable') {
      final hasSelectedVariant = controller.hasSelectedVariant(product.id);
      if (!hasSelectedVariant) {
        Get.snackbar(
          'Sélection requise',
          'Veuillez choisir une variante avant de continuer',
          backgroundColor: Colors.orange,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }
    }

    final quantity = controller.getProductQuantityInCart(product.id);
    if (quantity == 0) {
      // Add one item if none exists
      final cartItem = controller.productToCartItem(product, 1);
      controller.addOneToCart(cartItem);
    } else {
      // Navigate to cart screen
      Get.to(() => const CartScreen());
    }
  }

  void _handleIncrement(CartController controller) {
    if (!controller.canAddProduct(product)) return;
    if (product.productType == 'single' ||
        controller.hasSelectedVariant(product.id)) {
      final cartItem = controller.productToCartItem(product, 1);
      controller.addOneToCart(cartItem);
    }
  }

  void _handleDecrement(CartController controller) {
    if (product.productType == 'single' ||
        controller.hasSelectedVariant(product.id)) {
      final cartItem = controller.productToCartItem(product, 1);
      controller.removeOneFromCart(cartItem);
    }
  }
}

// Custom painter for the trendy placeholder background
class _ProductPlaceholderPainter extends CustomPainter {
  final bool dark;

  _ProductPlaceholderPainter({required this.dark});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = dark
          ? Colors.grey.shade800.withOpacity(0.3)
          : Colors.grey.shade300.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Draw diagonal lines
    for (double i = -size.height; i < size.width; i += 20) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
