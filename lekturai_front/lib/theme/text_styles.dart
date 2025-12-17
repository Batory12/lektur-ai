import 'package:flutter/material.dart';
import 'colors.dart';

class AppTextStyles {
  // Headings
  static const TextStyle heading1 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.black,
  );

  static const TextStyle heading2 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: AppColors.black,
  );

  static const TextStyle heading3 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: AppColors.black,
  );

  static const TextStyle heading4 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.black,
  );

  // Body text
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.black,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.black,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.greyMedium,
  );

  // Specific styles
  static const TextStyle cardTitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: AppColors.black,
  );

  static const TextStyle cardSubtitle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.greyMedium,
  );

  static const TextStyle contextTitle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: AppColors.black,
  );

  static const TextStyle contextDescription = TextStyle(
    fontSize: 14,
    color: AppColors.greyDark,
    height: 1.4,
  );

  static const TextStyle successTitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Color(0xFF388E3C), // Green 700
  );

  static const TextTheme appTextTheme = TextTheme(
    // Headings
    headlineLarge: AppTextStyles.heading1,
    headlineMedium: AppTextStyles.heading2,
    headlineSmall: AppTextStyles.heading3,
    titleMedium: AppTextStyles.heading4,

    bodyLarge: AppTextStyles.bodyLarge,
    bodyMedium: AppTextStyles.bodyMedium,
    bodySmall: AppTextStyles.bodySmall,

    labelLarge: AppTextStyles.cardTitle,
    labelMedium: AppTextStyles.cardSubtitle,
    labelSmall: AppTextStyles.contextTitle,
    titleSmall: AppTextStyles.contextDescription,
    displaySmall: AppTextStyles.successTitle,
  );
}
