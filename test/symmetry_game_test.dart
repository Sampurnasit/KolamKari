import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolamkari/data/seed/kolam_patterns_library.dart';
import 'package:kolamkari/providers/app_providers.dart';
import 'package:kolamkari/services/analysis_service.dart';
import 'package:kolamkari/services/storage_service.dart';
import 'package:kolamkari/ui/play/games/symmetry_game_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LocalGeometryAnalyzer Live Symmetry Derivations', () {
    final analyzer = LocalGeometryAnalyzer();

    test('Derives Multiple symmetry for Dihedral D4 patterns', () {
      final pattern = KolamPatternsLibrary.nelliSikku;
      final data = KolamData(
        strokes: pattern.strokes,
        gridSize: 5,
        canvasSize: const Size(350, 350),
      );

      final result = analyzer.analyze(data);
      expect(result.reflectionDetected, isTrue);
      expect(result.rotationalDegree > 0, isTrue);

      // Question 1 derivation logic
      final answer = (result.reflectionDetected && result.rotationalDegree > 0)
          ? 'Multiple'
          : result.reflectionDetected
              ? 'Reflection'
              : result.rotationalDegree > 0
                  ? 'Rotational'
                  : 'Translational';

      expect(answer, 'Multiple');
    });

    test('Derives Rotational symmetry for pure cyclic pinwheel patterns', () {
      final pattern = KolamPatternsLibrary.chakraSwirl;
      final data = KolamData(
        strokes: pattern.strokes,
        gridSize: 5,
        canvasSize: const Size(350, 350),
      );

      final result = analyzer.analyze(data);
      expect(result.rotationalDegree, 90);
      expect(result.rotationalSymmetrySummary, '90°');
    });

    test('Derives Reflection symmetry for Bilateral mirror patterns', () {
      final pattern = KolamPatternsLibrary.kodiVine;
      final data = KolamData(
        strokes: pattern.strokes,
        gridSize: 5,
        canvasSize: const Size(350, 350),
      );

      final result = analyzer.analyze(data);
      expect(result.reflectionDetected, isTrue);
      expect(result.matchingReflectionAxes.contains('Vertical Axis'), isTrue);
    });

    test('Advanced Mode: Vertical reflection reconstructs symmetry verified by analyzer', () {
      final pattern = KolamPatternsLibrary.nelliSikku;
      const center = Offset(175.0, 175.0);

      // Left half strokes
      final leftStrokes = <KolamStroke>[];
      for (final s in pattern.strokes) {
        final leftPts = s.points.where((p) => p.x <= center.dx + 4.0).toList();
        if (leftPts.length >= 2) {
          leftStrokes.add(KolamStroke(points: leftPts, colorValue: s.colorValue, strokeWidth: s.strokeWidth));
        }
      }

      // Reflect across vertical axis (Y-axis)
      final transformedStrokes = <KolamStroke>[];
      for (final s in leftStrokes) {
        final pts = s.points.map((p) => KolamPoint(2 * center.dx - p.x, p.y)).toList();
        transformedStrokes.add(KolamStroke(points: pts, colorValue: s.colorValue, strokeWidth: s.strokeWidth));
      }

      final reconstructedData = KolamData(
        strokes: [...leftStrokes, ...transformedStrokes],
        gridSize: 5,
        canvasSize: const Size(350, 350),
      );

      final result = analyzer.analyze(reconstructedData);
      expect(result.matchingReflectionAxes.contains('Vertical Axis'), isTrue);
    });
  });

  group('Symmetry Game Screen Widget Tests', () {
    testWidgets('Renders Symmetry Game screen with live question and options', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final storage = StorageService();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            storageServiceProvider.overrideWithValue(storage),
          ],
          child: const MaterialApp(
            home: SymmetryGameScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Title & XP tag
      expect(find.text('Kolam Symmetry Discovery'), findsOneWidget);
      expect(find.text('+50 XP'), findsOneWidget);

      // Mode tabs
      expect(find.text('Type'), findsOneWidget);
      expect(find.text('Rotation'), findsOneWidget);
      expect(find.text('Transform (Adv)'), findsOneWidget);

      // Question 1 Title & Options
      expect(find.text('What type of symmetry does this Kolam have?'), findsOneWidget);
      expect(find.text('Reflection'), findsOneWidget);
      expect(find.text('Rotational'), findsOneWidget);
      expect(find.text('Translational'), findsOneWidget);
      expect(find.text('Multiple'), findsOneWidget);
    });

    testWidgets('Switching to Rotation mode displays rotational options', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final storage = StorageService();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            storageServiceProvider.overrideWithValue(storage),
          ],
          child: const MaterialApp(
            home: SymmetryGameScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Tap Rotation tab
      final rotationTab = find.text('Rotation');
      expect(rotationTab, findsOneWidget);
      await tester.tap(rotationTab);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Question 2 Title & Options
      expect(find.text('What is its rotational symmetry?'), findsOneWidget);
      expect(find.text('90°'), findsOneWidget);
      expect(find.text('180°'), findsOneWidget);
      expect(find.text('270°'), findsOneWidget);
      expect(find.text('None'), findsOneWidget);
    });

    testWidgets('Switching to Transform mode displays advanced options and masked half', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final storage = StorageService();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            storageServiceProvider.overrideWithValue(storage),
          ],
          child: const MaterialApp(
            home: SymmetryGameScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Tap Transform (Adv) tab
      final advTab = find.text('Transform (Adv)');
      expect(advTab, findsOneWidget);
      await tester.tap(advTab);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Advanced Question Title & Masked Half
      expect(find.text('Which transformation completes this sacred Kolam?'), findsOneWidget);
      expect(find.text('Masked Half'), findsOneWidget);
      expect(find.text('Reflect across Vertical Axis (Y-axis)'), findsOneWidget);
    });

    testWidgets('Submitting answer triggers live analyzer evaluation and displays diagnostic card', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final storage = StorageService();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            storageServiceProvider.overrideWithValue(storage),
          ],
          child: const MaterialApp(
            home: SymmetryGameScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Tap 'Multiple'
      await tester.tap(find.text('Multiple'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Diagnostic card displayed
      expect(find.textContaining('Live Analyzer Properties:'), findsOneWidget);
    });
  });
}
