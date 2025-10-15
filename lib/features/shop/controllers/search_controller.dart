import 'package:get/get.dart';
import '../../../data/repositories/product/produit_repository.dart';
import '../models/produit_model.dart';

class ResearchController extends GetxController {
  final ProduitRepository _repo = Get.find<ProduitRepository>();

  /// States
  RxList<ProduitModel> searchResults = <ProduitModel>[].obs;
  RxBool isLoading = false.obs;
  RxBool isPaginating = false.obs;
  RxBool hasMore = true.obs;
  RxString query = ''.obs;

  /// Pagination vars
  int _page = 1;
  final int _limit = 10;

  @override
  void onInit() {
    super.onInit();
    fetchAllProducts(reset: true);
  }

  /// Load all products with pagination
  Future<void> fetchAllProducts({bool reset = false}) async {
    if (isLoading.value || isPaginating.value) return;
    if (!hasMore.value && !reset) return;

    if (reset) {
      _page = 1;
      hasMore.value = true;
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
        searchResults.addAll(products);
        _page++;
      }
    } catch (e) {
      print('Error fetching products: $e');
    } finally {
      isLoading.value = false;
      isPaginating.value = false;
    }
  }

  /// Called whenever the user types
  void onSearchChanged(String text) {
    query.value = text;
    if (text.isEmpty) {
      // Reset to paginated full list
      fetchAllProducts(reset: true);
      return;
    }

    // Simple local filtering from current products
    final results = searchResults.where((p) {
      final name = p.name.toLowerCase();
      final desc = p.description?.toLowerCase() ?? '';
      return name.contains(text.toLowerCase()) ||
          desc.contains(text.toLowerCase());
    }).toList();

    searchResults.assignAll(results);
  }

  void clearSearch() {
    query.value = '';
    fetchAllProducts(reset: true);
  }
}
