import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../common/widgets/layouts/grid_layout.dart';
import '../../../../../common/widgets/products/product_cards/product_card_vertical.dart';
import '../../../../../utils/constants/sizes.dart';
import '../../../../../utils/device/device_utility.dart';
import '../../../controllers/search_controller.dart';

class SearchOverlay extends StatelessWidget {
  const SearchOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ResearchController());
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.3),
      body: Stack(
        children: [
          /// --- Background Blur ---
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(color: Colors.black.withOpacity(0.3)),
          ),

          /// --- Search UI ---
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.defaultSpace),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// --- Search Field ---
                  TextField(
                    autofocus: true,
                    onChanged: controller.onSearchChanged,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Rechercher un produit...',
                      hintStyle: TextStyle(color: Colors.white70),
                      prefixIcon: Icon(Icons.search, color: Colors.white70),
                      suffixIcon: Obx(() => controller.query.value.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close, color: Colors.white70),
                              onPressed: controller.clearSearch,
                            )
                          : const SizedBox.shrink()),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.15),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    ),
                  ),

                  const SizedBox(height: 20),

                  /// --- Search Results ---
                  Expanded(
                    child: Obx(() {
                      if (controller.isLoading.value) {
                        return const Center(
                            child: CircularProgressIndicator(color: Colors.white));
                      }

                      if (controller.query.isEmpty) {
                        return const Center(
                            child: Text('Tapez pour rechercher...',
                                style: TextStyle(color: Colors.white70)));
                      }

                      if (controller.searchResults.isEmpty) {
                        return const Center(
                            child: Text('Aucun résultat trouvé.',
                                style: TextStyle(color: Colors.white70)));
                      }

                      return GridLayout(
                        itemCount: controller.searchResults.length,
                        itemBuilder: (_, index) => ProductCardVertical(
                          product: controller.searchResults[index],
                        ),
                        crossAxisCount:
                            TDeviceUtils.getCrossAxisCount(screenWidth),
                        mainAxisExtent:
                            TDeviceUtils.getMainAxisExtent(screenWidth),
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),

          /// --- Close Button ---
          Positioned(
            top: 30,
            right: 20,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 28),
              onPressed: () => Get.back(),
            ),
          ),
        ],
      ),
    );
  }
}
