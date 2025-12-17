import 'package:flutter/material.dart';

class AppSpacing {
  // Common spacing values
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  static const double xxxl = 32.0;
  
  // Specific spacing for different contexts
  static const double cardPadding = lg;
  static const double screenPadding = lg;
  static const double sectionSpacing = xxl;
  static const double elementSpacing = md;
  static const double buttonHeight = 48.0;
  
  // Edge insets
  static const EdgeInsets screenPaddingAll = EdgeInsets.all(screenPadding);
  static const EdgeInsets screenPaddingHorizontal = EdgeInsets.symmetric(horizontal: screenPadding);
  static const EdgeInsets cardPaddingAll = EdgeInsets.all(cardPadding);
  static const EdgeInsets safeAreaPadding = EdgeInsets.fromLTRB(lg, lg, lg, xxl);
}
