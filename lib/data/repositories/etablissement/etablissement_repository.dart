import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../features/shop/models/etablissement_model.dart';
import '../../../features/shop/models/produit_model.dart';
import '../../../features/shop/models/statut_etablissement_model.dart';

class EtablissementRepository {
  final SupabaseClient _db = Supabase.instance.client;
  final _table = 'etablissements';

  // Création avec gestion d'erreur
  Future<String?> createEtablissement(Etablissement etablissement) async {
    try {
      final data = etablissement.toJson()..['statut'] = 'en_attente';

      final response = await _db
          .from(_table)
          .insert(data)
          .select('*, id_owner:users!id_owner(*)') // 🔥 Jointure explicite
          .single();
      return response['id']?.toString();
    } catch (e, stack) {
      print('Erreur création établissement: $e');
      print('Stack: $stack');
      rethrow;
    }
  }

  // Mise à jour avec gestion d'erreur
  Future<bool> updateEtablissement(
      String? id, Map<String, dynamic> data) async {
    try {
      if (id == null || id.isEmpty) {
        throw 'ID établissement manquant';
      }

      print('Mise à jour établissement $id: $data');

      // S'assurer que le statut est bien converti
      if (data.containsKey('statut') && data['statut'] is String) {
        // Déjà converti par le contrôleur
      }

      final response = await _db
          .from(_table)
          .update(data)
          .eq('id', id)
          .select('*, id_owner:users!id_owner(*)') // 🔥 Jointure explicite
          .single();
      print('Établissement $id mis à jour avec succès');
      return true;
    } catch (e, stack) {
      print('Erreur mise à jour établissement $id: $e');
      print('Stack: $stack');
      rethrow;
    }
  }

  // Changement de statut
  Future<bool> changeStatut(String id, StatutEtablissement newStatut) async {
    try {
      print('Changement statut établissement $id: ${newStatut.value}');

      final response = await _db
          .from(_table)
          .update({'statut': newStatut.value}).eq('id', id);

      print('Statut établissement $id changé avec succès');
      return true;
    } catch (e, stack) {
      print('Erreur changement statut établissement $id: $e');
      print('Stack: $stack');
      rethrow;
    }
  }

  Future<List<Etablissement>> getFeaturedEtablissements() async {
    try {
      final response = await _db
          .from(_table)
          .select('*, id_owner:users!id_owner(*)') // 🔥 Jointure explicite
          .eq('is_featured', true)
          .limit(4)
          .order('created_at', ascending: false);
      return response.map((json) => Etablissement.fromJson(json)).toList();
    } on PostgrestException catch (e) {
      throw 'Database error: ${e.message}';
    } catch (e) {
      throw 'Echec de chargement des produits en vedette : ${e.toString()}';
    }
  }

  // Récupérer tous les établissements
  Future<List<Etablissement>> getAllEtablissements() async {
    try {
      final response = await _db
          .from(_table)
          .select('*, id_owner:users!id_owner(*)') // 🔥 Jointure explicite
          .order('created_at', ascending: false);

      return response
          .map<Etablissement>((json) => Etablissement.fromJson(json))
          .toList();
    } catch (e, stack) {
      print('Erreur récupération établissements: $e');
      print('Stack: $stack');
      rethrow;
    }
  }

  // Récupérer les établissements par propriétaire
  Future<List<Etablissement>> getEtablissementsByOwner(String ownerId) async {
    try {
      final response = await _db
          .from(_table)
          .select('*, id_owner:users!id_owner(*)') // 🔥 Jointure explicite
          .eq('id_owner', ownerId)
          .order('created_at', ascending: false);

      return response
          .map<Etablissement>((json) => Etablissement.fromJson(json))
          .toList();
    } catch (e, stack) {
      print('Erreur récupération établissements propriétaire: $e');
      print('Stack: $stack');
      rethrow;
    }
  }

  Future<List<Etablissement>> getBrandsForCategory(String categoryId) async {
    try {
      return [];
    } on PostgrestException catch (e) {
      throw 'Erreur Supabase: ${e.message}';
    } catch (e) {
      throw 'Quelque chose s\'est mal passée lors de la récupération des bannières.';
    }
  }

  // Suppression avec gestion des dépendances
  Future<bool> deleteEtablissement(String id) async {
    try {
      // 1. Supprimer les horaires associés
      try {
        await _db.from('horaires').delete().eq('etablissement_id', id);
        print('Horaires supprimés pour établissement: $id');
      } catch (e) {
        print('Aucun horaire à supprimer: $e');
      }

      // 2. Supprimer les produits associés
      try {
        await _db.from('produits').delete().eq('etablissement_id', id);
        print('Produits supprimés pour établissement: $id');
      } catch (e) {
        print('Aucun produit à supprimer: $e');
      }

      // 3. Supprimer l'établissement
      final response = await _db.from(_table).delete().eq('id', id);

      print('Établissement $id supprimé avec succès');
      return true;
    } catch (e, stack) {
      print('Erreur suppression établissement $id: $e');
      print('Stack: $stack');
      rethrow;
    }
  }

  Future<List<ProduitModel>> getProduitsEtablissement(
      String etablissementId) async {
    try {
      final response = await _db
          .from('produits') // your table name in Supabase
          .select('*')
          .eq('id_etablissement', etablissementId);

      // Convert the result into a list of ProductModel
      final produits =
          (response as List).map((p) => ProduitModel.fromJson(p)).toList();

      return produits;
    } catch (e) {
      print('Erreur getProduitsEtablissement: $e');
      rethrow;
    }
  }
}
