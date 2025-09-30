import 'package:flutter/material.dart';

/// Consistent spacing constants and widgets used throughout the app
/// to maintain uniform padding and margins.

class AppSpacing {
  // Standard spacing values
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  static const double xxxl = 32.0;

  // Common padding values
  static const EdgeInsets cardPadding = EdgeInsets.all(lg);
  static const EdgeInsets screenPadding = EdgeInsets.all(lg);
  static const EdgeInsets sectionPadding = EdgeInsets.symmetric(vertical: md);
  static const EdgeInsets buttonPadding = EdgeInsets.symmetric(vertical: 14, horizontal: xl);

  // Spacing widgets for convenience
  static const Widget verticalSpaceXS = SizedBox(height: xs);
  static const Widget verticalSpaceSM = SizedBox(height: sm);
  static const Widget verticalSpaceMD = SizedBox(height: md);
  static const Widget verticalSpaceLG = SizedBox(height: lg);
  static const Widget verticalSpaceXL = SizedBox(height: xl);
  static const Widget verticalSpaceXXL = SizedBox(height: xxl);

  static const Widget horizontalSpaceXS = SizedBox(width: xs);
  static const Widget horizontalSpaceSM = SizedBox(width: sm);
  static const Widget horizontalSpaceMD = SizedBox(width: md);
  static const Widget horizontalSpaceLG = SizedBox(width: lg);
  static const Widget horizontalSpaceXL = SizedBox(width: xl);
  static const Widget horizontalSpaceXXL = SizedBox(width: xxl);
}

/// A flexible spacer widget that can create both vertical and horizontal space
class FlexibleSpacer extends StatelessWidget {
  final double? height;
  final double? width;
  final Axis direction;

  const FlexibleSpacer({
    super.key,
    this.height,
    this.width,
    this.direction = Axis.vertical,
  });

  const FlexibleSpacer.vertical({
    super.key,
    this.height,
  }) : width = null, direction = Axis.vertical;

  const FlexibleSpacer.horizontal({
    super.key,
    this.width,
  }) : height = null, direction = Axis.horizontal;

  @override
  Widget build(BuildContext context) {
    if (direction == Axis.vertical) {
      return SizedBox(height: height ?? AppSpacing.md);
    } else {
      return SizedBox(width: width ?? AppSpacing.md);
    }
  }
}