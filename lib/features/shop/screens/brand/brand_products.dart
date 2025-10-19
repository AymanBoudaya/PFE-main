import 'package:caferesto/common/widgets/appbar/appbar.dart';
import 'package:caferesto/common/widgets/brands/brand_card.dart';
import 'package:caferesto/common/widgets/products/sortable/sortable_products.dart';
import 'package:caferesto/features/shop/controllers/product/all_products_controller.dart';
import 'package:caferesto/features/shop/models/etablissement_model.dart';
import 'package:caferesto/utils/constants/sizes.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../common/widgets/shimmer/vertical_product_shimmer.dart';

class BrandProducts extends StatelessWidget {
  const BrandProducts({super.key, required this.brand});

  final Etablissement brand;

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AllProductsController());
    controller.fetchBrandProducts(brand.id ?? '');

    return Scaffold(
      appBar: TAppBar(title: Text(brand.name)),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const TVerticalProductShimmer();
        }

        if (controller.brandProducts.isEmpty) {
          return const Center(child: Text('Aucun produit trouvé.'));
        }

        return SingleChildScrollView(
          padding: EdgeInsets.all(AppSizes.defaultSpace),
          child: Column(
            children: [
              BrandCard(showBorder: true, brand: brand),
              SizedBox(height: AppSizes.spaceBtwSections),
              TSortableProducts(products: controller.brandProducts),
            ],
          ),
        );
      }),
    );
  }
}
