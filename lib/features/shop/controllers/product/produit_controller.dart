import 'dart:io';
import 'package:caferesto/data/repositories/product/produit_repository.dart';
import 'package:caferesto/features/personalization/controllers/user_controller.dart';
import 'package:caferesto/features/shop/models/produit_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../utils/constants/enums.dart';
import '../../../../utils/popups/loaders.dart';
import '../etablissement_controller.dart';

enum ProduitFilter { all, stockables, nonStockables, rupture }

class ProduitController extends GetxController {
  static ProduitController get instance => Get.find();

  // --- FORMULAIRES ET CONTROLLERS ---
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final descriptionController = TextEditingController();
  final preparationTimeController = TextEditingController();
  final stockQuantityController = TextEditingController();

  final isStockable = false.obs;
  final selectedCategoryId = Rx<String?>(null);
  final ImagePicker _picker = ImagePicker();
  final pickedImage = Rx<XFile?>(null);

  // --- DÉPENDANCES ---
  final UserController userController = Get.find<UserController>();
  late final ProduitRepository produitRepository;

  // --- ÉTATS ET LISTES ---
  final isLoading = false.obs;
  RxList<ProduitModel> allProducts = <ProduitModel>[].obs;
  RxList<ProduitModel> filteredProducts = <ProduitModel>[].obs;
  final Rx<ProduitFilter> selectedFilter = ProduitFilter.all.obs;
  final RxString searchQuery = ''.obs;
  RxList<ProduitModel> featuredProducts = <ProduitModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    produitRepository = Get.put(ProduitRepository());
    fetchFeaturedProducts();
  }

  void filterProducts(String query) {
    searchQuery.value = query;
    applyFilters();
  }

  void applyFilters() {
    List<ProduitModel> filtered = allProducts;

    // Appliquer la recherche par nom
    if (searchQuery.isNotEmpty) {
      filtered = filtered
          .where((product) =>
              product.name.toLowerCase().contains(searchQuery.toLowerCase()))
          .toList();
    }

    // Appliquer le filtre sélectionné
    switch (selectedFilter.value) {
      case ProduitFilter.stockables:
        filtered = filtered.where((product) => product.isStockable).toList();
        break;
      case ProduitFilter.nonStockables:
        filtered = filtered.where((product) => !product.isStockable).toList();
        break;
      case ProduitFilter.rupture:
        filtered = filtered
            .where(
                (product) => product.isStockable && product.stockQuantity <= 0)
            .toList();
        break;
      case ProduitFilter.all:
    }

    filteredProducts.assignAll(filtered);
  }

  void updateFilter(ProduitFilter filter) {
    selectedFilter.value = filter;
    applyFilters();
  }

  // --- IMAGE ---
  Future<void> pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (pickedFile != null) {
        pickedImage.value = XFile(pickedFile.path);
      }
    } catch (e) {
      TLoaders.errorSnackBar(
          message: "Erreur lors de la sélection de l'image: $e");
    }
  }

  Future<String?> uploadProductImage(XFile imageFile) async {
    try {
      return await produitRepository.uploadProductImage(imageFile);
    } catch (e) {
      TLoaders.errorSnackBar(message: "Erreur lors de l'upload de l'image: $e");
      return null;
    }
  }

// --- CHARGEMENT DES PRODUITS PAR RÔLE ---
  Future<void> loadProductsByRole() async {
    try {
      isLoading.value = true;

      final userRole = userController.user.value.role;

      if (userRole == 'Admin') {
        // Admin voit tous les produits
        await fetchProducts();
      } else if (userRole == 'Gérant') {
        // Gérant ne voit que ses propres produits
        final etablissementId = await getEtablissementIdUtilisateur();
        if (etablissementId != null) {
          final products = await getProductsByEtablissement(etablissementId);
          allProducts.assignAll(products);
          filteredProducts.assignAll(products);
        } else {
          allProducts.clear();
          filteredProducts.clear();
          TLoaders.errorSnackBar(
              message:
                  "Impossible de récupérer les produits de votre établissement");
        }
      } else {
        // Autres rôles - liste vide ou logique spécifique
        allProducts.clear();
        filteredProducts.clear();
      }

      applyFilters(); // Appliquer les filtres après le chargement
    } catch (e) {
      TLoaders.errorSnackBar(
          message: 'Erreur lors du chargement des produits: $e');
      allProducts.clear();
      filteredProducts.clear();
    } finally {
      isLoading.value = false;
    }
  }

  // --- CHARGEMENT DES PRODUITS ---
  Future<void> fetchProducts() async {
    try {
      isLoading.value = true;
      final productsList = await produitRepository.getAllProducts();
      allProducts.assignAll(productsList);
      filteredProducts.assignAll(productsList);
    } catch (e) {
      TLoaders.errorSnackBar(
          message: 'Erreur lors du chargement des produits: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<List<ProduitModel>> getProductsByEtablissement(
      String etablissementId) async {
    try {
      return await produitRepository
          .getProductsByEtablissement(etablissementId);
    } catch (e) {
      TLoaders.errorSnackBar(message: 'Erreur: $e');
      return [];
    }
  }

  Future<List<ProduitModel>> getProductsByCategory(String categoryId) async {
    try {
      return await produitRepository.getProductsByCategory(categoryId);
    } catch (e) {
      TLoaders.errorSnackBar(message: 'Erreur: $e');
      return [];
    }
  }

  // --- ÉTABLISSEMENT ---
  Future<String?> getEtablissementIdUtilisateur() async {
    try {
      final etablissementController = Get.find<EtablissementController>();
      final etablissement =
          await etablissementController.getEtablissementUtilisateurConnecte();

      if (etablissement == null) {
        TLoaders.errorSnackBar(
            message:
                "Aucun établissement trouvé. Veuillez d'abord créer un établissement.");
        return null;
      }

      return etablissement.id;
    } catch (e) {
      TLoaders.errorSnackBar(
          message: "Erreur lors de la récupération de l'établissement: $e");
      return null;
    }
  }

  // --- AJOUT / MODIFICATION / SUPPRESSION ---
  Future<bool> addProduct(ProduitModel produit) async {
    if (!_hasProductManagementPermission()) {
      TLoaders.errorSnackBar(
          message: "Vous n'avez pas la permission d'ajouter un produit.");
      return false;
    }

    if (produit.name.isEmpty) {
      TLoaders.errorSnackBar(
          message: "Le nom du produit ne peut pas être vide.");
      return false;
    }

    if (produit.etablissementId.isEmpty) {
      TLoaders.errorSnackBar(message: "ID d'établissement manquant.");
      return false;
    }

    try {
      isLoading.value = true;
      await produitRepository.addProduct(produit);
      await loadProductsByRole();
      Get.back(result: true);
      TLoaders.successSnackBar(
          message: 'Produit "${produit.name}" ajouté avec succès');
      return true;
    } catch (e) {
      TLoaders.errorSnackBar(message: "Erreur lors de l'ajout: $e");
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> updateProduct(ProduitModel produit) async {
    if (!_hasProductManagementPermission()) {
      TLoaders.errorSnackBar(
          message: "Vous n'avez pas la permission de modifier un produit.");
      return false;
    }

    if (produit.name.isEmpty) {
      TLoaders.errorSnackBar(
          message: "Le nom du produit ne peut pas être vide.");
      return false;
    }

    try {
      isLoading.value = true;
      await produitRepository.updateProduct(produit);
      await loadProductsByRole();
      Get.back(result: true);
      TLoaders.successSnackBar(
          message: 'Produit "${produit.name}" modifié avec succès');
      return true;
    } catch (e) {
      TLoaders.errorSnackBar(message: "Erreur lors de la modification: $e");
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Fetch Products
  void fetchFeaturedProducts() async {
    try {
      // Show loader while loading products
      isLoading.value = true;

      // Fetch products from an API or database
      final products = await produitRepository.getFeaturedProducts();
      // Assign products
      featuredProducts.assignAll(products);
    } catch (e) {
      // Handle error
      TLoaders.errorSnackBar(title: 'Erreur!', message: e.toString());
    } finally {
      // Hide loader after loading products
      isLoading.value = false;
    }
  }

  Future<void> deleteProduct(String productId) async {
    if (!_hasProductManagementPermission()) {
      TLoaders.errorSnackBar(
          message: "Vous n'avez pas la permission de supprimer un produit.");
      return;
    }

    try {
      isLoading.value = true;
      await produitRepository.deleteProduct(productId);
      await loadProductsByRole();
      TLoaders.successSnackBar(message: 'Produit supprimé avec succès');
    } catch (e) {
      TLoaders.errorSnackBar(message: "Erreur lors de la suppression: $e");
    } finally {
      isLoading.value = false;
    }
  }

  // --- AUTRES OUTILS ---
  bool _hasProductManagementPermission() {
    final userRole = userController.user.value.role;
    return userRole == 'Gérant' || userRole == 'Admin';
  }

  ProduitModel? getProductById(String id) {
    try {
      return allProducts.firstWhere((product) => product.id == id);
    } catch (e) {
      return null;
    }
  }

  List<ProduitModel> getAvailableProducts() {
    return allProducts.where((product) => product.isAvailable).toList();
  }

  List<ProduitModel> getProductsWithStock() {
    return allProducts
        .where((product) => product.isStockable && product.stockQuantity > 0)
        .toList();
  }

  @override
  void onClose() {
    nameController.dispose();
    descriptionController.dispose();
    preparationTimeController.dispose();
    stockQuantityController.dispose();
    super.onClose();
  }

  Future<List<String>> pickMultipleImages() async {
    try {
      final ImagePicker picker = ImagePicker();
      final List<XFile> files = await picker.pickMultiImage(imageQuality: 75);

      if (files.isEmpty) return [];

      // Upload chaque image sur Supabase ou ton stockage
      final List<String> uploadedUrls = [];
      for (final file in files) {
        final imageUrl = await uploadProductImage(XFile(file.path));
        if (imageUrl != null) uploadedUrls.add(imageUrl);
      }

      return uploadedUrls;
    } catch (e) {
      debugPrint('Erreur sélection multiples images: $e');
      return [];
    }
  }

  /// Fetch Products
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

  String? calculateSalePercentage(double originalPrice, double salePrice) {
    // Si pas de réduction, on ne renvoie rien
    if (salePrice <= 0 || salePrice >= originalPrice) return null;

    final percent = ((originalPrice - salePrice) / originalPrice) * 100;
    return percent.toStringAsFixed(0); // Renvoie "20" (sans le symbole %)
  }

  /// -- check product stock status
  String getProductStockStatus(int stock) {
    return stock > 0 ? 'En Stock' : 'Hors Stock';
  }

  String getProductPrice(ProduitModel product) {
    try {
      // 🔹 PRODUIT SIMPLE
      if (product.productType == ProductType.single.toString()) {
        // Si promo active
        if (product.salePrice > 0 && product.salePrice < product.price) {
          return "${product.salePrice.toStringAsFixed(2)}";
        }
        return "${product.price.toStringAsFixed(2)}";
      }

      // 🔹 PRODUIT AVEC VARIANTES / TAILLES
      if (product.sizesPrices.isNotEmpty) {
        final prices = product.sizesPrices.map((e) => e.price).toList();
        prices.sort(); // du plus petit au plus grand
        final minPrice = prices.first;
        final maxPrice = prices.last;

        // Si toutes les tailles ont le même prix → un seul affichage
        if (minPrice == maxPrice) {
          return "${minPrice.toStringAsFixed(2)}";
        }

        // Sinon afficher une plage
        return "${minPrice.toStringAsFixed(2)} - ${maxPrice.toStringAsFixed(2)}";
      }

      // 🔹 PAR DÉFAUT
      return "${product.price.toStringAsFixed(2)}";
    } catch (e, s) {
      debugPrint("❌ Erreur getProductPrice: $e\n$s");
      return "0.00";
    }
  }
}
