import 'package:caferesto/features/personalization/controllers/user_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../common/widgets/success_screen/success_screen.dart';
import '../../../../data/repositories/authentication/authentication_repository.dart';
import '../../../../data/repositories/order/order_repository.dart';
import '../../../../navigation_menu.dart';
import '../../../../utils/constants/image_strings.dart';
import '../../../../utils/popups/full_screen_loader.dart';
import '../../../../utils/popups/loaders.dart';
import '../../../personalization/controllers/address_controller.dart';
import '../../models/order_model.dart';
import 'cart_controller.dart';
import 'checkout_controller.dart';

class OrderController extends GetxController {
  static OrderController get instance => Get.find();

  final orderRepository = Get.put(OrderRepository());
  final cartController = CartController.instance;
  final userController = UserController.instance;
  final _db = Supabase.instance.client;
  final addressController = AddressController.instance;
  final checkoutController = CheckoutController.instance;

  final orders = <OrderModel>[].obs;
  final isLoading = false.obs;
  final isUpdating = false.obs;
  RealtimeChannel? _ordersChannel;

  @override
  void onInit() {
    super.onInit();
    _subscribeToOrdersRealtime();
  }

  @override
  void onClose() {
    if (_ordersChannel != null) _db.removeChannel(_ordersChannel!);
    super.onClose();
  }

  Future<List<OrderModel>> fetchGerantOrders(String etablissementId) async {
    try {
      isLoading.value = true;
      debugPrint('🔍 Chargement commandes gérant pour: $etablissementId');

      // 🚀 FIX: Use the repository method
      final gerantOrders =
          await orderRepository.fetchOrdersByEtablissement(etablissementId);

      orders.value = gerantOrders;
      debugPrint('✅ ${gerantOrders.length} commandes gérant chargées');
      return gerantOrders;
    } catch (e) {
      debugPrint('❌ Erreur fetchGerantOrders: $e');
      // 🚀 FIX: Don't show snackbar here - let the screen handle it
      rethrow; // Re-throw to let caller handle the error
    } finally {
      isLoading.value = false;
    }
  }

  // 🚀 NEW: Update order status with notification
  Future<void> updateOrderStatus({
    required String orderId,
    required OrderStatus newStatus,
    String? refusalReason,
  }) async {
    try {
      isUpdating.value = true;

      final orderIndex = orders.indexWhere((o) => o.id == orderId);
      if (orderIndex == -1) throw 'Commande non trouvée';

      final order = orders[orderIndex];

      // Prepare update data
      final updates = {
        'status': newStatus.name,
        'updated_at': DateTime.now().toIso8601String(),
      };
      if (refusalReason != null) {
        updates['refusal_reason'] = refusalReason;
      }

      await orderRepository.updateOrder(orderId, updates);

      // Send notification to client
      await _sendStatusNotification(order, newStatus, refusalReason);

      TLoaders.successSnackBar(
        title: "Succès",
        message: "Statut mis à jour",
      );
    } catch (e) {
      TLoaders.errorSnackBar(
        title: "Erreur",
        message: "Impossible de mettre à jour: $e",
      );
    } finally {
      isUpdating.value = false;
    }
  }

  // 🚀 NEW: Send notification for status changes
  Future<void> _sendStatusNotification(
    OrderModel order,
    OrderStatus newStatus,
    String? refusalReason,
  ) async {
    try {
      String title = "";
      String message = "";

      switch (newStatus) {
        case OrderStatus.preparing:
          title = "Commande en préparation";
          message =
              "Votre commande #${order.id.substring(0, 8)} est en cours de préparation.";
          break;
        case OrderStatus.ready:
          title = "Commande prête";
          message =
              "Votre commande #${order.id.substring(0, 8)} est prête pour retrait.";
          break;
        case OrderStatus.delivered:
          title = "Commande livrée";
          message = "Votre commande #${order.id.substring(0, 8)} a été livrée.";
          break;
        case OrderStatus.refused:
          title = "Commande refusée";
          message =
              "Votre commande #${order.id.substring(0, 8)} a été refusée. Raison: $refusalReason";
          break;
        default:
          return;
      }

      await _db.from('notifications').insert({
        'user_id': order.userId,
        'title': title,
        'message': message,
        'read': false,
        'etablissement_id': order.etablissementId,
        'receiver_role': 'client',
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('❌ Erreur notification: $e');
    }
  }

  // 🚀 NEW: Real-time subscription
  void _subscribeToOrdersRealtime() {
    try {
      _ordersChannel = _db.channel('public:orders');

      _ordersChannel!.onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'orders',
        callback: (payload) {
          try {
            if (payload.newRecord == null) return;

            final updatedOrder = OrderModel.fromJson(payload.newRecord);
            final index = orders.indexWhere((o) => o.id == updatedOrder.id);

            if (index != -1) {
              orders[index] = updatedOrder;
              orders.refresh();
            } else {
              // Check if this new order belongs to current gérant
              final currentEtabId = userController.currentEtablissementId;
              if (currentEtabId != null &&
                  updatedOrder.etablissementId == currentEtabId) {
                orders.insert(0, updatedOrder);
                orders.refresh();
              }
            }
          } catch (e) {
            debugPrint('❌ Erreur temps réel: $e');
          }
        },
      );

      _ordersChannel!.subscribe(
        (status, [_]) {
          if (status == RealtimeSubscribeStatus.subscribed) {
            debugPrint('✅ Abonnement temps réel activé pour les commandes');
          }
        },
      );
    } catch (e) {
      debugPrint('❌ Erreur abonnement temps réel: $e');
    }
  }

  // 🚀 NEW: Filter orders by status
  List<OrderModel> get pendingOrders =>
      orders.where((o) => o.status == OrderStatus.pending).toList();
  List<OrderModel> get activeOrders => orders
      .where((o) =>
          o.status == OrderStatus.preparing || o.status == OrderStatus.ready)
      .toList();
  List<OrderModel> get completedOrders => orders
      .where((o) =>
          o.status == OrderStatus.delivered ||
          o.status == OrderStatus.cancelled ||
          o.status == OrderStatus.refused)
      .toList();

  final RxnString selectedDay = RxnString();
  final RxnString selectedSlot = RxnString();

  void setSelectedSlot(String day, String slot) {
    selectedDay.value = day;
    selectedSlot.value = slot;
  }

  void clearSelectedSlot() {
    selectedDay.value = null;
    selectedSlot.value = null;
  }

  String getEtsId(OrderModel order) {
    return order.etablissementId;
  }

  Future<List<OrderModel>> fetchUserOrders() async {
    try {
      final userOrders = await orderRepository.fetchUserOrders();
      return userOrders;
    } catch (e) {
      TLoaders.warningSnackBar(title: 'Erreur', message: e.toString());
      return [];
    }
  }

  Future<void> processOrder({
    required double totalAmount,
    required String etablissementId,
    DateTime? pickupDateTime,
    String? pickupDay,
    String? pickupTimeRange,
  }) async {
    try {
      TFullScreenLoader.openLoadingDialog(
          'En cours d\'enrgistrer votre commande...', TImages.pencilAnimation);

      final user = AuthenticationRepository.instance.authUser;
      if (user == null || user.id.isEmpty) {
        TFullScreenLoader.stopLoading();
        TLoaders.errorSnackBar(
          title: 'Erreur utilisateur',
          message: 'Impossible de récupérer vos informations utilisateur.',
        );
        return;
      }

      // Ensure we have a selected address
      final selectedAddress = addressController.selectedAddress.value;
      if (selectedAddress.id.isEmpty) {
        TFullScreenLoader.stopLoading();
        TLoaders.warningSnackBar(
          title: 'Adresse manquante',
          message: 'Veuillez sélectionner une adresse de livraison.',
        );
        return;
      }

      final order = OrderModel(
        id: '', // Let database generate UUID
        userId: user.id,
        etablissementId: etablissementId,
        status: OrderStatus.pending,
        totalAmount: totalAmount,
        orderDate: DateTime.now(),
        paymentMethod: checkoutController.selectedPaymentMethod.value.name,
        address: selectedAddress,
        deliveryDate: null, // Should be null initially
        items: cartController.cartItems.toList(),
        pickupDateTime: pickupDateTime,
        pickupDay: pickupDay,
        pickupTimeRange: pickupTimeRange,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await orderRepository.saveOrder(order, user.id);

      cartController.clearCart();
      TFullScreenLoader.stopLoading();

      Get.offAll(() => SuccessScreen(
          image: TImages.orderCompletedAnimation,
          title: 'Produit(s) commandé(s) !',
          subTitle: 'Votre commande est en cours de traitement',
          onPressed: () => Get.offAll(() => const NavigationMenu())));
    } catch (e, st) {
      TFullScreenLoader.stopLoading();
      print(st);

      TLoaders.warningSnackBar(title: 'Erreur', message: e.toString());
    }
  }
}
