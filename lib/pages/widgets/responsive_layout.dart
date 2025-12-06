import 'package:flutter/material.dart';

class ResponsiveLayout {
  static bool isTablet(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return screenWidth >= 600;
  }

  static bool isLargeTablet(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return screenWidth >= 900;
  }

  static double getMaxWidth(BuildContext context) {
    if (isLargeTablet(context)) {
      return 800; // Max width for large tablets/iPads
    } else if (isTablet(context)) {
      return 600; // Max width for small tablets
    }
    return double.infinity; // Full width for phones
  }

  static EdgeInsets getHorizontalPadding(BuildContext context) {
    if (isLargeTablet(context)) {
      return const EdgeInsets.symmetric(horizontal: 64);
    } else if (isTablet(context)) {
      return const EdgeInsets.symmetric(horizontal: 32);
    }
    return const EdgeInsets.symmetric(horizontal: 16);
  }

  static double getCardWidth(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (isLargeTablet(context)) {
      return (screenWidth - 128) / 2; // Two columns with padding
    }
    return screenWidth - 32; // Single column
  }

  static int getCrossAxisCount(BuildContext context) {
    if (isLargeTablet(context)) {
      return 2; // Two columns for large tablets
    }
    return 1; // Single column for phones and small tablets
  }

  static double getSliderCardMaxWidth(BuildContext context) {
    if (isTablet(context)) {
      return 500; // Constrain slider cards on tablets
    }
    return double.infinity;
  }
}
