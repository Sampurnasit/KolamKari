/// Authentic Kolam Image Library
/// Sourced directly from the sacred collection of 10 authentic Kolams
class KolamImageDesign {
  final String id;
  final String name;
  final String tamilName;
  final String category;
  final String assetPath;
  final String culturalLore;
  final int recommendedGridSize; // 2 (2x2 = 4 quadrants) or 3 (3x3 = 9 tiles)

  const KolamImageDesign({
    required this.id,
    required this.name,
    required this.tamilName,
    required this.category,
    required this.assetPath,
    required this.culturalLore,
    this.recommendedGridSize = 2,
  });
}

class KolamImageLibrary {
  static const List<KolamImageDesign> allDesigns = [
    KolamImageDesign(
      id: 'kolam_img_1',
      name: 'Eulerian Sikku Vine Kolam',
      tamilName: 'கொடி சிக்குக் கோலம்',
      category: 'Sikku Kolam',
      assetPath: 'assets/kolam/kolam_1.jpeg',
      culturalLore: 'A classic continuous curved line winding symmetrically through the pulli dots, symbolizing natural creeping vine growth and domestic fertility.',
      recommendedGridSize: 2,
    ),
    KolamImageDesign(
      id: 'kolam_img_2',
      name: 'Square Padi Cross Kolam',
      tamilName: 'படி சதுரக் கோலம்',
      category: 'Padi Kolam',
      assetPath: 'assets/kolam/kolam_2.jpeg',
      culturalLore: 'A structured geometric array of interlocking square frames and cardinal crosses that guards entrance thresholds with architectural harmony.',
      recommendedGridSize: 2,
    ),
    KolamImageDesign(
      id: 'kolam_img_32',
      name: 'Ashtalakshmi Lotus Mandala',
      tamilName: 'அஷ்டலக்ஷ்மி தாமரை கோலம்',
      category: 'Mandala Kolam',
      assetPath: 'assets/kolam/kolam_32.jpeg',
      culturalLore: 'A radiant multi-quadrant floral mandala centered on the bindu point, honoring the eight manifestations of wealth and auspiciousness.',
      recommendedGridSize: 2,
    ),
    KolamImageDesign(
      id: 'kolam_img_33',
      name: 'Symmetrical Kambi Knot Kolam',
      tamilName: 'கம்பி முடிச்சுக் கோலம்',
      category: 'Kambi Kolam',
      assetPath: 'assets/kolam/kolam_33.jpeg',
      culturalLore: 'Interlacing straight and curved kambi ribbons forming an unbroken protective grid around cardinal dot matrices.',
      recommendedGridSize: 2,
    ),
    KolamImageDesign(
      id: 'kolam_img_34',
      name: 'Navagraha Celestial Yantra',
      tamilName: 'நவகிரக கோலம்',
      category: 'Yantra Kolam',
      assetPath: 'assets/kolam/kolam_34.jpeg',
      culturalLore: 'Harmonizes cosmic planetary vibrations with nine interconnected geometric chambers aligned to the solar cardinal axes.',
      recommendedGridSize: 3,
    ),
    KolamImageDesign(
      id: 'kolam_img_35',
      name: 'Brahma Mudi Endless Loop',
      tamilName: 'பிரம்ம முடிச்சுக் கோலம்',
      category: 'Sikku Kolam',
      assetPath: 'assets/kolam/kolam_35.jpeg',
      culturalLore: 'An Eulerian knot representing infinity (Ananta) where the single unbroken line has no discernible beginning or end.',
      recommendedGridSize: 3,
    ),
    KolamImageDesign(
      id: 'kolam_img_36',
      name: 'Mayil Peacock Feather Kolam',
      tamilName: 'மயில் தோகைக் கோலம்',
      category: 'Faunal Motif',
      assetPath: 'assets/kolam/kolam_36.jpeg',
      culturalLore: 'Radiating curves inspired by the sacred peacock of Lord Murugan, welcoming grace, vibrant spirit, and divine protection.',
      recommendedGridSize: 2,
    ),
    KolamImageDesign(
      id: 'kolam_img_37',
      name: 'Temple Sanctum Step Kolam',
      tamilName: 'கோவில் படி கோலம்',
      category: 'Padi Kolam',
      assetPath: 'assets/kolam/kolam_37.jpeg',
      culturalLore: 'Stepped tiers reminiscent of Dravidian temple sanctum courtyards and Gopuram towers leading the mind into serene meditation.',
      recommendedGridSize: 2,
    ),
    KolamImageDesign(
      id: 'kolam_img_38',
      name: 'Thaamarai Floral Harmony',
      tamilName: 'தாமரை மலர்க் கோலம்',
      category: 'Lotus Kolam',
      assetPath: 'assets/kolam/kolam_38.jpeg',
      culturalLore: 'Lotus petals expanding gracefully outwards to invite purity and peace into the dawn threshold of the household.',
      recommendedGridSize: 3,
    ),
    KolamImageDesign(
      id: 'kolam_img_main',
      name: 'Sudarshana Wheel Sacred Kolam',
      tamilName: 'சக்கர சுழல் கோலம்',
      category: 'Chakra Kolam',
      assetPath: 'assets/kolam/kolam.jpeg',
      culturalLore: 'The dynamic cosmic wheel of time and righteousness, weaving concentric loops that dissolve negative energy.',
      recommendedGridSize: 2,
    ),
  ];

  static KolamImageDesign getById(String id) {
    return allDesigns.firstWhere(
      (d) => d.id == id,
      orElse: () => allDesigns.first,
    );
  }
}
