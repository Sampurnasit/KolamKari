import 'dart:math';
import 'package:flutter/material.dart';
import '../../services/analysis_service.dart';
import '../models/analysis_result.dart';
import '../models/sample_kolam_design.dart';

class TracingMatchResult {
  final int matchPercentage; // 0 to 100
  final double coverageRatio; // 0.0 to 1.0
  final int matchedPoints;
  final int totalTargetPoints;
  final String feedback;
  final int awardedXP;

  const TracingMatchResult({
    required this.matchPercentage,
    required this.coverageRatio,
    required this.matchedPoints,
    required this.totalTargetPoints,
    required this.feedback,
    required this.awardedXP,
  });
}

class SampleDesignsLibrary {
  static const double canvasDim = 350.0;

  static KolamStroke _stroke(List<Offset> points, {Color color = Colors.white, double width = 3.5}) {
    return KolamStroke(
      points: points.map((p) => KolamPoint(p.dx, p.dy)).toList(),
      colorValue: color.toARGB32(),
      strokeWidth: width,
    );
  }

  // --- EASY PRESETS (5x5 Grid) ---

  /// 1. Kodi Vine Border (5x5)
  static SampleKolamDesign get kodiVineBorder {
    const step = canvasDim / 6;
    const cx = 3 * step;
    const cy = 3 * step;

    final strokes = [
      // Top wave
      _stroke([
        const Offset(cx - step * 2, cy - step),
        const Offset(cx - step, cy - step * 1.5),
        const Offset(cx, cy - step),
        const Offset(cx + step, cy - step * 1.5),
        const Offset(cx + step * 2, cy - step),
      ]),
      // Bottom wave
      _stroke([
        const Offset(cx - step * 2, cy + step),
        const Offset(cx - step, cy + step * 1.5),
        const Offset(cx, cy + step),
        const Offset(cx + step, cy + step * 1.5),
        const Offset(cx + step * 2, cy + step),
      ]),
      // Central binding links
      _stroke([
        const Offset(cx - step, cy - step * 1.5),
        const Offset(cx - step * 0.5, cy),
        const Offset(cx - step, cy + step * 1.5),
      ]),
      _stroke([
        const Offset(cx + step, cy - step * 1.5),
        const Offset(cx + step * 0.5, cy),
        const Offset(cx + step, cy + step * 1.5),
      ]),
    ];

    return SampleKolamDesign(
      id: 'easy_kodi_vine_5',
      name: 'Kodi Vine Border',
      tamilName: 'கொடி கோலம்',
      category: 'Kodi Vine',
      difficulty: KolamDifficulty.easy,
      gridSize: 5,
      culturalLore: 'A gentle creeping vine drawn at thresholds to invite prosperity, nourishment, and natural growth.',
      symmetryType: SymmetryType.bilateralReflection,
      strokes: strokes,
      estimatedMinutes: 2,
      baseXP: 40,
    );
  }

  /// 2. Sun Chariot Kambi (5x5)
  static SampleKolamDesign get rathamChariotDiamond {
    const step = canvasDim / 6;
    const cx = 3 * step;
    const cy = 3 * step;

    final strokes = [
      // Inner diamond
      _stroke([
        const Offset(cx, cy - step * 1.2),
        const Offset(cx + step * 1.2, cy),
        const Offset(cx, cy + step * 1.2),
        const Offset(cx - step * 1.2, cy),
        const Offset(cx, cy - step * 1.2),
      ]),
      // Outer diamond
      _stroke([
        const Offset(cx, cy - step * 2.2),
        const Offset(cx + step * 2.2, cy),
        const Offset(cx, cy + step * 2.2),
        const Offset(cx - step * 2.2, cy),
        const Offset(cx, cy - step * 2.2),
      ]),
      // Cardinal axis spokes
      _stroke([
        const Offset(cx, cy - step * 2.2),
        const Offset(cx, cy + step * 2.2),
      ]),
      _stroke([
        const Offset(cx - step * 2.2, cy),
        const Offset(cx + step * 2.2, cy),
      ]),
    ];

    return SampleKolamDesign(
      id: 'easy_ratham_kambi_5',
      name: 'Sun Chariot Kambi',
      tamilName: 'ரதக் கம்பி கோலம்',
      category: 'Kambi Kolam',
      difficulty: KolamDifficulty.easy,
      gridSize: 5,
      culturalLore: 'Geometric chariot pattern traditionally drawn on Sundays honoring Surya for vitality and clarity.',
      symmetryType: SymmetryType.fourFoldReflection,
      strokes: strokes,
      estimatedMinutes: 2,
      baseXP: 45,
    );
  }

  /// 3. Four Corner Loops (5x5)
  static SampleKolamDesign get cornerLoops {
    const step = canvasDim / 6;
    const cx = 3 * step;
    const cy = 3 * step;

    final strokes = [
      // Loop Top-Left
      _stroke([
        const Offset(cx - step, cy - step * 2),
        const Offset(cx - step * 2, cy - step * 2),
        const Offset(cx - step * 2, cy - step),
        const Offset(cx - step, cy - step),
        const Offset(cx - step, cy - step * 2),
      ]),
      // Loop Top-Right
      _stroke([
        const Offset(cx + step, cy - step * 2),
        const Offset(cx + step * 2, cy - step * 2),
        const Offset(cx + step * 2, cy - step),
        const Offset(cx + step, cy - step),
        const Offset(cx + step, cy - step * 2),
      ]),
      // Loop Bottom-Left
      _stroke([
        const Offset(cx - step, cy + step * 2),
        const Offset(cx - step * 2, cy + step * 2),
        const Offset(cx - step * 2, cy + step),
        const Offset(cx - step, cy + step),
        const Offset(cx - step, cy + step * 2),
      ]),
      // Loop Bottom-Right
      _stroke([
        const Offset(cx + step, cy + step * 2),
        const Offset(cx + step * 2, cy + step * 2),
        const Offset(cx + step * 2, cy + step),
        const Offset(cx + step, cy + step),
        const Offset(cx + step, cy + step * 2),
      ]),
      // Center connecting ring
      _stroke([
        const Offset(cx, cy - step * 0.7),
        const Offset(cx + step * 0.7, cy),
        const Offset(cx, cy + step * 0.7),
        const Offset(cx - step * 0.7, cy),
        const Offset(cx, cy - step * 0.7),
      ]),
    ];

    return SampleKolamDesign(
      id: 'easy_corner_loops_5',
      name: 'Four Corner Loops',
      tamilName: 'மூலை சுழல் கோலம்',
      category: 'Sikku Kolam',
      difficulty: KolamDifficulty.easy,
      gridSize: 5,
      culturalLore: 'Encloses the outer cardinal corners to safeguard the home against negative energies.',
      symmetryType: SymmetryType.dihedralD4,
      strokes: strokes,
      estimatedMinutes: 2,
      baseXP: 45,
    );
  }

  /// 4. Auspicious Cross Ribbon (5x5)
  static SampleKolamDesign get crossRibbonKolam {
    const step = canvasDim / 6;
    const cx = 3 * step;
    const cy = 3 * step;

    final strokes = [
      // Vertical ribbon
      _stroke([
        const Offset(cx - step * 0.4, cy - step * 2),
        const Offset(cx + step * 0.4, cy - step * 2),
        const Offset(cx + step * 0.4, cy + step * 2),
        const Offset(cx - step * 0.4, cy + step * 2),
        const Offset(cx - step * 0.4, cy - step * 2),
      ]),
      // Horizontal ribbon
      _stroke([
        const Offset(cx - step * 2, cy - step * 0.4),
        const Offset(cx + step * 2, cy - step * 0.4),
        const Offset(cx + step * 2, cy + step * 0.4),
        const Offset(cx - step * 2, cy + step * 0.4),
        const Offset(cx - step * 2, cy - step * 0.4),
      ]),
    ];

    return SampleKolamDesign(
      id: 'easy_cross_knot_5',
      name: 'Auspicious Cross Ribbon',
      tamilName: 'சிலுவை முடிச்சுக் கோலம்',
      category: 'Kambi Kolam',
      difficulty: KolamDifficulty.easy,
      gridSize: 5,
      culturalLore: 'A simple balanced intersecting ribbon celebrating harmony across all four directions.',
      symmetryType: SymmetryType.dihedralD4,
      strokes: strokes,
      estimatedMinutes: 2,
      baseXP: 40,
    );
  }

  // --- MEDIUM PRESETS (5x5 & 7x7 Grid) ---

  /// 5. Nelli Sikku Eulerian Knot (5x5)
  static SampleKolamDesign get nelliSikkuLoop {
    const step = canvasDim / 6;
    const cx = 3 * step;
    const cy = 3 * step;

    final strokes = [
      _stroke([
        const Offset(cx, cy - step),
        const Offset(cx - step * 0.7, cy - step),
        const Offset(cx - step, cy - step * 0.7),
        const Offset(cx - step, cy),
        const Offset(cx - step * 1.5, cy - step * 0.5),
        const Offset(cx - step * 2, cy - step * 1),
        const Offset(cx - step * 1, cy - step * 2),
        const Offset(cx - step * 0.5, cy - step * 1.5),
        const Offset(cx, cy - step),
      ]),
      _stroke([
        const Offset(cx, cy - step),
        const Offset(cx + step * 0.7, cy - step),
        const Offset(cx + step, cy - step * 0.7),
        const Offset(cx + step, cy),
        const Offset(cx + step * 1.5, cy - step * 0.5),
        const Offset(cx + step * 2, cy - step * 1),
        const Offset(cx + step * 1, cy - step * 2),
        const Offset(cx + step * 0.5, cy - step * 1.5),
        const Offset(cx, cy - step),
      ]),
      _stroke([
        const Offset(cx, cy + step),
        const Offset(cx - step * 0.7, cy + step),
        const Offset(cx - step, cy + step * 0.7),
        const Offset(cx - step, cy),
        const Offset(cx - step * 1.5, cy + step * 0.5),
        const Offset(cx - step * 2, cy + step * 1),
        const Offset(cx - step * 1, cy + step * 2),
        const Offset(cx - step * 0.5, cy + step * 1.5),
        const Offset(cx, cy + step),
      ]),
      _stroke([
        const Offset(cx, cy + step),
        const Offset(cx + step * 0.7, cy + step),
        const Offset(cx + step, cy + step * 0.7),
        const Offset(cx + step, cy),
        const Offset(cx + step * 1.5, cy + step * 0.5),
        const Offset(cx + step * 2, cy + step * 1),
        const Offset(cx + step * 1, cy + step * 2),
        const Offset(cx + step * 0.5, cy + step * 1.5),
        const Offset(cx, cy + step),
      ]),
    ];

    return SampleKolamDesign(
      id: 'med_nelli_sikku_5',
      name: 'Nelli Sikku Eulerian Knot',
      tamilName: 'நெல்லி சிக்குக் கோலம்',
      category: 'Sikku Kolam',
      difficulty: KolamDifficulty.medium,
      gridSize: 5,
      culturalLore: 'A revered Tamil knot pattern representing infinite continuity, wisdom, and cosmic entanglement without beginning or end.',
      symmetryType: SymmetryType.dihedralD4,
      strokes: strokes,
      estimatedMinutes: 3,
      baseXP: 60,
    );
  }

  /// 6. Thaamarai Lotus 4-Petal (5x5)
  static SampleKolamDesign get thaamaraiLotusFloral {
    const step = canvasDim / 6;
    const cx = 3 * step;
    const cy = 3 * step;

    final strokes = [
      // Top petal
      _stroke([
        const Offset(cx, cy),
        const Offset(cx - step * 0.8, cy - step * 1.2),
        const Offset(cx, cy - step * 2.2),
        const Offset(cx + step * 0.8, cy - step * 1.2),
        const Offset(cx, cy),
      ]),
      // Bottom petal
      _stroke([
        const Offset(cx, cy),
        const Offset(cx - step * 0.8, cy + step * 1.2),
        const Offset(cx, cy + step * 2.2),
        const Offset(cx + step * 0.8, cy + step * 1.2),
        const Offset(cx, cy),
      ]),
      // Left petal
      _stroke([
        const Offset(cx, cy),
        const Offset(cx - step * 1.2, cy - step * 0.8),
        const Offset(cx - step * 2.2, cy),
        const Offset(cx - step * 1.2, cy + step * 0.8),
        const Offset(cx, cy),
      ]),
      // Right petal
      _stroke([
        const Offset(cx, cy),
        const Offset(cx + step * 1.2, cy - step * 0.8),
        const Offset(cx + step * 2.2, cy),
        const Offset(cx + step * 1.2, cy + step * 0.8),
        const Offset(cx, cy),
      ]),
    ];

    return SampleKolamDesign(
      id: 'med_thaamarai_lotus_5',
      name: 'Thaamarai Lotus 4-Petal',
      tamilName: 'தாமரை இதழ் கோலம்',
      category: 'Lotus Mandala',
      difficulty: KolamDifficulty.medium,
      gridSize: 5,
      culturalLore: 'Lotus petals symbolizing spiritual purity emerging unsullied from worldly challenges.',
      symmetryType: SymmetryType.fourFoldReflection,
      strokes: strokes,
      estimatedMinutes: 3,
      baseXP: 65,
    );
  }

  /// 7. Chakra Swirl Sudarshana (5x5)
  static SampleKolamDesign get chakraSwirlPinwheel {
    const step = canvasDim / 6;
    const cx = 3 * step;
    const cy = 3 * step;

    final strokes = [
      _stroke([
        const Offset(cx, cy),
        const Offset(cx, cy - step * 1.8),
        const Offset(cx + step * 1.8, cy - step * 1.8),
      ]),
      _stroke([
        const Offset(cx, cy),
        const Offset(cx + step * 1.8, cy),
        const Offset(cx + step * 1.8, cy + step * 1.8),
      ]),
      _stroke([
        const Offset(cx, cy),
        const Offset(cx, cy + step * 1.8),
        const Offset(cx - step * 1.8, cy + step * 1.8),
      ]),
      _stroke([
        const Offset(cx, cy),
        const Offset(cx - step * 1.8, cy),
        const Offset(cx - step * 1.8, cy - step * 1.8),
      ]),
    ];

    return SampleKolamDesign(
      id: 'med_chakra_swirl_5',
      name: 'Chakra Swirl Sudarshana',
      tamilName: 'சக்கர சுழல் கோலம்',
      category: 'Chakra Swirl',
      difficulty: KolamDifficulty.medium,
      gridSize: 5,
      culturalLore: 'Dynamic rotational pinwheel expressing cosmic time (Kaalachakra) and dynamic equilibrium.',
      symmetryType: SymmetryType.rotational90,
      strokes: strokes,
      estimatedMinutes: 3,
      baseXP: 60,
    );
  }

  /// 8. Mayil Peacock Feather Sikku (7x7)
  static SampleKolamDesign get mayilPeacockFeather {
    const step = canvasDim / 8; // 7x7 grid
    const cx = 4 * step;
    const cy = 4 * step;

    final strokes = [
      // Central diamond core
      _stroke([
        const Offset(cx, cy - step * 1.5),
        const Offset(cx + step * 1.5, cy),
        const Offset(cx, cy + step * 1.5),
        const Offset(cx - step * 1.5, cy),
        const Offset(cx, cy - step * 1.5),
      ]),
      // 4 Arching feather loops
      _stroke([
        const Offset(cx, cy - step * 1.5),
        const Offset(cx - step * 2, cy - step * 3),
        const Offset(cx, cy - step * 3.2),
        const Offset(cx + step * 2, cy - step * 3),
        const Offset(cx, cy - step * 1.5),
      ]),
      _stroke([
        const Offset(cx + step * 1.5, cy),
        const Offset(cx + step * 3, cy - step * 2),
        const Offset(cx + step * 3.2, cy),
        const Offset(cx + step * 3, cy + step * 2),
        const Offset(cx + step * 1.5, cy),
      ]),
      _stroke([
        const Offset(cx, cy + step * 1.5),
        const Offset(cx + step * 2, cy + step * 3),
        const Offset(cx, cy + step * 3.2),
        const Offset(cx - step * 2, cy + step * 3),
        const Offset(cx, cy + step * 1.5),
      ]),
      _stroke([
        const Offset(cx - step * 1.5, cy),
        const Offset(cx - step * 3, cy + step * 2),
        const Offset(cx - step * 3.2, cy),
        const Offset(cx - step * 3, cy - step * 2),
        const Offset(cx - step * 1.5, cy),
      ]),
    ];

    return SampleKolamDesign(
      id: 'med_mayil_peacock_7',
      name: 'Mayil Peacock Feather Sikku',
      tamilName: 'மயில் தோகை கோலம்',
      category: 'Sikku Kolam',
      difficulty: KolamDifficulty.medium,
      gridSize: 7,
      culturalLore: 'A celebration of the peacock, Murugan’s mount, with crest-like loops signifying grace and royalty.',
      symmetryType: SymmetryType.fourFoldReflection,
      strokes: strokes,
      estimatedMinutes: 4,
      baseXP: 75,
    );
  }

  // --- HARD PRESETS (7x7 & 9x9 Grid) ---

  /// 9. Brahma Mudi Cosmic Knot (7x7)
  static SampleKolamDesign get brahmaMudiCosmicKnot {
    const step = canvasDim / 8; // 7x7 grid
    const cx = 4 * step;
    const cy = 4 * step;

    final strokes = [
      // Outer interlaced weave ring
      _stroke([
        const Offset(cx - step * 3, cy - step * 1.5),
        const Offset(cx - step * 1.5, cy - step * 3),
        const Offset(cx + step * 1.5, cy - step * 3),
        const Offset(cx + step * 3, cy - step * 1.5),
        const Offset(cx + step * 3, cy + step * 1.5),
        const Offset(cx + step * 1.5, cy + step * 3),
        const Offset(cx - step * 1.5, cy + step * 3),
        const Offset(cx - step * 3, cy + step * 1.5),
        const Offset(cx - step * 3, cy - step * 1.5),
      ]),
      // Inner Sikku Loop 1
      _stroke([
        const Offset(cx - step * 2, cy),
        const Offset(cx, cy - step * 2),
        const Offset(cx + step * 2, cy),
        const Offset(cx, cy + step * 2),
        const Offset(cx - step * 2, cy),
      ]),
      // Cardinal crossing chiasms
      _stroke([
        const Offset(cx - step * 2.5, cy - step * 2.5),
        const Offset(cx + step * 2.5, cy + step * 2.5),
      ]),
      _stroke([
        const Offset(cx - step * 2.5, cy + step * 2.5),
        const Offset(cx + step * 2.5, cy - step * 2.5),
      ]),
    ];

    return SampleKolamDesign(
      id: 'hard_brahma_mudi_7',
      name: 'Brahma Mudi Cosmic Knot',
      tamilName: 'பிரம்மா முடிச்சுக் கோலம்',
      category: 'Sikku Kolam',
      difficulty: KolamDifficulty.hard,
      gridSize: 7,
      culturalLore: 'The legendary "Brahma’s Knot" — an intricate topological challenge embodying cosmic creation and universal order.',
      symmetryType: SymmetryType.dihedralD4,
      strokes: strokes,
      estimatedMinutes: 5,
      baseXP: 90,
    );
  }

  /// 10. Navagraha 9-Planet Sikku (7x7)
  static SampleKolamDesign get navagrahaPlanets {
    const step = canvasDim / 8; // 7x7 grid
    const cx = 4 * step;
    const cy = 4 * step;

    final strokes = <KolamStroke>[];

    // 9 circular planet rings positioned across the 7x7 pulli matrix
    final centers = [
      const Offset(cx, cy), // Surya (Center)
      Offset(cx, cy - step * 2), // Chandra (North)
      Offset(cx, cy + step * 2), // Angaaraka (South)
      Offset(cx - step * 2, cy), // Budha (West)
      Offset(cx + step * 2, cy), // Brihaspati (East)
      Offset(cx - step * 2, cy - step * 2), // Shukra (North-West)
      Offset(cx + step * 2, cy - step * 2), // Shani (North-East)
      Offset(cx - step * 2, cy + step * 2), // Rahu (South-West)
      Offset(cx + step * 2, cy + step * 2), // Ketu (South-East)
    ];

    for (final c in centers) {
      strokes.add(_stroke([
        Offset(c.dx, c.dy - step * 0.7),
        Offset(c.dx + step * 0.7, c.dy),
        Offset(c.dx, c.dy + step * 0.7),
        Offset(c.dx - step * 0.7, c.dy),
        Offset(c.dx, c.dy - step * 0.7),
      ]));
    }

    // Interlaced bounding diamond connecting all nine
    strokes.add(_stroke([
      Offset(cx, cy - step * 3.2),
      Offset(cx + step * 3.2, cy),
      Offset(cx, cy + step * 3.2),
      Offset(cx - step * 3.2, cy),
      Offset(cx, cy - step * 3.2),
    ]));

    return SampleKolamDesign(
      id: 'hard_navagraha_sikku_7',
      name: 'Navagraha 9-Planet Sikku',
      tamilName: 'நவகிரக சிக்குக் கோலம்',
      category: 'Pulli Kolam',
      difficulty: KolamDifficulty.hard,
      gridSize: 7,
      culturalLore: 'A complex arrangement commemorating the 9 celestial planetary deities to harmonize cosmic vibrations in the home.',
      symmetryType: SymmetryType.fourFoldReflection,
      strokes: strokes,
      estimatedMinutes: 6,
      baseXP: 95,
    );
  }

  /// 11. Ashtalakshmi 8-Petal Star (9x9)
  static SampleKolamDesign get ashtalakshmiStar {
    const step = canvasDim / 10; // 9x9 grid
    const cx = 5 * step;
    const cy = 5 * step;

    final strokes = <KolamStroke>[];

    // 8 star points around the perimeter
    for (int i = 0; i < 8; i++) {
      final rad1 = (i * 45) * pi / 180.0;
      final rad2 = ((i + 1) * 45) * pi / 180.0;
      final midRad = ((i * 45) + 22.5) * pi / 180.0;

      final p1 = Offset(cx + cos(rad1) * step * 2.2, cy + sin(rad1) * step * 2.2);
      final tip = Offset(cx + cos(midRad) * step * 4.2, cy + sin(midRad) * step * 4.2);
      final p2 = Offset(cx + cos(rad2) * step * 2.2, cy + sin(rad2) * step * 2.2);

      strokes.add(_stroke([p1, tip, p2]));
    }

    // Inner octagon ring
    final innerPoints = <Offset>[];
    for (int i = 0; i <= 8; i++) {
      final rad = (i * 45) * pi / 180.0;
      innerPoints.add(Offset(cx + cos(rad) * step * 2.0, cy + sin(rad) * step * 2.0));
    }
    strokes.add(_stroke(innerPoints));

    // Center lotus seed
    strokes.add(_stroke([
      Offset(cx, cy - step * 0.9),
      Offset(cx + step * 0.9, cy),
      Offset(cx, cy + step * 0.9),
      Offset(cx - step * 0.9, cy),
      Offset(cx, cy - step * 0.9),
    ]));

    return SampleKolamDesign(
      id: 'hard_ashtalakshmi_star_9',
      name: 'Ashtalakshmi 8-Petal Star',
      tamilName: 'அஷ்டலக்ஷ்மி நட்சத்திர கோலம்',
      category: 'Lotus Mandala',
      difficulty: KolamDifficulty.hard,
      gridSize: 9,
      culturalLore: 'Eight radiating petals dedicated to the eight forms of Goddess Lakshmi bringing wealth, courage, and wisdom.',
      symmetryType: SymmetryType.fourFoldReflection,
      strokes: strokes,
      estimatedMinutes: 6,
      baseXP: 100,
    );
  }

  /// 12. Mahamandala Sacred Temple Padi (9x9)
  static SampleKolamDesign get mahamandalaPadi {
    const step = canvasDim / 10; // 9x9 grid
    const cx = 5 * step;
    const cy = 5 * step;

    final strokes = [
      // Innermost square
      _stroke([
        Offset(cx - step * 1.5, cy - step * 1.5),
        Offset(cx + step * 1.5, cy - step * 1.5),
        Offset(cx + step * 1.5, cy + step * 1.5),
        Offset(cx - step * 1.5, cy + step * 1.5),
        Offset(cx - step * 1.5, cy - step * 1.5),
      ]),
      // Middle stepped stepped padi
      _stroke([
        Offset(cx, cy - step * 2.8),
        Offset(cx + step * 2.8, cy),
        Offset(cx, cy + step * 2.8),
        Offset(cx - step * 2.8, cy),
        Offset(cx, cy - step * 2.8),
      ]),
      // Outer temple ramparts
      _stroke([
        Offset(cx - step * 4.0, cy - step * 4.0),
        Offset(cx + step * 4.0, cy - step * 4.0),
        Offset(cx + step * 4.0, cy + step * 4.0),
        Offset(cx - step * 4.0, cy + step * 4.0),
        Offset(cx - step * 4.0, cy - step * 4.0),
      ]),
      // 4 Cardinal Gopuram stepped towers
      _stroke([
        Offset(cx - step * 1.2, cy - step * 4.0),
        Offset(cx, cy - step * 4.8),
        Offset(cx + step * 1.2, cy - step * 4.0),
      ]),
      _stroke([
        Offset(cx - step * 1.2, cy + step * 4.0),
        Offset(cx, cy + step * 4.8),
        Offset(cx + step * 1.2, cy + step * 4.0),
      ]),
      _stroke([
        Offset(cx - step * 4.0, cy - step * 1.2),
        Offset(cx - step * 4.8, cy),
        Offset(cx - step * 4.0, cy + step * 1.2),
      ]),
      _stroke([
        Offset(cx + step * 4.0, cy - step * 1.2),
        Offset(cx + step * 4.8, cy),
        Offset(cx + step * 4.0, cy + step * 1.2),
      ]),
    ];

    return SampleKolamDesign(
      id: 'hard_mahamandala_padi_9',
      name: 'Mahamandala Temple Padi',
      tamilName: 'மகா மண்டலப் படி கோலம்',
      category: 'Padi Kolam',
      difficulty: KolamDifficulty.hard,
      gridSize: 9,
      culturalLore: 'A grand architectural Padi Kolam reflecting South Indian temple sanctum stepped courtyards and Gopuram towers.',
      symmetryType: SymmetryType.fourFoldReflection,
      strokes: strokes,
      estimatedMinutes: 7,
      baseXP: 110,
    );
  }

  /// All 12 presets catalog
  static List<SampleKolamDesign> get allSamples => [
        kodiVineBorder,
        rathamChariotDiamond,
        cornerLoops,
        crossRibbonKolam,
        nelliSikkuLoop,
        thaamaraiLotusFloral,
        chakraSwirlPinwheel,
        mayilPeacockFeather,
        brahmaMudiCosmicKnot,
        navagrahaPlanets,
        ashtalakshmiStar,
        mahamandalaPadi,
      ];

  static SampleKolamDesign getById(String id) {
    return allSamples.firstWhere(
      (s) => s.id == id,
      orElse: () => allSamples.first,
    );
  }

  // --- TRACING MATCH EVALUATION ENGINE ---

  /// Compares user drawn strokes/shapes with the reference sample design
  static TracingMatchResult evaluateTracingMatch({
    required List<KolamStroke> userStrokes,
    required List<KolamStroke> targetStrokes,
    double snapTolerance = 24.0,
  }) {
    if (userStrokes.isEmpty || targetStrokes.isEmpty) {
      return const TracingMatchResult(
        matchPercentage: 0,
        coverageRatio: 0.0,
        matchedPoints: 0,
        totalTargetPoints: 0,
        feedback: 'No lines drawn yet. Trace over the faint ghost lines to practice!',
        awardedXP: 0,
      );
    }

    // 1. Resample target strokes into discrete verification points (approx every 12px)
    final targetSamplePoints = <Offset>[];
    for (final stroke in targetStrokes) {
      if (stroke.points.length < 2) {
        if (stroke.points.isNotEmpty) {
          targetSamplePoints.add(Offset(stroke.points.first.x, stroke.points.first.y));
        }
        continue;
      }
      for (int i = 0; i < stroke.points.length - 1; i++) {
        final p1 = Offset(stroke.points[i].x, stroke.points[i].y);
        final p2 = Offset(stroke.points[i + 1].x, stroke.points[i + 1].y);
        final dist = (p2 - p1).distance;
        final steps = max(1, (dist / 12.0).ceil());
        for (int s = 0; s < steps; s++) {
          final t = s / steps;
          targetSamplePoints.add(Offset.lerp(p1, p2, t)!);
        }
      }
      targetSamplePoints.add(Offset(stroke.points.last.x, stroke.points.last.y));
    }

    if (targetSamplePoints.isEmpty) {
      return const TracingMatchResult(
        matchPercentage: 0,
        coverageRatio: 0.0,
        matchedPoints: 0,
        totalTargetPoints: 0,
        feedback: 'Empty target reference.',
        awardedXP: 0,
      );
    }

    // 2. Resample user strokes into discrete points
    final userSamplePoints = <Offset>[];
    for (final stroke in userStrokes) {
      if (stroke.points.length < 2) {
        if (stroke.points.isNotEmpty) {
          userSamplePoints.add(Offset(stroke.points.first.x, stroke.points.first.y));
        }
        continue;
      }
      for (int i = 0; i < stroke.points.length - 1; i++) {
        final p1 = Offset(stroke.points[i].x, stroke.points[i].y);
        final p2 = Offset(stroke.points[i + 1].x, stroke.points[i + 1].y);
        final dist = (p2 - p1).distance;
        final steps = max(1, (dist / 12.0).ceil());
        for (int s = 0; s < steps; s++) {
          final t = s / steps;
          userSamplePoints.add(Offset.lerp(p1, p2, t)!);
        }
      }
      userSamplePoints.add(Offset(stroke.points.last.x, stroke.points.last.y));
    }

    // 3. For each target point, find if any user point is within snapTolerance
    int matchedCount = 0;
    for (final tp in targetSamplePoints) {
      bool matched = false;
      for (final up in userSamplePoints) {
        if ((up - tp).distance <= snapTolerance) {
          matched = true;
          break;
        }
      }
      if (matched) matchedCount++;
    }

    final rawCoverage = matchedCount / targetSamplePoints.length;

    // 4. Precision check: Penalize if user has many stray points far from any target path
    int strayCount = 0;
    for (final up in userSamplePoints) {
      bool nearTarget = false;
      for (final tp in targetSamplePoints) {
        if ((up - tp).distance <= (snapTolerance * 1.5)) {
          nearTarget = true;
          break;
        }
      }
      if (!nearTarget) strayCount++;
    }

    final strayRatio = userSamplePoints.isNotEmpty ? strayCount / userSamplePoints.length : 0.0;
    final precisionFactor = (1.0 - (strayRatio * 0.4)).clamp(0.4, 1.0);

    final finalScore = ((rawCoverage * precisionFactor) * 100).round().clamp(0, 100);

    String feedback;
    int xp = 0;

    if (finalScore >= 85) {
      feedback = 'Sacred Precision! (அற்புதம்) You traced this Kolam with masterful fidelity!';
      xp = 45;
    } else if (finalScore >= 65) {
      feedback = 'Splendid Effort! (நன்று) Most loops and lines align closely with the tradition.';
      xp = 30;
    } else if (finalScore >= 40) {
      feedback = 'Good Start! (தொடரவும்) Try following the curves around the pulli dots more closely.';
      xp = 15;
    } else {
      feedback = 'Keep Practicing! Adjust reference opacity to follow the ghost lines gently.';
      xp = 5;
    }

    return TracingMatchResult(
      matchPercentage: finalScore,
      coverageRatio: rawCoverage,
      matchedPoints: matchedCount,
      totalTargetPoints: targetSamplePoints.length,
      feedback: feedback,
      awardedXP: xp,
    );
  }
}
