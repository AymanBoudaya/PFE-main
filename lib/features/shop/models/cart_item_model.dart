class CartItemModel {
  String productId;
  String title;
  double price;
  String? image;
  int quantity;
  String variationId;
  String? brandName;
  Map<String, String>? selectedVariation;
  String etablissementId; // ✅ ADD THIS FIELD

  CartItemModel(
      {required this.productId,
      required this.quantity,
      this.variationId = '',
      this.title = '',
      this.price = 0.0,
      this.image,
      this.brandName,
      this.selectedVariation,
      this.etablissementId = ''});

  static CartItemModel empty() {
    return CartItemModel(
      productId: '',
      quantity: 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'title': title,
      'price': price,
      'image': image,
      'quantity': quantity,
      'variationId': variationId,
      'brandName': brandName,
      'selectedVariation': selectedVariation,
      'etablissementId': etablissementId,
    };
  }

  factory CartItemModel.fromJson(Map<String, dynamic> data) {
    return CartItemModel(
      productId: data['productId'] ?? '',
      title: data['title'] ?? '',
      price: (data['price'] as num).toDouble(),
      image: data['image'],
      quantity: data['quantity'] ?? 1,
      variationId: data['variationId'] ?? '',
      brandName: data['brandName'],
      selectedVariation: data['selectedVariation'] != null
          ? Map<String, String>.from(data['selectedVariation'])
          : null,
      etablissementId: data['etablissement_id'] ?? '',
    );
  }
}
