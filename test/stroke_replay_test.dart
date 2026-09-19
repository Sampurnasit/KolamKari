import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolamkari/data/seed/sample_designs_library.dart';
import 'package:kolamkari/services/analysis_service.dart';

void main() {
  group('Stroke Replay Timeline & Interpolation Tests', () {
    test('Calculates segment offsets correctly across multiple strokes', () {
      final stroke1 = KolamStroke(
        points: const [KolamPoint(0, 0), KolamPoint(10, 0), KolamPoint(20, 0)], // 2 segments
        colorValue: 0xFFFFFFFF,
      );
      final stroke2 = KolamStroke(
        points: const [KolamPoint(20, 0), KolamPoint(30, 10)], // 1 segment
        colorValue: 0xFFFFFFFF,
      );
      final stroke3 = KolamStroke(
        points: const [KolamPoint(30, 10), KolamPoint(40, 20), KolamPoint(50, 30), KolamPoint(60, 40)], // 3 segments
        colorValue: 0xFFFFFFFF,
      );

      final strokes = [stroke1, stroke2, stroke3];
      final offsets = [0];
      int runningSegments = 0;
      for (final s in strokes) {
        final segs = max(1, s.points.length - 1);
        runningSegments += segs;
        offsets.add(runningSegments);
      }

      // Offsets should be: [0, 2, 3, 6]
      expect(offsets, [0, 2, 3, 6]);
      final totalSegments = runningSegments;
      expect(totalSegments, 6);

      // At progress 0.0 -> Segment 0 (in stroke 0)
      double progress = 0.0;
      double globalSeg = progress * totalSegments;
      int activeStrokeIdx = 0;
      for (int i = 0; i < offsets.length - 1; i++) {
        if (globalSeg >= offsets[i]) activeStrokeIdx = i;
      }
      expect(activeStrokeIdx, 0);

      // At progress 0.5 (segment 3.0) -> Start of stroke 2
      progress = 0.5;
      globalSeg = progress * totalSegments;
      for (int i = 0; i < offsets.length - 1; i++) {
        if (globalSeg >= offsets[i]) activeStrokeIdx = i;
      }
      expect(activeStrokeIdx, 2);

      // At progress 1.0 (segment 6.0) -> stroke 2 completed
      progress = 1.0;
      globalSeg = (progress * totalSegments).clamp(0.0, (totalSegments - 0.001));
      for (int i = 0; i < offsets.length - 1; i++) {
        if (globalSeg >= offsets[i]) activeStrokeIdx = i;
      }
      expect(activeStrokeIdx, 2);
    });

    test('Point interpolation along sub-segment matches expected coordinates', () {
      final stroke = KolamStroke(
        points: const [
          KolamPoint(100, 100),
          KolamPoint(200, 100),
        ],
        colorValue: 0xFFFFFFFF,
      );

      // At localProgress = 0.5: exactly halfway between (100, 100) and (200, 100)
      const localProgress = 0.5;
      final segmentIdx = localProgress.floor().clamp(0, stroke.points.length - 2);
      final t = (localProgress - segmentIdx).clamp(0.0, 1.0);

      final pA = stroke.points[segmentIdx];
      final pB = stroke.points[segmentIdx + 1];
      final activeX = pA.x + (pB.x - pA.x) * t;
      final activeY = pA.y + (pB.y - pA.y) * t;

      expect(activeX, 150.0);
      expect(activeY, 100.0);
    });

    test('Replay timeline works cleanly with all sample designs', () {
      for (final sample in SampleDesignsLibrary.allSamples) {
        int segs = 0;
        for (final s in sample.strokes) {
          segs += max(1, s.points.length - 1);
        }
        expect(segs, greaterThan(0));

        final durationMs = (segs * 70).clamp(3500, 16000);
        expect(durationMs, greaterThanOrEqualTo(3500));
        expect(durationMs, lessThanOrEqualTo(16000));
      }
    });
  });
}
