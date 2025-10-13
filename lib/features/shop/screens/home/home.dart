import 'package:caferesto/common/widgets/products/product_cards/product_card_vertical.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';

import '../../../../common/widgets/layouts/grid_layout.dart';
import '../../../../common/widgets/shimmer/vertical_product_shimmer.dart';
import '../../../../common/widgets/texts/section_heading.dart';
import '../../../../utils/constants/image_strings.dart';
import '../../../../utils/constants/sizes.dart';
import '../../../../common/widgets/custom_shapes/containers/primary_header_container.dart';
import '../../../authentication/screens/home/widgets/home_categories.dart';
import '../../controllers/product/produit_controller.dart';
import '../all_products/all_products.dart';
import 'widgets/home_appbar.dart';
import 'widgets/promo_slider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ProduitController());
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            /// Primary Header Container
            TPrimaryHeaderContainer(
              child: Column(
                children: [
                  /// AppBar
                  const THomeAppBar(),
                  const SizedBox(height: AppSizes.spaceBtwSections),

                  /// Catégories
                  TSectionHeading(
                    title: 'Catégories Populaires',
                    showActionButton: true,
                  ),
                  const SizedBox(height: AppSizes.spaceBtwItems),

                  /// Categories List
                  const THomeCategories(),
                  const SizedBox(height: AppSizes.spaceBtwItems),
                ],
              ),
            ),

            /// Corps
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: _getHorizontalPadding(screenWidth),
                vertical: AppSizes.defaultSpace,
              ),
              child: Column(
                children: [
                  /// -- PromoSlider avec hauteur responsive
                  TPromoSlider(
                    banners: const [
                      TImages.promoBanner1,
                      TImages.promoBanner2,
                      TImages.promoBanner3
                    ],
                    height: _getPromoSliderHeight(screenWidth, screenHeight),
                    autoPlay: true,
                    autoPlayInterval: 5000,
                  ),
                  const SizedBox(height: AppSizes.spaceBtwSections),

                  /// -- En tête
                  TSectionHeading(
                    title: 'Produits Populaires',
                    onPressed: () => Get.to(() => AllProducts(
                          title: 'Produits populaires',
                          futureMethod: controller.fetchAllFeaturedProducts(),
                        )),
                  ),
                  const SizedBox(height: AppSizes.spaceBtwItems),

                  /// Popular products avec GridLayout responsive
                  Obx(() {
                    if (controller.isLoading.value) {
                      return const TVerticalProductShimmer();
                    }
                    if (controller.featuredProducts.isEmpty) {
                      return _buildEmptyState();
                    }
                    return GridLayout(
                      itemCount: controller.featuredProducts.length,
                      itemBuilder: (_, index) => ProductCardVertical(
                        product: controller.featuredProducts[index],
                      ),
                      crossAxisCount: _getCrossAxisCount(screenWidth),
                      mainAxisExtent: _getMainAxisExtent(screenWidth),
                    );
                  })
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🔧 MÉTHODES RESPONSIVES

  /// Détermine le nombre de colonnes selon la largeur de l'écran
  int _getCrossAxisCount(double screenWidth) {
    if (screenWidth < 480) {
      return 2; // Mobile petit
    } else if (screenWidth < 768) {
      return 3; // Mobile large / tablette petite
    } else if (screenWidth < 1024) {
      return 4; // Tablette
    } else if (screenWidth < 1440) {
      return 5; // PC moyen
    } else {
      return 6; // PC large
    }
  }

  /// Détermine la hauteur des éléments selon la largeur de l'écran
  double _getMainAxisExtent(double screenWidth) {
    if (screenWidth < 480) {
      return 280; // Mobile petit
    } else if (screenWidth < 768) {
      return 300; // Mobile large / tablette petite
    } else if (screenWidth < 1024) {
      return 320; // Tablette
    } else if (screenWidth < 1440) {
      return 340; // PC moyen
    } else {
      return 360; // PC large
    }
  }

  /// Détermine la hauteur du PromoSlider avec taille maximale
  double _getPromoSliderHeight(double screenWidth, double screenHeight) {
    double baseHeight;

    if (screenWidth < 480) {
      baseHeight = screenHeight * 0.20; // 20% de la hauteur sur mobile
    } else if (screenWidth < 768) {
      baseHeight = screenHeight * 0.25; // 25% sur tablette petite
    } else if (screenWidth < 1024) {
      baseHeight = screenHeight * 0.30; // 30% sur tablette
    } else {
      baseHeight = screenHeight * 0.35; // 35% sur PC
    }

    // Taille maximale à ne pas dépasser
    const double maxHeight = 400.0;
    return baseHeight > maxHeight ? maxHeight : baseHeight;
  }

  /// Détermine le padding horizontal selon la largeur de l'écran
  double _getHorizontalPadding(double screenWidth) {
    if (screenWidth < 480) {
      return 16.0; // Mobile petit
    } else if (screenWidth < 768) {
      return 20.0; // Mobile large
    } else if (screenWidth < 1024) {
      return 32.0; // Tablette
    } else if (screenWidth < 1440) {
      return 48.0; // PC moyen
    } else {
      return 64.0; // PC large
    }
  }

  /// Widget pour l'état vide
  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(
            Icons.fastfood_outlined,
            size: 64,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun produit populaire',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Les produits en vedette apparaîtront ici',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
