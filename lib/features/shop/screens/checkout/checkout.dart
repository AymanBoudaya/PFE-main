import 'package:caferesto/features/shop/screens/cart/widgets/cart_items.dart';
import 'package:caferesto/features/shop/screens/checkout/widgets/billing_payment_section.dart';
import 'package:caferesto/utils/constants/colors.dart';
import 'package:caferesto/utils/constants/sizes.dart';
import 'package:caferesto/utils/helpers/helper_functions.dart';
import 'package:caferesto/utils/popups/loaders.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../common/widgets/appbar/appbar.dart';
import '../../../../common/widgets/products/cart/coupon_widget.dart';
import '../../../../common/widgets/products/product_cards/widgets/rounded_container.dart';
import '../../../../utils/helpers/pricing_calculator.dart';
import '../../controllers/product/cart_controller.dart';
import '../../controllers/product/order_controller.dart';
import 'widgets/billing_address_section.dart';
import 'widgets/billing_amount_section.dart';

class CheckoutScreen extends StatelessWidget {
  const CheckoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cartController = CartController.instance;
    final subTotal = cartController.totalCartPrice.value;
    final orderController = Get.put(OrderController());
    final totalAmount = TPricingCalculator.calculateTotalPrice(subTotal, 'tn');
    final dark = THelperFunctions.isDarkMode(context);

    return Scaffold(
      appBar: TAppBar(
          title: Text('Résumé de la Commande',
              style: Theme.of(context).textTheme.headlineSmall)),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.defaultSpace),
          child: Column(
            children: [
              /// Items in cart
              TCartItems(
                showAddRemoveButtons: false,
              ),
              SizedBox(
                height: AppSizes.spaceBtwSections,
              ),

              /// --Coupon TextField
              TCouponCode(dark: dark),
              const SizedBox(height: AppSizes.spaceBtwSections),

              /// --Billing section
              TRoundedContainer(
                showBorder: true,
                padding: const EdgeInsets.all(AppSizes.md),
                backgroundColor: dark ? AppColors.black : AppColors.white,
                child: Column(
                  children: [
                    /// Pricing
                    TBillingAmountSection(),
                    const SizedBox(height: AppSizes.spaceBtwItems),

                    /// Divider
                    const Divider(),
                    const SizedBox(height: AppSizes.spaceBtwItems),

                    /// Payment Methods
                    TBillingPaymentSection(),
                    const SizedBox(height: AppSizes.spaceBtwItems),

                    /// Address
                    TBillingAddressSection(),
                    const SizedBox(height: AppSizes.spaceBtwItems),

                    /// 🔥 CORRECTION : Section créneau horaire améliorée
                    _buildTimeSlotSection(orderController),
                  ],
                ),
              )
            ],
          ),
        ),
      ),

      /// Checkout button
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(AppSizes.defaultSpace),
        child: ElevatedButton(
            onPressed: subTotal > 0
                ? () => _processOrder(orderController, totalAmount, context)
                : () => TLoaders.warningSnackBar(
                    title: 'Panier vide',
                    message:
                        'Veuillez ajouter des produits au panier pour proceder au paiement'),
            child: Text('Commander $totalAmount DT')),
      ),
    );
  }

  // 🔥 NOUVELLE MÉTHODE : Section créneau horaire
  Widget _buildTimeSlotSection(OrderController orderController) {
    return Obx(() {
      final hasTimeSlot = orderController.selectedSlot.value != null &&
          orderController.selectedDay.value != null;

      if (!hasTimeSlot) {
        return _buildNoTimeSlotWidget(orderController);
      }

      return _buildSelectedTimeSlotWidget(orderController);
    });
  }

  // 🔥 WIDGET : Aucun créneau sélectionné
  Widget _buildNoTimeSlotWidget(OrderController orderController) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Créneau de retrait",
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            TextButton(
              onPressed: () => _showTimeSlotSelectionDialog(orderController),
              child: const Text(
                "Choisir un créneau",
                style: TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.orange.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.access_time, color: Colors.orange.shade600, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Aucun créneau sélectionné",
                  style: TextStyle(
                    color: Colors.orange.shade800,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 🔥 WIDGET : Créneau sélectionné
  Widget _buildSelectedTimeSlotWidget(OrderController orderController) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Créneau de retrait choisi",
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            TextButton(
              onPressed: () => _showTimeSlotSelectionDialog(orderController),
              child: const Text(
                "Modifier",
                style: TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green.shade600, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${orderController.selectedDay.value!}",
                      style: TextStyle(
                        color: Colors.green.shade800,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      "${orderController.selectedSlot.value!}",
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.access_time_filled, color: Colors.green.shade600),
            ],
          ),
        ),
      ],
    );
  }

  // 🔥 MÉTHODE : Afficher la sélection de créneau
  void _showTimeSlotSelectionDialog(OrderController orderController) {
    Get.dialog(
      AlertDialog(
        title: const Text("Choisir un créneau de retrait"),
        content: SizedBox(
          width: double.maxFinite,
          child: _buildTimeSlotSelectionContent(orderController),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text("Annuler"),
          ),
          Obx(() {
            final hasSelection = orderController.selectedSlot.value != null &&
                orderController.selectedDay.value != null;
            return TextButton(
              onPressed: hasSelection ? () => Get.back() : null,
              child: const Text("Confirmer"),
            );
          }),
        ],
      ),
    );
  }

  // 🔥 CONTENU DE LA SÉLECTION DE CRÉNEAU
  Widget _buildTimeSlotSelectionContent(OrderController orderController) {
    // Simuler des données de créneaux (à remplacer par vos vraies données)
    final timeSlots = {
      'Lundi': ['09:00 - 10:00', '14:00 - 15:00', '18:00 - 19:00'],
      'Mardi': ['09:00 - 10:00', '14:00 - 15:00', '18:00 - 19:00'],
      'Mercredi': ['09:00 - 10:00', '14:00 - 15:00', '18:00 - 19:00'],
    };

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final entry in timeSlots.entries)
            _buildDaySection(entry.key, entry.value, orderController),
        ],
      ),
    );
  }

  Widget _buildDaySection(
      String day, List<String> slots, OrderController orderController) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        title: Text(
          day,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        children: slots
            .map((slot) => _buildTimeSlotOption(day, slot, orderController))
            .toList(),
      ),
    );
  }

  Widget _buildTimeSlotOption(
      String day, String slot, OrderController orderController) {
    return Obx(() {
      final isSelected = orderController.selectedDay.value == day &&
          orderController.selectedSlot.value == slot;

      return ListTile(
        leading: isSelected
            ? const Icon(Icons.check_circle, color: Colors.green)
            : const Icon(Icons.access_time),
        title: Text(slot),
        onTap: () {
          orderController.setSelectedSlot(day, slot);
        },
        tileColor: isSelected ? Colors.green.shade50 : null,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      );
    });
  }

  // 🔥 MÉTHODE : Traitement de la commande
  void _processOrder(OrderController orderController, double totalAmount,
      BuildContext context) {
    // Vérifier qu'un créneau est sélectionné
    if (orderController.selectedSlot.value == null ||
        orderController.selectedDay.value == null) {
      TLoaders.warningSnackBar(
        title: 'Créneau manquant',
        message: 'Veuillez choisir un créneau de retrait pour votre commande',
      );
      return;
    }

    // Vérifier que le panier n'est pas vide
    if (CartController.instance.cartItems.isEmpty) {
      TLoaders.warningSnackBar(
        title: 'Panier vide',
        message: 'Veuillez ajouter des produits au panier',
      );
      return;
    }

    // Traiter la commande
    orderController.processOrder(
      totalAmount: totalAmount,
      pickupDay: orderController.selectedDay.value!,
      pickupTimeRange: orderController.selectedSlot.value!,
    );
  }
}
