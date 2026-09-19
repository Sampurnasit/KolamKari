import 'dart:math';
import 'package:flutter/material.dart';
import '../../services/analysis_service.dart';
import '../models/analysis_result.dart';

/// Authentic Kolam Pattern Definition with strokes, symmetry classification,
/// quadrant segments for puzzle reconstruction, and cultural lore.
class KolamPatternDefinition {
  final String id;
  final String name;
  final String tamilName;
  final String category; // Sikku Kolam, Pulli Kolam, Lotus Mandala, Kambi Kolam
  final String culturalLore;
  final SymmetryType symmetryType;
  final int gridSize; // 5
  final List<KolamStroke> strokes;
  // Quadrant strokes (normalized to 175x175 quadrant bounds)
  final List<KolamStroke> quadrant1; // Top-Left
  final List<KolamStroke> quadrant2; // Top-Right
  final List<KolamStroke> quadrant3; // Bottom-Left
  final List<KolamStroke> quadrant4; // Bottom-Right
  // Distractor decoys for quadrant 4
  final List<List<KolamStroke>> decoysForQuadrant4;

  const KolamPatternDefinition({
    required this.id,
    required this.name,
    required this.tamilName,
    required this.category,
    required this.culturalLore,
    required this.symmetryType,
    this.gridSize = 5,
    required this.strokes,
    required this.quadrant1,
    required this.quadrant2,
    required this.quadrant3,
    required this.quadrant4,
    required this.decoysForQuadrant4,
  });
}

class KolamPatternsLibrary {
  static const double canvasDim = 350.0;
  static const double step = canvasDim / 6; // ~58.33 px step between dots on 5x5 grid

  // Utility to create smooth stroke from points
  static KolamStroke _s(List<Offset> pts, {Color color = Colors.white, double width = 3.5}) {
    return KolamStroke(
      points: pts.map((p) => KolamPoint(p.dx, p.dy)).toList(),
      colorValue: color.toARGB32(),
      strokeWidth: width,
    );
  }

  /// Pattern 1: Nelli Sikku Kolam (Gooseberry Knot Kolam)
  /// An unbroken continuous Eulerian knot loop that wraps around 5x5 dots.
  static KolamPatternDefinition get nelliSikku {
    const cx = 3 * step; // (175, 175)
    const cy = 3 * step;

    final q1 = [
      _s([
        const Offset(cx, cy - step),
        const Offset(cx - step * 0.7, cy - step),
        const Offset(cx - step, cy - step * 0.7),
        const Offset(cx - step, cy),
      ]),
      _s([
        const Offset(cx - step, cy),
        const Offset(cx - step * 1.5, cy - step * 0.5),
        const Offset(cx - step * 2, cy - step * 1),
        const Offset(cx - step * 1, cy - step * 2),
        const Offset(cx - step * 0.5, cy - step * 1.5),
        const Offset(cx, cy - step),
      ]),
    ];

    final q2 = [
      _s([
        const Offset(cx, cy - step),
        const Offset(cx + step * 0.7, cy - step),
        const Offset(cx + step, cy - step * 0.7),
        const Offset(cx + step, cy),
      ]),
      _s([
        const Offset(cx + step, cy),
        const Offset(cx + step * 1.5, cy - step * 0.5),
        const Offset(cx + step * 2, cy - step * 1),
        const Offset(cx + step * 1, cy - step * 2),
        const Offset(cx + step * 0.5, cy - step * 1.5),
        const Offset(cx, cy - step),
      ]),
    ];

    final q3 = [
      _s([
        const Offset(cx, cy + step),
        const Offset(cx - step * 0.7, cy + step),
        const Offset(cx - step, cy + step * 0.7),
        const Offset(cx - step, cy),
      ]),
      _s([
        const Offset(cx - step, cy),
        const Offset(cx - step * 1.5, cy + step * 0.5),
        const Offset(cx - step * 2, cy + step * 1),
        const Offset(cx - step * 1, cy + step * 2),
        const Offset(cx - step * 0.5, cy + step * 1.5),
        const Offset(cx, cy + step),
      ]),
    ];

    // Correct Quadrant 4: Bottom-Right
    final q4 = [
      _s([
        const Offset(cx, cy + step),
        const Offset(cx + step * 0.7, cy + step),
        const Offset(cx + step, cy + step * 0.7),
        const Offset(cx + step, cy),
      ]),
      _s([
        const Offset(cx + step, cy),
        const Offset(cx + step * 1.5, cy + step * 0.5),
        const Offset(cx + step * 2, cy + step * 1),
        const Offset(cx + step * 1, cy + step * 2),
        const Offset(cx + step * 0.5, cy + step * 1.5),
        const Offset(cx, cy + step),
      ]),
    ];

    // Decoy 1: Inverted concave arc (breaks the smooth loop around dots)
    final decoy1 = [
      _s([
        const Offset(cx, cy + step),
        const Offset(cx + step * 0.5, cy + step * 0.5),
        const Offset(cx + step, cy),
      ]),
      _s([
        const Offset(cx + step, cy),
        const Offset(cx + step * 1.2, cy + step * 1.2),
        const Offset(cx, cy + step),
      ]),
    ];

    // Decoy 2: Wrong 90-degree clockwise rotation of quadrant 1 (mismatches connection points)
    final decoy2 = [
      _s([
        const Offset(cx, cy + step * 0.5),
        const Offset(cx + step * 1.5, cy + step * 1.8),
        const Offset(cx + step * 1.8, cy + step * 0.5),
      ]),
    ];

    // Decoy 3: Straight diagonal chord (lacks curved pulli wrap)
    final decoy3 = [
      _s([
        const Offset(cx, cy + step),
        const Offset(cx + step * 1.5, cy + step * 1.5),
        const Offset(cx + step, cy),
      ]),
    ];

    return KolamPatternDefinition(
      id: 'nelli_sikku_5',
      name: 'Nelli Sikku Kolam (Gooseberry Loop)',
      tamilName: 'நெல்லி சிக்கு கோலம்',
      category: 'Sikku (Knot Kolam)',
      culturalLore: 'A classic Margazhi dawn pattern. The unbroken continuous knot snaking around pulli dots represents infinity and spiritual continuity.',
      symmetryType: SymmetryType.dihedralD4,
      gridSize: 5,
      strokes: [...q1, ...q2, ...q3, ...q4],
      quadrant1: q1,
      quadrant2: q2,
      quadrant3: q3,
      quadrant4: q4,
      decoysForQuadrant4: [decoy1, decoy2, decoy3],
    );
  }

  /// Pattern 2: Thaamarai Pulli Kolam (4-Petal Sacred Lotus Kolam)
  /// Beautiful floral petals gracefully embracing 5x5 dots.
  static KolamPatternDefinition get thaamaraiLotus {
    const cx = 3 * step;
    const cy = 3 * step;

    // Center circular bindu
    final centerStrokes = [
      _s([
        const Offset(cx, cy - step * 0.4),
        const Offset(cx + step * 0.4, cy),
        const Offset(cx, cy + step * 0.4),
        const Offset(cx - step * 0.4, cy),
        const Offset(cx, cy - step * 0.4),
      ]),
    ];

    final q1 = [
      ...centerStrokes,
      _s([
        const Offset(cx, cy - step * 0.4),
        const Offset(cx - step * 0.8, cy - step * 1.6),
        const Offset(cx - step * 1.6, cy - step * 0.8),
        const Offset(cx - step * 0.4, cy),
      ]),
      _s([
        const Offset(cx - step * 1.6, cy - step * 0.8),
        const Offset(cx - step * 2.2, cy - step * 1.2),
        const Offset(cx - step * 1.2, cy - step * 2.2),
        const Offset(cx - step * 0.8, cy - step * 1.6),
      ]),
    ];

    final q2 = [
      _s([
        const Offset(cx, cy - step * 0.4),
        const Offset(cx + step * 0.8, cy - step * 1.6),
        const Offset(cx + step * 1.6, cy - step * 0.8),
        const Offset(cx + step * 0.4, cy),
      ]),
      _s([
        const Offset(cx + step * 1.6, cy - step * 0.8),
        const Offset(cx + step * 2.2, cy - step * 1.2),
        const Offset(cx + step * 1.2, cy - step * 2.2),
        const Offset(cx + step * 0.8, cy - step * 1.6),
      ]),
    ];

    final q3 = [
      _s([
        const Offset(cx, cy + step * 0.4),
        const Offset(cx - step * 0.8, cy + step * 1.6),
        const Offset(cx - step * 1.6, cy + step * 0.8),
        const Offset(cx - step * 0.4, cy),
      ]),
      _s([
        const Offset(cx - step * 1.6, cy + step * 0.8),
        const Offset(cx - step * 2.2, cy + step * 1.2),
        const Offset(cx - step * 1.2, cy + step * 2.2),
        const Offset(cx - step * 0.8, cy + step * 1.6),
      ]),
    ];

    final q4 = [
      _s([
        const Offset(cx, cy + step * 0.4),
        const Offset(cx + step * 0.8, cy + step * 1.6),
        const Offset(cx + step * 1.6, cy + step * 0.8),
        const Offset(cx + step * 0.4, cy),
      ]),
      _s([
        const Offset(cx + step * 1.6, cy + step * 0.8),
        const Offset(cx + step * 2.2, cy + step * 1.2),
        const Offset(cx + step * 1.2, cy + step * 2.2),
        const Offset(cx + step * 0.8, cy + step * 1.6),
      ]),
    ];

    final decoy1 = [
      _s([
        const Offset(cx, cy + step * 0.4),
        const Offset(cx + step * 1.2, cy + step * 0.8),
        const Offset(cx + step * 0.4, cy),
      ]),
    ];

    final decoy2 = [
      _s([
        const Offset(cx, cy + step * 0.4),
        const Offset(cx + step * 1.8, cy + step * 1.8),
        const Offset(cx + step * 0.4, cy),
      ]),
    ];

    final decoy3 = [
      _s([
        const Offset(cx, cy + step * 0.4),
        const Offset(cx + step * 0.5, cy + step * 2.0),
        const Offset(cx + step * 2.0, cy + step * 0.5),
        const Offset(cx + step * 0.4, cy),
      ]),
    ];

    return KolamPatternDefinition(
      id: 'thaamarai_lotus_5',
      name: 'Thaamarai Lotus Kolam',
      tamilName: 'தாமரை கோலம்',
      category: 'Pulli Flower Kolam',
      culturalLore: 'Drawn on Friday mornings to invite Goddess Mahalakshmi. The four lotus petals correspond with the four cardinal gates of temple architecture.',
      symmetryType: SymmetryType.dihedralD4,
      gridSize: 5,
      strokes: [...q1, ...q2, ...q3, ...q4],
      quadrant1: q1,
      quadrant2: q2,
      quadrant3: q3,
      quadrant4: q4,
      decoysForQuadrant4: [decoy1, decoy2, decoy3],
    );
  }

  /// Pattern 3: Ratham Kambi Kolam (Sun Chariot Diamond Kolam)
  /// Geometric stepped diamonds and outer protective arrows.
  static KolamPatternDefinition get rathamDiamond {
    const cx = 3 * step;
    const cy = 3 * step;

    final q1 = [
      _s([
        const Offset(cx, cy - step),
        const Offset(cx - step, cy),
      ]),
      _s([
        const Offset(cx, cy - step * 2),
        const Offset(cx - step * 2, cy),
      ]),
      _s([
        const Offset(cx - step, cy - step),
        const Offset(cx - step * 1.8, cy - step * 1.8),
        const Offset(cx - step * 2, cy - step),
      ]),
    ];

    final q2 = [
      _s([
        const Offset(cx, cy - step),
        const Offset(cx + step, cy),
      ]),
      _s([
        const Offset(cx, cy - step * 2),
        const Offset(cx + step * 2, cy),
      ]),
      _s([
        const Offset(cx + step, cy - step),
        const Offset(cx + step * 1.8, cy - step * 1.8),
        const Offset(cx + step * 2, cy - step),
      ]),
    ];

    final q3 = [
      _s([
        const Offset(cx, cy + step),
        const Offset(cx - step, cy),
      ]),
      _s([
        const Offset(cx, cy + step * 2),
        const Offset(cx - step * 2, cy),
      ]),
      _s([
        const Offset(cx - step, cy + step),
        const Offset(cx - step * 1.8, cy + step * 1.8),
        const Offset(cx - step * 2, cy + step),
      ]),
    ];

    final q4 = [
      _s([
        const Offset(cx, cy + step),
        const Offset(cx + step, cy),
      ]),
      _s([
        const Offset(cx, cy + step * 2),
        const Offset(cx + step * 2, cy),
      ]),
      _s([
        const Offset(cx + step, cy + step),
        const Offset(cx + step * 1.8, cy + step * 1.8),
        const Offset(cx + step * 2, cy + step),
      ]),
    ];

    final decoy1 = [
      _s([
        const Offset(cx, cy + step * 1.5),
        const Offset(cx + step * 1.5, cy),
      ]),
    ];

    final decoy2 = [
      _s([
        const Offset(cx + step, cy + step),
        const Offset(cx + step * 2.2, cy + step * 1.5),
      ]),
    ];

    final decoy3 = [
      _s([
        const Offset(cx, cy + step),
        const Offset(cx + step * 2, cy),
      ]),
    ];

    return KolamPatternDefinition(
      id: 'ratham_diamond_5',
      name: 'Ratham Kambi Kolam (Sun Chariot)',
      tamilName: 'ரதக் கம்பி கோலம்',
      category: 'Kambi (Linear Line Kolam)',
      culturalLore: 'Drawn during Makara Sankranti and Pongal to celebrate Surya moving into Uttarayana. The concentric diamond borders evoke the cosmic chariot.',
      symmetryType: SymmetryType.fourFoldReflection,
      gridSize: 5,
      strokes: [...q1, ...q2, ...q3, ...q4],
      quadrant1: q1,
      quadrant2: q2,
      quadrant3: q3,
      quadrant4: q4,
      decoysForQuadrant4: [decoy1, decoy2, decoy3],
    );
  }

  /// Pattern 4: Chakra Sudarshana Swirl Kolam (Dynamic Rotational Symmetry)
  /// Features 4-fold rotational invariance (90° pinwheel swirl without reflection).
  static KolamPatternDefinition get chakraSwirl {
    const cx = 3 * step;
    const cy = 3 * step;

    final q1 = [
      _s([
        const Offset(cx, cy - step * 0.5),
        const Offset(cx - step * 1.2, cy - step * 0.5),
        const Offset(cx - step * 1.8, cy - step * 1.8),
        const Offset(cx - step * 0.5, cy - step * 1.2),
      ]),
    ];

    final q2 = [
      _s([
        const Offset(cx + step * 0.5, cy),
        const Offset(cx + step * 0.5, cy - step * 1.2),
        const Offset(cx + step * 1.8, cy - step * 1.8),
        const Offset(cx + step * 1.2, cy - step * 0.5),
      ]),
    ];

    final q3 = [
      _s([
        const Offset(cx - step * 0.5, cy),
        const Offset(cx - step * 0.5, cy + step * 1.2),
        const Offset(cx - step * 1.8, cy + step * 1.8),
        const Offset(cx - step * 1.2, cy + step * 0.5),
      ]),
    ];

    final q4 = [
      _s([
        const Offset(cx, cy + step * 0.5),
        const Offset(cx + step * 1.2, cy + step * 0.5),
        const Offset(cx + step * 1.8, cy + step * 1.8),
        const Offset(cx + step * 0.5, cy + step * 1.2),
      ]),
    ];

    final decoy1 = [
      _s([
        const Offset(cx, cy + step * 0.5),
        const Offset(cx + step * 0.5, cy + step * 1.2),
        const Offset(cx + step * 1.8, cy + step * 0.5),
      ]),
    ];

    final decoy2 = [
      _s([
        const Offset(cx, cy + step * 0.5),
        const Offset(cx - step * 1.2, cy + step * 0.5),
        const Offset(cx - step * 1.8, cy + step * 1.8),
      ]),
    ];

    final decoy3 = [
      _s([
        const Offset(cx, cy + step),
        const Offset(cx + step, cy),
      ]),
    ];

    return KolamPatternDefinition(
      id: 'chakra_swirl_5',
      name: 'Chakra Sudarshana Swirl Kolam',
      tamilName: 'சக்கர சுழல் கோலம்',
      category: 'Chakra Rotational Kolam',
      culturalLore: 'A vortex of auspicious motion. Demonstrates 90° cyclic rotational symmetry without reflection axes, evoking the wheel of time (Kaalachakra).',
      symmetryType: SymmetryType.rotational90,
      gridSize: 5,
      strokes: [...q1, ...q2, ...q3, ...q4],
      quadrant1: q1,
      quadrant2: q2,
      quadrant3: q3,
      quadrant4: q4,
      decoysForQuadrant4: [decoy1, decoy2, decoy3],
    );
  }

  /// Pattern 5: Kodi Kolam (Sacred Twin Vine Kolam)
  /// Features 2-fold bilateral reflection across vertical axis.
  static KolamPatternDefinition get kodiVine {
    const cx = 3 * step;
    const cy = 3 * step;

    final q1 = [
      _s([
        const Offset(cx - step * 0.5, cy - step * 2),
        const Offset(cx - step * 1.5, cy - step * 1.5),
        const Offset(cx - step * 0.5, cy - step * 0.5),
        const Offset(cx - step * 1.5, cy),
      ]),
      _s([
        const Offset(cx - step * 1.5, cy - step * 1.5),
        const Offset(cx - step * 2.2, cy - step * 1.5),
      ]),
    ];

    final q2 = [
      _s([
        const Offset(cx + step * 0.5, cy - step * 2),
        const Offset(cx + step * 1.5, cy - step * 1.5),
        const Offset(cx + step * 0.5, cy - step * 0.5),
        const Offset(cx + step * 1.5, cy),
      ]),
      _s([
        const Offset(cx + step * 1.5, cy - step * 1.5),
        const Offset(cx + step * 2.2, cy - step * 1.5),
      ]),
    ];

    final q3 = [
      _s([
        const Offset(cx - step * 1.5, cy),
        const Offset(cx - step * 0.5, cy + step * 0.5),
        const Offset(cx - step * 1.5, cy + step * 1.5),
        const Offset(cx - step * 0.5, cy + step * 2),
      ]),
      _s([
        const Offset(cx - step * 1.5, cy + step * 1.5),
        const Offset(cx - step * 2.2, cy + step * 1.5),
      ]),
    ];

    final q4 = [
      _s([
        const Offset(cx + step * 1.5, cy),
        const Offset(cx + step * 0.5, cy + step * 0.5),
        const Offset(cx + step * 1.5, cy + step * 1.5),
        const Offset(cx + step * 0.5, cy + step * 2),
      ]),
      _s([
        const Offset(cx + step * 1.5, cy + step * 1.5),
        const Offset(cx + step * 2.2, cy + step * 1.5),
      ]),
    ];

    final decoy1 = [
      _s([
        const Offset(cx + step * 0.5, cy),
        const Offset(cx + step * 2.0, cy + step * 2.0),
      ]),
    ];

    final decoy2 = [
      _s([
        const Offset(cx + step * 1.5, cy),
        const Offset(cx + step * 1.5, cy + step * 2),
      ]),
    ];

    final decoy3 = [
      _s([
        const Offset(cx + step * 0.5, cy),
        const Offset(cx + step * 1.5, cy + step * 0.8),
        const Offset(cx + step * 0.5, cy + step * 1.5),
      ]),
    ];

    return KolamPatternDefinition(
      id: 'kodi_vine_5',
      name: 'Kodi Vine Auspicious Kolam',
      tamilName: 'கொடி கோலம்',
      category: 'Kodi (Creeping Vine Kolam)',
      culturalLore: 'A meandering vine motif drawn along verandah edges. Features Bilateral reflection symmetry, symbolizing fertility, healthy crops, and domestic growth.',
      symmetryType: SymmetryType.bilateralReflection,
      gridSize: 5,
      strokes: [...q1, ...q2, ...q3, ...q4],
      quadrant1: q1,
      quadrant2: q2,
      quadrant3: q3,
      quadrant4: q4,
      decoysForQuadrant4: [decoy1, decoy2, decoy3],
    );
  }

  /// All patterns list for random selection
  static List<KolamPatternDefinition> get allPatterns => [
        nelliSikku,
        thaamaraiLotus,
        rathamDiamond,
        chakraSwirl,
        kodiVine,
      ];

  /// Get random pattern
  static KolamPatternDefinition getRandomPattern([Random? rng]) {
    final rand = rng ?? Random();
    final list = allPatterns;
    return list[rand.nextInt(list.length)];
  }
}
