import 'package:flutter/material.dart';

class AppColors {
  // Brand Agricultural Primary Palette
  static const Color primary = Color(0xFF059669); // Radiant Emerald
  static const Color primaryDark = Color(0xFF064E3B); // Deep Forest Green
  static const Color primaryLight = Color(0xFF34D399); // Soft Mint

  // Secondary Warm Onion / Ruby Tunic Accent
  static const Color onionRuby = Color(0xFFBE123C); // Rich Onion Crimson
  static const Color onionRubyLight = Color(0xFFFB7185); // Soft Rosé
  static const Color onionGold = Color(0xFFD97706); // Golden Dry Onion Skin
  static const Color onionAmber = Color(0xFFF59E0B); // Amber Glow

  // Quality Category Indicators (Strict 4-Class System: Good, Defective, Sprouted, URS)
  static const Color goodQuality = Color(0xFF10B981); // Emerald Green
  @Deprecated('Medium is removed in 4-class quality system')
  static const Color mediumQuality = Color(0xFFF59E0B); // Legacy Amber
  static const Color defectiveQuality = Color(0xFFEF4444); // Crimson Defect
  static const Color sproutedQuality = Color(0xFF84CC16); // Sprout Lime Green
  static const Color undersizedQuality = Color(0xFF8B5CF6); // Purple / URS
 
   // Dark Theme Palette
   static const Color darkBg = Color(0xFF09120F); // Deep Obsidian Slate
   static const Color darkSurface = Color(0xFF10201A); // Forest Slate Card
   static const Color darkSurfaceElevated = Color(0xFF162C24);
   static const Color darkBorder = Color(0xFF1E3D32);
   static const Color darkTextPrimary = Color(0xFFF1F5F9);
   static const Color darkTextSecondary = Color(0xFF94A3B8);
   static const Color darkTextMuted = Color(0xFF64748B);
 
   // Light Theme Palette
   static const Color lightBg = Color(0xFFF5F9F6); // Soft Sage Tint
   static const Color lightSurface = Color(0xFFFFFFFF); // Pure White Card
   static const Color lightSurfaceElevated = Color(0xFFF0F6F2);
   static const Color lightBorder = Color(0xFFE0ECE4);
   static const Color lightTextPrimary = Color(0xFF0F172A);
   static const Color lightTextSecondary = Color(0xFF475569);
   static const Color lightTextMuted = Color(0xFF94A3B8);
 
   // Helper methods
   static Color getCategoryColor(String category) {
     final cat = category.toLowerCase();
     if (cat.contains('good')) return goodQuality;
     if (cat.contains('defect')) return defectiveQuality;
     if (cat.contains('sprout')) return sproutedQuality;
     if (cat.contains('undersize') || cat.contains('urs')) return undersizedQuality;
     return primary;
   }
}
