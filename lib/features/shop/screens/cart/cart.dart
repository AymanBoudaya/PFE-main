import 'package:caferesto/features/shop/controllers/product/panier_controller.dart';
import 'package:caferesto/features/shop/screens/checkout/checkout.dart';
import 'package:caferesto/utils/constants/sizes.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../common/widgets/appbar/appbar.dart';
import '../../../../navigation_menu.dart';
import '../../../../utils/constants/image_strings.dart';
import '../../../../utils/loaders/animation_loader.dart';
import 'widgets/cart_items.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = CartController.instance;

    return Scaffold(
      appBar: TAppBar(
        title: Text('Panier', style: Theme.of(context).textTheme.headlineSmall),
        showBackArrow: true,
      ),
      body: Obx(() {
        if (controller.cartItems.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.defaultSpace),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: TAnimationLoaderWidget(
                  text: "Votre panier est vide !",
                  animation: TImages.pencilAnimation,
                  showAction: true,
                  actionText: 'Explorer les produits',
                  onActionPressed: () => Get.off(() => const NavigationMenu()),
                ),
              ),
            ),
          );
        }

        return Column(
          children: [
            // Header with item count
            Padding(
              padding: const EdgeInsets.all(AppSizes.defaultSpace),
              child: Row(
                children: [
                  Text(
                    'Votre sélection',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const Spacer(),
                  Obx(() => Text(
                        '${controller.cartItemsCount.value} ${controller.cartItemsCount.value > 1 ? 'articles' : 'article'}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey.shade600,
                            ),
                      )),
                ],
              ),
            ),

            // Cart items list
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.defaultSpace),
                child: const TCartItems(),
              ),
            ),
          ],
        );
      }),
      // Bottom checkout section - hidden when empty
      bottomNavigationBar: Obx(() {
        if (controller.cartItems.isEmpty) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.all(AppSizes.defaultSpace),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 12,
                offset: const Offset(0, -4),
              ),
            ],
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
          ),
          child: Row(
            children: [
              // Total price
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Total',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Obx(() => Text(
                          '${controller.totalCartPrice.value.toStringAsFixed(2)} DT',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                        )),
                  ],
                ),
              ),
              const SizedBox(width: AppSizes.spaceBtwItems),
              // Checkout button
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: () => Get.to(() => const CheckoutScreen()),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: Text(
                    'Commander',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
