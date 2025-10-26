import 'package:caferesto/features/shop/controllers/product/order_controller.dart';
import 'package:caferesto/utils/constants/colors.dart';
import 'package:caferesto/utils/constants/sizes.dart';
import 'package:caferesto/utils/helpers/helper_functions.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../../common/widgets/products/product_cards/widgets/rounded_container.dart';
import '../../../../../navigation_menu.dart';
import '../../../../../utils/constants/image_strings.dart';
import '../../../../../utils/helpers/cloud_helper_functions.dart';
import '../../../../../utils/loaders/animation_loader.dart';
import '../../../../../utils/popups/loaders.dart';
import '../../../models/order_model.dart';
import '../order_tracking_screen.dart';




class TOrderListItems extends StatelessWidget {
  const TOrderListItems({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    final controller = Get.put(OrderController());
    
    return FutureBuilder(
      future: controller.fetchUserOrders(),
      builder: (_, snapshot) {
        final emptyWidget = TAnimationLoaderWidget(
          text: "Aucune commande",
          animation: TImages.orderCompletedAnimation,
          showAction: true,
          actionText: 'Ajouter des commandes',
          onActionPressed: () => Get.off(() => const NavigationMenu()),
        );

        final response = TCloudHelperFunctions.checkMultiRecordState(
          snapshot: snapshot,
          nothingFound: emptyWidget,
        );
        if (response != null) return response;

        final orders = snapshot.data!;
        return ListView.separated(
          shrinkWrap: true,
          itemCount: orders.length,
          separatorBuilder: (_, __) => const SizedBox(height: AppSizes.spaceBtwItems),
          itemBuilder: (_, index) {
            final order = orders[index];
            return TRoundedContainer(
              showBorder: true,
              padding: const EdgeInsets.all(AppSizes.md),
              backgroundColor: dark ? AppColors.dark : AppColors.light,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  /// -- Row 1
                  Row(
                    children: [
                      /// Icon - Updated with status-based icons
                      _buildStatusIcon(order.status),
                      const SizedBox(width: AppSizes.spaceBtwItems / 2),

                      /// Status and Date
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              order.orderStatusText,
                              style: Theme.of(context).textTheme.bodyLarge!.apply(
                                    color: _getStatusColor(order.status),
                                    fontWeightDelta: 1,
                                  ),
                            ),
                            Text(
                              order.formattedOrderDate,
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                          ],
                        ),
                      ),

                      /// Icon Button
                      IconButton(
                        onPressed: () => Get.to(() => OrderTrackingScreen(order: order)),
                        icon: const Icon(Iconsax.arrow_right_34, size: AppSizes.iconSm),
                      ),

                      /// Track Order Button
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Iconsax.map, size: 18),
                          label: const Text("Suivre la commande"),
                          onPressed: () => Get.to(() => OrderTrackingScreen(order: order)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.spaceBtwItems),

                  /// -- Row 2
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            /// Icon
                            const Icon(Iconsax.tag),
                            const SizedBox(width: AppSizes.spaceBtwItems / 2),

                            /// Order Total
                            Expanded(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Commande',
                                    style: Theme.of(context).textTheme.labelMedium,
                                  ),
                                  Text(
                                    '${order.totalAmount.toStringAsFixed(2)} DT',
                                    style: Theme.of(context).textTheme.titleMedium,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Row(
                          children: [
                            /// Icon
                            const Icon(Iconsax.calendar),
                            const SizedBox(width: AppSizes.spaceBtwItems / 2),

                            /// Delivery Date
                            Expanded(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Date de livraison',
                                    style: Theme.of(context).textTheme.labelMedium,
                                  ),
                                  Text(
                                    order.formattedDeliveryDate.isEmpty 
                                        ? 'À venir' 
                                        : order.formattedDeliveryDate,
                                    style: Theme.of(context).textTheme.titleMedium,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  /// 🔥 Time Slot Information
                  const SizedBox(height: AppSizes.spaceBtwItems),
                  _buildTimeSlotInfo(order, context),

                  /// 🔥 Refusal Reason (if applicable)
                  if (order.status == OrderStatus.refused && order.refusalReason != null)
                    _buildRefusalInfo(order, context),

                  /// 🔥 Client Actions (Cancel & Modify) - Only for pending orders
                  if (order.canBeModified) ...[
                    const SizedBox(height: AppSizes.spaceBtwItems),
                    _buildClientActions(order, context),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  // 🎨 Status Icon
  Widget _buildStatusIcon(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return const Icon(Iconsax.clock, color: Colors.orange);
      case OrderStatus.preparing:
        return const Icon(Iconsax.cpu, color: Colors.blue);
      case OrderStatus.ready:
        return const Icon(Iconsax.box_tick, color: Colors.green);
      case OrderStatus.delivered:
        return const Icon(Iconsax.truck_tick, color: Colors.purple);
      case OrderStatus.cancelled:
        return const Icon(Iconsax.close_circle, color: Colors.red);
      case OrderStatus.refused:
        return const Icon(Iconsax.info_circle, color: Colors.red);
    }
  }

  // 🎨 Status Color
  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.preparing:
        return Colors.blue;
      case OrderStatus.ready:
        return Colors.green;
      case OrderStatus.delivered:
        return Colors.purple;
      case OrderStatus.cancelled:
        return Colors.red;
      case OrderStatus.refused:
        return Colors.red;
    }
  }

  // 🔥 Time Slot Information
  Widget _buildTimeSlotInfo(OrderModel order, BuildContext context) {
    final hasPickupInfo = order.pickupDay != null && order.pickupTimeRange != null;

    if (!hasPickupInfo) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.access_time, color: Colors.blue.shade600, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Créneau de retrait",
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Colors.blue.shade800,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  "${order.pickupDay!} • ${order.pickupTimeRange!}",
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 🔥 Refusal Information
  Widget _buildRefusalInfo(OrderModel order, BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.05),
        borderRadius: BorderRadius.circular(AppSizes.cardRadiusMd),
        border: Border.all(color: Colors.red.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Icon(Iconsax.info_circle, color: Colors.red, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Commande refusée",
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  order.refusalReason!,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 🚀 Client Actions (Cancel & Modify)
  Widget _buildClientActions(OrderModel order, BuildContext context) {
    final controller = Get.find<OrderController>();

    return Obx(() {
      final isUpdating = controller.isUpdating.value;

      return Row(
        children: [
          // Modify Button
          Expanded(
            child: OutlinedButton.icon(
              icon: isUpdating 
                  ? SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Iconsax.edit, size: 18),
              label: isUpdating ? const Text("Modification...") : const Text("Modifier"),
              onPressed: isUpdating ? null : () => _showEditDialog(context, order),
            ),
          ),
          const SizedBox(width: 8),
          
          // Cancel Button
          Expanded(
            child: ElevatedButton.icon(
              icon: isUpdating 
                  ? SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Iconsax.close_circle, size: 18),
              label: isUpdating ? const Text("Annulation...") : const Text("Annuler"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: isUpdating ? null : () => _showCancelConfirmation(context, order),
            ),
          ),
        ],
      );
    });
  }

  // 🚀 Cancel Confirmation Dialog
  void _showCancelConfirmation(BuildContext context, OrderModel order) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Annuler la commande"),
        content: const Text("Êtes-vous sûr de vouloir annuler cette commande ? Cette action est irréversible."),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text("Non"),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              _cancelOrder(order);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Oui, annuler"),
          ),
        ],
      ),
    );
  }

  // 🚀 Cancel Order
  void _cancelOrder(OrderModel order) {
    final controller = Get.find<OrderController>();
    controller.cancelOrder(order.id);
  }

  // 🚀 Edit Dialog for Order Modification
  void _showEditDialog(BuildContext context, OrderModel order) {
    final timeController = TextEditingController(text: order.pickupTimeRange ?? "");
    final dayController = TextEditingController(text: order.pickupDay ?? "");

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Modifier la commande"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: dayController,
              decoration: const InputDecoration(
                labelText: "Jour de retrait",
                hintText: "Ex: Lundi, Mardi...",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: timeController,
              decoration: const InputDecoration(
                labelText: "Plage horaire",
                hintText: "Ex: 14h-15h, 18h-19h...",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text("Annuler"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (dayController.text.trim().isEmpty || timeController.text.trim().isEmpty) {
                TLoaders.warningSnackBar(
                  title: "Champs requis",
                  message: "Veuillez remplir tous les champs.",
                );
                return;
              }

              final controller = Get.find<OrderController>();
              await controller.updateOrderDetails(
                orderId: order.id,
                pickupDay: dayController.text.trim(),
                pickupTimeRange: timeController.text.trim(),
              );
              Get.back();
            },
            child: const Text("Enregistrer"),
          ),
        ],
      ),
    );
  }
}