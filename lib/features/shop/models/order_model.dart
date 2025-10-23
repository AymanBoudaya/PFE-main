import 'package:caferesto/features/shop/models/cart_item_model.dart';
import 'package:caferesto/utils/helpers/helper_functions.dart';

import '../../personalization/models/address_model.dart';
import 'etablissement_model.dart';

enum OrderStatus { pending, shipped, delivered }

class OrderModel {
  final String id;
  final String userId;
  final OrderStatus status;
  final double totalAmount;
  final DateTime orderDate;
  final String paymentMethod;
  final AddressModel? address;
  final DateTime? deliveryDate;
  final List<CartItemModel> items;
  final DateTime? pickupDateTime;
  final String? pickupDay;
  final String? pickupTimeRange;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final Etablissement? etablissement;
  final String etablissementId;
  OrderModel(
      {required this.id,
      required this.userId,
      required this.status,
      required this.totalAmount,
      required this.orderDate,
      required this.paymentMethod,
      required this.items,
      this.address,
      this.deliveryDate,
      this.pickupDateTime,
      this.pickupDay,
      this.pickupTimeRange,
      this.createdAt,
      this.updatedAt,
      this.etablissement,
      required this.etablissementId});

  // -------------------------
  // Computed / helper getters
  // -------------------------
  String get formattedOrderDate => THelperFunctions.getFormattedDate(orderDate);

  String get formattedDeliveryDate => deliveryDate != null
      ? THelperFunctions.getFormattedDate(deliveryDate!)
      : '';

  String get orderStatusText {
    switch (status) {
      case OrderStatus.delivered:
        return 'Livrée';
      case OrderStatus.shipped:
        return 'Livraison en cours';
      default:
        return 'En cours de traitement';
    }
  }

  // -------------------------
  // Serialization
  // -------------------------

  /// Converts Dart model → JSON (for Supabase insert/update)
  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'status': status.name,
      'total_amount': totalAmount,
      'order_date': orderDate.toIso8601String(),
      'delivery_date': deliveryDate?.toIso8601String(),
      'payment_method': paymentMethod,
      'address': address?.toJson(),
      'items': items.map((item) => item.toJson()).toList(),
      'pickup_date_time': pickupDateTime?.toIso8601String(),
      'pickup_day': pickupDay,
      'pickup_time_range': pickupTimeRange,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// Converts Supabase JSON → Dart model
  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      status: _parseStatus(json['status']),
      totalAmount: (json['total_amount'] as num).toDouble(),
      orderDate: DateTime.parse(json['order_date'] as String),
      deliveryDate: json['delivery_date'] != null
          ? DateTime.parse(json['delivery_date'] as String)
          : null,
      paymentMethod: json['payment_method'] as String,
      address: json['address'] != null
          ? AddressModel.fromJson(Map<String, dynamic>.from(json['address']))
          : null,
      items: (json['items'] as List)
          .map((e) => CartItemModel.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      pickupDateTime: json['pickup_date_time'] != null
          ? DateTime.parse(json['pickup_date_time'] as String)
          : null,
      pickupDay: json['pickup_day'] as String?,
      pickupTimeRange: json['pickup_time_range'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      etablissement: json['etablissement'] != null
          ? Etablissement.fromJson(json['etablissement'])
          : null,
      etablissementId: json['etablissement_id'] ?? '',
    );
  }

  static OrderStatus _parseStatus(String? statusStr) {
    switch (statusStr) {
      case 'delivered':
        return OrderStatus.delivered;
      case 'shipped':
        return OrderStatus.shipped;
      default:
        return OrderStatus.pending;
    }
  }
}
