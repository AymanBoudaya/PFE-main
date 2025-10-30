import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../utils/constants/sizes.dart';
import '../../../controllers/product/panier_controller.dart';
import '../../product_details/product_detail.dart';
import '../cart_item.dart';

class TCartItems extends StatelessWidget {
  const TCartItems({super.key});

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
          final item = items[index];
          final isSingle =
              (item.product?.productType ?? '').toLowerCase() == 'single';

          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.defaultSpace),
              child: Column(
                children: [
                  // Product info row
                  TCartItem(cartItem: item),

                  const SizedBox(height: AppSizes.spaceBtwItems),

                  // Controls row
                  Row(
                    children: [
                      // Edit variant button - only for variable products
                      if (!isSingle)
                        Expanded(
                          flex: 2,
                          child: OutlinedButton.icon(
                            onPressed: () {
                               controller.prepareVariationForEditing(item);
                              // Navigate to product page for variant editing
                              Get.to(() =>
                                  ProductDetailScreen(product: item.product!));
                            },
                            icon: const Icon(Icons.edit_outlined, size: 16),
                            label: Text(
                              'Modifier',
                              style: Theme.of(context).textTheme.labelMedium,
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      if (!isSingle)
                        const SizedBox(width: AppSizes.spaceBtwItems),

                      // Quantity controls
                      Expanded(
                        flex: 3,
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                onPressed: () =>
                                    controller.removeOneFromCart(item),
                                icon: const Icon(Icons.remove, size: 18),
                                padding: const EdgeInsets.all(8),
                                constraints: const BoxConstraints(),
                              ),
                              Text(
                                item.quantity.toString(),
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                              IconButton(
                                onPressed: () => controller.addOneToCart(item),
                                icon: const Icon(Icons.add, size: 18),
                                padding: const EdgeInsets.all(8),
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(width: AppSizes.spaceBtwItems),

                      // Delete button
                      Expanded(
                        flex: 1,
                        child: IconButton(
                          onPressed: () =>
                              controller.removeFromCartDialog(index),
                          icon: const Icon(Icons.delete_outline,
                              color: Colors.red),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.red.withOpacity(0.1),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
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
