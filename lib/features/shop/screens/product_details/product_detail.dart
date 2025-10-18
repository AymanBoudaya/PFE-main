import 'package:caferesto/common/widgets/texts/section_heading.dart';
import 'package:caferesto/features/shop/controllers/product/horaire_controller.dart';
import 'package:caferesto/features/shop/screens/product_details/widgets/product_meta_data.dart';
import 'package:caferesto/features/shop/screens/product_reviews/product_reviews.dart';
import 'package:caferesto/utils/constants/sizes.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:readmore/readmore.dart';

import '../../../../data/repositories/horaire/horaire_repository.dart';
import '../../../../utils/constants/enums.dart';
import '../../controllers/product/cart_controller.dart';
import '../../controllers/product/order_controller.dart';
import '../../models/produit_model.dart';
import '../order/pick_up_slot_picker.dart';
import 'widgets/bottom_add_to_cart_widget.dart';
import 'widgets/product_attributes.dart';
import 'widgets/product_detail_image_slider.dart';
import 'widgets/rating_share_widget.dart';

class ProductDetailScreen extends StatelessWidget {
  const ProductDetailScreen({super.key, required this.product});

  final ProduitModel product;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        bottomNavigationBar: TBottomAddToCart(product: product),
        body: SingleChildScrollView(
            child: Column(
          children: [
            /// 1 - Product Image Slider
            TProductImageSlider(product: product),

            /// 2 - Product Details
            Padding(
                padding: EdgeInsets.only(
                    right: AppSizes.defaultSpace,
                    left: AppSizes.defaultSpace,
                    bottom: AppSizes.defaultSpace),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    /// - Rating & share
                    TRatingAndShare(),

                    /// - Price title stock and brand
                    TProductMetaData(product: product),
                    const SizedBox(
                      height: AppSizes.sm,
                    ),

                    /// Attributes
                    if (product.productType == ProductType.variable.toString())
                      TProductAttributes(product: product),
                    const SizedBox(
                      height: AppSizes.spaceBtwSections,
                    ),

                    /// Checkout button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          final orderController = Get.put(OrderController());
                          final cartController = CartController.instance;
                          final horaireController =
                              Get.put(HoraireController(HoraireRepository()));

                          // Ouvrir bottom sheet pour choisir créneau
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            builder: (_) {
                              return PickUpSlotPicker(
                                onSlotSelected: (pickupDateTime, dayLabel,
                                    timeRange) async {
                                  // Ici vous pouvez valider la disponibilité réelle via HoraireController
                                  await orderController.processOrder(
                                    totalAmount:
                                        cartController.totalCartPrice.value,
                                    pickupDateTime: pickupDateTime,
                                    pickupDay: dayLabel,
                                    pickupTimeRange: timeRange,
                                  );
                                },
                              );
                            },
                          );
                        },
                        child: Text('Cmandi -  كماندي'),
                      ),
                    ),
                    const SizedBox(
                      height: AppSizes.spaceBtwSections,
                    ),

                    /// Description
                    const TSectionHeading(
                      title: 'Description',
                      showActionButton: false,
                    ),
                    const SizedBox(
                      height: AppSizes.spaceBtwItems,
                    ),
                    ReadMoreText(
                      product.description ?? '',
                      trimLines: 2,
                      trimMode: TrimMode.Line,
                      trimCollapsedText: 'Voir plus',
                      trimExpandedText: 'Moins',
                      moreStyle: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w800),
                      lessStyle: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w800),
                    ),

                    /// Reviews
                    const Divider(),
                    const SizedBox(
                      height: AppSizes.spaceBtwItems,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: const TSectionHeading(
                            title: 'Reviews(199)',
                            showActionButton: false,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Iconsax.arrow_right, size: 18),
                          onPressed: () =>
                              Get.to(() => const ProductReviewsScreen()),
                        )
                      ],
                    ),
                    const SizedBox(
                      height: AppSizes.spaceBtwSections,
                    ),
                  ],
                ))
          ],
        )));
  }
}
