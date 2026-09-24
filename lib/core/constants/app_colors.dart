import 'package:flutter/material.dart';

/// Cultural Heritage color palette for KolamKari.
/// Rooted in traditional Indian art materials:
/// - Rice flour (Arisi Maavu)
/// - Kumkum (Sindoor/Vermilion)
/// - Turmeric (Manjal/Haldi)
/// - Red Brick Soil (Kaavi)
/// - Sacred Basil (Tulsi)
class AppColors {
  // Heritage Core
  static const Color terracottaRed = Color(0xFF8E2824);
  static const Color crimsonRed = Color(0xFFB33927);
  static const Color kaaviBrick = Color(0xFF9E422C);
  static const Color turmericGold = Color(0xFFE59500);
  static const Color turmericAmber = Color(0xFFC77A00);
  static const Color tulsiGreen = Color(0xFF2E6F40);
  static const Color templeIndigo = Color(0xFF2A4D69);

  // Background & Surfaces (Rice Flour and Temple Slate)
  static const Color riceFlourBg = Color(0xFFFAF6EE);
  static const Color riceFlourCard = Color(0xFFFFFDF8);
  static const Color slateDark = Color(0xFF221A1D);
  static const Color slateCard = Color(0xFF2C2226);
  static const Color slateLight = Color(0xFF3B2E33);

  // Text & Accents
  static const Color textDark = Color(0xFF1E1719);
  static const Color textMuted = Color(0xFF6B5E62);
  static const Color textLight = Color(0xFFFAF6EE);
  static const Color borderLight = Color(0xFFE6DCD1);
  static const Color borderDark = Color(0xFF423439);

  // Traditional Kolam drawing pigments
  static const List<Color> drawingPigments = [
    Color(0xFFFFFDF8), // Rice Flour (Default white)
    Color(0xFFC33C29), // Sindoor Red
    Color(0xFFEAA214), // Turmeric Yellow
    Color(0xFF2E6F40), // Tulsi Green
    Color(0xFF2A52BE), // Neelam Indigo
    Color(0xFFA0522D), // Kaavi Ochre
    Color(0xFFD63384), // Gulab Pink
  ];
}

/// Canvas Palette Colors with dedicated shades optimized for Light and Dark themes.
enum KolamPaletteColor {
  basic(
    name: 'Basic',
    darkShade: Color(0xFFFFFFFF),  // Pure White for Dark Theme
    lightShade: Color(0xFF000000), // Pure Black for Light Theme
  ),
  red(
    name: 'Red',
    darkShade: Color(0xFFFF5252),  // Bright Kumkum / Vermilion Red for Dark Mode
    lightShade: Color(0xFFC62828), // Deep Sacred Crimson Red for Light Mode
  ),
  green(
    name: 'Green',
    darkShade: Color(0xFF69F0AE),  // Luminous Jade Green for Dark Mode
    lightShade: Color(0xFF1B5E20), // Sacred Deep Tulsi Green for Light Mode
  ),
  yellow(
    name: 'Yellow',
    darkShade: Color(0xFFFFEA00),  // Radiant Golden Haldi Yellow for Dark Mode
    lightShade: Color(0xFFD97706), // Rich Turmeric Amber / Ochre for Light Mode
  ),
  blue(
    name: 'Blue',
    darkShade: Color(0xFF40C4FF),  // Vibrant Neelam Sky Blue for Dark Mode
    lightShade: Color(0xFF0D47A1), // Deep Temple Royal Indigo Blue for Light Mode
  ),
  brown(
    name: 'Brown',
    darkShade: Color(0xFFFFAB91),  // Warm Terracotta / Sandalwood Ochre for Dark Mode
    lightShade: Color(0xFF5D2E17), // Deep Kaavi Brick Soil Brown for Light Mode
  );

  final String name;
  final Color darkShade;
  final Color lightShade;

  const KolamPaletteColor({
    required this.name,
    required this.darkShade,
    required this.lightShade,
  });

  /// Resolves the optimal shade for the current theme mode
  Color getShade(bool isDark) {
    switch (this) {
      case KolamPaletteColor.basic:
        return isDark ? const Color(0xFFFFFFFF) : const Color(0xFF000000);
      case KolamPaletteColor.red:
        return isDark ? const Color(0xFFFF5252) : const Color(0xFFC62828);
      case KolamPaletteColor.green:
        return isDark ? const Color(0xFF69F0AE) : const Color(0xFF1B5E20);
      case KolamPaletteColor.yellow:
        return isDark ? const Color(0xFFFFEA00) : const Color(0xFFD97706);
      case KolamPaletteColor.blue:
        return isDark ? const Color(0xFF40C4FF) : const Color(0xFF0D47A1);
      case KolamPaletteColor.brown:
        return isDark ? const Color(0xFFFFAB91) : const Color(0xFF5D2E17);
    }
  }

  /// Human-readable color name adapted for the active theme
  String getDisplayName(bool isDark) {
    if (this == KolamPaletteColor.basic) {
      return isDark ? 'White' : 'Black';
    }
    return name;
  }

  /// Resolves matching KolamPaletteColor from an existing Color or colorValue
  static KolamPaletteColor fromColor(Color color) {
    final int val = color.toARGB32();
    for (final c in KolamPaletteColor.values) {
      if (c.getShade(true).toARGB32() == val || c.getShade(false).toARGB32() == val) {
        return c;
      }
    }
    // Backward compatibility mappings
    if (val == 0xFFFFFFFF || val == 0xFFFAFAFA || val == 0xFFF5F5F5 ||
        val == 0xFF000000 || val == 0xFF121212 || val == 0xFF212121 ||
        val == 0xFF263238 || val == 0xFFE2E8F0) {
      return KolamPaletteColor.basic;
    } else if (val == 0xFFE53935 || val == 0xFFE91E63 || val == 0xFFB33927 || val == 0xFF8E2824) {
      return KolamPaletteColor.red;
    } else if (val == 0xFF2E7D32 || val == 0xFF76FF03 || val == 0xFF2E6F40) {
      return KolamPaletteColor.green;
    } else if (val == 0xFFFFD600 || val == 0xFFE59500 || val == 0xFFC77A00) {
      return KolamPaletteColor.yellow;
    } else if (val == 0xFF2196F3 || val == 0xFF2A4D69 || val == 0xFF2A52BE) {
      return KolamPaletteColor.blue;
    } else if (val == 0xFF9E422C || val == 0xFFA0522D || val == 0xFF5D2E17 || val == 0xFF3E2723) {
      return KolamPaletteColor.brown;
    }
    // Default fallback
    return KolamPaletteColor.basic;
  }
}
