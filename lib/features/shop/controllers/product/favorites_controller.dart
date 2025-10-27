import 'dart:convert';

import 'package:get/get.dart';

import '../../../../data/repositories/product/product_repository.dart';
import '../../../../utils/local_storage/storage_utility.dart';
import '../../../../utils/popups/loaders.dart';
import '../../models/product_model.dart';
import '../../models/produit_model.dart';

class FavoritesController extends GetxController {
  static FavoritesController get instance => Get.find();

  /// Reactive favorites list
  final favoriteIds = <String>[].obs;
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadFavorites();
  }

  /// Load favorites from local storage
  Future<void> loadFavorites() async {
    try {
      final json = TLocalStorage.instance().readData('favorites');
      if (json != null) {
        final List<dynamic> storedFavorites = jsonDecode(json);
        favoriteIds.assignAll(storedFavorites.cast<String>());
      }
    } catch (e) {
      TLoaders.errorSnackBar(
          title: 'Erreur', message: 'Impossible de charger les favoris');
    }
  }

  /// Save favorites to local storage
  Future<void> _saveFavorites() async {
    try {
      final encodedFavorites = json.encode(favoriteIds);
      await TLocalStorage.instance().saveData('favorites', encodedFavorites);
    } catch (e) {
      TLoaders.errorSnackBar(
          title: 'Erreur', message: 'Impossible de sauvegarder les favoris');
    }
  }

  /// Check if product is favorite
  bool isFavorite(String productId) {
    return favoriteIds.contains(productId);
  }

  /// Toggle favorite status
  Future<void> toggleFavorite(String productId) async {
    try {
      if (favoriteIds.contains(productId)) {
        favoriteIds.remove(productId);
        TLoaders.customToast(message: 'Produit retiré des favoris');
      } else {
        favoriteIds.add(productId);
        TLoaders.customToast(message: 'Produit ajouté aux favoris');
      }
      await _saveFavorites();
    } catch (e) {
      TLoaders.errorSnackBar(title: 'Erreur', message: 'Action impossible');
    }
  }

  /// Get favorite products
  Future<List<ProduitModel>> getFavoriteProducts() async {
    if (favoriteIds.isEmpty) return [];

    isLoading.value = true;
    try {
      final products =
          await ProductRepository.instance.getFavoriteProducts(favoriteIds);
      isLoading.value = false;
      return products;
    } catch (e) {
      isLoading.value = false;
      TLoaders.errorSnackBar(
          title: 'Erreur', message: 'Impossible de charger les favoris');
      return [];
    }
  }

  /// Clear all favorites
  Future<void> clearAllFavorites() async {
    try {
      favoriteIds.clear();
      await _saveFavorites();
      TLoaders.successSnackBar(
          title: 'Succès', message: 'Tous les favoris ont été supprimés');
    } catch (e) {
      TLoaders.errorSnackBar(
          title: 'Erreur', message: 'Impossible de vider les favoris');
    }
  }
}
