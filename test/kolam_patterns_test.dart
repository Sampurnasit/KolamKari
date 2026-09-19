import 'package:flutter_test/flutter_test.dart';
import 'package:kolamkari/data/seed/kolam_patterns_library.dart';

void main() {
  group('KolamPatternsLibrary Tests', () {
    test('Library has multiple authentic patterns', () {
      final patterns = KolamPatternsLibrary.allPatterns;
      expect(patterns.length, greaterThanOrEqualTo(5));
    });

    test('Each pattern has valid 4 quadrants and decoys for puzzle matching', () {
      for (final p in KolamPatternsLibrary.allPatterns) {
        expect(p.name.isNotEmpty, isTrue);
        expect(p.strokes.isNotEmpty, isTrue);
        expect(p.quadrant1.isNotEmpty, isTrue);
        expect(p.quadrant2.isNotEmpty, isTrue);
        expect(p.quadrant3.isNotEmpty, isTrue);
        expect(p.quadrant4.isNotEmpty, isTrue);
        expect(p.decoysForQuadrant4.length, equals(3));
      }
    });

    test('Random pattern returns a valid pattern', () {
      final p = KolamPatternsLibrary.getRandomPattern();
      expect(p.gridSize, equals(5));
      expect(p.strokes.length, greaterThan(0));
    });
  });
}
