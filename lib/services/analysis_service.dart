import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../data/models/analysis_result.dart';
import '../data/models/kolam_shape_primitive.dart';
import 'connectivity_graph_service.dart';

/// Representation of raw stroke points drawn on the Kolam canvas
class KolamPoint {
  final double x;
  final double y;

  const KolamPoint(this.x, this.y);

  Map<String, dynamic> toJson() => {'x': x, 'y': y};

  factory KolamPoint.fromJson(Map<String, dynamic> json) =>
      KolamPoint((json['x'] as num).toDouble(), (json['y'] as num).toDouble());
}

class KolamStroke {
  final List<KolamPoint> points;
  final int colorValue;
  final double strokeWidth;

  const KolamStroke({
    required this.points,
    required this.colorValue,
    this.strokeWidth = 3.5,
  });

  Map<String, dynamic> toJson() => {
        'points': points.map((p) => p.toJson()).toList(),
        'colorValue': colorValue,
        'strokeWidth': strokeWidth,
      };

  factory KolamStroke.fromJson(Map<String, dynamic> json) => KolamStroke(
        points: (json['points'] as List)
            .map((p) => KolamPoint.fromJson(Map<String, dynamic>.from(p)))
            .toList(),
        colorValue: json['colorValue'] as int? ?? 0xFFFFFFFF,
        strokeWidth: (json['strokeWidth'] as num?)?.toDouble() ?? 3.5,
      );
}

/// Unified Kolam dataset containing freehand strokes, modular placed shapes,
/// topological connectivity graph, grid configuration, and canvas dimensions.
class KolamData {
  final List<KolamStroke> strokes;
  final List<PlacedShapePrimitive> placedShapes;
  final KolamConnectivityGraph? connectivityGraph;
  final int gridSize; // 5, 7, 9
  final Size canvasSize;

  const KolamData({
    required this.strokes,
    this.placedShapes = const [],
    this.connectivityGraph,
    required this.gridSize,
    required this.canvasSize,
  });

  /// All strokes flattened across freehand paths and placed modular shape primitives
  List<KolamStroke> get allStrokes {
    final shapeStrokes = placedShapes.map((s) => s.toStroke()).toList();
    return [...strokes, ...shapeStrokes];
  }
}

/// Backward-compatible alias for existing code referencing KolamStrokeData
typedef KolamStrokeData = KolamData;

/// Abstract AI/Analysis service interface.
/// Allows clean swapping of on-device geometry analyzer with future ML or remote API models.
/// Future MLKolamClassifier or remote API analyzers can implement this exact interface
/// without requiring any UI code modifications.
abstract class AnalysisService {
  FutureOr<AnalysisResult> analyze(KolamData data);
}

/// Example future ML classifier implementing [AnalysisService].
/// Demonstrates that future ML or remote API analyzers can implement
/// [AnalysisService] seamlessly without any UI code changes.
class MLKolamClassifier implements AnalysisService {
  @override
  Future<AnalysisResult> analyze(KolamData data) async {
    // In future releases, run on-device TFLite/ONNX or remote backend classifier.
    throw UnimplementedError('MLKolamClassifier is ready for future model weights');
  }
}

/// On-Device Computational Geometry Analyzer for Kolam patterns.
/// Evaluates:
/// 1. Centroid calculation & spatial normalization
/// 2. Reflection symmetry across Horizontal, Vertical, and Dual Diagonal axes (reporting matching axes)
/// 3. Rotational symmetry for 90°, 180°, 270° around centroid (reporting smallest matching angle or "None")
/// 4. Closed loop & intersection detection (incorporating connectivity graph cycle counts)
/// 5. Deterministic complexity formula (0-100) based on measurable geometric properties:
///    - Stroke count (freehand + shapes)
///    - Closed loop count (from connectivity graph and freehand loops)
///    - Intersection count
///    - Grid size (5, 7, 9)
///    - Pattern density (strokes per grid cell)
///    - Unique shape primitives used
///    - Number of symmetry operations detected
class LocalGeometryAnalyzer implements AnalysisService {
  @override
  AnalysisResult analyze(KolamData data) {
    final effectiveStrokes = data.allStrokes;

    if (effectiveStrokes.isEmpty) {
      return AnalysisResult(
        symmetryType: SymmetryType.none,
        rotationalDegree: 0,
        rotationalSymmetrySummary: 'None',
        reflectionDetected: false,
        reflectionAxesCount: 0,
        matchingReflectionAxes: const [],
        complexityScore: 0,
        gridSize: '${data.gridSize}x${data.gridSize}',
        closedLoopCount: 0,
        strokeCount: 0,
        intersectionCount: 0,
        patternDensity: 0.0,
        uniqueShapePrimitivesCount: 0,
        symmetryOperationsCount: 0,
        structureSummary: '${data.gridSize}x${data.gridSize} Grid • 0 Closed Loops',
        complexityTier: 'Minimal',
        culturalInterpretation: 'A clean canvas awaiting the first sacred mark.',
        formulaBreakdown: const {},
      );
    }

    // 1. Flatten all points and compute bounding box & centroid
    final allPoints = <KolamPoint>[];
    for (final stroke in effectiveStrokes) {
      allPoints.addAll(stroke.points);
    }

    if (allPoints.length < 4) {
      return AnalysisResult(
        symmetryType: SymmetryType.none,
        rotationalDegree: 0,
        rotationalSymmetrySummary: 'None',
        reflectionDetected: false,
        reflectionAxesCount: 0,
        matchingReflectionAxes: const [],
        complexityScore: 10,
        gridSize: '${data.gridSize}x${data.gridSize}',
        closedLoopCount: 0,
        strokeCount: effectiveStrokes.length,
        intersectionCount: 0,
        patternDensity: effectiveStrokes.length / (data.gridSize * data.gridSize),
        uniqueShapePrimitivesCount: data.placedShapes.map((s) => s.primitive.type).toSet().length,
        symmetryOperationsCount: 0,
        structureSummary: '${data.gridSize}x${data.gridSize} Grid • 0 Closed Loops',
        complexityTier: 'Simple',
        culturalInterpretation: 'Initial preparatory strokes.',
        formulaBreakdown: {'strokes': effectiveStrokes.length},
      );
    }

    double sumX = 0, sumY = 0;
    double minX = double.infinity, maxX = -double.infinity;
    double minY = double.infinity, maxY = -double.infinity;

    for (final p in allPoints) {
      sumX += p.x;
      sumY += p.y;
      if (p.x < minX) minX = p.x;
      if (p.x > maxX) maxX = p.x;
      if (p.y < minY) minY = p.y;
      if (p.y > maxY) maxY = p.y;
    }

    final centroidX = sumX / allPoints.length;
    final centroidY = sumY / allPoints.length;

    // Centered points around pattern centroid
    final centeredPoints = allPoints
        .map((p) => KolamPoint(p.x - centroidX, p.y - centroidY))
        .toList();

    // 2. Reflection Symmetry Testing
    // Tolerance threshold in pixels for fingertip touchscreen drawing
    const double tolerance = 24.0;

    final matchingReflectionAxes = <String>[];
    final bool hasVerticalReflection = _testReflection(centeredPoints, (p) => KolamPoint(-p.x, p.y), tolerance);
    final bool hasHorizontalReflection = _testReflection(centeredPoints, (p) => KolamPoint(p.x, -p.y), tolerance);
    final bool hasDiagonal1Reflection = _testReflection(centeredPoints, (p) => KolamPoint(p.y, p.x), tolerance);
    final bool hasDiagonal2Reflection = _testReflection(centeredPoints, (p) => KolamPoint(-p.y, -p.x), tolerance);

    if (hasVerticalReflection) matchingReflectionAxes.add('Vertical Axis');
    if (hasHorizontalReflection) matchingReflectionAxes.add('Horizontal Axis');
    if (hasDiagonal1Reflection) matchingReflectionAxes.add('Main Diagonal (45°)');
    if (hasDiagonal2Reflection) matchingReflectionAxes.add('Anti-Diagonal (135°)');

    final int reflectionAxesCount = matchingReflectionAxes.length;
    final bool reflectionDetected = matchingReflectionAxes.isNotEmpty;

    // 3. Rotational Symmetry Testing
    final bool hasRot180 = _testRotation(centeredPoints, pi, tolerance);
    final bool hasRot90 = _testRotation(centeredPoints, pi / 2, tolerance) && hasRot180;
    final bool hasRot270 = hasRot90 || _testRotation(centeredPoints, 3 * pi / 2, tolerance);

    int rotationalDegree = 0;
    String rotationalSymmetrySummary = 'None';

    // Report smallest matching rotation angle, or "None"
    if (hasRot90) {
      rotationalDegree = 90;
      rotationalSymmetrySummary = '90°';
    } else if (hasRot180) {
      rotationalDegree = 180;
      rotationalSymmetrySummary = '180°';
    } else if (hasRot270) {
      rotationalDegree = 270;
      rotationalSymmetrySummary = '270°';
    }

    // Determine Symmetry Type
    SymmetryType symmetryType = SymmetryType.none;
    if (hasRot90 && reflectionAxesCount >= 2) {
      symmetryType = SymmetryType.dihedralD4;
    } else if (reflectionAxesCount >= 4) {
      symmetryType = SymmetryType.fourFoldReflection;
    } else if (reflectionAxesCount >= 2) {
      symmetryType = SymmetryType.twoFoldReflection;
    } else if (reflectionAxesCount == 1) {
      symmetryType = SymmetryType.bilateralReflection;
    } else if (hasRot90) {
      symmetryType = SymmetryType.rotational90;
    } else if (hasRot180) {
      symmetryType = SymmetryType.rotational180;
    }

    // 4. Closed Loop & Intersection Detection
    // Loop count from topological connectivity graph (cycles formed by shapes)
    final int graphLoops = data.connectivityGraph?.countClosedLoops() ?? 0;

    // Additional loop detection from freehand closed strokes
    int freehandLoops = 0;
    for (final stroke in data.strokes) {
      if (stroke.points.length >= 6) {
        final start = stroke.points.first;
        final end = stroke.points.last;
        final dist = sqrt(pow(start.x - end.x, 2) + pow(start.y - end.y, 2));
        if (dist <= 28.0) {
          freehandLoops++;
        }
      }
    }

    final int closedLoops = graphLoops + freehandLoops;

    // Approximate intersection count across strokes
    final int intersections = _estimateIntersections(effectiveStrokes);

    // 5. Grid scale and pattern density (strokes per grid cell)
    final int totalGridCells = data.gridSize * data.gridSize;
    final double patternDensity = effectiveStrokes.length / totalGridCells;

    // 6. Unique shape primitives used
    final int uniqueShapesCount = data.placedShapes.map((s) => s.primitive.type).toSet().length;

    // 7. Symmetry operations count (reflection planes + rotational symmetry orders)
    final int symmetryOperationsCount = reflectionAxesCount +
        (rotationalDegree > 0 ? (rotationalDegree == 90 ? 2 : 1) : 0);

    // =========================================================================
    // KOLAM GEOMETRIC COMPLEXITY FORMULA (Score Range: 0 - 100)
    // =========================================================================
    //
    // C = W_stroke * S + W_loop * L + W_inter * I + W_grid * G +
    //     W_density * D + W_unique * U + W_sym * Sym
    //
    // Where:
    //  1. S = Stroke Count (freehand + shape primitives).
    //     Weight: 2.0 pts per stroke, capped at 18 pts.
    //  2. L = Closed Loop Count (Brahma Mudi topological cycles in graph).
    //     Weight: 7.0 pts per loop, capped at 24 pts.
    //  3. I = Intersection Count (crossings / weave nodes).
    //     Weight: 2.5 pts per intersection, capped at 16 pts.
    //  4. G = Grid Scale Factor:
    //     Calculated as ((gridSize - 5) / 4.0) * 8.0 -> 0 pts (5x5), 4 pts (7x7), 8 pts (9x9).
    //  5. D = Pattern Density (strokes per grid cell = S / (gridSize * gridSize)).
    //     Weight: 35.0 pts per unit density, capped at 12 pts.
    //  6. U = Unique Shape Primitives Count (from modular palette).
    //     Weight: 2.0 pts per unique primitive type, capped at 10 pts.
    //  7. Sym = Symmetry Operations Count (reflection planes 0-4 + rotational orders 0-2).
    //     Weight: 2.0 pts per operation, capped at 12 pts.
    //
    // Max theoretical sum: 18 + 24 + 16 + 8 + 12 + 10 + 12 = 100 pts.
    // Total raw sum is clamped between [5, 100] for non-empty designs (0 for empty).
    // =========================================================================
    final double strokePts = (effectiveStrokes.length * 2.0).clamp(0.0, 18.0);
    final double loopPts = (closedLoops * 7.0).clamp(0.0, 24.0);
    final double interPts = (intersections * 2.5).clamp(0.0, 16.0);
    final double gridPts = (((data.gridSize - 5) / 4.0) * 8.0).clamp(0.0, 8.0);
    final double densityPts = (patternDensity * 35.0).clamp(0.0, 12.0);
    final double shapePts = (uniqueShapesCount * 2.0).clamp(0.0, 10.0);
    final double symPts = (symmetryOperationsCount * 2.0).clamp(0.0, 12.0);

    final int rawScore = (strokePts + loopPts + interPts + gridPts + densityPts + shapePts + symPts)
        .round()
        .clamp(5, 100);

    String complexityTier;
    if (rawScore < 30) {
      complexityTier = 'Simple';
    } else if (rawScore < 60) {
      complexityTier = 'Moderate';
    } else if (rawScore < 85) {
      complexityTier = 'Intricate';
    } else {
      complexityTier = 'Masterwork';
    }

    // Structure summary
    final structureSummary = '${data.gridSize}x${data.gridSize} Grid • $closedLoops Closed Loops';

    // Cultural interpretation based on detected symmetry and loops
    final String culturalInterpretation = _generateInterpretation(
      symmetryType: symmetryType,
      loops: closedLoops,
      gridSize: data.gridSize,
      tier: complexityTier,
    );

    return AnalysisResult(
      symmetryType: symmetryType,
      rotationalDegree: rotationalDegree,
      rotationalSymmetrySummary: rotationalSymmetrySummary,
      reflectionDetected: reflectionDetected,
      reflectionAxesCount: reflectionAxesCount,
      matchingReflectionAxes: matchingReflectionAxes,
      complexityScore: rawScore,
      gridSize: '${data.gridSize}x${data.gridSize}',
      closedLoopCount: closedLoops,
      strokeCount: effectiveStrokes.length,
      intersectionCount: intersections,
      patternDensity: patternDensity,
      uniqueShapePrimitivesCount: uniqueShapesCount,
      symmetryOperationsCount: symmetryOperationsCount,
      structureSummary: structureSummary,
      complexityTier: complexityTier,
      culturalInterpretation: culturalInterpretation,
      formulaBreakdown: {
        'strokeScore': strokePts.round(),
        'loopScore': loopPts.round(),
        'intersectionScore': interPts.round(),
        'gridScaleScore': gridPts.round(),
        'densityScore': densityPts.round(),
        'uniqueShapeScore': shapePts.round(),
        'symmetryBonus': symPts.round(),
        'totalComputed': rawScore,
      },
    );
  }

  bool _testReflection(List<KolamPoint> points, KolamPoint Function(KolamPoint) transform, double tol) {
    if (points.isEmpty) return false;
    int matched = 0;
    int totalTested = 0;
    final sampleStep = max(1, points.length ~/ 60);

    for (int i = 0; i < points.length; i += sampleStep) {
      totalTested++;
      final p = points[i];
      final transformed = transform(p);
      bool hasMatch = false;
      for (int j = 0; j < points.length; j += max(1, sampleStep ~/ 2)) {
        final target = points[j];
        final dist = sqrt(pow(transformed.x - target.x, 2) + pow(transformed.y - target.y, 2));
        if (dist <= tol) {
          hasMatch = true;
          break;
        }
      }
      if (hasMatch) matched++;
    }

    if (totalTested == 0) return false;
    final matchRatio = matched / totalTested;
    return matchRatio >= 0.72; // 72% spatial match qualifies as reflection
  }

  bool _testRotation(List<KolamPoint> points, double angle, double tol) {
    if (points.isEmpty) return false;
    final cosA = cos(angle);
    final sinA = sin(angle);

    int matched = 0;
    int totalTested = 0;
    final sampleStep = max(1, points.length ~/ 60);

    for (int i = 0; i < points.length; i += sampleStep) {
      totalTested++;
      final p = points[i];
      final rx = p.x * cosA - p.y * sinA;
      final ry = p.x * sinA + p.y * cosA;

      bool hasMatch = false;
      for (int j = 0; j < points.length; j += max(1, sampleStep ~/ 2)) {
        final target = points[j];
        final dist = sqrt(pow(rx - target.x, 2) + pow(ry - target.y, 2));
        if (dist <= tol) {
          hasMatch = true;
          break;
        }
      }
      if (hasMatch) matched++;
    }

    if (totalTested == 0) return false;
    final matchRatio = matched / totalTested;
    return matchRatio >= 0.70;
  }

  int _estimateIntersections(List<KolamStroke> strokes) {
    int count = 0;
    // Fast bounding box intersection test across strokes
    for (int i = 0; i < strokes.length; i++) {
      for (int j = i + 1; j < strokes.length; j++) {
        if (_strokesIntersect(strokes[i], strokes[j])) {
          count++;
        }
      }
    }
    return count;
  }

  bool _strokesIntersect(KolamStroke s1, KolamStroke s2) {
    if (s1.points.isEmpty || s2.points.isEmpty) return false;
    final sample1 = s1.points.whereIndexed((idx, _) => idx % 4 == 0).toList();
    final sample2 = s2.points.whereIndexed((idx, _) => idx % 4 == 0).toList();

    for (final p1 in sample1) {
      for (final p2 in sample2) {
        final dist = sqrt(pow(p1.x - p2.x, 2) + pow(p1.y - p2.y, 2));
        if (dist < 12.0) {
          return true;
        }
      }
    }
    return false;
  }

  String _generateInterpretation({
    required SymmetryType symmetryType,
    required int loops,
    required int gridSize,
    required String tier,
  }) {
    if (symmetryType == SymmetryType.dihedralD4) {
      return 'Exhibits profound D4 Dihedral Harmony. The four-axis reflection and rotational balance mirrors temple mandala geometry, channeling protective energy at the doorstep.';
    } else if (symmetryType == SymmetryType.fourFoldReflection || symmetryType == SymmetryType.rotational90) {
      return 'Features 4-fold cardinal balance. In traditional Tamil philosophy, four-quadrant alignment harmonizes with the four Vedas and cardinal directions.';
    } else if (symmetryType == SymmetryType.twoFoldReflection || symmetryType == SymmetryType.rotational180) {
      return 'Demonstrates 2-fold dual symmetry. Characteristic of Ratham (chariot) Kolams, embodying balance between solar and lunar cosmic forces.';
    } else if (loops >= 2) {
      return 'Shows intricate closed Sikku loops. The continuous loops symbolize Brahma Mudi — an unbroken knot reminding us of the continuity of cosmic order.';
    } else {
      return 'Organic dynamic flow. Demonstrates spontaneous creative movement reminiscent of Bengal Alpana and freehand threshold borders.';
    }
  }
}

extension IterableExtension<E> on Iterable<E> {
  Iterable<T> mapIndexed<T>(T Function(int index, E item) f) sync* {
    var index = 0;
    for (final item in this) {
      yield f(index, item);
      index++;
    }
  }

  Iterable<E> whereIndexed(bool Function(int index, E item) f) sync* {
    var index = 0;
    for (final item in this) {
      if (f(index, item)) {
        yield item;
      }
      index++;
    }
  }
}
