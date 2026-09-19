import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolamkari/data/seed/kolam_image_library.dart';
import 'package:kolamkari/providers/app_providers.dart';
import 'package:kolamkari/services/storage_service.dart';
import 'package:kolamkari/ui/play/games/kolam_puzzle_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Kolam Puzzle Game Tier & Candidate Logic', () {
    test('Difficulty tiers define correct grid dimensions', () {
      expect(PuzzleDifficultyTier.beginner.gridSize, 2);
      expect(PuzzleDifficultyTier.skilled.gridSize, 3);
      expect(PuzzleDifficultyTier.master.gridSize, 3);
    });

    test('Candidate pieces adhere to authentic library assets', () {
      final validAssets = KolamImageLibrary.allDesigns.map((d) => d.assetPath).toSet();
      expect(validAssets.length, 10);

      // Verify a candidate piece can be instantiated with authentic assets
      const piece = PuzzleCandidatePiece(
        id: 'test_1',
        designId: 'kolam_img_1',
        assetPath: 'assets/kolam/kolam_1.jpeg',
        row: 0,
        col: 0,
        gridSize: 2,
        isCorrect: true,
        explanation: 'Authentic piece',
      );

      expect(validAssets.contains(piece.assetPath), isTrue);
      expect(piece.isCorrect, isTrue);
    });
  });

  group('Kolam Puzzle Screen Widget Tests', () {
    late StorageService storage;

    setUp(() {
      storage = StorageService();
    });

    testWidgets('Renders puzzle board with masked gap and 4 candidate cards', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            storageServiceProvider.overrideWithValue(storage),
          ],
          child: const MaterialApp(
            home: KolamPuzzleScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Verify title & tier buttons
      expect(find.text('Kolam Missing Piece Puzzle'), findsOneWidget);
      expect(find.text('Tier 1 (2x2)'), findsOneWidget);
      expect(find.text('Tier 2 (3x3)'), findsOneWidget);
      expect(find.text('Tier 3 (Master)'), findsOneWidget);

      // Verify header and XP reward tag
      expect(find.text('+50 XP'), findsOneWidget);

      // Verify 4 candidate options (A, B, C, D)
      expect(find.text('A'), findsOneWidget);
      expect(find.text('B'), findsOneWidget);
      expect(find.text('C'), findsOneWidget);
      expect(find.text('D'), findsOneWidget);

      // Verify action button
      expect(find.text('Verify Missing Piece'), findsOneWidget);
    });

    testWidgets('Tapping another tier switches difficulty mode', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: KolamPuzzleScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Tap Tier 2 button
      final tier2Button = find.text('Tier 2 (3x3)');
      expect(tier2Button, findsOneWidget);
      await tester.tap(tier2Button);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // 4 candidates still present for the new puzzle
      expect(find.text('A'), findsOneWidget);
      expect(find.text('B'), findsOneWidget);
      expect(find.text('C'), findsOneWidget);
      expect(find.text('D'), findsOneWidget);
    });

    testWidgets('Selecting a candidate and pressing verify submits puzzle answer', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            storageServiceProvider.overrideWithValue(storage),
          ],
          child: const MaterialApp(
            home: KolamPuzzleScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Tap candidate A
      await tester.tap(find.text('A'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Tap Verify Missing Piece
      await tester.tap(find.text('Verify Missing Piece'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Either won or incorrect choice feedback is displayed
      final wonFinder = find.text('Kolam Symmetry Restored! (+50 XP)');
      final incorrectFinder = find.text('Incorrect Choice');
      expect(wonFinder.evaluate().isNotEmpty || incorrectFinder.evaluate().isNotEmpty, isTrue);
    });
  });
}
