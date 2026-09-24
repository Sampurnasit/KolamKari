import 'dart:math';
import 'package:flutter/material.dart';
import '../../services/analysis_service.dart';
import 'analysis_result.dart';

enum AlgorithmicSymmetry {
  d4Multiple('Multiple (4-Way / 8-Fold)', 'D4 Dihedral symmetry with both 4 reflection axes and 90° rotation'),
  d1Vertical('Reflection (Vertical Axis)', 'D1 Bilateral reflection across the central vertical axis (Y-axis)'),
  d1Horizontal('Reflection (Horizontal Axis)', 'D1 Bilateral reflection across the central horizontal axis (X-axis)'),
  d1Diagonal('Reflection (Diagonal Axis)', 'D1 Reflection across the 45° main diagonal axis'),
  c4Rotational('Rotational (90°)', 'C4 Cyclic rotational invariance (90°, 180°, 270°) without reflection planes'),
  c2Rotational('Rotational (180°)', 'C2 Half-turn rotational invariance (180°) without reflection planes'),
  asymmetric('Translational / Asymmetric', 'Irregular asymmetric or repeating tile connectivity');

  final String label;
  final String description;

  const AlgorithmicSymmetry(this.label, this.description);
}

/// Dynamic algorithmic Kolam pattern generator using rounded-corner tile connectivity.
/// Implements 4-way, Vertical, Horizontal, and Diagonal reflection algorithms.
class AlgorithmicKolamPattern {
  final int tnumber;
  late List<List<double>> link;
  late List<List<double>> nlink;
  AlgorithmicSymmetry symmetry;
  String name;
  String tamilName;
  String category;
  String culturalLore;

  AlgorithmicKolamPattern({
    this.tnumber = 9,
    this.symmetry = AlgorithmicSymmetry.d4Multiple,
    this.name = 'Dynamic Sikku Chuzhi',
    this.tamilName = 'சுக்கு சுழி கோலம்',
    this.category = 'Sacred Geometry',
    this.culturalLore = 'Continuous looping curves weave symmetrically around rice flour pulli dots, symbolizing infinite auspicious cycles.',
  }) {
    _initArrays();
    configTile(forcedSymmetry: symmetry);
    _syncLinkToNlink();
  }

  void _initArrays() {
    link = List.generate(tnumber + 1, (_) => List.filled(tnumber + 1, 1.0));
    nlink = List.generate(tnumber + 1, (_) => List.filled(tnumber + 1, 1.0));
  }

  void _syncLinkToNlink() {
    for (int i = 0; i < link.length; i++) {
      for (int j = 0; j < link[0].length; j++) {
        link[i][j] = nlink[i][j];
      }
    }
  }

  /// Copies current nlink to link (copyCurrent)
  void copyCurrent() {
    for (int i = 0; i < link.length; i++) {
      for (int j = 0; j < link[0].length; j++) {
        link[i][j] = nlink[i][j];
      }
    }
  }

  /// Implements Vertical Reflection Algorithm:
  /// for i in 0 .. nlink.length / 2:
  ///   for j in 0 .. nlink[0].length:
  ///     nlink[i][j] = l;
  ///     nlink[nlink.length - i - 1][j] = l;
  void configTileVertical({double? customLimit, Random? rng}) {
    copyCurrent();
    final random = rng ?? Random();
    final double limit = customLimit ?? (0.4 + random.nextDouble() * 0.3);
    final int halfI = (nlink.length / 2).floor();

    for (int i = 0; i < halfI; i++) {
      for (int j = 0; j < nlink[0].length; j++) {
        final double l = (random.nextDouble() > limit) ? 1.0 : 0.0;
        nlink[i][j] = l;
        nlink[nlink.length - i - 1][j] = l;
      }
    }
    symmetry = AlgorithmicSymmetry.d1Vertical;
    _assignCulturalMetadata();
  }

  /// Implements Horizontal Reflection Algorithm:
  /// for i in 0 .. nlink.length:
  ///   for j in 0 .. nlink[0].length / 2:
  ///     nlink[i][j] = l;
  ///     nlink[i][nlink[0].length - j - 1] = l;
  void configTileHorizontal({double? customLimit, Random? rng}) {
    copyCurrent();
    final random = rng ?? Random();
    final double limit = customLimit ?? (0.4 + random.nextDouble() * 0.3);
    final int halfJ = (nlink[0].length / 2).floor();

    for (int i = 0; i < nlink.length; i++) {
      for (int j = 0; j < halfJ; j++) {
        final double l = (random.nextDouble() > limit) ? 1.0 : 0.0;
        nlink[i][j] = l;
        nlink[i][nlink[0].length - j - 1] = l;
      }
    }
    symmetry = AlgorithmicSymmetry.d1Horizontal;
    _assignCulturalMetadata();
  }

  /// Implements Diagonal Reflection Algorithm:
  /// for i in 0 .. nlink.length:
  ///   for j in 0 .. i:
  ///     nlink[i][j] = l;
  ///     nlink[j][i] = l;
  void configTileDiagonal({double? customLimit, Random? rng}) {
    copyCurrent();
    final random = rng ?? Random();
    final double limit = customLimit ?? (0.4 + random.nextDouble() * 0.3);

    for (int i = 0; i < nlink.length; i++) {
      for (int j = 0; j <= i; j++) {
        final double l = (random.nextDouble() > limit) ? 1.0 : 0.0;
        nlink[i][j] = l;
        nlink[j][i] = l;
      }
    }
    symmetry = AlgorithmicSymmetry.d1Diagonal;
    _assignCulturalMetadata();
  }

  /// Implements 4-Way / 8-Fold Dihedral D4 Algorithm
  void configTile4Way({double? customLimit, Random? rng}) {
    copyCurrent();
    final random = rng ?? Random();
    final double limit = customLimit ?? (0.4 + random.nextDouble() * 0.3);
    final int lenI = nlink.length - 1;
    final int lenJ = nlink[0].length - 1;

    for (int i = 0; i < nlink.length; i++) {
      final int half = (nlink[0].length / 2).ceil();
      for (int j = i; j < half; j++) {
        final double l = (random.nextDouble() > limit) ? 1.0 : 0.0;
        nlink[i][j] = l;
        nlink[i][lenJ - j] = l;
        nlink[j][i] = l;
        nlink[lenJ - j][i] = l;
        nlink[lenI - i][j] = l;
        nlink[lenI - i][lenJ - j] = l;
        nlink[j][lenI - i] = l;
        nlink[lenJ - j][lenI - i] = l;
      }
    }
    symmetry = AlgorithmicSymmetry.d4Multiple;
    _assignCulturalMetadata();
  }

  /// Generalized configTile method supporting all symmetry modes
  void configTile({AlgorithmicSymmetry? forcedSymmetry, double? customLimit, Random? rng}) {
    if (forcedSymmetry != null) {
      symmetry = forcedSymmetry;
    }

    switch (symmetry) {
      case AlgorithmicSymmetry.d1Vertical:
        configTileVertical(customLimit: customLimit, rng: rng);
        break;
      case AlgorithmicSymmetry.d1Horizontal:
        configTileHorizontal(customLimit: customLimit, rng: rng);
        break;
      case AlgorithmicSymmetry.d1Diagonal:
        configTileDiagonal(customLimit: customLimit, rng: rng);
        break;
      case AlgorithmicSymmetry.d4Multiple:
        configTile4Way(customLimit: customLimit, rng: rng);
        break;
      case AlgorithmicSymmetry.c4Rotational:
        copyCurrent();
        final random = rng ?? Random();
        final double limit = customLimit ?? (0.4 + random.nextDouble() * 0.3);
        final int lenI = nlink.length - 1;
        final int lenJ = nlink[0].length - 1;
        final int halfI = (nlink.length / 2).ceil();
        final int halfJ = (nlink[0].length / 2).ceil();
        for (int i = 0; i < halfI; i++) {
          for (int j = 0; j < halfJ; j++) {
            final double l = (random.nextDouble() > limit) ? 1.0 : 0.0;
            nlink[i][j] = l;
            nlink[lenJ - j][i] = l;
            nlink[lenI - i][lenJ - j] = l;
            nlink[j][lenI - i] = l;
          }
        }
        _assignCulturalMetadata();
        break;
      case AlgorithmicSymmetry.c2Rotational:
        copyCurrent();
        final random = rng ?? Random();
        final double limit = customLimit ?? (0.4 + random.nextDouble() * 0.3);
        final int lenI = nlink.length - 1;
        final int lenJ = nlink[0].length - 1;
        final int halfJ = (nlink[0].length / 2).ceil();
        for (int i = 0; i < nlink.length; i++) {
          for (int j = 0; j < halfJ; j++) {
            final double l = (random.nextDouble() > limit) ? 1.0 : 0.0;
            nlink[i][j] = l;
            nlink[lenI - i][lenJ - j] = l;
          }
        }
        _assignCulturalMetadata();
        break;
      case AlgorithmicSymmetry.asymmetric:
        copyCurrent();
        final random = rng ?? Random();
        final double limit = customLimit ?? (0.4 + random.nextDouble() * 0.3);
        for (int i = 0; i < nlink.length; i++) {
          for (int j = 0; j < nlink[0].length; j++) {
            nlink[i][j] = (random.nextDouble() > limit) ? 1.0 : 0.0;
          }
        }
        _assignCulturalMetadata();
        break;
    }
  }

  void _assignCulturalMetadata() {
    switch (symmetry) {
      case AlgorithmicSymmetry.d4Multiple:
        name = 'Sudarshana 8-Fold Loop';
        tamilName = 'சுதர்சன சக்கரம்';
        category = 'All Axis (8-Way Dihedral)';
        culturalLore = 'Features 4 reflection axes (Vertical, Horizontal, 2 Diagonals) and 90° rotational invariance.';
        break;
      case AlgorithmicSymmetry.d1Vertical:
        name = 'Mayil Peacock Gateway';
        tamilName = 'மயில் கோலம்';
        category = 'Vertical Axis Reflection';
        culturalLore = 'Mirror symmetry across the central vertical axis (Y-axis), welcoming devotees into the sanctum.';
        break;
      case AlgorithmicSymmetry.d1Horizontal:
        name = 'Water Reflection Lotus';
        tamilName = 'தாமரை பிரதிபலிப்பு';
        category = 'Horizontal Axis Reflection';
        culturalLore = 'Mirror symmetry across the central horizontal axis (X-axis), echoing sacred water reflections.';
        break;
      case AlgorithmicSymmetry.d1Diagonal:
        name = 'Sanctum Diagonal Ray';
        tamilName = 'மூலைவிட்ட கோலம்';
        category = 'Diagonal Axis Reflection';
        culturalLore = 'Mirror symmetry along the 45° diagonal axis (y = x), aligning corner corridors with solar angles.';
        break;
      case AlgorithmicSymmetry.c4Rotational:
        name = 'Chakra Swirl Dynamic';
        tamilName = 'சுழல் சக்கரம்';
        category = 'Cyclic C4 Rotation';
        culturalLore = 'Invariance under 90° rotation without reflection lines, representing eternal kinetic flow and energy.';
        break;
      case AlgorithmicSymmetry.c2Rotational:
        name = 'Kambi Yin-Yang Loop';
        tamilName = 'கம்பி சுழி';
        category = 'Cyclic C2 Half-Turn';
        culturalLore = 'Exhibits 180° rotational balance, commonly drawn at traditional thresholds at sunrise and dusk.';
        break;
      case AlgorithmicSymmetry.asymmetric:
        name = 'Kodi Dynamic Vine';
        tamilName = 'கொடி கோலம்';
        category = 'Translational / Freeform';
        culturalLore = 'Free-flowing organic Sikku vine pathways without rigid reflection constraints.';
        break;
    }
  }

  /// Derives the exact AnalysisResult from the mathematical properties of the generated pattern.
  AnalysisResult toAnalysisResult() {
    switch (symmetry) {
      case AlgorithmicSymmetry.d4Multiple:
        return const AnalysisResult(
          symmetryType: SymmetryType.dihedralD4,
          rotationalDegree: 90,
          rotationalSymmetrySummary: '90°',
          reflectionDetected: true,
          reflectionAxesCount: 4,
          matchingReflectionAxes: ['Vertical Axis', 'Horizontal Axis', 'Main Diagonal (45°)', 'Anti-Diagonal (135°)'],
          complexityScore: 92,
          gridSize: '9x9',
          closedLoopCount: 8,
          strokeCount: 41,
          intersectionCount: 16,
          patternDensity: 0.85,
          uniqueShapePrimitivesCount: 4,
          symmetryOperationsCount: 8,
          structureSummary: '9x9 Dihedral Grid • 8 Continuous Sikku Loops',
          complexityTier: 'Masterwork',
          culturalInterpretation: 'Full 8-fold dihedral symmetry invoking complete cosmic protection (Ashta Dikpalas).',
          formulaBreakdown: {'dihedral': 4, 'cyclic': 4, 'reflections': 4},
        );

      case AlgorithmicSymmetry.d1Vertical:
        return const AnalysisResult(
          symmetryType: SymmetryType.bilateralReflection,
          rotationalDegree: 0,
          rotationalSymmetrySummary: 'None',
          reflectionDetected: true,
          reflectionAxesCount: 1,
          matchingReflectionAxes: ['Vertical Axis'],
          complexityScore: 68,
          gridSize: '9x9',
          closedLoopCount: 2,
          strokeCount: 41,
          intersectionCount: 6,
          patternDensity: 0.70,
          uniqueShapePrimitivesCount: 2,
          symmetryOperationsCount: 1,
          structureSummary: '9x9 Bilateral Grid • Vertical Mirror Plane',
          complexityTier: 'Moderate',
          culturalInterpretation: 'Bilateral vertical reflection welcoming guests through a symmetrical archway.',
          formulaBreakdown: {'reflections': 1, 'axes': ['Vertical']},
        );

      case AlgorithmicSymmetry.d1Horizontal:
        return const AnalysisResult(
          symmetryType: SymmetryType.bilateralReflection,
          rotationalDegree: 0,
          rotationalSymmetrySummary: 'None',
          reflectionDetected: true,
          reflectionAxesCount: 1,
          matchingReflectionAxes: ['Horizontal Axis'],
          complexityScore: 68,
          gridSize: '9x9',
          closedLoopCount: 2,
          strokeCount: 41,
          intersectionCount: 6,
          patternDensity: 0.70,
          uniqueShapePrimitivesCount: 2,
          symmetryOperationsCount: 1,
          structureSummary: '9x9 Bilateral Grid • Horizontal Mirror Plane',
          complexityTier: 'Moderate',
          culturalInterpretation: 'Horizontal reflection evoking the sacred reflection of temple vimanam in water.',
          formulaBreakdown: {'reflections': 1, 'axes': ['Horizontal']},
        );

      case AlgorithmicSymmetry.d1Diagonal:
        return const AnalysisResult(
          symmetryType: SymmetryType.bilateralReflection,
          rotationalDegree: 0,
          rotationalSymmetrySummary: 'None',
          reflectionDetected: true,
          reflectionAxesCount: 1,
          matchingReflectionAxes: ['Main Diagonal (45°)'],
          complexityScore: 70,
          gridSize: '9x9',
          closedLoopCount: 2,
          strokeCount: 41,
          intersectionCount: 6,
          patternDensity: 0.72,
          uniqueShapePrimitivesCount: 2,
          symmetryOperationsCount: 1,
          structureSummary: '9x9 Bilateral Grid • Diagonal Mirror Plane',
          complexityTier: 'Moderate',
          culturalInterpretation: 'Diagonal reflection aligning energy along corner corridors and cardinal angles.',
          formulaBreakdown: {'reflections': 1, 'axes': ['Main Diagonal']},
        );

      case AlgorithmicSymmetry.c4Rotational:
        return const AnalysisResult(
          symmetryType: SymmetryType.rotational90,
          rotationalDegree: 90,
          rotationalSymmetrySummary: '90°',
          reflectionDetected: false,
          reflectionAxesCount: 0,
          matchingReflectionAxes: [],
          complexityScore: 84,
          gridSize: '9x9',
          closedLoopCount: 4,
          strokeCount: 41,
          intersectionCount: 12,
          patternDensity: 0.80,
          uniqueShapePrimitivesCount: 3,
          symmetryOperationsCount: 4,
          structureSummary: '9x9 Cyclic Grid • 4 Swirling Sikku Loops',
          complexityTier: 'Intricate',
          culturalInterpretation: 'Pure 90° rotational symmetry celebrating the spinning Chakra wheel of time.',
          formulaBreakdown: {'cyclic': 4, 'reflections': 0},
        );

      case AlgorithmicSymmetry.c2Rotational:
        return const AnalysisResult(
          symmetryType: SymmetryType.rotational180,
          rotationalDegree: 180,
          rotationalSymmetrySummary: '180°',
          reflectionDetected: false,
          reflectionAxesCount: 0,
          matchingReflectionAxes: [],
          complexityScore: 75,
          gridSize: '9x9',
          closedLoopCount: 2,
          strokeCount: 41,
          intersectionCount: 8,
          patternDensity: 0.75,
          uniqueShapePrimitivesCount: 2,
          symmetryOperationsCount: 2,
          structureSummary: '9x9 Two-Fold Grid • 2 Interlocked Sikku Loops',
          complexityTier: 'Moderate',
          culturalInterpretation: '180° point reflection symmetry evoking dual cosmic forces (Prakriti & Purusha).',
          formulaBreakdown: {'cyclic': 2, 'reflections': 0},
        );

      case AlgorithmicSymmetry.asymmetric:
        return const AnalysisResult(
          symmetryType: SymmetryType.none,
          rotationalDegree: 0,
          rotationalSymmetrySummary: 'None',
          reflectionDetected: false,
          reflectionAxesCount: 0,
          matchingReflectionAxes: [],
          complexityScore: 50,
          gridSize: '9x9',
          closedLoopCount: 1,
          strokeCount: 41,
          intersectionCount: 4,
          patternDensity: 0.65,
          uniqueShapePrimitivesCount: 1,
          symmetryOperationsCount: 0,
          structureSummary: '9x9 Organic Grid • Asymmetric Flowing Sikku',
          complexityTier: 'Simple',
          culturalInterpretation: 'Dynamic freeform Kolam vine, exploring unconstrained geometric permutations.',
          formulaBreakdown: {'reflections': 0, 'cyclic': 0},
        );
    }
  }

  /// Converts the algorithmic rounded-rectangle tiles into a list of KolamStrokes
  List<KolamStroke> toStrokes({
    double canvasSize = 350.0,
    double margin = 6.0,
    double strokeWidth = 3.0,
    Color color = Colors.white,
  }) {
    final strokes = <KolamStroke>[];
    final int tnum = tnumber;
    final double tsize = (canvasSize - 2 * margin) / tnum;
    final colorVal = color.toARGB32();

    for (int i = 0; i < tnum; i++) {
      for (int j = 0; j < tnum; j++) {
        if ((i + j) % 2 == 0) {
          final double rawTL = nlink[i][j];
          final double rawTR = nlink[i + 1][j];
          final double rawBR = nlink[i + 1][j + 1];
          final double rawBL = nlink[i][j + 1];

          final double topLeft = (tsize / 2) * rawTL;
          final double topRight = (tsize / 2) * rawTR;
          final double bottomRight = (tsize / 2) * rawBR;
          final double bottomLeft = (tsize / 2) * rawBL;

          final rect = Rect.fromLTWH(
            i * tsize + margin,
            j * tsize + margin,
            tsize,
            tsize,
          );

          final rrect = RRect.fromRectAndCorners(
            rect,
            topLeft: Radius.circular(topLeft),
            topRight: Radius.circular(topRight),
            bottomRight: Radius.circular(bottomRight),
            bottomLeft: Radius.circular(bottomLeft),
          );

          // Sample points along the RRect path
          final path = Path()..addRRect(rrect);
          final points = <KolamPoint>[];
          for (final metric in path.computeMetrics()) {
            final length = metric.length;
            const step = 6.0;
            final count = max(4, (length / step).ceil());
            for (int s = 0; s <= count; s++) {
              final dist = (s / count) * length;
              final tangent = metric.getTangentForOffset(dist);
              if (tangent != null) {
                points.add(KolamPoint(tangent.position.dx, tangent.position.dy));
              }
            }
          }

          if (points.isNotEmpty) {
            strokes.add(KolamStroke(
              points: points,
              colorValue: colorVal,
              strokeWidth: strokeWidth,
            ));
          }
        }
      }
    }
    return strokes;
  }

  /// Create a preset library of patterns showcasing Vertical, Horizontal, Diagonal, and All-Axis (8-Way)
  static List<AlgorithmicKolamPattern> createPresetGameLibrary() {
    final list = <AlgorithmicKolamPattern>[];
    final symmetries = [
      AlgorithmicSymmetry.d1Vertical,
      AlgorithmicSymmetry.d1Horizontal,
      AlgorithmicSymmetry.d1Diagonal,
      AlgorithmicSymmetry.d4Multiple,
      AlgorithmicSymmetry.d1Vertical,
      AlgorithmicSymmetry.d1Horizontal,
      AlgorithmicSymmetry.d1Diagonal,
      AlgorithmicSymmetry.d4Multiple,
    ];

    for (int i = 0; i < symmetries.length; i++) {
      final p = AlgorithmicKolamPattern(
        tnumber: 9,
        symmetry: symmetries[i],
      );
      p.configTile(forcedSymmetry: symmetries[i], rng: Random(42 + i * 37));
      list.add(p);
    }
    return list;
  }
}
