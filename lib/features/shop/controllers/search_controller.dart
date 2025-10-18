import 'package:get/get.dart';
import '../../../data/repositories/product/produit_repository.dart';
import '../models/produit_model.dart';
import '../models/etablissement_model.dart';
import '../models/category_model.dart';

class ResearchController extends GetxController {
  final ProduitRepository _repo = Get.find<ProduitRepository>();

  /// States
  RxList<ProduitModel> searchResults = <ProduitModel>[].obs;
  RxList<ProduitModel> allProducts = <ProduitModel>[].obs;

  RxBool isLoading = false.obs;
  RxBool isPaginating = false.obs;
  RxBool hasMore = true.obs;
  RxString query = ''.obs;

  /// 🔥 AMÉLIORATION : Filtres avec objets complets
  Rx<CategoryModel?> selectedCategory = Rx<CategoryModel?>(null);
  Rx<Etablissement?> selectedEtablissement = Rx<Etablissement?>(null);
  RxString selectedSort = ''.obs;

  // 🔥 NOUVEAU : Listes complètes pour les filtres
  RxList<CategoryModel> categories = <CategoryModel>[].obs;
  RxList<Etablissement> etablissements = <Etablissement>[].obs;

  /// Pagination vars
  int _page = 1;
  final int _limit = 10;

  @override
  void onInit() {
    super.onInit();
    fetchAllProducts(reset: true);
    loadFilterData();
  }

  // 🔥 AMÉLIORATION : Chargement des données de filtres
  Future<void> loadFilterData() async {
    try {
      // 🔥 CORRECTION : Récupérer les objets complets avec IDs
      final cats = await _repo.getAllCategoriesWithIds();
      final ets = await _repo.getAllEtablissementsWithIds();

      categories.assignAll(cats);
      etablissements.assignAll(ets);

      print(
          '✅ Filtres chargés: ${cats.length} catégories, ${ets.length} établissements');
    } catch (e) {
      print('❌ Erreur chargement filtres: $e');
    }
  }

  /// Fetch all products (with pagination)
  Future<void> fetchAllProducts({bool reset = false}) async {
    if (isLoading.value || isPaginating.value) return;
    if (!hasMore.value && !reset) return;

    if (reset) {
      _page = 1;
      hasMore.value = true;
      allProducts.clear();
      searchResults.clear();
    }

    try {
      if (reset) {
        isLoading.value = true;
      } else {
        isPaginating.value = true;
      }

      final products =
          await _repo.getAllProductsPaginated(page: _page, limit: _limit);

      if (products.isEmpty) {
        hasMore.value = false;
      } else {
        allProducts.addAll(products);
        searchResults.addAll(products);
        _page++;
      }

      applyFilters();
    } catch (e) {
      print('❌ Erreur fetch produits: $e');
    } finally {
      isLoading.value = false;
      isPaginating.value = false;
    }
  }

  /// 🔥 AMÉLIORATION : Filtrage combiné avec gestion des IDs
  void applyFilters() {
    List<ProduitModel> results = List.from(allProducts);

    // 🔍 Recherche textuelle
    if (query.value.isNotEmpty) {
      results = results.where((p) {
        final name = p.name.toLowerCase();
        final desc = p.description?.toLowerCase() ?? '';
        final etabName = p.etablissement?.name.toLowerCase() ?? '';

        return name.contains(query.value.toLowerCase()) ||
            desc.contains(query.value.toLowerCase()) ||
            etabName.contains(query.value.toLowerCase());
      }).toList();
    }

    // 🏷️ Filtre par catégorie (ID)
    if (selectedCategory.value != null) {
      results = results
          .where((p) => p.categoryId == selectedCategory.value!.id)
          .toList();
    }

    // 🏠 Filtre par établissement (ID)
    if (selectedEtablissement.value != null) {
      results = results
          .where((p) => p.etablissementId == selectedEtablissement.value!.id)
          .toList();
    }

    // 🧮 Tri
    switch (selectedSort.value) {
      case 'Prix ↑':
        results.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'Prix ↓':
        results.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'Nom A-Z':
        results.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'Popularité':
        results.sort((a, b) => (b.isFeatured == true ? 1 : 0)
            .compareTo(a.isFeatured == true ? 1 : 0));
        break;
    }

    searchResults.assignAll(results);
  }

  /// 🔥 NOUVEAU : Gestion des changements avec objets
  void onSearchChanged(String text) {
    query.value = text;
    applyFilters();
  }

  void onCategorySelected(CategoryModel? category) {
    selectedCategory.value = category;
    applyFilters();
  }

  void onEtablissementSelected(Etablissement? etablissement) {
    selectedEtablissement.value = etablissement;
    applyFilters();
  }

  void onSortSelected(String? sort) {
    selectedSort.value = sort ?? '';
    applyFilters();
  }

  // 🔥 NOUVEAU : Méthodes pour retirer les filtres
  void clearSearch() {
    query.value = '';
    applyFilters();
  }

  void clearCategoryFilter() {
    selectedCategory.value = null;
    applyFilters();
  }

  void clearEtablissementFilter() {
    selectedEtablissement.value = null;
    applyFilters();
  }

  void clearSortFilter() {
    selectedSort.value = '';
    applyFilters();
  }

  void clearAllFilters() {
    query.value = '';
    selectedCategory.value = null;
    selectedEtablissement.value = null;
    selectedSort.value = '';
    applyFilters();
  }

  // 🔥 NOUVEAU : Vérifier si des filtres sont actifs
  bool get hasActiveFilters {
    return query.value.isNotEmpty ||
        selectedCategory.value != null ||
        selectedEtablissement.value != null ||
        selectedSort.value.isNotEmpty;
  }

  // 🔥 NOUVEAU : Getters pour l'affichage
  String get selectedCategoryName => selectedCategory.value?.name ?? '';
  String get selectedEtablissementName =>
      selectedEtablissement.value?.name ?? '';

  // 🔥 NOUVEAU : Debug des filtres
  void debugFilters() {
    print('🔍 DEBUG FILTRES:');
    print('  - Recherche: "${query.value}"');
    print(
        '  - Catégorie: ${selectedCategory.value?.name} (ID: ${selectedCategory.value?.id})');
    print(
        '  - Établissement: ${selectedEtablissement.value?.name} (ID: ${selectedEtablissement.value?.id})');
    print('  - Tri: $selectedSort');
    print('  - Produits totaux: ${allProducts.length}');
    print('  - Résultats filtrés: ${searchResults.length}');
  }
}
