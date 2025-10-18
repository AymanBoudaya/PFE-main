import 'package:get/get.dart';
import '../../../data/repositories/product/produit_repository.dart';
import '../models/produit_model.dart';

class ResearchController extends GetxController {
  final ProduitRepository _repo = Get.find<ProduitRepository>();

  /// States
  RxList<ProduitModel> searchResults = <ProduitModel>[].obs;
  RxList<ProduitModel> allProducts = <ProduitModel>[].obs;

  RxBool isLoading = false.obs;
  RxBool isPaginating = false.obs;
  RxBool hasMore = true.obs;
  RxString query = ''.obs;

  /// Filtres
  RxString selectedCategory = ''.obs;
  RxString selectedEtablissement = ''.obs;
  RxString selectedSort = ''.obs; // 'Prix ↑', 'Prix ↓', 'Nom A-Z', 'Popularité'
  RxList<String> categories = <String>[].obs;
  RxList<String> etablissements = <String>[].obs;

  /// Pagination vars
  int _page = 1;
  final int _limit = 10;

  @override
  void onInit() {
    super.onInit();
    fetchAllProducts(reset: true);
    loadFilterData();
  }

  Future<void> loadFilterData() async {
    try {
      final cats = await _repo.getAllCategories();
      final ets = await _repo.getAllEtablissementsNames();
      categories.assignAll(cats);
      etablissements.assignAll(ets);
    } catch (e) {
      print('Erreur chargement filtres: $e');
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
        // ✅ Correction : remplir allProducts aussi
        allProducts.addAll(products);
        searchResults.addAll(products);
        _page++;
      }

      // ✅ Appliquer les filtres après avoir ajouté les produits
      applyFilters();
    } catch (e) {
      print('Erreur fetch produits: $e');
    } finally {
      isLoading.value = false;
      isPaginating.value = false;
    }
  }

  /// Filtrage combiné
  void applyFilters() {
    List<ProduitModel> results = List.from(allProducts);

    // 🔍 Recherche textuelle
    if (query.value.isNotEmpty) {
      results = results.where((p) {
        final name = p.name.toLowerCase();
        final desc = p.description?.toLowerCase() ?? '';
        return name.contains(query.value.toLowerCase()) ||
            desc.contains(query.value.toLowerCase());
      }).toList();
    }

    // 🏷️ Filtre par catégorie (ID)
    if (selectedCategory.value.isNotEmpty) {
      results =
          results.where((p) => p.categoryId == selectedCategory.value).toList();
    }

    // 🏠 Filtre par établissement (ID)
    if (selectedEtablissement.value.isNotEmpty) {
      results = results
          .where((p) => p.etablissementId == selectedEtablissement.value)
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
        results.sort(
            (a, b) => (b.isFeatured! ? 1 : 0).compareTo(a.isFeatured! ? 1 : 0));
        break;
    }

    searchResults.assignAll(results);
  }

  /// 📱 Gestion des changements
  void onSearchChanged(String text) {
    query.value = text;
    applyFilters();
  }

  void onCategorySelected(String? cat) {
    selectedCategory.value = cat ?? '';
    applyFilters();
  }

  void onEtablissementSelected(String? etab) {
    selectedEtablissement.value = etab ?? '';
    applyFilters();
  }

  void onSortSelected(String? sort) {
    selectedSort.value = sort ?? '';
    applyFilters();
  }

  void clearSearch() {
    query.value = '';
    applyFilters();
  }
}
