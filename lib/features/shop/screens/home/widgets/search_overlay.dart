import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../common/widgets/layouts/grid_layout.dart';
import '../../../../../common/widgets/products/product_cards/product_card_vertical.dart';
import '../../../../../utils/constants/sizes.dart';
import '../../../../../utils/device/device_utility.dart';
import '../../../controllers/search_controller.dart';

class SearchOverlay extends StatefulWidget {
  const SearchOverlay({super.key});

  @override
  State<SearchOverlay> createState() => _SearchOverlayState();
}

class _SearchOverlayState extends State<SearchOverlay> {
  final controller = Get.put(ResearchController());
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    // Initial fetch (all products)
    controller.fetchAllProducts(reset: true);

    // Pagination listener (single instance)
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 200 &&
          !controller.isPaginating.value &&
          controller.query.value.isEmpty &&
          controller.hasMore.value) {
        controller.fetchAllProducts();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.4),
      body: Stack(
        children: [
          /// --- Background Blur ---
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(color: Colors.black.withOpacity(0.25)),
          ),

          /// --- Main Content ---
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.defaultSpace),
              child: Column(
                children: [
                  /// --- Search Field ---
                  TextField(
                    autofocus: true,
                    onChanged: controller.onSearchChanged,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Rechercher un produit...',
                      hintStyle: const TextStyle(color: Colors.white70),
                      prefixIcon:
                          const Icon(Icons.search, color: Colors.white70),
                      suffixIcon: Obx(() => controller.query.value.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close,
                                  color: Colors.white70),
                              onPressed: controller.clearSearch,
                            )
                          : const SizedBox.shrink()),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.15),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 14),
                    ),
                  ),

                  const SizedBox(height: 20),

                  /// --- Product Grid (Scrollable Page) ---
                  Expanded(
                    child: Obx(() {
                      if (controller.isLoading.value &&
                          controller.searchResults.isEmpty) {
                        return const Center(
                            child:
                                CircularProgressIndicator(color: Colors.white));
                      }

                      if (controller.searchResults.isEmpty) {
                        return const Center(
                          child: Text(
                            'Aucun produit trouvé.',
                            style: TextStyle(color: Colors.white70),
                          ),
                        );
                      }

                      return SingleChildScrollView(
                        controller: _scrollController,
                        child: Column(
                          children: [
                            GridLayout(
                              itemCount: controller.searchResults.length,
                              itemBuilder: (_, index) {
                                return ProductCardVertical(
                                  product: controller.searchResults[index],
                                );
                              },
                              crossAxisCount:
                                  TDeviceUtils.getCrossAxisCount(screenWidth),
                              mainAxisExtent:
                                  TDeviceUtils.getMainAxisExtent(screenWidth),
                            ),
                            const SizedBox(height: 20),

                            /// Pagination loader
                            if (controller.isPaginating.value)
                              const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: CircularProgressIndicator(
                                      color: Colors.white),
                                ),
                              ),
                          ],
                        ),
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
