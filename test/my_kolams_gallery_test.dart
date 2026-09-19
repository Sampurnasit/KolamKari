import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolamkari/data/models/analysis_result.dart';
import 'package:kolamkari/data/models/saved_kolam.dart';
import 'package:kolamkari/providers/app_providers.dart';
import 'package:kolamkari/services/analysis_service.dart';
import 'package:kolamkari/services/storage_service.dart';
import 'package:kolamkari/ui/create/my_kolams_gallery_screen.dart';

class InMemoryStorageService extends StorageService {
  final Map<String, SavedKolam> _kolams = {};

  InMemoryStorageService([List<SavedKolam>? initial]) {
    if (initial != null) {
      for (final k in initial) {
        _kolams[k.id] = k;
      }
    }
  }

  @override
  List<SavedKolam> getSavedKolams() {
    return _kolams.values.toList();
  }

  @override
  Future<void> saveKolam(SavedKolam kolam) async {
    _kolams[kolam.id] = kolam;
  }

  @override
  Future<void> deleteKolam(String kolamId) async {
    _kolams.remove(kolamId);
  }
}

void main() {
  final sampleStroke = KolamStroke(
    points: const [KolamPoint(100, 100), KolamPoint(200, 200)],
    colorValue: 0xFFFFFFFF,
  );
  final sampleStrokeJson = jsonEncode([sampleStroke.toJson()]);

  final sampleAnalysis = const AnalysisResult(
    symmetryType: SymmetryType.dihedralD4,
    rotationalDegree: 90,
    rotationalSymmetrySummary: '90°',
    reflectionDetected: true,
    reflectionAxesCount: 4,
    matchingReflectionAxes: ['Vertical Axis', 'Horizontal Axis'],
    complexityScore: 75,
    gridSize: '7x7',
    closedLoopCount: 3,
    strokeCount: 1,
    intersectionCount: 0,
    patternDensity: 0.1,
    structureSummary: '7x7 Grid • 3 Closed Loops',
    complexityTier: 'Intricate',
    culturalInterpretation: 'Sacred D4 Mandala balance.',
    formulaBreakdown: {},
  );

  final testKolams = [
    SavedKolam(
      id: 'k1',
      name: 'Morning Lotus Original',
      createdDate: DateTime(2026, 3, 10, 10, 0),
      canvasStrokeData: sampleStrokeJson,
      gridSize: 7,
      complexityScore: 75,
      analysisResult: sampleAnalysis,
    ),
    SavedKolam(
      id: 'k2',
      name: 'Nelli Sikku Traced',
      createdDate: DateTime(2026, 3, 12, 14, 0),
      canvasStrokeData: sampleStrokeJson,
      gridSize: 5,
      complexityScore: 35,
      sourceSampleId: 'sample_nelli_5',
      culturalTag: 'Traced: Nelli Sikku',
    ),
    SavedKolam(
      id: 'k3',
      name: 'Brahma Mudi Original',
      createdDate: DateTime(2026, 3, 14, 9, 30),
      canvasStrokeData: sampleStrokeJson,
      gridSize: 9,
      complexityScore: 88,
    ),
  ];

  group('SavedKolamsNotifier Storage Operations', () {
    test('Can save, rename, and delete kolams in notifier', () async {
      final storage = InMemoryStorageService(testKolams);
      final notifier = SavedKolamsNotifier(storage);

      expect(notifier.state.length, 3);

      // Rename k1
      await notifier.rename('k1', 'Renamed Morning Lotus');
      expect(notifier.state.firstWhere((k) => k.id == 'k1').name, 'Renamed Morning Lotus');

      // Delete k2
      await notifier.delete('k2');
      expect(notifier.state.length, 2);
      expect(notifier.state.any((k) => k.id == 'k2'), isFalse);
    });
  });

  group('MyKolamsGalleryScreen Widget Tests', () {
    testWidgets('Renders empty state when no Kolams are saved', (tester) async {
      final storage = InMemoryStorageService([]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            storageServiceProvider.overrideWithValue(storage),
            savedKolamsProvider.overrideWith((ref) => SavedKolamsNotifier(storage)),
          ],
          child: const MaterialApp(
            home: MyKolamsGalleryScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Your Kolam Gallery is Empty'), findsOneWidget);
      expect(find.text('Draw in Studio'), findsOneWidget);
      expect(find.byIcon(Icons.palette_outlined), findsOneWidget);
    });

    testWidgets('Renders grid of Kolams with complexity pills and filter chips', (tester) async {
      tester.view.physicalSize = const Size(1200, 2000);
      addTearDown(tester.view.resetPhysicalSize);
      final storage = InMemoryStorageService(testKolams);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            storageServiceProvider.overrideWithValue(storage),
            savedKolamsProvider.overrideWith((ref) => SavedKolamsNotifier(storage)),
          ],
          child: const MaterialApp(
            home: MyKolamsGalleryScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check header title and sort button
      expect(find.text('My Saved Kolams'), findsOneWidget);
      expect(find.byIcon(Icons.sort_rounded), findsOneWidget);

      // Check filter chips
      expect(find.text('All (3)'), findsOneWidget);
      expect(find.text('Originals (2)'), findsOneWidget);
      expect(find.text('Traced (1)'), findsOneWidget);

      // Check Kolam cards rendered
      expect(find.text('Morning Lotus Original'), findsOneWidget);
      expect(find.text('Nelli Sikku Traced'), findsOneWidget);
      expect(find.text('Brahma Mudi Original'), findsOneWidget);

      // Check complexity badges: 75 (red >= 70), 35 (green < 40), 88 (red >= 70)
      expect(find.text('75'), findsOneWidget);
      expect(find.text('35'), findsOneWidget);
      expect(find.text('88'), findsOneWidget);
    });

    testWidgets('Filters between All, Originals, and Traced copies', (tester) async {
      final storage = InMemoryStorageService(testKolams);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            storageServiceProvider.overrideWithValue(storage),
            savedKolamsProvider.overrideWith((ref) => SavedKolamsNotifier(storage)),
          ],
          child: const MaterialApp(
            home: MyKolamsGalleryScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap 'Traced (1)' filter
      await tester.tap(find.text('Traced (1)'));
      await tester.pumpAndSettle();

      expect(find.text('Nelli Sikku Traced'), findsOneWidget);
      expect(find.text('Morning Lotus Original'), findsNothing);
      expect(find.text('Brahma Mudi Original'), findsNothing);

      // Tap 'Originals (2)' filter
      await tester.tap(find.text('Originals (2)'));
      await tester.pumpAndSettle();

      expect(find.text('Morning Lotus Original'), findsOneWidget);
      expect(find.text('Brahma Mudi Original'), findsOneWidget);
      expect(find.text('Nelli Sikku Traced'), findsNothing);
    });

    testWidgets('Tapping Kolam card opens detail dialog with AnalysisResult and replay button', (tester) async {
      tester.view.physicalSize = const Size(1200, 2000);
      addTearDown(tester.view.resetPhysicalSize);
      final storage = InMemoryStorageService(testKolams);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            storageServiceProvider.overrideWithValue(storage),
            savedKolamsProvider.overrideWith((ref) => SavedKolamsNotifier(storage)),
          ],
          child: const MaterialApp(
            home: MyKolamsGalleryScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap on Morning Lotus card
      await tester.tap(find.text('Morning Lotus Original'));
      await tester.pumpAndSettle();

      // Check detail dialog contents
      expect(find.text('Sacred Geometry Analysis'), findsOneWidget);
      expect(find.text('7x7 Grid • 3 Closed Loops'), findsOneWidget);
      expect(find.text('Dihedral D4 (Mandala)'), findsOneWidget);
      expect(find.text('Original Studio Creation'), findsOneWidget);
      expect(find.text('Watch how this was drawn'), findsOneWidget);
      expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
      expect(find.byIcon(Icons.delete_outline_rounded), findsOneWidget);
    });

    testWidgets('Rename action opens rename dialog and updates Kolam name', (tester) async {
      tester.view.physicalSize = const Size(1200, 2000);
      addTearDown(tester.view.resetPhysicalSize);
      final storage = InMemoryStorageService(testKolams);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            storageServiceProvider.overrideWithValue(storage),
            savedKolamsProvider.overrideWith((ref) => SavedKolamsNotifier(storage)),
          ],
          child: const MaterialApp(
            home: MyKolamsGalleryScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Open detail dialog
      await tester.tap(find.text('Morning Lotus Original'));
      await tester.pumpAndSettle();

      // Tap rename icon
      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pumpAndSettle();

      expect(find.text('Rename Kolam'), findsOneWidget);

      // Enter new name and save
      await tester.enterText(find.byType(TextField), 'Twilight Lotus Sunrise');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Verify renamed in storage
      expect(find.text('Twilight Lotus Sunrise'), findsOneWidget);
    });

    testWidgets('Delete action shows confirmation dialog before deleting', (tester) async {
      tester.view.physicalSize = const Size(1200, 2000);
      addTearDown(tester.view.resetPhysicalSize);
      final storage = InMemoryStorageService(testKolams);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            storageServiceProvider.overrideWithValue(storage),
            savedKolamsProvider.overrideWith((ref) => SavedKolamsNotifier(storage)),
          ],
          child: const MaterialApp(
            home: MyKolamsGalleryScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Open detail dialog for k2
      await tester.tap(find.text('Nelli Sikku Traced'));
      await tester.pumpAndSettle();

      // Tap delete icon in detail dialog
      await tester.tap(find.byIcon(Icons.delete_outline_rounded));
      await tester.pumpAndSettle();

      // Check confirmation dialog
      expect(find.text('Delete Kolam?'), findsOneWidget);
      expect(find.text('Are you sure you want to delete "Nelli Sikku Traced"? This action cannot be undone.'), findsOneWidget);

      // Confirm delete
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      // Verify item deleted
      expect(find.text('Nelli Sikku Traced'), findsNothing);
      expect(find.text('All (2)'), findsOneWidget);
    });
  });
}
