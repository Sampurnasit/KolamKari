import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolamkari/services/analysis_service.dart';
import 'package:kolamkari/services/connectivity_graph_service.dart';
import 'package:kolamkari/data/models/analysis_result.dart';
import 'package:kolamkari/data/models/kolam_shape_primitive.dart';
import 'package:kolamkari/data/models/saved_kolam.dart';

void main() {
  group('LocalGeometryAnalyzer Computational Geometry Tests', () {
    late LocalGeometryAnalyzer analyzer;

    setUp(() {
      analyzer = LocalGeometryAnalyzer();
    });

    test('Empty strokes returns minimal complexity, zero symmetry, and empty structure', () async {
      final data = KolamData(
        strokes: [],
        gridSize: 5,
        canvasSize: const Size(350, 350),
      );

      final result = analyzer.analyze(data);
      expect(result.complexityScore, equals(0));
      expect(result.symmetryType, equals(SymmetryType.none));
      expect(result.reflectionDetected, isFalse);
      expect(result.matchingReflectionAxes, isEmpty);
      expect(result.rotationalSymmetrySummary, equals('None'));
      expect(result.structureSummary, equals('5x5 Grid • 0 Closed Loops'));
    });

    test('Bilateral vertical reflection detects vertical axis and reports matching reflection axes', () async {
      const cx = 175.0;
      const cy = 175.0;

      // Draw mirrored lines across vertical axis x = cx
      final strokes = [
        KolamStroke(
          points: [
            const KolamPoint(cx - 40, cy - 30),
            const KolamPoint(cx - 20, cy),
            const KolamPoint(cx - 40, cy + 30),
          ],
          colorValue: 0xFFFFFFFF,
        ),
        KolamStroke(
          points: [
            const KolamPoint(cx + 40, cy - 30),
            const KolamPoint(cx + 20, cy),
            const KolamPoint(cx + 40, cy + 30),
          ],
          colorValue: 0xFFFFFFFF,
        ),
      ];

      final data = KolamData(
        strokes: strokes,
        gridSize: 5,
        canvasSize: const Size(350, 350),
      );

      final result = analyzer.analyze(data);
      expect(result.reflectionDetected, isTrue);
      expect(result.matchingReflectionAxes, contains('Vertical Axis'));
      expect(result.reflectionAxesCount, greaterThanOrEqualTo(1));
    });

    test('Rotational symmetry detects 90-degree invariance', () async {
      const cx = 175.0;
      const cy = 175.0;
      const r = 40.0;

      // 4-fold cross with symmetry
      final strokes = [
        // North petal
        KolamStroke(
          points: [
            const KolamPoint(cx, cy),
            const KolamPoint(cx - 10, cy - r / 2),
            const KolamPoint(cx, cy - r),
            const KolamPoint(cx + 10, cy - r / 2),
            const KolamPoint(cx, cy),
          ],
          colorValue: 0xFFFFFFFF,
        ),
        // South petal
        KolamStroke(
          points: [
            const KolamPoint(cx, cy),
            const KolamPoint(cx - 10, cy + r / 2),
            const KolamPoint(cx, cy + r),
            const KolamPoint(cx + 10, cy + r / 2),
            const KolamPoint(cx, cy),
          ],
          colorValue: 0xFFFFFFFF,
        ),
        // East petal
        KolamStroke(
          points: [
            const KolamPoint(cx, cy),
            const KolamPoint(cx + r / 2, cy - 10),
            const KolamPoint(cx + r, cy),
            const KolamPoint(cx + r / 2, cy + 10),
            const KolamPoint(cx, cy),
          ],
          colorValue: 0xFFFFFFFF,
        ),
        // West petal
        KolamStroke(
          points: [
            const KolamPoint(cx, cy),
            const KolamPoint(cx - r / 2, cy - 10),
            const KolamPoint(cx - r, cy),
            const KolamPoint(cx - r / 2, cy + 10),
            const KolamPoint(cx, cy),
          ],
          colorValue: 0xFFFFFFFF,
        ),
      ];

      final data = KolamData(
        strokes: strokes,
        gridSize: 7,
        canvasSize: const Size(350, 350),
      );

      final result = analyzer.analyze(data);
      expect(result.rotationalDegree, equals(90));
      expect(result.rotationalSymmetrySummary, equals('90°'));
      expect(result.structureSummary, contains('7x7 Grid'));
    });

    test('7-Factor Complexity formula breakdown contains all required components', () async {
      const cx = 175.0;
      const cy = 175.0;
      const r = 50.0;

      // Closed circle loop with 12 points
      final circlePoints = <KolamPoint>[];
      for (int i = 0; i <= 12; i++) {
        final angle = i * 2 * pi / 12;
        circlePoints.add(KolamPoint(cx + r * cos(angle), cy + r * sin(angle)));
      }

      final strokes = [
        KolamStroke(
          points: circlePoints,
          colorValue: 0xFFFFFFFF,
        ),
      ];

      final graph = KolamConnectivityGraph();
      // Add a placed shape primitive
      const placedShape = PlacedKolamShape(
        id: 'test-1',
        primitiveId: 'quarter_arc',
        position: Offset(100, 100),
      );

      final data = KolamData(
        strokes: strokes,
        placedShapes: [placedShape],
        connectivityGraph: graph,
        gridSize: 7,
        canvasSize: const Size(350, 350),
      );

      final result = analyzer.analyze(data);
      expect(result.closedLoopCount, greaterThanOrEqualTo(1));
      expect(result.complexityScore, greaterThan(15));
      expect(result.uniqueShapePrimitivesCount, equals(1));
      expect(result.formulaBreakdown.containsKey('strokeScore'), isTrue);
      expect(result.formulaBreakdown.containsKey('loopScore'), isTrue);
      expect(result.formulaBreakdown.containsKey('intersectionScore'), isTrue);
      expect(result.formulaBreakdown.containsKey('gridScaleScore'), isTrue);
      expect(result.formulaBreakdown.containsKey('densityScore'), isTrue);
      expect(result.formulaBreakdown.containsKey('uniqueShapeScore'), isTrue);
      expect(result.formulaBreakdown.containsKey('symmetryBonus'), isTrue);
    });

    test('Topology loop detection: graph closed loops are counted in AnalysisResult', () async {
      final graph = KolamConnectivityGraph();

      // 4 quarter arcs forming a closed loop
      final shapes = [
        const PlacedKolamShape(
          id: 'arc_0',
          primitiveId: 'quarter_arc',
          position: Offset(100, 100),
          size: 100.0,
          rotationDegrees: 0,
        ),
        const PlacedKolamShape(
          id: 'arc_1',
          primitiveId: 'quarter_arc',
          position: Offset(100, 100),
          size: 100.0,
          rotationDegrees: 90,
        ),
        const PlacedKolamShape(
          id: 'arc_2',
          primitiveId: 'quarter_arc',
          position: Offset(100, 100),
          size: 100.0,
          rotationDegrees: 180,
        ),
        const PlacedKolamShape(
          id: 'arc_3',
          primitiveId: 'quarter_arc',
          position: Offset(100, 100),
          size: 100.0,
          rotationDegrees: 270,
        ),
      ];

      graph.rebuild(gridDots: [], shapes: shapes, snapThreshold: 10.0);
      expect(graph.countClosedLoops(), equals(1));

      final data = KolamData(
        strokes: [],
        placedShapes: shapes,
        connectivityGraph: graph,
        gridSize: 5,
        canvasSize: const Size(350, 350),
      );

      final result = analyzer.analyze(data);
      expect(result.closedLoopCount, equals(1));
      expect(result.structureSummary, equals('5x5 Grid • 1 Closed Loops'));
    });

    test('Horizontal reflection detects horizontal axis through centroid', () async {
      const cx = 175.0;
      const cy = 175.0;

      // Draw mirrored lines across horizontal axis y = cy
      final strokes = [
        KolamStroke(
          points: [
            const KolamPoint(cx - 30, cy - 40),
            const KolamPoint(cx, cy - 20),
            const KolamPoint(cx + 30, cy - 40),
          ],
          colorValue: 0xFFFFFFFF,
        ),
        KolamStroke(
          points: [
            const KolamPoint(cx - 30, cy + 40),
            const KolamPoint(cx, cy + 20),
            const KolamPoint(cx + 30, cy + 40),
          ],
          colorValue: 0xFFFFFFFF,
        ),
      ];

      final data = KolamData(
        strokes: strokes,
        gridSize: 5,
        canvasSize: const Size(350, 350),
      );

      final result = analyzer.analyze(data);
      expect(result.reflectionDetected, isTrue);
      expect(result.matchingReflectionAxes, contains('Horizontal Axis'));
    });

    test('Rotational symmetry: reports smallest matching angle 180° when 90° does not match', () async {
      const cx = 175.0;
      const cy = 175.0;

      // 2-fold dumbbell shape (invariant under 180° but not 90°)
      final strokes = [
        // Top lobe
        KolamStroke(
          points: [
            const KolamPoint(cx - 15, cy - 60),
            const KolamPoint(cx + 15, cy - 60),
            const KolamPoint(cx, cy - 20),
          ],
          colorValue: 0xFFFFFFFF,
        ),
        // Bottom lobe (180° rotated from top lobe)
        KolamStroke(
          points: [
            const KolamPoint(cx + 15, cy + 60),
            const KolamPoint(cx - 15, cy + 60),
            const KolamPoint(cx, cy + 20),
          ],
          colorValue: 0xFFFFFFFF,
        ),
      ];

      final data = KolamData(
        strokes: strokes,
        gridSize: 7,
        canvasSize: const Size(350, 350),
      );

      final result = analyzer.analyze(data);
      expect(result.rotationalDegree, equals(180));
      expect(result.rotationalSymmetrySummary, equals('180°'));
    });

    test('Asymmetric pattern reports rotational summary "None" and reflectionDetected false', () async {
      final strokes = [
        KolamStroke(
          points: [
            const KolamPoint(20, 20),
            const KolamPoint(50, 70),
            const KolamPoint(80, 40),
            const KolamPoint(120, 90),
            const KolamPoint(200, 250),
          ],
          colorValue: 0xFFFFFFFF,
        ),
      ];

      final data = KolamData(
        strokes: strokes,
        gridSize: 5,
        canvasSize: const Size(350, 350),
      );

      final result = analyzer.analyze(data);
      expect(result.rotationalSymmetrySummary, equals('None'));
      expect(result.rotationalDegree, equals(0));
      expect(result.reflectionDetected, isFalse);
    });

    test('SavedKolam correctly serializes and deserializes AnalysisResult', () {
      final mockResult = AnalysisResult(
        symmetryType: SymmetryType.dihedralD4,
        rotationalDegree: 90,
        rotationalSymmetrySummary: '90°',
        reflectionDetected: true,
        reflectionAxesCount: 4,
        matchingReflectionAxes: const ['Vertical Axis', 'Horizontal Axis', 'Main Diagonal (45°)', 'Anti-Diagonal (135°)'],
        complexityScore: 78,
        gridSize: '7x7',
        closedLoopCount: 4,
        strokeCount: 12,
        intersectionCount: 8,
        patternDensity: 0.24,
        uniqueShapePrimitivesCount: 3,
        symmetryOperationsCount: 6,
        structureSummary: '7x7 Grid • 4 Closed Loops',
        complexityTier: 'Intricate',
        culturalInterpretation: 'Harmonious mandala geometry.',
        formulaBreakdown: {'totalComputed': 78},
      );

      final savedKolam = SavedKolam(
        id: 'test-kolam-1',
        name: 'Mandala Lotus',
        createdDate: DateTime(2026, 1, 1),
        canvasStrokeData: '[]',
        gridSize: 7,
        complexityScore: 78,
        analysisResult: mockResult,
      );

      expect(savedKolam.analysisResult, isNotNull);
      expect(savedKolam.analysisResult!.complexityScore, equals(78));
      expect(savedKolam.analysisResult!.structureSummary, equals('7x7 Grid • 4 Closed Loops'));

      final json = savedKolam.toJson();
      expect(json.containsKey('analysisResult'), isTrue);

      final revived = SavedKolam.fromJson(json);
      expect(revived.analysisResult, isNotNull);
      expect(revived.analysisResult!.rotationalSymmetrySummary, equals('90°'));
      expect(revived.analysisResult!.reflectionAxesCount, equals(4));
    });

    test('AnalysisService interface allows polymorphic swap with future ML or remote analyzer', () async {
      // Mock classifier implementing the same AnalysisService interface
      final AnalysisService customAnalyzer = _MockExternalAnalyzer();

      final data = KolamData(
        strokes: [],
        gridSize: 5,
        canvasSize: const Size(350, 350),
      );

      final result = await customAnalyzer.analyze(data);
      expect(result.complexityScore, equals(99));
      expect(result.complexityTier, equals('Masterwork'));
    });
  });
}

class _MockExternalAnalyzer implements AnalysisService {
  @override
  Future<AnalysisResult> analyze(KolamData data) async {
    return const AnalysisResult(
      symmetryType: SymmetryType.dihedralD4,
      rotationalDegree: 90,
      rotationalSymmetrySummary: '90°',
      reflectionDetected: true,
      reflectionAxesCount: 4,
      matchingReflectionAxes: ['Vertical Axis', 'Horizontal Axis'],
      complexityScore: 99,
      gridSize: '9x9',
      closedLoopCount: 8,
      strokeCount: 20,
      intersectionCount: 16,
      patternDensity: 0.5,
      structureSummary: '9x9 Grid • 8 Closed Loops',
      complexityTier: 'Masterwork',
      culturalInterpretation: 'Remote/ML classified masterwork Kolam.',
      formulaBreakdown: {},
    );
  }
}
