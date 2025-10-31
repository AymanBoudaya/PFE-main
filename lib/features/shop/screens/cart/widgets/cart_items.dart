import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../utils/constants/sizes.dart';
import '../../../controllers/product/panier_controller.dart';
import '../../../models/cart_item_model.dart';
import '../../product_details/product_detail.dart';
import '../cart_item.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../quantity_controls.dart';

class TCartItems extends StatelessWidget {
  const TCartItems({
    super.key,
    this.showDeleteButton = true,
    this.showModifyButton = true,
    this.compactQuantity = false,
  });

  final bool showDeleteButton;
  final bool showModifyButton;
  final bool compactQuantity;

  @override
  Widget build(BuildContext context) {
    final controller = CartController.instance;

    return Obx(() {
      final items = controller.cartItems;
      return ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (_, __) =>
            const SizedBox(height: AppSizes.spaceBtwItems),
        itemBuilder: (_, index) {
          final CartItemModel item = items[index];
          final isSingle =
              (item.product?.productType ?? '').toLowerCase() == 'single';

          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.defaultSpace),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Product row (image + details + price)
                  TCartItem(cartItem: item),
                  const SizedBox(height: AppSizes.spaceBtwItems),

                  // Controls row
                  Row(
                    children: [
                      // Modify variant (only for variable products)
                      if (showModifyButton && !isSingle)
                        OutlinedButton.icon(
                          onPressed: () {
                            // Navigate to product detail for editing variant
                            if (item.product != null) {
                              Get.to(() =>
                                  ProductDetailScreen(product: item.product!));
                            }
                          },
                          icon: const Icon(Icons.edit_outlined, size: 16),
                          label: const Text('Modifier'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                        ),

                      if (showModifyButton && !isSingle)
                        const SizedBox(width: AppSizes.spaceBtwItems),

                      // Quantity controls (center)
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: QuantityControls(
                            quantity: item.quantity,
                            compact: compactQuantity,
                            enabled: true,
                            onIncrement: () => controller.addOneToCart(item),
                            onDecrement: () =>
                                controller.removeOneFrom_cart_safe(item),
                            // Note: removeOneFrom_cart_safe is defined below to avoid accidental dialog cases
                          ),
                        ),
                      ),

                      const SizedBox(width: AppSizes.spaceBtwItems),

                      // Delete
                      if (showDeleteButton)
                        IconButton(
                          onPressed: () =>
                              controller.removeFromCartDialog(index),
                          icon: const Icon(Icons.delete_outline,
                              color: Colors.redAccent),
                          tooltip: 'Supprimer',
                        ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    });
  }
}

// Helper extension-like functions on controller are convenient but cannot be added here.
// To keep this file self-contained, we call a safe wrapper on PanierController via extension:
extension _PanierControllerSafe on CartController {
  /// Remove one item but avoid immediate dialog when quantity == 1.
  /// If quantity == 1 it will trigger the confirmation dialog (existing behavior).
  void removeOneFrom_cart_safe(CartItemModel item) {
    final index = cartItems.indexWhere((it) =>
        it.productId == item.productId &&
        (it.variationId ?? '') == (item.variationId ?? ''));
    if (index < 0) return;
    if (cartItems[index].quantity > 1) {
      removeOneFromCart(item);
    } else {
      removeFromCartDialog(index);
    }
  }
}
