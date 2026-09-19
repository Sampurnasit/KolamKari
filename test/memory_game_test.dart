import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kolamkari/data/models/game_result.dart';
import 'package:kolamkari/providers/app_providers.dart';
import 'package:kolamkari/services/storage_service.dart';
import 'package:kolamkari/ui/play/games/memory_game_screen.dart';

void main() {
  group('MemoryGameCatalog & Difficulty Level Tests', () {
    test('Catalog provides authentic target patterns with assetPath for all 4 difficulty levels', () {
      for (int diff = 1; diff <= 4; diff++) {
        final targets = MemoryGameCatalog.getTargetsForDifficulty(diff);
        expect(targets.isNotEmpty, isTrue, reason: 'Level $diff should have targets');
        for (final target in targets) {
          expect(target.name.isNotEmpty, isTrue);
          expect(target.tamilName.isNotEmpty, isTrue);
          expect(target.culturalLore.isNotEmpty, isTrue);
          expect(target.assetPath.isNotEmpty, isTrue);
          expect(target.assetPath.startsWith('assets/kolam/'), isTrue);
          expect(target.strokes.isNotEmpty, isTrue);
          expect(target.difficultyLevel, equals(diff));
          expect([5, 7, 9].contains(target.gridSize), isTrue);
        }
      }
    });

    test('Level 1 targets are 5x5 grids suitable for 10s preview with authentic images', () {
      final l1Targets = MemoryGameCatalog.getTargetsForDifficulty(1);
      expect(l1Targets.every((t) => t.gridSize == 5), isTrue);
      expect(l1Targets.every((t) => t.assetPath.isNotEmpty), isTrue);
    });

    test('Level 3 and 4 targets include complex 7x7 and 9x9 grids with authentic images', () {
      final l3Targets = MemoryGameCatalog.getTargetsForDifficulty(3);
      final l4Targets = MemoryGameCatalog.getTargetsForDifficulty(4);

      expect(l3Targets.any((t) => t.gridSize >= 7), isTrue);
      expect(l4Targets.any((t) => t.gridSize >= 7), isTrue);
      expect(l3Targets.every((t) => t.assetPath.startsWith('assets/kolam/')), isTrue);
      expect(l4Targets.every((t) => t.assetPath.startsWith('assets/kolam/')), isTrue);
    });
  });

  group('MemoryScoreBreakdown & Scoring Threshold Tests', () {
    test('Passing score at or above 60% calculates correct stars and flags', () {
      const passingBreakdown = MemoryScoreBreakdown(
        pathSimilarityScore: 35,
        coveragePercent: 70.0,
        precisionPenalty: 0.0,
        connectionPointsScore: 20,
        matchedConnectionDots: 10,
        totalTargetDots: 12,
        timeBonusScore: 15,
        elapsedSeconds: 18.5,
        totalScore: 70,
        isPassing: true,
      );

      expect(passingBreakdown.isPassing, isTrue);
      expect(passingBreakdown.stars, equals(2));
    });

    test('High score (>= 85%) earns 3 stars', () {
      const topBreakdown = MemoryScoreBreakdown(
        pathSimilarityScore: 48,
        coveragePercent: 96.0,
        precisionPenalty: 0.0,
        connectionPointsScore: 28,
        matchedConnectionDots: 15,
        totalTargetDots: 15,
        timeBonusScore: 18,
        elapsedSeconds: 12.0,
        totalScore: 94,
        isPassing: true,
      );

      expect(topBreakdown.isPassing, isTrue);
      expect(topBreakdown.stars, equals(3));
    });

    test('Score below 60% is not passing and earns 0 stars', () {
      const failingBreakdown = MemoryScoreBreakdown(
        pathSimilarityScore: 20,
        coveragePercent: 40.0,
        precisionPenalty: 5.0,
        connectionPointsScore: 10,
        matchedConnectionDots: 4,
        totalTargetDots: 14,
        timeBonusScore: 10,
        elapsedSeconds: 45.0,
        totalScore: 40,
        isPassing: false,
      );

      expect(failingBreakdown.isPassing, isFalse);
      expect(failingBreakdown.stars, equals(0));
    });
  });

  group('GameResult Logging Integration Tests', () {
    test('GameResult serializes correctly for memoryGame', () {
      final result = GameResult(
        id: 'test_memory_123',
        gameType: GameType.memoryGame,
        score: 75,
        xpEarned: 50,
        timestamp: DateTime(2026, 9, 19, 15, 30),
        difficultyLevel: 2,
        culturalNote: 'Memorized Nelli Sikku',
        won: true,
      );

      final json = result.toJson();
      expect(json['gameType'], equals('memoryGame'));
      expect(json['score'], equals(75));
      expect(json['xpEarned'], equals(50));
      expect(json['difficultyLevel'], equals(2));
      expect(json['won'], isTrue);

      final deserialized = GameResult.fromJson(json);
      expect(deserialized.gameType, equals(GameType.memoryGame));
      expect(deserialized.score, equals(75));
      expect(deserialized.xpEarned, equals(50));
      expect(deserialized.won, isTrue);
    });
  });

  group('MemoryGameScreen Widget Flow Tests', () {
    testWidgets('Shows difficulty selector screen with 4 levels initially', (WidgetTester tester) async {
      final storage = StorageService();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            storageServiceProvider.overrideWithValue(storage),
          ],
          child: const MaterialApp(
            home: MemoryGameScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Sacred Visual Recall'), findsOneWidget);
      expect(find.text('Choose Difficulty Level'), findsOneWidget);
      expect(find.text('Level 1: Beginner'), findsOneWidget);
      expect(find.text('Level 2: Skilled'), findsOneWidget);
      expect(find.text('Level 3: Adept'), findsOneWidget);
      expect(find.text('Level 4: Master'), findsOneWidget);
    });

    testWidgets('Selecting Level 1 transitions to preview countdown then drawing mode', (WidgetTester tester) async {
      final storage = StorageService();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            storageServiceProvider.overrideWithValue(storage),
          ],
          child: const MaterialApp(
            home: MemoryGameScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Tap Level 1 card
      await tester.tap(find.text('Level 1: Beginner'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify preview countdown header is displayed
      expect(find.textContaining('Memorize the sacred pattern:'), findsOneWidget);
      expect(find.text('Memorized! Start Drawing Now'), findsOneWidget);
      expect(find.text('Authentic Kolam Glimpse'), findsOneWidget);
      expect(find.byType(Image), findsWidgets);

      // Tap skip button to jump straight into drawing mode
      await tester.tap(find.text('Memorized! Start Drawing Now'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify drawing screen widgets are active
      expect(find.textContaining('Recreating:'), findsOneWidget);
      expect(find.text('Freehand'), findsOneWidget);
      expect(find.text('Shapes'), findsOneWidget);
      expect(find.text('Submit Memory Match'), findsOneWidget);

      // Toggle Shapes mode
      await tester.tap(find.text('Shapes'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify shape primitives palette is present
      expect(find.textContaining('Kolam Primitives Palette'), findsOneWidget);
    });
  });
}
