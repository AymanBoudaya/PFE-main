import 'package:get/get.dart';

import '../../../../data/repositories/product/produit_repository.dart';
import '../../../../utils/constants/enums.dart';
import '../../../../utils/popups/loaders.dart';
import '../../models/produit_model.dart';

enum ProduitFilter { all, stockables, nonStockables, rupture }

class ProductController extends GetxController {
  static ProductController get instance => Get.find();

  final isLoading = false.obs;
  final produitRepository = ProduitRepository.instance;

  RxList<ProduitModel> featuredProducts = <ProduitModel>[].obs;
  @override
  void onInit() {
    fetchFeaturedProducts();
    super.onInit();
  }

  /// Product List

  /// Fetch Products
  void fetchFeaturedProducts() async {
    try {
      // Show loader while loading products
      isLoading.value = true;

      // Fetch products from an API or database
      final products = await produitRepository.getFeaturedProducts();
      // Assign products
      featuredProducts.assignAll(products);
      print(featuredProducts[0].id);
    } catch (e) {
      // Handle error
      TLoaders.errorSnackBar(title: 'Erreur!', message: e.toString());
    } finally {
      // Hide loader after loading products
      isLoading.value = false;
    }
  }

  Future<List<ProduitModel>> fetchAllFeaturedProducts() async {
    try {
      // Fetch products from an API or database
      final products = await produitRepository.getFeaturedProducts();
      return products;
    } catch (e) {
      // Handle error
      TLoaders.errorSnackBar(title: 'Erreur!', message: e.toString());
      return [];
    }
  }

  /// get product price or price range for variations
  String getProductPrice(ProduitModel product) {
    double smallestPrice = double.infinity;
    double largestPrice = 0.0;

    //if no variations exist return the simple price or sale price
    if (product.productType == ProductType.single.toString()) {
      return (product.salePrice > 0 ? product.salePrice : product.price)
          .toString();
    } else {
      //calculate the smallest and largest prices among variations
      if (product.sizesPrices != null) {
        for (var variation in product.sizesPrices!) {
          //determine the price to consider(sale price if available, otherwise regular price)
          double priceToConsider =
              variation.price > 0.0 ? variation.price : variation.price;

          //update smallest and largest price
          if (priceToConsider < smallestPrice) {
            smallestPrice = priceToConsider;
          }

          if (priceToConsider > largestPrice) {
            largestPrice = priceToConsider;
          }
        }
      } else {
        smallestPrice = 0.0;
        largestPrice = 234;
      }

      //if smallest and largest price are the same return a single price
      if (smallestPrice.isEqual(largestPrice)) {
        return largestPrice.toString();
      } else {
        //otherwise return A price range
        return '$smallestPrice - \$$largestPrice';
      }
    }
  }

  /// calculate discount percentage
  String? calculateSalePercentage(double originalPrice, double? salePrice) {
    if (salePrice == null || salePrice <= 0.0) return null;
    if (originalPrice <= 0) return null;

    double percentage = ((originalPrice - salePrice) / originalPrice) * 100;
    return percentage.toStringAsFixed(0);
  }

  /// -- check product stock status
  String getProductStockStatus(int stock) {
    return stock > 0 ? 'En Stock' : 'Hors Stock';
  }
}
