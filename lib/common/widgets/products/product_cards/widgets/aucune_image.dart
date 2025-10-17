
  import 'package:flutter/material.dart';

import '../../../../../utils/constants/sizes.dart';

Widget aucuneImageWidget() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(AppSizes.productImageRadius),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.fastfood, color: Colors.grey, size: 24),
          SizedBox(height: 4),
          Text(
            'Aucune image',
            style: TextStyle(color: Colors.grey, fontSize: 10),
          ),
        ],
      ),
    );
  }
