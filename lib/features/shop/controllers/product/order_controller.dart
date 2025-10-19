import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

import '../../../../common/widgets/success_screen/success_screen.dart';
import '../../../../data/repositories/authentication/authentication_repository.dart';
import '../../../../data/repositories/order/order_repository.dart';
import '../../../../navigation_menu.dart';
import '../../../../utils/constants/enums.dart' hide OrderStatus;
import '../../../../utils/constants/image_strings.dart';
import '../../../../utils/popups/full_screen_loader.dart';
import '../../../../utils/popups/loaders.dart';
import '../../../personalization/controllers/address_controller.dart';
import '../../models/order_model.dart';
import 'cart_controller.dart';
import 'checkout_controller.dart';

class OrderController extends GetxController {
  static OrderController get instance => Get.find();

  final cartController = CartController.instance;
  final addressController = AddressController.instance;
  final checkoutController = CheckoutController.instance;
  final orderRepository = Get.put(OrderRepository());

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
    DateTime? pickupDateTime,
    String? pickupDay,
    String? pickupTimeRange,
  }) async {
    try {
      TFullScreenLoader.openLoadingDialog(
          'En cours d\'enrgistrer votre commande...', TImages.pencilAnimation);

      final userId = AuthenticationRepository.instance.authUser!.id;
      if (userId.isEmpty) {
        TFullScreenLoader.stopLoading(); // Close loader before returning
        return;
      }

      final order = OrderModel(
        id: '', // Let database generate UUID
        userId: userId,
        status: OrderStatus.pending,
        totalAmount: totalAmount,
        orderDate: DateTime.now(),
        paymentMethod: checkoutController.selectedPaymentMethod.value.name,
        address: addressController.selectedAddress.value,
        deliveryDate: null, // Should be null initially
        items: cartController.cartItems.toList(),
        pickupDateTime: pickupDateTime,
        pickupDay: pickupDay,
        pickupTimeRange: pickupTimeRange,
        createdAt: DateTime.now(), // ✅ Set createdAt
        updatedAt: DateTime.now(), // ✅ Set updatedAt
      );

      await orderRepository.saveOrder(order, userId);

      cartController.clearCart();
      TFullScreenLoader.stopLoading();

      Get.offAll(() => SuccessScreen(
          image: TImages.orderCompletedAnimation,
          title: 'Produit(s) commandé(s) !',
          subTitle: 'Votre commande est en cours de traitement',
          onPressed: () => Get.offAll(() => const NavigationMenu())));
    } catch (e, st) {
      TFullScreenLoader.stopLoading();

      TLoaders.warningSnackBar(title: 'Erreur', message: e.toString());
    }
  }
}
