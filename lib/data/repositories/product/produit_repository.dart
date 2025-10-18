import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../features/shop/models/category_model.dart';
import '../../../features/shop/models/etablissement_model.dart';
import '../../../features/shop/models/produit_model.dart';
import '../../../features/shop/models/statut_etablissement_model.dart';
import '../../../utils/exceptions/platform_exceptions.dart';

class ProduitRepository extends GetxController {
  static ProduitRepository get instance => Get.find();

  /// Variables
  final _db = Supabase.instance.client;
  final _table = 'produits';
  int _page = 1;
  final int _limit = 10;

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

  Future<List<String>> getAllCategories() async {
  final data = await _db.from('categories').select('name');
  return data.map<String>((c) => c['name'] as String).toList();
}

Future<List<String>> getAllEtablissementsNames() async {
  final data = await _db.from('etablissements').select('name');
  return data.map<String>((e) => e['name'] as String).toList();
}


  /// Optional: Search directly in Supabase (server-side search)
  Future<List<ProduitModel>> searchProducts(String query) async {
    final response = await _db
        .from(_table)
        .select('*')
        .or('name.ilike.%$query%,description.ilike.%$query%')
        .order('created_at', ascending: false)
        .limit(20);

    if (response.isEmpty) return [];

    return response.map((e) => ProduitModel.fromMap(e)).toList();
  }

  Future<List<ProduitModel>> getAllProductsPaginated({
    int? page,
    int? limit,
  }) async {
    final currentPage = page ?? _page;
    final currentLimit = limit ?? _limit;

    final from = (currentPage - 1) * currentLimit;
    final to = from + currentLimit - 1;

    final response = await _db
        .from(_table)
        .select('*')
        .order('created_at', ascending: false)
        .range(from, to);

    if (response.isEmpty) return [];

    // Increment page counter for next call
    _page++;

    return response.map((e) => ProduitModel.fromMap(e)).toList();
  }

  Future<List<ProduitModel>> getProductsForCategory(
      {required String categoryId, int limit = 4}) async {
    try {
      // Essayer avec différents noms de colonnes possibles
      final query = _db.from(_table).select('''
            *,
            etablissement:etablissement_id(*),
            category:categorie_id(*)
          ''').eq('categorie_id', categoryId);

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
  Future<ProduitModel> addProduct(ProduitModel produit) async {
    try {
      final response =
          await _db.from('produits').insert(produit.toJson()).select().single();
      final createdProduct = ProduitModel.fromMap(response);

      return createdProduct;
    } catch (e) {
      throw Exception('Erreur lors de l’ajout du produit: $e');
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

  Future<List<ProduitModel>> getFeaturedProducts() async {
    try {
      final response = await _db
          .from(_table)
          .select('*, etablissement:etablissement_id(*)')
          .eq('is_featured', true)
          .limit(8)
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

  Future<List<ProduitModel>> getAllFeaturedProducts() async {
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

  // 🔥 NOUVELLES MÉTHODES : Récupération avec IDs
Future<List<CategoryModel>> getAllCategoriesWithIds() async {
  try {
    final data = await _db.from('categories').select('id, name, image'); // 🔥 Inclure image si disponible
    
    return data.map<CategoryModel>((c) {
      // 🔥 CORRECTION : Utiliser fromJson ou fromBasicData selon les données disponibles
      if (c['image'] != null) {
        return CategoryModel.fromJson(c);
      } else {
        return CategoryModel.fromBasicData(
          id: c['id']?.toString() ?? '',
          name: c['name']?.toString() ?? '',
        );
      }
    }).toList();
  } catch (e) {
    print('❌ Erreur getAllCategoriesWithIds: $e');
    return [];
  }
}

Future<List<Etablissement>> getAllEtablissementsWithIds() async {
  try {
    final data = await _db.from('etablissements').select('id, name, statut');
    return data.map<Etablissement>((e) => Etablissement(
      id: e['id']?.toString(),
      name: e['name']?.toString() ?? '',
      address: '',
      idOwner: '',
      statut: StatutEtablissementExt.fromString(e['statut']?.toString()),
      createdAt: DateTime.now(),
    )).toList();
  } catch (e) {
    print('❌ Erreur getAllEtablissementsWithIds: $e');
    return [];
  }
}

// 🔥 CORRECTION : Recherche améliorée avec gestion correcte des types
Future<List<ProduitModel>> searchProductsWithFilters({
  String? query,
  String? categoryId,
  String? etablissementId,
  String? sortBy,
}) async {
  try {
    // 🔥 CORRECTION : Utiliser dynamic pour éviter les conflits de types
    dynamic request = _db.from(_table).select('''
      *, 
      etablissement:etablissement_id(*),
      category:categorie_id(*)
    ''');

    // Appliquer les filtres
    if (query != null && query.isNotEmpty) {
      request = request.or('nom.ilike.%$query%,description.ilike.%$query%');
    }
    
    if (categoryId != null && categoryId.isNotEmpty) {
      request = request.eq('categorie_id', categoryId);
    }
    
    if (etablissementId != null && etablissementId.isNotEmpty) {
      request = request.eq('etablissement_id', etablissementId);
    }

    // 🔥 CORRECTION : Appliquer le tri avec gestion de type
    switch (sortBy) {
      case 'Prix ↑':
        request = (request as dynamic).order('prix', ascending: true);
        break;
      case 'Prix ↓':
        request = (request as dynamic).order('prix', ascending: false);
        break;
      case 'Nom A-Z':
        request = (request as dynamic).order('nom', ascending: true);
        break;
      case 'Popularité':
        request = (request as dynamic).order('is_featured', ascending: false);
        break;
      default:
        request = (request as dynamic).order('created_at', ascending: false);
    }

    final response = await request;
    return response.map((e) => ProduitModel.fromMap(e)).toList();
  } catch (e) {
    print('❌ Erreur searchProductsWithFilters: $e');
    return [];
  }
}
}
