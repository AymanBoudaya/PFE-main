import 'package:caferesto/common/widgets/texts/product_price_text.dart';
import 'package:caferesto/common/widgets/texts/section_heading.dart';
import 'package:caferesto/utils/constants/colors.dart';
import 'package:caferesto/utils/helpers/helper_functions.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../common/widgets/products/product_cards/widgets/rounded_container.dart';
import '../../../../../utils/constants/sizes.dart';
import '../../../models/produit_model.dart';

class TProductAttributes extends StatelessWidget {
  const TProductAttributes({super.key, required this.product});

  final ProduitModel product;

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    final RxString selectedSize = ''.obs; // reactive size
    final RxDouble selectedPrice = 0.0.obs;

    return Obx(() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TSectionHeading(
            title: 'Tailles disponibles',
            showActionButton: false,
          ),
          const SizedBox(height: AppSizes.spaceBtwItems),

          // --- Modern Chips ---
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: product.sizesPrices.map((sp) {
              final bool isSelected = selectedSize.value == sp.size;
              return ChoiceChip(
                label: Text(
                  '${sp.size} (${sp.price.toStringAsFixed(2)} DT)',
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : (dark ? Colors.white70 : Colors.black87),
                  ),
                ),
                selected: isSelected,
                selectedColor: AppColors.primary,
                backgroundColor:
                    dark ? AppColors.darkerGrey : AppColors.lightGrey,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onSelected: (bool selected) {
                  if (selected) {
                    selectedSize.value = sp.size;
                    selectedPrice.value = sp.price;
                  } else {
                    selectedSize.value = '';
                    selectedPrice.value = 0.0;
                  }
                },
              );
            }).toList(),
          ),

          const SizedBox(height: AppSizes.spaceBtwItems * 1.5),

          // --- Selected size / price info ---
          if (selectedSize.value.isNotEmpty)
            TRoundedContainer(
              padding: const EdgeInsets.all(AppSizes.md),
              backgroundColor: dark ? AppColors.darkerGrey : AppColors.grey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Taille sélectionnée : ${selectedSize.value}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSizes.sm),
                  Row(
                    children: [
                      const Text('Prix : ',
                          style: TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 15)),
                      ProductPriceText(price: selectedPrice.value.toString()),
                    ],
                  ),
                ],
              ),
            ),
        ],
      );
    });
  }
}
