import 'package:flutter_test/flutter_test.dart';
import 'package:kolamkari/data/models/sample_kolam_design.dart';
import 'package:kolamkari/data/models/saved_kolam.dart';
import 'package:kolamkari/data/seed/sample_designs_library.dart';
import 'package:kolamkari/services/analysis_service.dart';

void main() {
  group('Sample Designs Library Catalog Tests', () {
    test('Library contains 12 authentic hand-defined Kolam presets', () {
      final samples = SampleDesignsLibrary.allSamples;
      expect(samples.length, 12);

      // Verify all IDs are unique
      final ids = samples.map((s) => s.id).toSet();
      expect(ids.length, 12);

      // Verify difficulty distribution
      final easy = samples.where((s) => s.difficulty == KolamDifficulty.easy).toList();
      final medium = samples.where((s) => s.difficulty == KolamDifficulty.medium).toList();
      final hard = samples.where((s) => s.difficulty == KolamDifficulty.hard).toList();

      expect(easy.length, 4);
      expect(medium.length, 4);
      expect(hard.length, 4);

      // Verify grid sizes
      final grids = samples.map((s) => s.gridSize).toSet();
      expect(grids.contains(5), true);
      expect(grids.contains(7), true);
      expect(grids.contains(9), true);
    });

    test('Each sample design has valid non-empty strokes and cultural lore', () {
      for (final sample in SampleDesignsLibrary.allSamples) {
        expect(sample.id.isNotEmpty, true);
        expect(sample.name.isNotEmpty, true);
        expect(sample.tamilName.isNotEmpty, true);
        expect(sample.culturalLore.isNotEmpty, true);
        expect(sample.strokes.isNotEmpty, true, reason: 'Sample ${sample.id} has no strokes');
        for (final stroke in sample.strokes) {
          expect(stroke.points.isNotEmpty, true);
        }
      }
    });

    test('getById retrieves the correct sample design', () {
      final nelli = SampleDesignsLibrary.getById('med_nelli_sikku_5');
      expect(nelli.name, 'Nelli Sikku Eulerian Knot');
      expect(nelli.difficulty, KolamDifficulty.medium);
      expect(nelli.gridSize, 5);

      final star = SampleDesignsLibrary.getById('hard_ashtalakshmi_star_9');
      expect(star.name, 'Ashtalakshmi 8-Petal Star');
      expect(star.difficulty, KolamDifficulty.hard);
      expect(star.gridSize, 9);
    });
  });

  group('SavedKolam Tracing Attribution Tests', () {
    test('Correctly identifies traced copy vs original freehand creation', () {
      final original = SavedKolam(
        id: 'orig_1',
        name: 'My Original Kolam',
        createdDate: DateTime.now(),
        canvasStrokeData: '[]',
        gridSize: 5,
        complexityScore: 60,
      );
      expect(original.isTracedCopy, false);
      expect(original.sourceSampleId, null);

      final traced = SavedKolam(
        id: 'traced_1',
        name: 'Traced Nelli Sikku',
        createdDate: DateTime.now(),
        canvasStrokeData: '[]',
        gridSize: 5,
        complexityScore: 65,
        sourceSampleId: 'med_nelli_sikku_5',
        culturalTag: 'Traced: Nelli Sikku',
      );
      expect(traced.isTracedCopy, true);
      expect(traced.sourceSampleId, 'med_nelli_sikku_5');

      // Serialization round-trip
      final json = traced.toJson();
      expect(json['sourceSampleId'], 'med_nelli_sikku_5');

      final reconstructed = SavedKolam.fromJson(json);
      expect(reconstructed.isTracedCopy, true);
      expect(reconstructed.sourceSampleId, 'med_nelli_sikku_5');
    });
  });

  group('Tracing Match Engine Tests', () {
    test('Returns 0% for empty user strokes', () {
      final sample = SampleDesignsLibrary.kodiVineBorder;
      final result = SampleDesignsLibrary.evaluateTracingMatch(
        userStrokes: [],
        targetStrokes: sample.strokes,
      );
      expect(result.matchPercentage, 0);
      expect(result.coverageRatio, 0.0);
      expect(result.awardedXP, 0);
    });

    test('High accuracy for accurately traced strokes', () {
      final sample = SampleDesignsLibrary.rathamChariotDiamond;
      // Exact copy of target strokes
      final result = SampleDesignsLibrary.evaluateTracingMatch(
        userStrokes: sample.strokes,
        targetStrokes: sample.strokes,
      );

      expect(result.matchPercentage, greaterThanOrEqualTo(85));
      expect(result.coverageRatio, closeTo(1.0, 0.05));
      expect(result.awardedXP, greaterThanOrEqualTo(30));
    });

    test('Penalizes wild stray scribbles far from target', () {
      final sample = SampleDesignsLibrary.cornerLoops;

      // Strokes far away from any target
      final strayStrokes = [
        KolamStroke(
          points: const [KolamPoint(10, 10), KolamPoint(15, 15), KolamPoint(20, 20)],
          colorValue: 0xFFFFFFFF,
          strokeWidth: 3.5,
        ),
      ];

      final result = SampleDesignsLibrary.evaluateTracingMatch(
        userStrokes: strayStrokes,
        targetStrokes: sample.strokes,
      );

      expect(result.matchPercentage, lessThan(30));
    });
  });
}
