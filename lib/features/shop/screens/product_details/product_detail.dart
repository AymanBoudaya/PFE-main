import 'package:caferesto/common/widgets/texts/section_heading.dart';
import 'package:caferesto/features/shop/controllers/product/horaire_controller.dart';
import 'package:caferesto/features/shop/screens/product_details/widgets/product_meta_data.dart';
import 'package:caferesto/features/shop/screens/product_reviews/product_reviews.dart';
import 'package:caferesto/utils/constants/sizes.dart';
import 'package:caferesto/utils/helpers/helper_functions.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:readmore/readmore.dart';
import '../../../../utils/constants/colors.dart';
import '../../models/horaire_model.dart';
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
    final dark = THelperFunctions.isDarkMode(context);
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
                bottom: AppSizes.defaultSpace,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  /// - Rating & share
                  TRatingAndShare(),

                  /// - Price title stock and brand
                  TProductMetaData(product: product),

                  const SizedBox(height: AppSizes.sm),

                  /// Attributes
                  if (product.productType == 'variable')
                    TProductAttributes(product: product),

                  const SizedBox(height: AppSizes.spaceBtwSections),

                  /// Checkout button
                  _buildOrderButton(context, dark),

                  const SizedBox(height: AppSizes.spaceBtwSections),

                  /// Description
                  const TSectionHeading(
                    title: 'Description',
                    showActionButton: false,
                  ),
                  const SizedBox(height: AppSizes.spaceBtwItems),
                  ReadMoreText(
                    product.description ?? '',
                    trimLines: 2,
                    trimMode: TrimMode.Line,
                    trimCollapsedText: 'Voir plus',
                    trimExpandedText: 'Moins',
                    moreStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                    lessStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  /// Reviews
                  const Divider(),
                  const SizedBox(height: AppSizes.spaceBtwItems),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: TSectionHeading(
                          title: 'Avis (199)',
                          showActionButton: false,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Iconsax.arrow_right, size: 18),
                        onPressed: () =>
                            Get.to(() => const ProductReviewsScreen()),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.spaceBtwSections),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderButton(BuildContext context, bool dark) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => _openTimeSlotModal(context, dark),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orangeAccent,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: const Text(
          'Commander - كماندي',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Future<void> _openTimeSlotModal(BuildContext context, bool dark) async {
    final orderController = Get.put(OrderController());
    final cartController = CartController.instance;
    final horaireController = Get.put(HoraireController(HoraireRepository()));

    // Charger les horaires
    await horaireController.fetchHoraires(product.etablissementId);

    if (horaireController.horaires.isEmpty) {
      Get.snackbar(
        "Aucun horaire disponible",
        "L’établissement n’a pas encore défini ses horaires.",
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return;
    }

    // Ouvrir la modale
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: dark ? AppColors.eerieBlack : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _buildTimeSlotModalContent(
          context, dark, horaireController, orderController, cartController),
    );
  }

  Widget _buildTimeSlotModalContent(
    BuildContext context,
    bool dark,
    HoraireController horaireController,
    OrderController orderController,
    CartController cartController,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            "Choisir un créneau de retrait 🕓",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          /// Liste des créneaux
          Expanded(
            child:
                _buildTimeSlotsList(horaireController, orderController, dark),
          ),
          const SizedBox(height: 20),

          /// Bouton de confirmation
          _buildConfirmButton(
              orderController, horaireController, cartController, context),
        ],
      ),
    );
  }

  Widget _buildTimeSlotsList(
    HoraireController horaireController,
    OrderController orderController,
    bool dark,
  ) {
    return Obx(() {
      if (horaireController.isLoading.value) {
        return const Padding(
          padding: EdgeInsets.all(24.0),
          child: Center(child: CircularProgressIndicator()),
        );
      }

      final horaires = horaireController.horaires;
      if (horaires.isEmpty) {
        return const Padding(
          padding: EdgeInsets.all(24.0),
          child: Center(child: Text("Aucun créneau disponible")),
        );
      }

      return ListView.builder(
        shrinkWrap: true,
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

          return _buildDayExpansionTile(h, dayLabel, orderController, dark);
        },
      );
    });
  }

  Widget _buildDayExpansionTile(
    Horaire h,
    String dayLabel,
    OrderController orderController,
    bool dark,
  ) {
    final slots =
        THelperFunctions.generateTimeSlots(h.ouverture!, h.fermeture!);
    final now = DateTime.now();
    final todayWeekday = now.weekday;
    final targetWeekday = THelperFunctions.weekdayFromJour(h.jour);
    final daysToAdd = (targetWeekday - todayWeekday + 7) % 7;
    final isToday = daysToAdd == 0;

    return ExpansionTile(
      title: Text(
        dayLabel,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
      initiallyExpanded: orderController.selectedDay.value == dayLabel,
      children: slots
          .map((slot) => _buildTimeSlotItem(
                slot: slot,
                dayLabel: dayLabel,
                isToday: isToday,
                now: now,
                orderController: orderController,
                dark: dark,
              ))
          .toList(),
    );
  }

  Widget _buildTimeSlotItem({
    required String slot,
    required String dayLabel,
    required bool isToday,
    required DateTime now,
    required OrderController orderController,
    required bool dark,
  }) {
    final startParts = slot.split(' - ')[0].split(':').map(int.parse).toList();
    final slotStart =
        DateTime(now.year, now.month, now.day, startParts[0], startParts[1]);
    final isPast = isToday && slotStart.isBefore(now);

    return Obx(() {
      final isSelected = orderController.selectedSlot.value == slot &&
          orderController.selectedDay.value == dayLabel;

      return GestureDetector(
        onTap: isPast
            ? null
            : () {
                orderController.setSelectedSlot(dayLabel, slot);
              },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isPast
                ? Colors.grey.shade200
                : isSelected
                    ? Colors.green.withOpacity(
                        0.3) // 🔥 CORRECTION : Opacité augmentée pour meilleure visibilité
                    : Colors.transparent,
            border: Border.all(
              color: isSelected
                  ? Colors.green
                  : (dark ? Colors.grey.shade700 : Colors.grey.shade300),
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                  ]
                : null, // 🔥 AJOUT : Ombre pour mieux mettre en évidence
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                slot,
                style: TextStyle(
                  color: isPast
                      ? Colors.grey
                      : (isSelected
                          ? Colors.green.shade800
                          : (dark ? Colors.white : Colors.black)),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  fontSize: isSelected
                      ? 15
                      : 14, // 🔥 AJOUT : Taille de police légèrement augmentée
                ),
              ),
              if (isSelected)
                Icon(Icons.check_circle,
                    color: Colors.green,
                    size: 20), // 🔥 CORRECTION : Taille d'icône
            ],
          ),
        ),
      );
    });
  }

  Widget _buildConfirmButton(
    OrderController orderController,
    HoraireController horaireController,
    CartController cartController,
    BuildContext context,
  ) {
    return Obx(() {
      final hasSelection = orderController.selectedSlot.value != null &&
          orderController.selectedDay.value != null;

      return ElevatedButton.icon(
        onPressed: hasSelection
            ? () => _confirmOrder(
                orderController, horaireController, cartController, context)
            : null,
        icon: const Icon(Icons.check),
        label: const Text("Confirmer le créneau"),
        style: ElevatedButton.styleFrom(
          backgroundColor: hasSelection ? Colors.green : Colors.grey.shade400,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    });
  }

  Future<void> _confirmOrder(
    OrderController orderController,
    HoraireController horaireController,
    CartController cartController,
    BuildContext context,
  ) async {
    try {
      // Vérifier si le panier est vide
      if (cartController.cartItems.isEmpty) {
        Get.snackbar(
          "Panier vide",
          "Veuillez ajouter des produits au panier avant de confirmer la commande",
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      // Vérifier qu'un créneau est sélectionné
      if (orderController.selectedDay.value == null ||
          orderController.selectedSlot.value == null) {
        Get.snackbar(
          "Créneau manquant",
          "Veuillez sélectionner un jour et un créneau avant de confirmer",
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      // Récupérer le créneau horaire correspondant
      Horaire? selectedHoraire;
      try {
        selectedHoraire = horaireController.horaires.firstWhere(
          (h) => h.jour.valeur == orderController.selectedDay.value,
        );
      } catch (e) {
        selectedHoraire = null;
      }

      if (selectedHoraire == null) {
        Get.snackbar(
          "Erreur",
          "Impossible de trouver le créneau horaire sélectionné",
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      final now = DateTime.now();
      final targetWeekday =
          THelperFunctions.weekdayFromJour(selectedHoraire.jour);
      final daysToAdd = (targetWeekday - now.weekday + 7) % 7;
      final chosenDate = now.add(Duration(days: daysToAdd));

      final startParts = orderController.selectedSlot.value!
          .split(' - ')[0]
          .split(':')
          .map(int.parse)
          .toList();

      final pickupDateTime = DateTime(
        chosenDate.year,
        chosenDate.month,
        chosenDate.day,
        startParts[0],
        startParts[1],
      );

      // Récupérer l'etablissementId depuis le panier en toute sécurité
      final etablissementId = cartController.cartItems.first.etablissementId;
      if (etablissementId == null || etablissementId.isEmpty) {
        Get.snackbar(
          "Erreur",
          "Impossible de déterminer l'établissement pour cette commande",
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      Navigator.of(context).pop();

      await orderController.processOrder(
        totalAmount: cartController.totalCartPrice.value,
        pickupDateTime: pickupDateTime,
        pickupDay: orderController.selectedDay.value!,
        pickupTimeRange: orderController.selectedSlot.value!,
        etablissementId: etablissementId,
      );

      Get.snackbar(
        "Commande enregistrée ✅",
        "Créneau : ${orderController.selectedDay.value!} (${orderController.selectedSlot.value!})",
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        "Erreur",
        "Impossible de confirmer la commande: $e",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
}
