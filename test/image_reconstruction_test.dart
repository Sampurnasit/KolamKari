import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolamkari/data/seed/kolam_image_library.dart';
import 'package:kolamkari/ui/play/games/pattern_construction_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Kolam Image Library Asset Verification', () {
    test('Library contains exactly 10 authentic drive images', () {
      expect(KolamImageLibrary.allDesigns.length, 10);
    });

    test('All 10 asset files exist on disk', () {
      for (final design in KolamImageLibrary.allDesigns) {
        final file = File(design.assetPath);
        expect(file.existsSync(), isTrue, reason: '${design.assetPath} should exist');
      }
    });

    test('All designs have valid metadata', () {
      for (final design in KolamImageLibrary.allDesigns) {
        expect(design.id.isNotEmpty, isTrue);
        expect(design.name.isNotEmpty, isTrue);
        expect(design.category.isNotEmpty, isTrue);
        expect(design.culturalLore.isNotEmpty, isTrue);
        expect(design.recommendedGridSize >= 2, isTrue);
      }
    });

    test('Can retrieve design by ID', () {
      final design = KolamImageLibrary.getById('kolam_img_1');
      expect(design.name, contains('Kolam'));
    });
  });

  group('Pattern Construction Widget Test', () {
    testWidgets('Renders game screen with target image and grid tiles', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: PatternConstructionScreen(),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Verify header and UI elements
      expect(find.text('Kolam Reconstruction Game'), findsOneWidget);
      expect(find.text('2x2 (4 pcs)'), findsOneWidget);
      expect(find.text('3x3 (9 pcs)'), findsOneWidget);
      expect(find.textContaining('Piece Tray'), findsOneWidget);

      // Verify grid cells exist
      expect(find.byType(DragTarget<KolamImagePiece>), findsWidgets);
    });

    testWidgets('Switching difficulty changes grid size', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: PatternConstructionScreen(),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Tap 3x3 button
      final btn3x3 = find.text('3x3 (9 pcs)');
      expect(btn3x3, findsOneWidget);
      await tester.tap(btn3x3);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // In 3x3, there are 9 grid targets
      final targets = find.byType(DragTarget<KolamImagePiece>);
      expect(targets, findsNWidgets(9));
    });

    testWidgets('Can toggle ghost guide', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: PatternConstructionScreen(),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      final ghostButton = find.byIcon(Icons.visibility_off_rounded);
      expect(ghostButton, findsOneWidget);
      await tester.tap(ghostButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Ghost button changes icon
      expect(find.byIcon(Icons.visibility_rounded), findsOneWidget);
    });
  });
}
