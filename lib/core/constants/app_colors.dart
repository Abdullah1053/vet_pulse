import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary Palette
  static const Color primary = Color(0xFF0E8388); // Clinical Teal
  static const Color primaryDark = Color(0xFF0A6367);
  static const Color primaryLight = Color(0xFF45A5A9);

  // Secondary Palette
  static const Color secondary = Color(0xFFCBE4DE); // Soft Mint
  static const Color secondaryLight = Color(0xFFE9F4F1);
  static const Color accent = Color(0xFFF4A261); // Amber Accent

  // Neutrals
  static const Color darkNeutral = Color(0xFF2E4F4F); // Deep Slate
  static const Color background = Color(0xFFF8FAFC); // Snow Off-White
  static const Color surface = Color(0xFFFFFFFF); // Card Surface
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color border = Color(0xFFE2E8F0);
  static const Color divider = Color(0xFFEEF2F6);

  // Clinical Status Indicators
  static const Color critical = Color(0xFFE63946); // Emergency / Expired / Allergy
  static const Color criticalBackground = Color(0xFFFFECEE);
  
  static const Color warning = Color(0xFFF4A261); // Pending / Low Stock / Due Soon
  static const Color warningBackground = Color(0xFFFFF6ED);

  static const Color success = Color(0xFF2A9D8F); // Stable / Completed / In-Stock
  static const Color successBackground = Color(0xFFEAF8F6);

  static const Color info = Color(0xFF3A86FF);
  static const Color infoBackground = Color(0xFFEEF4FF);
}
