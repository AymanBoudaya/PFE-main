import 'package:caferesto/utils/popups/loaders.dart';
import 'package:get/get.dart';
import '../../../data/repositories/etablissement/etablissement_repository.dart';
import '../../personalization/controllers/user_controller.dart';
import '../models/etablissement_model.dart';
import '../models/horaire_model.dart';
import '../models/statut_etablissement_model.dart';

class EtablissementController extends GetxController {
  final EtablissementRepository repo;
  final UserController userController = Get.find<UserController>();
  final etablissements = <Etablissement>[].obs;

  EtablissementController(this.repo);

  // Ajouter établissement sans horaires
  Future<String?> createEtablissement(Etablissement e) async {
    try {
      if (!_isUserGerant()) {
        _logError('création',
            'Permission refusée : seul un Gérant peut créer un établissement');
        return null;
      }

      final id = await repo.createEtablissement(e);

      if (id != null && id.isNotEmpty) {
        // Ajouter localement
        etablissements.add(e.copyWith(id: id));

        // Et rafraîchir depuis la base pour être sûr d’avoir les dernières données
        final user = userController.user.value;
        if (user.id.isNotEmpty) {
          await fetchEtablissementsByOwner(user.id);
        }
      }

      return id;
    } catch (err, stack) {
      _logError('création', err, stack);
      return null;
    }
  }

  // Mettre à jour un établissement
  Future<bool> updateEtablissement(
      String? id, Map<String, dynamic> data) async {
    try {
      if (!_isUserGerant() && !_isUserAdmin()) {
        _logError('mise à jour',
            'Permission refusée : seul un Gérant/Admin peut modifier un établissement');
        return false;
      }

      final success = await repo.updateEtablissement(id, data);
      return success;
    } catch (e, stack) {
      _logError('mise à jour', e, stack);
      return false;
    }
  }

  // Méthode pour changer le statut d'un établissement (pour Admin)
  Future<bool> changeStatutEtablissement(
      String id, StatutEtablissement newStatut) async {
    try {
      if (!_isUserAdmin()) {
        _logError('changement statut', 'Permission refusée : Admin requis');
        return false;
      }

      final success = await repo.changeStatut(id, newStatut);

      if (success) {
        // Rafraîchir la liste des établissements
        await getTousEtablissements();
        TLoaders.successSnackBar(message: 'Statut mis à jour avec succès');
      } else {
        TLoaders.errorSnackBar(message: 'Échec de la mise à jour du statut');
      }

      return success;
    } catch (e, stack) {
      _logError('changement statut', e, stack);
      TLoaders.errorSnackBar(
          message: 'Erreur lors du changement de statut: $e');
      return false;
    }
  }

  // Ajouter des horaires à un établissement existant
  Future<bool> addHorairesToEtablissement(
      String etablissementId, List<Horaire> horaires) async {
    try {
      if (!_isUserGerant()) {
        _logError('ajout horaires', 'Permission refusée');
        return false;
      }
      await repo.addHorairesToEtablissement(etablissementId, horaires);
      return true;
    } catch (e, stack) {
      _logError('ajout horaires', e, stack);
      return false;
    }
  }

  // Récupérer les établissements d'un propriétaire
  Future<List<Etablissement>?> fetchEtablissementsByOwner(
      String ownerId) async {
    try {
      final data = await repo.getEtablissementsByOwner(ownerId);
      etablissements.assignAll(data);
      return data;
    } catch (e, stack) {
      _logError('récupération', e, stack);
      return null;
    }
  }

  // Récupérer l'établissement du gérant connecté
  Future<Etablissement?> getMonEtablissement() async {
    try {
      final userRole = userController.userRole;
      if (userRole.isEmpty) {
        _logError('récupération établissement', 'Utilisateur non connecté');
        return null;
      }

      final user = userController.user.value;
      if (user.id.isEmpty) {
        _logError('récupération établissement', 'Utilisateur non connecté');
        return null;
      }

      final etablissements = await repo.getEtablissementsByOwner(user.id);
      return etablissements.isNotEmpty ? etablissements.first : null;
    } catch (e, stack) {
      _logError('récupération établissement', e, stack);
      return null;
    }
  }

  /// 2. Pour Admin - tous les établissements (liste complète)
  Future<List<Etablissement>> getTousEtablissements() async {
    try {
      final userRole = userController.userRole;
      if (userRole.isEmpty || userRole != 'Admin') {
        return [];
      }

      return await repo.getAllEtablissements();
    } catch (e, stack) {
      _logError('récupération établissements', e, stack);
      return [];
    }
  }

  Future<bool> deleteEtablissement(String id) async {
    try {
      if (!_isUserGerant() && !_isUserAdmin()) {
        _logError('suppression',
            'Permission refusée : seul un Gérant/Admin peut supprimer un établissement');
        return false;
      }

      await repo.deleteEtablissement(id);

      etablissements.removeWhere((e) => e.id == id);

      final user = userController.user.value;
      if (user.id.isNotEmpty) {
        await fetchEtablissementsByOwner(user.id);
      }

      return true;
    } catch (e, stack) {
      _logError('suppression', e, stack);
      return false;
    }
  }

// Méthode pour récupérer un établissement par son ID
  Future<Etablissement?> getEtablissementById(String id) async {
    try {
      /* final tousEtablissements = await getTousEtablissements(); */
      final tousEtablissements = await getTousEtablissementsPourProduit();

      return tousEtablissements.firstWhereOrNull((etab) => etab.id == id);
    } catch (e) {
      _logError('récupération par ID', e);
      return null;
    }
  }

  bool _isUserGerant() {
    final userRole = userController.userRole;
    if (userRole.isEmpty) {
      _logError('vérification rôle', 'Utilisateur non connecté');
      return false;
    }
    if (userRole != 'Gérant') {
      _logError(
          'vérification rôle', 'Rôle insuffisant. Rôle actuel: $userRole');
      return false;
    }
    return true;
  }

  // Méthode utilitaire pour vérifier si l'utilisateur est admin
  bool _isUserAdmin() {
    final userRole = userController.userRole;

    if (userRole.isEmpty) {
      _logError('vérification admin', 'Utilisateur non connecté');
      return false;
    }

    // Vérifie si le rôle est "Admin" (avec majuscule comme dans votre UserModel)
    final isAdmin = userRole == 'Admin';

    return isAdmin;
  }

  /// Pour récupérer  le statut
  Future<StatutEtablissement?> getStatutEtablissement(
      String etablissementId) async {
    try {
      final etablissement = await getEtablissementById(etablissementId);
      return etablissement?.statut;
    } catch (e) {
      _logError('récupération statut', e);
      return null;
    }
  }

  // Récupérer l'établissement de l'utilisateur connecté
  Future<Etablissement?> getEtablissementUtilisateurConnecte() async {
    try {
      final user = userController.user.value;

      // Vérifier que l'utilisateur est connecté
      if (user.id.isEmpty) {
        _logError('récupération établissement', 'Utilisateur non connecté');
        return null;
      }

      // Récupérer les établissements de l'utilisateur
      final etablissementsUtilisateur =
          await fetchEtablissementsByOwner(user.id);

      if (etablissementsUtilisateur == null ||
          etablissementsUtilisateur.isEmpty) {
        return null;
      }

      // Retourner le premier établissement (ou le seul établissement)
      final etablissement = etablissementsUtilisateur.first;
      return etablissement;
    } catch (e, stack) {
      _logError('récupération établissement utilisateur', e, stack);
      return null;
    }
  }

  void _logError(String action, Object error, [StackTrace? stack]) {
    if (stack != null) {
      print(stack);
    }
  }

  /// Méthode pour récupérer tous les établissements,
  /// sans filtrer par rôle (utile pour les produits)
  Future<List<Etablissement>> getTousEtablissementsPourProduit() async {
    try {
      final data = await repo.getAllEtablissements();
      return data;
    } catch (e, stack) {
      _logError('récupération établissements pour produit', e, stack);
      return [];
    }
  }
}
