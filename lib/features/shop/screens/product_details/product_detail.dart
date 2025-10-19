import 'package:caferesto/common/widgets/texts/section_heading.dart';
import 'package:caferesto/features/shop/controllers/product/horaire_controller.dart';
import 'package:caferesto/features/shop/screens/product_details/widgets/product_meta_data.dart';
import 'package:caferesto/features/shop/screens/product_reviews/product_reviews.dart';
import 'package:caferesto/utils/constants/sizes.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:readmore/readmore.dart';
import 'widgets/rating_share_widget.dart';

import '../../../../data/repositories/horaire/horaire_repository.dart';
import '../../controllers/product/cart_controller.dart';
import '../../controllers/product/order_controller.dart';
import '../../models/jour_semaine.dart';
import '../../models/produit_model.dart';
import 'widgets/bottom_add_to_cart_widget.dart';
import 'widgets/product_attributes.dart';
import 'widgets/product_detail_image_slider.dart';

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
                    if (product.productType == 'variable')
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

                          // ✅ Initialise HoraireController si pas encore fait
                          final horaireController =
                              Get.put(HoraireController(HoraireRepository()));

                          // ✅ Charge les horaires de l’établissement du produit
                          await horaireController
                              .fetchHoraires(product.etablissementId);

                          // ✅ Vérifie s’il y a des horaires disponibles
                          if (horaireController.horaires.isEmpty) {
                            Get.snackbar(
                              "Aucun horaire disponible",
                              "L’établissement n’a pas encore défini ses horaires.",
                              backgroundColor: Colors.redAccent,
                              colorText: Colors.white,
                            );
                            return;
                          }

                          // ✅ Ouvre la modale de sélection de créneau
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.white,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(16)),
                            ),
                            builder: (_) {
                              return Obx(() {
                                if (horaireController.isLoading.value) {
                                  return const Padding(
                                    padding: EdgeInsets.all(24.0),
                                    child: Center(
                                        child: CircularProgressIndicator()),
                                  );
                                }

                                final horaires = horaireController.horaires;
                                if (horaires.isEmpty) {
                                  return const Padding(
                                    padding: EdgeInsets.all(24.0),
                                    child: Center(
                                        child:
                                            Text("Aucun créneau disponible")),
                                  );
                                }

                                return Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text(
                                        "Choisir un créneau de retrait 🕓",
                                        style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 12),
                                      ListView.builder(
                                        shrinkWrap: true,
                                        physics:
                                            const NeverScrollableScrollPhysics(),
                                        itemCount: horaires.length,
                                        itemBuilder: (ctx, index) {
                                          final h = horaires[index];
                                          final dayLabel = h.jour.valeur;
                                          if (!h.isValid) {
                                            return ListTile(
                                              title: Text(dayLabel),
                                              subtitle: const Text("Fermé"),
                                              enabled: false,
                                            );
                                          }

                                          final timeRange =
                                              "${h.ouverture} - ${h.fermeture}";
                                          return ListTile(
                                            title: Text(dayLabel),
                                            subtitle: Text(timeRange),
                                            trailing: const Icon(
                                                Icons.arrow_forward_ios,
                                                size: 14),
                                            onTap: () async {
                                              // 🔢 Calcule la date exacte du jour sélectionné
                                              final now = DateTime.now();
                                              final targetWeekday =
                                                  _weekdayFromJour(h
                                                      .jour); // fonction helper
                                              final daysToAdd = (targetWeekday -
                                                      now.weekday +
                                                      7) %
                                                  7;
                                              final chosenDate = now.add(
                                                  Duration(days: daysToAdd));

                                              final parts =
                                                  h.ouverture!.split(':');
                                              final pickupDateTime = DateTime(
                                                chosenDate.year,
                                                chosenDate.month,
                                                chosenDate.day,
                                                int.parse(parts[0]),
                                                int.parse(parts[1]),
                                              );

                                              Navigator.of(ctx)
                                                  .pop(); // ferme la modale

                                              // ✅ Enregistre la commande
                                              await orderController
                                                  .processOrder(
                                                totalAmount: cartController
                                                    .totalCartPrice.value,
                                                pickupDateTime:
                                                    pickupDateTime, // ✅ conversion
                                                pickupDay: dayLabel,
                                                pickupTimeRange: timeRange,
                                              );

                                              Get.snackbar(
                                                "Commande enregistrée ✅",
                                                "Créneau : $dayLabel ($timeRange)",
                                                backgroundColor: Colors.green,
                                                colorText: Colors.white,
                                              );
                                            },
                                          );
                                        },
                                      ),
                                      const SizedBox(height: 20),
                                    ],
                                  ),
                                );
                              });
                            },
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orangeAccent,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text(
                          'Commander - كماندي',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
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
                            title: 'Avis (199)',
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

int _weekdayFromJour(JourSemaine jour) {
  switch (jour) {
    case JourSemaine.lundi:
      return 1;
    case JourSemaine.mardi:
      return 2;
    case JourSemaine.mercredi:
      return 3;
    case JourSemaine.jeudi:
      return 4;
    case JourSemaine.vendredi:
      return 5;
    case JourSemaine.samedi:
      return 6;
    case JourSemaine.dimanche:
      return 7;
  }
}
