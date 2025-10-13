import 'package:flutter/material.dart';

import '../features/shop/models/produit_model.dart';

class ProduitHelper {
  static String getAffichagePrix(ProduitModel produit) {
    if (produit.sizesPrices.isEmpty) {
      return 'Prix à définir';
    } else if (produit.sizesPrices.length == 1) {
      return 'DT${produit.sizesPrices.first.price.toStringAsFixed(2)}';
    } else {
      final minPrice = produit.minPrice;
      final maxPrice = produit.maxPrice;
      return 'DT${minPrice.toStringAsFixed(2)} - DT${maxPrice.toStringAsFixed(2)}';
    }
  }

  static String getAffichageTailles(ProduitModel produit) {
    if (produit.sizesPrices.isEmpty) {
      return 'Aucune taille';
    } else if (produit.sizesPrices.length == 1) {
      return produit.sizesPrices.first.size;
    } else {
      return '${produit.sizesPrices.length} tailles';
    }
  }

  static String getAffichageStock(ProduitModel produit) {
    if (!produit.isStockable) {
      return 'Non stockable';
    } else if (produit.stockQuantity > 0) {
      return 'Stock: ${produit.stockQuantity}';
    } else {
      return 'Rupture de stock';
    }
  }

  static Color getCouleurStock(ProduitModel produit) {
    if (!produit.isStockable) {
      return Colors.grey;
    } else if (produit.stockQuantity > 10) {
      return Colors.green;
    } else if (produit.stockQuantity > 0) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  static String getAffichageTempsPreparation(ProduitModel produit) {
    if (produit.preparationTime == 0) {
      return 'Prêt immédiatement';
    } else if (produit.preparationTime == 1) {
      return '1 minute';
    } else {
      return '${produit.preparationTime} minutes';
    }
  }

  static bool estProduitValide(ProduitModel produit) {
    return produit.name.isNotEmpty &&
        produit.categoryId.isNotEmpty &&
        produit.preparationTime >= 0 &&
        (!produit.isStockable || produit.stockQuantity >= 0);
  }

  static String getStatutProduit(ProduitModel produit) {
    if (!produit.isStockable) {
      return 'Disponible';
    } else if (produit.stockQuantity > 0) {
      return 'En stock';
    } else {
      return 'Rupture';
    }
  }
}
