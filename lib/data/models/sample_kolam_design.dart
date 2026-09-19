import '../../services/analysis_service.dart';
import 'analysis_result.dart';
import 'kolam_shape_primitive.dart';

enum KolamDifficulty {
  easy,
  medium,
  hard,
}

extension KolamDifficultyExtension on KolamDifficulty {
  String get label {
    switch (this) {
      case KolamDifficulty.easy:
        return 'Easy';
      case KolamDifficulty.medium:
        return 'Medium';
      case KolamDifficulty.hard:
        return 'Hard';
    }
  }

  String get tamilLabel {
    switch (this) {
      case KolamDifficulty.easy:
        return 'எளியது';
      case KolamDifficulty.medium:
        return 'நடுத்தரம்';
      case KolamDifficulty.hard:
        return 'கடினம்';
    }
  }
}

/// A hand-defined preset Kolam pattern for learning and tracing
class SampleKolamDesign {
  final String id;
  final String name;
  final String tamilName;
  final String category; // Sikku, Kambi, Pulli, Lotus, Padi
  final KolamDifficulty difficulty;
  final int gridSize; // 5, 7, 9
  final String culturalLore;
  final SymmetryType symmetryType;
  final List<KolamStroke> strokes;
  final List<PlacedKolamShape>? suggestedShapes;
  final int estimatedMinutes;
  final int baseXP;

  const SampleKolamDesign({
    required this.id,
    required this.name,
    required this.tamilName,
    required this.category,
    required this.difficulty,
    required this.gridSize,
    required this.culturalLore,
    required this.symmetryType,
    required this.strokes,
    this.suggestedShapes,
    this.estimatedMinutes = 3,
    this.baseXP = 50,
  });

  int get strokeCount => strokes.length;
}
