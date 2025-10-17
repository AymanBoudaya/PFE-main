import 'package:caferesto/utils/popups/loaders.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../data/repositories/etablissement/etablissement_repository.dart';
import '../../personalization/controllers/user_controller.dart';
import '../models/etablissement_model.dart';
import '../models/produit_model.dart';
import '../models/statut_etablissement_model.dart';

class EtablissementController extends GetxController {
  static EtablissementController get instance => Get.find();

  final EtablissementRepository repo;
  final UserController userController = Get.find<UserController>();
  final isLoading = false.obs;
  final etablissements = <Etablissement>[].obs;
  final SupabaseClient _supabase = Supabase.instance.client;
  RxList<Etablissement> featuredBrands = <Etablissement>[].obs;
  final RxList<Etablissement> allEtablissements = <Etablissement>[].obs;

  EtablissementController(this.repo);

  @override
  void onInit() {
    super.onInit();
    print('EtablissementController initialisé');
    fetchFeaturedEtablissements();
  }

  Future<String?> uploadEtablissementImage(XFile file) async {
    try {
      final bytes = await file.readAsBytes();
      final filePath =
          'etablissements/${DateTime.now().millisecondsSinceEpoch}_${file.name}';
      await _supabase.storage
          .from('etablissements')
          .uploadBinary(filePath, bytes);
      return _supabase.storage.from('etablissements').getPublicUrl(filePath);
    } catch (e) {
      TLoaders.errorSnackBar(message: 'Erreur upload image: $e');
      return null;
    }
  }

  Future<String?> createEtablissement(Etablissement e) async {
    try {
      if (!_hasPermissionForAction('création')) {
        return null;
      }

      isLoading.value = true;
      final id = await repo.createEtablissement(e);
      Get.back(result: true);

      if (id != null && id.isNotEmpty) {
        // Rafraîchir selon le rôle
        await _refreshEtablissementsAfterAction();
        TLoaders.successSnackBar(message: 'Établissement créé avec succès');
      } else {
        TLoaders.errorSnackBar(message: 'Erreur lors de la création');
      }

      return id;
    } catch (err, stack) {
      _logError('création', err, stack);
      TLoaders.errorSnackBar(message: 'Erreur création: $err');
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> updateEtablissement(
      String? id, Map<String, dynamic> data) async {
    try {
      if (!_hasPermissionForAction('mise à jour')) {
        return false;
      }

      if (id == null || id.isEmpty) {
        TLoaders.errorSnackBar(message: 'ID établissement manquant');
        return false;
      }

      isLoading.value = true;

      // S'assurer que le statut est converti correctement
      if (data.containsKey('statut') && data['statut'] is StatutEtablissement) {
        data['statut'] = (data['statut'] as StatutEtablissement).value;
      }

      Get.back(result: true);
      final success = await repo.updateEtablissement(id, data);
      if (success) {
        await _refreshEtablissementsAfterAction();
        TLoaders.successSnackBar(
            message: 'Établissement mis à jour avec succès');
      } else {
        TLoaders.errorSnackBar(message: 'Échec de la mise à jour');
      }

      return success;
    } catch (e, stack) {
      _logError('mise à jour', e, stack);
      TLoaders.errorSnackBar(message: 'Erreur mise à jour: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Méthode pour changer le statut
  Future<bool> changeStatutEtablissement(
      String id, StatutEtablissement newStatut) async {
    try {
      if (!_isUserAdmin()) {
        _logError('changement statut', 'Permission refusée : Admin requis');
        return false;
      }

      isLoading.value = true;

      // Utiliser la valeur correcte pour l'enum
      final success = await repo.changeStatut(id, newStatut);

      if (success) {
        await _refreshEtablissementsAfterAction();
        TLoaders.successSnackBar(message: 'Statut mis à jour avec succès');
      } else {
        TLoaders.errorSnackBar(message: 'Échec de la mise à jour du statut');
      }

      return success;
    } catch (e, stack) {
      _logError('changement statut', e, stack);
      TLoaders.errorSnackBar(message: 'Erreur changement statut: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Rafraîchissement après action
  Future<void> _refreshEtablissementsAfterAction() async {
    try {
      final userRole = userController.userRole;
      final userId = userController.user.value.id;

      if (userRole == 'Admin') {
        await getTousEtablissements();
      } else if (userRole == 'Gérant' && userId.isNotEmpty) {
        await fetchEtablissementsByOwner(userId);
      }
    } catch (e) {
      print('Erreur rafraîchissement: $e');
    }
  }

  // Vérification de permission unifiée
  bool _hasPermissionForAction(String action) {
    final userRole = userController.userRole;

    if (userRole.isEmpty) {
      TLoaders.errorSnackBar(message: 'Utilisateur non connecté');
      return false;
    }

    if (action == 'création' && userRole != 'Gérant' && userRole != 'Admin') {
      TLoaders.errorSnackBar(
          message: 'Seuls les Admins/Gérants peuvent créer des établissements');
      return false;
    }

    if (action == 'mise à jour' &&
        userRole != 'Gérant' &&
        userRole != 'Admin') {
      TLoaders.errorSnackBar(message: 'Permission refusée pour la mise à jour');
      return false;
    }

    return true;
  }

  // Récupérer les établissements d'un propriétaire
  Future<List<Etablissement>?> fetchEtablissementsByOwner(
      String ownerId) async {
    try {
      isLoading.value = true;
      final data = await repo.getEtablissementsByOwner(ownerId);
      etablissements.assignAll(data);
      return data;
    } catch (e) {
      print('Erreur fetchEtablissementsByOwner: $e');
      TLoaders.errorSnackBar(message: 'Erreur chargement établissements: $e');
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  // Pour Admin - tous les établissements
  Future<List<Etablissement>> getTousEtablissements() async {
    try {
      isLoading.value = true;
      final data = await repo.getAllEtablissements();
      etablissements.assignAll(data);
      return data;
    } catch (e) {
      print('Erreur getTousEtablissements: $e');
      TLoaders.errorSnackBar(message: 'Erreur chargement établissements: $e');
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  // Suppression améliorée
  Future<bool> deleteEtablissement(String id) async {
    try {
      if (!_hasPermissionForAction('suppression')) {
        return false;
      }

      // Confirmation avant suppression
      final shouldDelete = await _showDeleteConfirmation();
      if (!shouldDelete) return false;

      isLoading.value = true;

      final success = await repo.deleteEtablissement(id);

      if (success) {
        // Supprimer localement ET rafraîchir
        etablissements.removeWhere((e) => e.id == id);
        await _refreshEtablissementsAfterAction();
        TLoaders.successSnackBar(message: 'Établissement supprimé avec succès');
      } else {
        TLoaders.errorSnackBar(message: 'Échec de la suppression');
      }

      return success;
    } catch (e, stack) {
      _logError('suppression', e, stack);
      TLoaders.errorSnackBar(message: 'Erreur suppression: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  //Confirmatio n de suppression
  Future<bool> _showDeleteConfirmation() async {
    final result = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: const Text(
            'Êtes-vous sûr de vouloir supprimer cet établissement avec tout ses produits ?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  // Récupérer un établissement par ID
  Future<Etablissement?> getEtablissementById(String id) async {
    try {
      final tousEtablissements = await getTousEtablissementsPourProduit();
      return tousEtablissements.firstWhereOrNull((etab) => etab.id == id);
    } catch (e) {
      _logError('récupération par ID', e);
      return null;
    }
  }

  bool _isUserGerant() {
    final userRole = userController.userRole;
    return userRole == 'Gérant';
  }

  bool _isUserAdmin() {
    final userRole = userController.userRole;
    return userRole == 'Admin';
  }

  // Récupérer l'établissement de l'utilisateur connecté
  Future<Etablissement?> getEtablissementUtilisateurConnecte() async {
    try {
      final user = userController.user.value;

      if (user.id.isEmpty) {
        _logError('récupération établissement', 'Utilisateur non connecté');
        return null;
      }

      final etablissementsUtilisateur =
          await fetchEtablissementsByOwner(user.id);
      return etablissementsUtilisateur?.isNotEmpty == true
          ? etablissementsUtilisateur!.first
          : null;
    } catch (e, stack) {
      _logError('récupération établissement utilisateur', e, stack);
      return null;
    }
  }

  // Pour les produits - sans loading state
  Future<List<Etablissement>> getTousEtablissementsPourProduit() async {
    try {
      final data = await repo.getAllEtablissements();
      return data;
    } catch (e, stack) {
      _logError('récupération établissements pour produit', e, stack);
      return [];
    }
  }

  void _logError(String action, Object error, [StackTrace? stack]) {
    print('Erreur $action: $error');
    if (stack != null) {
      print('Stack: $stack');
    }
  }

  /// Fetch etablissements
  void fetchFeaturedEtablissements() async {
    try {
      // Show loader while loading etablissements
      isLoading.value = true;

      // Fetch etablissements from an API or database
      final etablissements = await repo.getFeaturedEtablissements();
      // Assign etablissements
      featuredBrands.assignAll(etablissements);
      print(featuredBrands.toString());
    } catch (e) {
      // Handle error
      TLoaders.errorSnackBar(title: 'Erreur!', message: e.toString());
    } finally {
      // Hide loader after loading etablissements
      isLoading.value = false;
    }
  }

  /// Fetch etablissements
  void fetchAllEtablissements() async {
    try {
      // Show loader while loading etablissements
      isLoading.value = true;

      // Fetch etablissements from an API or database
      final etablissements = await repo.getAllEtablissements();
      // Assign etablissements
      allEtablissements.assignAll(etablissements);
    } catch (e) {
      // Handle error
      TLoaders.errorSnackBar(title: 'Erreur!', message: e.toString());
    } finally {
      // Hide loader after loading etablissements
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    print('EtablissementController fermé');
    super.onClose();
  }

  Future<List<ProduitModel>> getProduitsEtablissement({
    required String etablissementId,
  }) async {
    try {
      isLoading.value = true;
      final produits = await repo.getProduitsEtablissement(etablissementId);
      return produits;
    } catch (e) {
      TLoaders.errorSnackBar(
          title: 'Erreur', message: 'Impossible de charger les produits: $e');
      return [];
    } finally {
      isLoading.value = false;
    }
  }

  /// -- Charger ETS pour une catégorie
  Future<List<Etablissement>> getBrandsForCategory(String categoryId) async {
    try {
      final brands = await repo.getBrandsForCategory(categoryId);

      return brands;
    } catch (e) {
      TLoaders.errorSnackBar(title: 'Erreur', message: e.toString());
      return [];
    }
  }
}
