import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

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

  final cartController = CartController.instance;
  final addressController = AddressController.instance;
  final checkoutController = CheckoutController.instance;
  final orderRepository = Get.put(OrderRepository());

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
