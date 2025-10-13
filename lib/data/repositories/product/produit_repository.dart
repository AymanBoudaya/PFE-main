import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../features/shop/models/produit_model.dart';
import '../../../utils/exceptions/platform_exceptions.dart';

class ProduitRepository extends GetxController {
  static ProduitRepository get instance => Get.find();

  /// Variables
  final _db = Supabase.instance.client;
  final _table = 'produits';

  /// Charger tous les produits
  Future<List<ProduitModel>> getAllProducts() async {
    try {
      final response = await _db
          .from(_table)
          .select('*, etablissement:etablissement_id(*)')
          .order('created_at', ascending: false);
      return response.map((produit) => ProduitModel.fromMap(produit)).toList();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw 'Echec de récupération des produits : $e';
    }
  }

  Future<List<ProduitModel>> getProductsForCategory(
      {required String categoryId, int limit = 4}) async {
    try {
      // Essayer avec différents noms de colonnes possibles
      final query = _db.from(_table).select('''
            *,
            etablissement:etablissement_id(*),
            category:categorie_id(*)
          ''').eq('categorie_id', categoryId); // ou 'categoryId' selon votre BD

      if (limit > 0) {
        query.limit(limit);
      }

      final data = await query;

      if (data.isEmpty) return [];

      return data.map((item) => ProduitModel.fromMap(item)).toList();
    } catch (e) {
      // Debug: afficher l'erreur exacte
      debugPrint('Erreur getProductsForCategory: $e');

      // Fallback: essayer avec une requête plus simple
      try {
        final simpleQuery = _db
            .from(_table)
            .select('*')
            .eq('categorie_id', categoryId)
            .limit(limit);

        final simpleData = await simpleQuery;
        return simpleData.map((item) => ProduitModel.fromMap(item)).toList();
      } catch (fallbackError) {
        debugPrint('Fallback error: $fallbackError');
        throw 'Impossible de charger les produits: $e';
      }
    }
  }

  // Helper to split lists into chunks
  List<List<T>> _chunkList<T>(List<T> list, int chunkSize) {
    final chunks = <List<T>>[];
    for (var i = 0; i < list.length; i += chunkSize) {
      chunks.add(list.sublist(
          i, i + chunkSize > list.length ? list.length : i + chunkSize));
    }
    return chunks;
  }

  Future<List<ProduitModel>> getProductsForBrand({
    required String etablissementId,
    int limit = -1,
  }) async {
    try {
      final query = _db
          .from(_table)
          .select('*')
          .eq('etablissement_id', etablissementId)
          .order('name', ascending: true);

      final response = limit == -1 ? await query : await query.limit(limit);

      if (response == null) return [];

      return (response as List<dynamic>)
          .map((json) => ProduitModel.fromJson(json))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Erreur Supabase: ${e.message}');
    } catch (e) {
      throw Exception('Erreur lors du chargement des produits: $e');
    }
  }

  /// Récupérer un produit par son ID
  Future<ProduitModel?> getProductById(String productId) async {
    try {
      final response = await _db
          .from(_table)
          .select('*, etablissement:etablissement_id(*)')
          .eq('id', productId)
          .single();

      return ProduitModel.fromMap(response);
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw 'Echec de récupération du produit : $e';
    }
  }

  /// Récupérer les produits d'un établissement
  Future<List<ProduitModel>> getProductsByEtablissement(
      String etablissementId) async {
    try {
      final response = await _db
          .from(_table)
          .select('*')
          .eq('etablissement_id', etablissementId)
          .order('created_at', ascending: false);
      return response.map((produit) => ProduitModel.fromMap(produit)).toList();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw 'Echec de récupération des produits de l\'établissement : $e';
    }
  }

  /// Récupérer les produits d'une catégorie
  Future<List<ProduitModel>> getProductsByCategory(String categoryId) async {
    try {
      final response = await _db
          .from(_table)
          .select('*')
          .eq('categorie_id', categoryId)
          .order('created_at', ascending: false);
      return response.map((produit) => ProduitModel.fromMap(produit)).toList();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw 'Echec de récupération des produits de la catégorie : $e';
    }
  }

  /// Ajouter un nouveau produit
  Future<void> addProduct(ProduitModel produit) async {
    try {
      await _db.from(_table).insert(produit.toJson());
      // Pas besoin de vérifier error → si ça échoue, une exception sera levée
    } on PostgrestException catch (e) {
      throw 'Erreur base de données : ${e.code} - ${e.message}';
    } catch (e) {
      print(e);
      throw 'Erreur lors de l\'ajout du produit : $e';
    }
  }

  /// Modifier un produit
  Future<void> updateProduct(ProduitModel produit) async {
    try {
      await _db.from(_table).update(produit.toJson()).eq('id', produit.id);
    } on PostgrestException catch (e) {
      throw 'Erreur base de données : ${e.code} - ${e.message}';
    } catch (e) {
      throw 'Erreur lors de la mise à jour du produit : $e';
    }
  }

  /// Supprimer un produit
  Future<void> deleteProduct(String productId) async {
    try {
      await _db.from(_table).delete().eq('id', productId);
    } on PostgrestException catch (e) {
      throw 'Erreur base de données : ${e.code} - ${e.message}';
    } catch (e) {
      throw 'Erreur lors de la suppression du produit : $e';
    }
  }

// For XFile (web and mobile)
  Future<String> uploadProductImage(XFile pickedFile) async {
    try {
      final bytes = await pickedFile.readAsBytes();
      return await _uploadProductImageBytes(bytes);
    } catch (e) {
      debugPrint("Erreur uploadProductImage: $e");
      throw 'Erreur lors de l\'upload de l\'image : $e';
    }
  }

  Future<String> _uploadProductImageBytes(Uint8List bytes) async {
    final fileName = 'produit_${DateTime.now().millisecondsSinceEpoch}.png';
    final bucket = 'produits';

    await Supabase.instance.client.storage.from(bucket).uploadBinary(
        fileName, bytes,
        fileOptions: const FileOptions(contentType: 'image/png'));

    final publicUrl =
        Supabase.instance.client.storage.from(bucket).getPublicUrl(fileName);

    debugPrint("Product image uploaded. Public URL: $publicUrl");
    return publicUrl;
  }

  /// Uploader une image de produit
  /*Future<String> uploadProductImage(File imageFile) async {
    try {
      final fileName = 'produit_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final bucket = 'produits';

      // Upload vers le bucket "produits"
      await Supabase.instance.client.storage
          .from(bucket)
          .upload(fileName, imageFile);

      // Récupérer l'URL publique
      final publicUrl =
          Supabase.instance.client.storage.from(bucket).getPublicUrl(fileName);

      return publicUrl;
    } catch (e) {
      throw 'Erreur lors de l\'upload de l\'image : $e';
    }
  }*/

  Future<List<ProduitModel>> getFeaturedProducts() async {
    try {
      final response = await _db
          .from(_table)
          .select('*, etablissement:etablissement_id(*)')
          .eq('is_featured', true)
          .order('created_at', ascending: false);

      if (response == null) {
        throw Exception('Aucune réponse reçue de Supabase.');
      }

      final data = response as List<dynamic>;

      // Convertit les résultats en objets ProduitModel
      final products = data.map((productData) {
        return ProduitModel.fromMap(Map<String, dynamic>.from(productData));
      }).toList();

      return products;
    } on PostgrestException catch (e) {
      throw Exception('Erreur Supabase: ${e.message}');
    } catch (e) {
      rethrow; // important pour que Flutter te montre l’exception dans la console
    }
  }
}
