import 'package:caferesto/common/widgets/appbar/appbar.dart';
import 'package:caferesto/common/widgets/icons/t_circular_icon.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../common/widgets/products/product_cards/product_card_vertical.dart';
import '../../../../common/widgets/shimmer/vertical_product_shimmer.dart';
import '../../../../navigation_menu.dart';
import '../../../../utils/constants/colors.dart';
import '../../../../utils/constants/image_strings.dart';
import '../../../../utils/constants/sizes.dart';
import '../../../../utils/device/device_utility.dart';
import '../../../../utils/helpers/helper_functions.dart';
import '../../../../utils/loaders/animation_loader.dart';
import '../../controllers/product/favorites_controller.dart';
import '../../models/produit_model.dart';

class FavoriteScreen extends StatelessWidget {
  const FavoriteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = FavoritesController.instance;
    final isDark = THelperFunctions.isDarkMode(context);
    final isDesktop = TDeviceUtils.isDesktop(context);
    final isTablet = TDeviceUtils.isTablet(context);

    return Scaffold(
      backgroundColor: isDark ? AppColors.dark : AppColors.light,
      appBar: _buildAppBar(context, isDark, controller),
      body: _buildBody(context, controller, isDesktop, isTablet),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, bool isDark, FavoritesController controller) {
    return TAppBar(
      title: Text(
        'Mes Favoris',
        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
          color: isDark ? Colors.white : Colors.black,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        // Clear all button
        Obx(() => controller.favoriteIds.isNotEmpty
            ? IconButton(
                onPressed: () => _showClearAllDialog(context, controller),
                icon: Icon(
                  Icons.delete_outline_rounded,
                  color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                ),
                tooltip: 'Vider tous les favoris',
              )
            : const SizedBox.shrink()),
        
        // Home navigation
        TCircularIcon(
          icon: Icons.home_rounded,
          onPressed: () => Get.off(() => const NavigationMenu()),
          // tooltip: 'Retour à l\'accueil',
        ),
      ],
    );
  }

  Widget _buildBody(BuildContext context, FavoritesController controller, bool isDesktop, bool isTablet) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 40 : AppSizes.defaultSpace,
        vertical: isDesktop ? 20 : AppSizes.defaultSpace,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with count
          _buildHeader(context, controller),
          
          const SizedBox(height: AppSizes.spaceBtwSections),
          
          // Products grid
          Expanded(
            child: _buildProductsGrid(controller, isDesktop, isTablet),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, FavoritesController controller) {
    return Obx(() => Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Produits favoris (${controller.favoriteIds.length})',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        
        if (controller.favoriteIds.isNotEmpty)
          Text(
            '${controller.favoriteIds.length} ${controller.favoriteIds.length > 1 ? 'produits' : 'produit'}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
      ],
    ));
  }

  Widget _buildProductsGrid(FavoritesController controller, bool isDesktop, bool isTablet) {
    return Obx(() {
      if (controller.favoriteIds.isEmpty) {
        return _buildEmptyState(controller);
      }

      return FutureBuilder(
        future: controller.getFavoriteProducts(),
        builder: (context, snapshot) {
          // Handle loading state
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingState(isDesktop, isTablet);
          }

          // Handle error state
          if (snapshot.hasError) {
            return _buildErrorState(controller, snapshot.error.toString());
          }

          // Handle empty state after loading
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState(controller);
          }

          final products = snapshot.data!;
          return _buildProductsGridContent(products, isDesktop, isTablet);
        },
      );
    });
  }

  Widget _buildLoadingState(bool isDesktop, bool isTablet) {
    final crossAxisCount = isDesktop ? 4 : (isTablet ? 3 : 2);
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: AppSizes.defaultSpace,
        mainAxisSpacing: AppSizes.defaultSpace,
        mainAxisExtent: 280,
      ),
      itemCount: 6,
      itemBuilder: (_, index) => const TVerticalProductShimmer(),
    );
  }

  Widget _buildErrorState(FavoritesController controller, String error) {
    return TAnimationLoaderWidget(
      text: "Erreur de chargement",
      animation: TImages.docerAnimation,
      showAction: true,
      actionText: "Réessayer",
      onActionPressed: () => controller.getFavoriteProducts(),
    );
  }

  Widget _buildEmptyState(FavoritesController controller) {
    return Center(
      child: TAnimationLoaderWidget(
        text: "Votre liste de favoris est vide !",
        animation: TImages.pencilAnimation,
        showAction: true,
        actionText: "Découvrir des produits",
        onActionPressed: () => Get.off(() => const NavigationMenu()),
      ),
    );
  }

  Widget _buildProductsGridContent(List<ProduitModel> products, bool isDesktop, bool isTablet) {
    final crossAxisCount = isDesktop ? 4 : (isTablet ? 3 : 2);
    
    return GridView.builder(
      physics: const BouncingScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: AppSizes.defaultSpace,
        mainAxisSpacing: AppSizes.defaultSpace,
        mainAxisExtent: isDesktop ? 320 : (isTablet ? 300 : 280),
      ),
      itemCount: products.length,
      itemBuilder: (_, index) => ProductCardVertical(
        product: products[index],
        onFavoriteTap: () => FavoritesController.instance.toggleFavorite(products[index].id),
      ),
    );
  }

  void _showClearAllDialog(BuildContext context, FavoritesController controller) {
    Get.defaultDialog(
      title: "Vider les favoris",
      titleStyle: Theme.of(context).textTheme.headlineSmall,
      content: Column(
        children: [
          Icon(Icons.warning_amber_rounded, size: 60, color: Colors.orange.shade600),
          const SizedBox(height: AppSizes.spaceBtwItems),
          Text(
            "Êtes-vous sûr de vouloir supprimer tous vos produits favoris ?",
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
      confirm: ElevatedButton(
        onPressed: () {
          Get.back();
          controller.clearAllFavorites();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
        child: const Text("Supprimer tout", style: TextStyle(color: Colors.white)),
      ),
      cancel: OutlinedButton(
        onPressed: () => Get.back(),
        child: const Text("Annuler"),
      ),
    );
  }
}