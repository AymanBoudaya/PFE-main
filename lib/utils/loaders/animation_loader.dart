import 'package:caferesto/utils/device/device_utility.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../../../utils/constants/colors.dart';
import '../../../utils/constants/sizes.dart';

/// A widget for displaying an animated loading indicator with optional text and action button.
class TAnimationLoaderWidget extends StatelessWidget {
  /// Default constructor for the TAnimationLoaderWidget.
  ///
  /// Parameters:
  ///   - text: The text to be displayed below the animation.
  ///   - animation: The path to the Lottie animation file.
  ///   - showAction: Whether to show an action button below the text.
  ///   - actionText: The text to be displayed on the action button.
  ///   - onActionPressed: Callback function to be executed when the action button is pressed.
  const TAnimationLoaderWidget({
    super.key,
    required this.text,
    required this.animation,
    this.showAction = false,
    this.actionText,
    this.onActionPressed,
  });

  final String text;
  final String animation;
  final bool showAction;
  final String? actionText;
  final VoidCallback? onActionPressed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Lottie.asset(
              animation,
              width: _getAnimationSize(context), // Responsive animation size
            ),
            const SizedBox(height: AppSizes.defaultSpace),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: AppSizes.defaultSpace),
              child: Text(
                text,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: AppSizes.defaultSpace),
            showAction
                ? SizedBox(
                    width: 250,
                    child: OutlinedButton(
                      onPressed: onActionPressed,
                      style: OutlinedButton.styleFrom(
                          backgroundColor: AppColors.dark),
                      child: Text(
                        actionText!,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium!
                            .apply(color: AppColors.light),
                      ),
                    ),
                  )
                : const SizedBox(),
          ],
        ),
      ),
    );
  }

  double _getAnimationSize(BuildContext context) {
    final screenWidth = TDeviceUtils.getScreenWidth(context);
    if (screenWidth > 1200) {
      return 400.0;
    } else if (screenWidth > 600) {
      return 300.0;
    } else {
      return screenWidth * 0.8;
    }
  }
}
