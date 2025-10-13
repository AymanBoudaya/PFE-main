import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../features/shop/models/etablissement_model.dart';
import '../../../features/shop/models/horaire_model.dart';
import '../../../features/shop/models/statut_etablissement_model.dart';

class EtablissementRepository {
  final supabase = Supabase.instance.client;

  // Créer un établissement SANS horaires
  Future<String> createEtablissement(Etablissement e) async {
    final etabMap = e.toJson()..remove('created_at');

    final inserted =
        await supabase.from('etablissements').insert(etabMap).select().single();

    return inserted['id'];
  }

  // NOUVELLE MÉTHODE : Mettre à jour un établissement (sans toucher aux horaires)
  Future<bool> updateEtablissement(String? id, Map<String, dynamic> data) async {
    try {
      await supabase.from('etablissements').update(data).eq('id', id!);
      return true; // Retourne true si succès
    } catch (e) {
      print('Erreur mise à jour établissement: $e');
      return false; // Retourne false si erreur
    }
  }

  // Ajouter des horaires à un établissement existant
  Future<void> addHorairesToEtablissement(
      String etablissementId, List<Horaire> horaires) async {
    if (horaires.isEmpty) return;

    final horairesData = horaires
        .map((h) => {
              'etablissement_id': etablissementId,
              'jour': h.jour.valeur,
              'ouverture': h.ouverture,
              'fermeture': h.fermeture,
              'est_ouvert': h.estOuvert,
            })
        .toList();

    await supabase.from('horaires').insert(horairesData);
  }

  // Mettre à jour un établissement ET ses horaires
  Future<void> updateEtablissementWithHoraires(
      String id, Map<String, dynamic> data,
      {List<Horaire>? newHoraires}) async {
    await supabase.from('etablissements').update(data).eq('id', id);

    if (newHoraires != null) {
      await supabase.from('horaires').delete().eq('etablissement_id', id);

      if (newHoraires.isNotEmpty) {
        await addHorairesToEtablissement(id, newHoraires);
      }
    }
  }

  // Récupérer les établissements d'un propriétaire
  Future<List<Etablissement>> getEtablissementsByOwner(String ownerId) async {
    final res = await supabase
        .from('etablissements')
        .select('*, horaires(*)')
        .eq('id_owner', ownerId)
        .order('created_at', ascending: false);

    return (res as List).map((e) => Etablissement.fromJson(e)).toList();
  }

  /// Récupérer TOUS les établissements (pour Admin)

  Future<List<Etablissement>> getAllEtablissements() async {
    try {
      final response = await supabase
          .from('etablissements')
          .select()
          .order('created_at', ascending: false);

      return response.map((json) => Etablissement.fromJson(json)).toList();
    } catch (e) {
      throw 'Erreur lors de la récupération de tous les établissements: $e';
    }
  }

  // Supprimer un établissement
  Future<void> deleteEtablissement(String id) async {
    await supabase.from('etablissements').delete().eq('id', id);
  }

  // Modifier le statut
  Future<bool> changeStatut(String id, StatutEtablissement statut) async {
    try {
      await supabase
          .from('etablissements')
          .update({'statut': statut.value})
          .eq('id', id);
      return true;  //Retourne true en cas de succès
    } catch (e) {
      print('Erreur changement statut: $e');
      return false; //  Retourne false en cas d'erreur
    }
  }
  }

