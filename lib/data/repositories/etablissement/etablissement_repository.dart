import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../features/shop/models/etablissement_model.dart';
import '../../../features/shop/models/horaire_model.dart';
import '../../../features/shop/models/statut_etablissement_model.dart';

class EtablissementRepository {
  final SupabaseClient supabase = Supabase.instance.client;

  // 🔥 CORRECTION : Création avec gestion d'erreur
  Future<String?> createEtablissement(Etablissement etablissement) async {
    try {
      final data = etablissement.toJson();

      // 🔥 CORRECTION : S'assurer que le statut est bien en_attente
      data['statut'] = 'en_attente';

      final response = await supabase
          .from('etablissements')
          .insert(data)
          .select('id')
          .single();

      return response['id']?.toString();
    } catch (e, stack) {
      print('❌ Erreur création établissement: $e');
      print('Stack: $stack');
      rethrow;
    }
  }

  // 🔥 CORRECTION : Mise à jour avec gestion d'erreur
  Future<bool> updateEtablissement(
      String? id, Map<String, dynamic> data) async {
    try {
      if (id == null || id.isEmpty) {
        throw 'ID établissement manquant';
      }

      print('🔄 Mise à jour établissement $id: $data');

      // 🔥 CORRECTION : S'assurer que le statut est bien converti
      if (data.containsKey('statut') && data['statut'] is String) {
        // Déjà converti par le contrôleur
      }

      final response =
          await supabase.from('etablissements').update(data).eq('id', id);

      print('✅ Établissement $id mis à jour avec succès');
      return true;
    } catch (e, stack) {
      print('❌ Erreur mise à jour établissement $id: $e');
      print('Stack: $stack');
      rethrow;
    }
  }

  // 🔥 CORRECTION : Changement de statut
  Future<bool> changeStatut(String id, StatutEtablissement newStatut) async {
    try {
      print('🔄 Changement statut établissement $id: ${newStatut.value}');

      final response = await supabase
          .from('etablissements')
          .update({'statut': newStatut.value}).eq('id', id);

      print('✅ Statut établissement $id changé avec succès');
      return true;
    } catch (e, stack) {
      print('❌ Erreur changement statut établissement $id: $e');
      print('Stack: $stack');
      rethrow;
    }
  }

  // Récupérer tous les établissements
  Future<List<Etablissement>> getAllEtablissements() async {
    try {
      final response = await supabase
          .from('etablissements')
          .select('*')
          .order('created_at', ascending: false);

      return response
          .map<Etablissement>((json) => Etablissement.fromJson(json))
          .toList();
    } catch (e, stack) {
      print('❌ Erreur récupération établissements: $e');
      print('Stack: $stack');
      rethrow;
    }
  }

  // Récupérer les établissements par propriétaire
  Future<List<Etablissement>> getEtablissementsByOwner(String ownerId) async {
    try {
      final response = await supabase
          .from('etablissements')
          .select('*')
          .eq('id_owner', ownerId)
          .order('created_at', ascending: false);

      return response
          .map<Etablissement>((json) => Etablissement.fromJson(json))
          .toList();
    } catch (e, stack) {
      print('❌ Erreur récupération établissements propriétaire: $e');
      print('Stack: $stack');
      rethrow;
    }
  }

  // 🔥 CORRECTION : Suppression avec gestion des dépendances
  Future<bool> deleteEtablissement(String id) async {
    try {
      // 1. Supprimer les horaires associés
      try {
        await supabase.from('horaires').delete().eq('etablissement_id', id);
        print('✅ Horaires supprimés pour établissement: $id');
      } catch (e) {
        print('ℹ️ Aucun horaire à supprimer: $e');
      }

      // 2. Supprimer les produits associés
      try {
        await supabase.from('produits').delete().eq('etablissement_id', id);
        print('✅ Produits supprimés pour établissement: $id');
      } catch (e) {
        print('ℹ️ Aucun produit à supprimer: $e');
      }

      // 3. Supprimer l'établissement
      final response =
          await supabase.from('etablissements').delete().eq('id', id);

      print('✅ Établissement $id supprimé avec succès');
      return true;
    } catch (e, stack) {
      print('❌ Erreur suppression établissement $id: $e');
      print('Stack: $stack');
      rethrow;
    }
  }
}
