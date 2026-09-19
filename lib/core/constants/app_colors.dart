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
