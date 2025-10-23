import 'package:caferesto/utils/popups/loaders.dart';
import 'package:get/get.dart';

import '../../../features/shop/models/order_model.dart';
import '../authentication/authentication_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OrderRepository extends GetxController {
  static OrderRepository get instance => Get.find();

  final _db = Supabase.instance.client;

  /// Fetch all orders belonging to the current user
  Future<List<OrderModel>> fetchUserOrders() async {
    try {
      final user = AuthenticationRepository.instance.authUser;
      if (user == null || user.id.isEmpty) {
        throw 'Unable to find user information, try again later';
      }

      final response = await _db
          .from('orders')
          .select('*')
          .eq('user_id', user.id)
          .order('order_date', ascending: false);

      return (response as List)
          .map((json) => OrderModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error fetching orders: $e');
      throw 'Something went wrong while fetching order information, try again later';
    }
  }

  /// Save a new order for a specific user
  Future<void> saveOrder(OrderModel order, String userId) async {
    try {
      final data = order.toJson()..['user_id'] = userId;

      await _db.from('orders').insert(data).select();
    } on PostgrestException catch (e) {
      print('❌ Postgres error: ${e.message}');
      rethrow;
    } catch (e) {
      TLoaders.errorSnackBar(title: 'Erreur', message: e.toString());
    }
  }
}
