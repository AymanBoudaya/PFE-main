import 'package:flutter/material.dart';
import '../../../../utils/constants/sizes.dart';

class GridLayout extends StatelessWidget {
  const GridLayout(
      {super.key,
      required this.itemCount,
      required this.itemBuilder,
      this.crossAxisCount = 2,
      this.mainAxisExtent = 278});

  final int itemCount;
  final int crossAxisCount;
  final double mainAxisExtent;
  final Widget? Function(BuildContext, int) itemBuilder;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      itemCount: itemCount,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisExtent: mainAxisExtent,
        mainAxisSpacing: AppSizes.gridViewSpacing,
        crossAxisSpacing: AppSizes.gridViewSpacing,
      ),
      itemBuilder: itemBuilder,
    );
  }
}
