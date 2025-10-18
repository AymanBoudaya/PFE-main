import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../common/widgets/layouts/grid_layout.dart';
import '../../../../../common/widgets/products/product_cards/product_card_vertical.dart';
import '../../../../../utils/constants/sizes.dart';
import '../../../../../utils/device/device_utility.dart';
import '../../../controllers/search_controller.dart';

import '../../../models/category_model.dart';
import '../../../models/etablissement_model.dart';

class SearchOverlay extends StatefulWidget {
  const SearchOverlay({super.key});

  @override
  State<SearchOverlay> createState() => _SearchOverlayState();
}

class _SearchOverlayState extends State<SearchOverlay> {
  final ResearchController controller = Get.put(ResearchController());
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    controller.fetchAllProducts(reset: true);
    
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 200 &&
          !controller.isPaginating.value &&
          controller.query.value.isEmpty &&
          controller.hasMore.value) {
        controller.fetchAllProducts();
      }
    });
    
    // 🔥 Lier le controller de texte
    _searchController.addListener(() {
      controller.onSearchChanged(_searchController.text);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
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
                    controller: _searchController,
                    autofocus: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Rechercher un produit, établissement...',
                      hintStyle: const TextStyle(color: Colors.white70),
                      prefixIcon: const Icon(Icons.search, color: Colors.white70),
                      suffixIcon: Obx(() => controller.query.value.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close, color: Colors.white70),
                              onPressed: () {
                                _searchController.clear();
                                controller.clearSearch();
                              },
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

                  /// 🔥 AMÉLIORATION : Filtres actifs ---
                  _buildActiveFilters(),

                  const SizedBox(height: 16),

                  /// --- Filtres --- ///
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: _buildCategoryFilter(),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildEtablissementFilter(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  /// --- Tri --- ///
                  _buildSortFilter(),
                  const SizedBox(height: 20),

                  /// --- Product Grid (Scrollable Page) ---
                  Expanded(
                    child: _buildProductGrid(screenWidth),
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

  // 🔥 NOUVEAU : Filtres actifs avec badges
  Widget _buildActiveFilters() {
    return Obx(() {
      if (!controller.hasActiveFilters) return const SizedBox();

      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filtres actifs:',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (controller.query.value.isNotEmpty)
                  _buildFilterChip(
                    label: 'Recherche: "${controller.query.value}"',
                    onRemove: controller.clearSearch,
                  ),
                if (controller.selectedCategory.value != null)
                  _buildFilterChip(
                    label: 'Catégorie: ${controller.selectedCategoryName}',
                    onRemove: controller.clearCategoryFilter,
                  ),
                if (controller.selectedEtablissement.value != null)
                  _buildFilterChip(
                    label: 'Établissement: ${controller.selectedEtablissementName}',
                    onRemove: controller.clearEtablissementFilter,
                  ),
                if (controller.selectedSort.value.isNotEmpty)
                  _buildFilterChip(
                    label: 'Tri: ${controller.selectedSort.value}',
                    onRemove: controller.clearSortFilter,
                  ),
                _buildClearAllChip(),
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget _buildFilterChip({required String label, required VoidCallback onRemove}) {
    return Chip(
      label: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
      backgroundColor: Colors.blue.withOpacity(0.3),
      deleteIcon: const Icon(Icons.close, size: 16, color: Colors.white),
      onDeleted: onRemove,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      labelPadding: const EdgeInsets.symmetric(horizontal: 8),
    );
  }

  Widget _buildClearAllChip() {
    return InkWell(
      onTap: controller.clearAllFilters,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.3),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.clear_all, size: 14, color: Colors.white),
            SizedBox(width: 4),
            Text(
              'Tout effacer',
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  // 🔥 AMÉLIORATION : Filtre catégorie avec objets
  Widget _buildCategoryFilter() {
    return Obx(() => DropdownButtonFormField<CategoryModel>(
          value: controller.selectedCategory.value,
          decoration: const InputDecoration(
            labelText: 'Catégorie',
            labelStyle: TextStyle(color: Colors.white70),
            filled: true,
            fillColor: Colors.white10,
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          dropdownColor: Colors.black87,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          items: [
            const DropdownMenuItem<CategoryModel>(
              value: null,
              child: Text('Toutes les catégories', style: TextStyle(color: Colors.white70)),
            ),
            ...controller.categories.map((category) {
              return DropdownMenuItem<CategoryModel>(
                value: category,
                child: Text(
                  category.name,
                  style: const TextStyle(color: Colors.white),
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
          ],
          onChanged: controller.onCategorySelected,
        ));
  }

  // 🔥 AMÉLIORATION : Filtre établissement avec objets
  Widget _buildEtablissementFilter() {
    return Obx(() => DropdownButtonFormField<Etablissement>(
          value: controller.selectedEtablissement.value,
          decoration: const InputDecoration(
            labelText: 'Établissement',
            labelStyle: TextStyle(color: Colors.white70),
            filled: true,
            fillColor: Colors.white10,
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          dropdownColor: Colors.black87,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          items: [
            const DropdownMenuItem<Etablissement>(
              value: null,
              child: Text('Tous les établissements', style: TextStyle(color: Colors.white70)),
            ),
            ...controller.etablissements.map((etablissement) {
              return DropdownMenuItem<Etablissement>(
                value: etablissement,
                child: Text(
                  etablissement.name,
                  style: const TextStyle(color: Colors.white),
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
          ],
          onChanged: controller.onEtablissementSelected,
        ));
  }

  // 🔥 AMÉLIORATION : Filtre tri
  Widget _buildSortFilter() {
    return Obx(() => DropdownButtonFormField<String>(
          value: controller.selectedSort.value.isEmpty ? null : controller.selectedSort.value,
          decoration: const InputDecoration(
            labelText: 'Trier par',
            labelStyle: TextStyle(color: Colors.white70),
            filled: true,
            fillColor: Colors.white10,
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          dropdownColor: Colors.black87,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          items: [
            const DropdownMenuItem<String>(
              value: null,
              child: Text('Aucun tri', style: TextStyle(color: Colors.white70)),
            ),
            ...['Prix ↑', 'Prix ↓', 'Nom A-Z', 'Popularité'].map((sort) {
              return DropdownMenuItem<String>(
                value: sort,
                child: Text(sort, style: const TextStyle(color: Colors.white)),
              );
            }).toList(),
          ],
          onChanged: controller.onSortSelected,
        ));
  }

  // 🔥 AMÉLIORATION : Grille de produits
  Widget _buildProductGrid(double screenWidth) {
    return Obx(() {
      if (controller.isLoading.value && controller.searchResults.isEmpty) {
        return const Center(child: CircularProgressIndicator(color: Colors.white));
      }

      if (controller.searchResults.isEmpty) {
        return _buildEmptyState();
      }

      return SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          children: [
            // 🔥 INFO : Nombre de résultats
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${controller.searchResults.length} produit(s) trouvé(s)',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  if (controller.hasActiveFilters)
                    InkWell(
                      onTap: controller.debugFilters,
                      child: const Icon(Icons.info_outline, size: 16, color: Colors.white70),
                    ),
                ],
              ),
            ),

            GridLayout(
              itemCount: controller.searchResults.length,
              itemBuilder: (_, index) {
                return ProductCardVertical(
                  product: controller.searchResults[index],
                );
              },
              crossAxisCount: TDeviceUtils.getCrossAxisCount(screenWidth),
              mainAxisExtent: TDeviceUtils.getMainAxisExtent(screenWidth),
            ),
            const SizedBox(height: 20),

            /// Pagination loader
            if (controller.isPaginating.value)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              ),
          ],
        ),
      );
    });
  }

  // 🔥 NOUVEAU : État vide amélioré
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 80,
            color: Colors.white.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'Aucun produit trouvé',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Obx(() {
            if (controller.hasActiveFilters) {
              return Column(
                children: [
                  Text(
                    'Essayez de modifier vos filtres de recherche',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: controller.clearAllFilters,
                    icon: const Icon(Icons.clear_all),
                    label: const Text('Réinitialiser les filtres'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.withOpacity(0.3),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              );
            } else {
              return Text(
                'Aucun produit ne correspond à votre recherche',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              );
            }
          }),
        ],
      ),
    );
  }
}