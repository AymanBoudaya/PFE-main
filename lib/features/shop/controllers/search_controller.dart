import 'package:get/get.dart';
import '../../../data/repositories/product/produit_repository.dart';
import '../models/produit_model.dart';

class ResearchController extends GetxController {
  final ProduitRepository _repo = Get.find<ProduitRepository>();

  RxList<ProduitModel> searchResults = <ProduitModel>[].obs;
  RxBool isLoading = false.obs;
  RxString query = ''.obs;

  /// Fetch all products once and keep them in memory for instant filtering
  RxList<ProduitModel> allProducts = <ProduitModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    _loadAllProducts();
  }

  Future<void> _loadAllProducts() async {
    try {
      isLoading.value = true;
      final products = await _repo.getAllProducts();
      allProducts.assignAll(products);
    } catch (e) {
      print('Error loading products for search: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Called whenever the user types in the search field
  void onSearchChanged(String text) {
    query.value = text;
    if (text.isEmpty) {
      searchResults.clear();
      return;
    }

    final results = allProducts.where((p) {
      final name = p.name.toLowerCase();
      final desc = p.description?.toLowerCase() ?? '';
      return name.contains(text.toLowerCase()) || desc.contains(text.toLowerCase());
    }).toList();

    searchResults.assignAll(results);
  }

  void clearSearch() {
    query.value = '';
    searchResults.clear();
  }
}