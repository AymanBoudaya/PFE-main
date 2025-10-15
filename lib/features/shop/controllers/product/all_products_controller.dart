import 'package:get/get.dart';
import '../../../../data/repositories/product/produit_repository.dart';
import '../../models/produit_model.dart';

class AllProductsController extends GetxController {
  static AllProductsController get instance => Get.find();

  final repository = ProduitRepository.instance;

  /// Liste complète des produits
  final RxList<ProduitModel> products = <ProduitModel>[].obs;

  /// État du chargement
  final RxBool isLoading = false.obs;

  /// Option de tri sélectionnée
  final RxString selectedSortOption = 'Nom'.obs;

  @override
  void onInit() {
    super.onInit();
    fetchAllProducts();
  }

  /// Récupère tous les produits
  Future<void> fetchAllProducts() async {
    try {
      isLoading.value = true;
      final all = await repository.getAllProducts();
      
      // 🔥 CORRECTION : S'assurer que la liste n'est pas null
      products.assignAll(all ?? []);
      
      // 🔥 CORRECTION : Trier après assignation
      sortProducts(selectedSortOption.value);
      
      print('✅ ${products.length} produits chargés avec succès');
    } catch (e) {
      print("❌ Erreur chargement produits : $e");
      // 🔥 CORRECTION : Assigner une liste vide en cas d'erreur
      products.assignAll([]);
    } finally {
      isLoading.value = false;
    }
  }

  /// Trie les produits selon l'option choisie
  void sortProducts(String sortOption) {
    selectedSortOption.value = sortOption;

    switch (sortOption) {
      case 'Nom':
        products.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'Prix croissant':
        products.sort((a, b) {
          final priceA = a.price ?? a.salePrice ?? 0.0;
          final priceB = b.price ?? b.salePrice ?? 0.0;
          return priceA.compareTo(priceB);
        });
        break;
      case 'Prix décroissant':
        products.sort((a, b) {
          final priceA = a.price ?? a.salePrice ?? 0.0;
          final priceB = b.price ?? b.salePrice ?? 0.0;
          return priceB.compareTo(priceA);
        });
        break;
      case 'Récent':
        products.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case 'Ventes':
        products.sort((a, b) {
          // 🔥 CORRECTION : Logique de tri par ventes améliorée
          final salesA = a.salePrice ?? 0.0;
          final salesB = b.salePrice ?? 0.0;
          return salesB.compareTo(salesA);
        });
        break;
      default:
        products.sort((a, b) => a.name.compareTo(b.name));
    }
    
    print('🔄 Produits triés par: $sortOption');
  }

  /// Permet d'assigner une nouvelle liste (utilisé dans la recherche)
  void assignProducts(List<ProduitModel> newProducts) {
    products.assignAll(newProducts);
    sortProducts(selectedSortOption.value);
  }

  // Recherche rapide
  List<ProduitModel> searchProducts(String query) {
    if (query.isEmpty) return products;
    
    final searchText = query.toLowerCase();
    return products.where((product) {
      return product.name.toLowerCase().contains(searchText) ||
          (product.description ?? '').toLowerCase().contains(searchText);// ||
          // (product.categoryName ?? '').toLowerCase().contains(searchText);
    }).toList();
  }
}