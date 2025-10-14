import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../../common/widgets/products/product_cards/product_card_vertical.dart';
import '../../../controllers/product/all_products_controller.dart';
import '../../../controllers/search_controller.dart';
import '../../../models/produit_model.dart';

class CustomSearchPage extends StatelessWidget {
  const CustomSearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ProductSearchController());
    final allProductsController = AllProductsController.instance;

    // affiche tous les produits dès l’ouverture
    if (controller.searchedProducts.isEmpty &&
        allProductsController.products.isNotEmpty) {
      controller.searchedProducts.assignAll(allProductsController.products);
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Effet de flou en fond
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(color: Colors.transparent),
          ),
          Container(color: Colors.black.withOpacity(0.3)),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildSearchBar(controller),
                  const SizedBox(height: 25),
                  Expanded(child: _buildResults(controller)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(ProductSearchController controller) {
    return Hero(
      tag: 'barre de recherche',
      child: Material(
        color: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Iconsax.search_normal_1, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: controller.searchController,
                      onChanged: (val) => controller.query.value = val,
                      autofocus: true,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: "Rechercher un produit...",
                        hintStyle: TextStyle(color: Colors.white70),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  Obx(() => controller.query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close,
                              color: Colors.white70, size: 22),
                          onPressed: controller.clearSearch,
                        )
                      : IconButton(
                          icon: const Icon(Iconsax.arrow_left_2,
                              color: Colors.white70),
                          onPressed: () => Get.back(),
                        )),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResults(ProductSearchController controller) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(
            child: CircularProgressIndicator(color: Colors.white));
      }

      final products = controller.searchedProducts;

      if (products.isEmpty) {
        return _buildEmptyState();
      }

      return GridView.builder(
        padding: const EdgeInsets.only(bottom: 20),
        physics: const BouncingScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.62,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          return ProductCardVertical(product: product);
        },
      );
    });
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Iconsax.search_status, color: Colors.white54, size: 64),
          SizedBox(height: 16),
          Text('Aucun produit trouvé',
              style: TextStyle(color: Colors.white70, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildProductGrid(List<ProduitModel> products) {
    return GridView.builder(
      physics: const BouncingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) => _buildProductCard(products[index]),
    );
  }

  Widget _buildProductCard(ProduitModel product) {
    return GestureDetector(
      onTap: () {
        // Navigue vers la page détail du produit
        Get.toNamed('/product', arguments: product);
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.15)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(16)),
                      image: DecorationImage(
                        image: NetworkImage(product.imageUrl),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(product.name,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500)),
                      const SizedBox(height: 4),
                      Text(
                        "${product.price.toStringAsFixed(2)} DT",
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
