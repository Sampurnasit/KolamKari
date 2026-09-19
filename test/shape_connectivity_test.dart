import 'package:flutter_test/flutter_test.dart';
import 'package:kolamkari/data/models/kolam_shape_primitive.dart';
import 'package:kolamkari/services/connectivity_graph_service.dart';

void main() {
  group('Kolam Shape Primitives & Geometry', () {
    test('Catalog contains 9 predefined Kolam primitives', () {
      expect(KolamShapeCatalog.primitives.length, 9);
      final ids = KolamShapeCatalog.primitives.map((p) => p.id).toSet();
      expect(ids.contains('quarter_arc'), true);
      expect(ids.contains('half_loop'), true);
      expect(ids.contains('s_curve_weave'), true);
      expect(ids.contains('straight_line'), true);
      expect(ids.contains('diagonal_bridge'), true);
      expect(ids.contains('corner_sikku_turn'), true);
      expect(ids.contains('petal_loop'), true);
      expect(ids.contains('cross_ribbon'), true);
      expect(ids.contains('cusp_arch'), true);
    });

    test('World anchor calculation without rotation', () {
      const shape = PlacedKolamShape(
        id: 'shape_1',
        primitiveId: 'straight_line',
        position: Offset(100, 100),
        size: 50.0,
        rotationDegrees: 0,
      );

      // straight line local start is (-0.5, 0.0), local end is (0.5, 0.0)
      // worldStartAnchor: (100 - 0.5 * 50, 100) = (75, 100)
      // worldEndAnchor: (100 + 0.5 * 50, 100) = (125, 100)
      expect(shape.worldStartAnchor.dx, closeTo(75.0, 0.001));
      expect(shape.worldStartAnchor.dy, closeTo(100.0, 0.001));
      expect(shape.worldEndAnchor.dx, closeTo(125.0, 0.001));
      expect(shape.worldEndAnchor.dy, closeTo(100.0, 0.001));
    });

    test('World anchor calculation with 90-degree rotation', () {
      const shape = PlacedKolamShape(
        id: 'shape_1',
        primitiveId: 'straight_line',
        position: Offset(100, 100),
        size: 50.0,
        rotationDegrees: 90,
      );

      // Rotating (-25, 0) by 90 deg -> (0, -25)
      // worldStartAnchor: (100, 75)
      // worldEndAnchor: (100, 125)
      expect(shape.worldStartAnchor.dx, closeTo(100.0, 0.001));
      expect(shape.worldStartAnchor.dy, closeTo(75.0, 0.001));
      expect(shape.worldEndAnchor.dx, closeTo(100.0, 0.001));
      expect(shape.worldEndAnchor.dy, closeTo(125.0, 0.001));
    });

    test('toStroke produces valid stroke points', () {
      const shape = PlacedKolamShape(
        id: 'shape_1',
        primitiveId: 'quarter_arc',
        position: Offset(100, 100),
        size: 60.0,
      );

      final stroke = shape.toStroke();
      expect(stroke.points.isNotEmpty, true);
      expect(stroke.points.length, greaterThanOrEqualTo(10));
    });
  });

  group('KolamConnectivityGraph & Magnetic Snapping', () {
    test('Snap to grid dot within threshold', () {
      final graph = KolamConnectivityGraph();
      final gridDots = [
        const Offset(50, 50),
        const Offset(100, 50),
        const Offset(50, 100),
        const Offset(100, 100),
      ];

      // Placed straight line where start anchor is at (88 - 25, 50) = (63, 50)
      // Distance to (50, 50) is 13px (within 22px threshold)
      const shape = PlacedKolamShape(
        id: 'test_shape',
        primitiveId: 'straight_line',
        position: Offset(88, 50),
        size: 50.0,
      );

      final snap = graph.evaluateSnap(
        shape: shape,
        gridDots: gridDots,
        snapThreshold: 22.0,
      );

      expect(snap, isNotNull);
      expect(snap!.isGridDot, true);
      expect(snap.snappedAnchorPoint, const Offset(50, 50));
      // Snapped position should shift by delta (-13, 0) -> (75, 50)
      expect(snap.snappedShapePosition.dx, closeTo(75.0, 0.001));
      expect(snap.snappedShapePosition.dy, closeTo(50.0, 0.001));
    });

    test('Snap to adjacent shape anchor endpoint', () {
      final graph = KolamConnectivityGraph();
      final gridDots = <Offset>[];

      // Shape 1 end anchor is at (125, 100)
      const shape1 = PlacedKolamShape(
        id: 's1',
        primitiveId: 'straight_line',
        position: Offset(100, 100),
        size: 50.0,
      );

      graph.rebuild(gridDots: gridDots, shapes: [shape1]);

      // Shape 2 start anchor is placed near (125, 100), e.g. at (135 - 20, 100) = (115, 100)
      // Distance is 10px (within threshold)
      const shape2 = PlacedKolamShape(
        id: 's2',
        primitiveId: 'straight_line',
        position: Offset(135, 100),
        size: 40.0, // localStart is -20 -> world start (115, 100)
      );

      final snap = graph.evaluateSnap(
        shape: shape2,
        gridDots: gridDots,
        snapThreshold: 22.0,
      );

      expect(snap, isNotNull);
      expect(snap!.snappedAnchorPoint.dx, closeTo(125.0, 0.001));
      expect(snap.snappedAnchorPoint.dy, closeTo(100.0, 0.001));
    });

    test('Cycle detection: 4 quarter-arcs forming a closed circle', () {
      final graph = KolamConnectivityGraph();

      // Form 4 corners of a loop connected at (100, 50), (150, 100), (100, 150), (50, 100)
      // For quarter_arc: localStart = (0, -0.5), localEnd = (0.5, 0)
      // Center at (100, 100), size = 100
      // Arc 0 (rot 0): start=(100, 50), end=(150, 100)
      // Arc 1 (rot 90): start=(150, 100), end=(100, 150)
      // Arc 2 (rot 180): start=(100, 150), end=(50, 100)
      // Arc 3 (rot 270): start=(50, 100), end=(100, 50)
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

      expect(graph.edges.length, 4);
      final closedLoops = graph.countClosedLoops();
      expect(closedLoops, greaterThanOrEqualTo(1));

      final mergedStrokes = graph.getMergedStrokes();
      expect(mergedStrokes.isNotEmpty, true);
    });
  });
}
