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
          'Processing your order', TImages.pencilAnimation);

      final userId = AuthenticationRepository.instance.authUser!.id;
      if (userId.isEmpty) return;

      final order = OrderModel(
        id: UniqueKey().toString(),
        userId: userId,
        status: OrderStatus.pending,
        totalAmount: totalAmount,
        orderDate: DateTime.now(),
        paymentMethod: checkoutController.selectedPaymentMethod.value.name,
        address: addressController.selectedAddress.value,
        deliveryDate: DateTime.now(),
        items: cartController.cartItems.toList(),
        pickupDateTime: pickupDateTime,
        pickupDay: pickupDay,
        pickupTimeRange: pickupTimeRange,
      );

      await orderRepository.saveOrder(order, userId);

      cartController.clearCart();

      Get.off(() => SuccessScreen(
          image: TImages.orderCompletedAnimation,
          title: 'Produits commandés !',
          subTitle: 'Votre commande est en cours de traitement',
          onPressed: () => Get.offAll(() => const NavigationMenu())));
    } catch (e) {
      TLoaders.warningSnackBar(title: 'Erreur', message: e.toString());
    }
  }
}
