import 'package:caferesto/common/widgets/appbar/appbar.dart';
import 'package:caferesto/common/widgets/brands/brand_card.dart';
import 'package:caferesto/common/widgets/products/sortable/sortable_products.dart';
import 'package:caferesto/features/shop/controllers/etablissement_controller.dart';
import 'package:caferesto/features/shop/models/etablissement_model.dart';
import 'package:caferesto/utils/constants/sizes.dart';
import 'package:caferesto/utils/helpers/cloud_helper_functions.dart';
import 'package:flutter/material.dart';

import '../../../../common/widgets/shimmer/vertical_product_shimmer.dart';

class BrandProducts extends StatelessWidget {
  const BrandProducts({super.key, required this.brand});

  final Etablissement brand;

  @override
  Widget build(BuildContext context) {
    final controller = EtablissementController.instance;
    return Scaffold(
      appBar: TAppBar(
        title: Text(brand.name),
      ),
      body: SingleChildScrollView(
          child: Padding(
        padding: EdgeInsets.all(AppSizes.defaultSpace),
        child: Column(
          children: [
            /// Details de marques
            BrandCard(
              showBorder: true,
              brand: brand,
            ),
            SizedBox(
              height: AppSizes.spaceBtwSections,
            ),
            FutureBuilder(
              future: controller.getProduitsEtablissement(
                  etablissementId: brand.id ?? ''),
              builder: (context, snapshot) {
                const loader = TVerticalProductShimmer();
                final widget = TCloudHelperFunctions.checkMultiRecordState(
                    snapshot: snapshot, loader: loader);
                if (widget != null) return widget;

                final brandProducts = snapshot.data!;
                return TSortableProducts(products: brandProducts);
              },
            )
          ],
        ),
      )),
    );
  }
}
