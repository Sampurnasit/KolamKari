import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:kolamkari/data/models/daily_challenge.dart';
import 'package:kolamkari/data/models/learn_module.dart';
import 'package:kolamkari/data/models/user_profile.dart';
import 'package:kolamkari/providers/app_providers.dart';
import 'package:kolamkari/services/daily_challenge_service.dart';
import 'package:kolamkari/services/storage_service.dart';
import 'package:kolamkari/ui/home/home_screen.dart';
import 'package:kolamkari/ui/learn/topic_detail_screen.dart';
import 'package:kolamkari/ui/play/games/memory_game_screen.dart';
import 'package:kolamkari/ui/play/games/kolam_puzzle_screen.dart';
import 'package:kolamkari/ui/play/games/symmetry_game_screen.dart';

class MockDailyChallengeService extends DailyChallengeService {
  MockDailyChallengeService(super.storage);

  int getTodayChallengeCallCount = 0;

  @override
  DailyChallenge getTodaysChallenge([DateTime? customDate]) {
    getTodayChallengeCallCount++;
    return DailyChallenge(
      date: DateFormat('yyyy-MM-dd').format(DateTime.now()),
      title: 'Eulerian Sikku Journey',
      description: 'Observe and recreate the endless cosmic knot.',
      type: ChallengeType.observeRecreate,
      targetModule: 'PLAY',
      culturalNote: 'Endless loops symbolize cosmic harmony.',
      xpAwarded: 100,
      completed: false,
    );
  }
}

class MockUserProfileNotifier extends StateNotifier<UserProfile> implements UserProfileNotifier {
  MockUserProfileNotifier(super.state);

  @override
  Future<void> awardXp(int xp, [String? reason]) async {}

  @override
  Future<bool> onDailyChallengeCompleted([DateTime? customDate]) async => true;

  @override
  Future<void> onKolamAnalysed() async {}

  @override
  Future<void> onKolamCreated({bool hasAnalysis = false}) async {}

  @override
  Future<void> onLearnModuleCompleted(String moduleId) async {}

  @override
  Future<void> onMemoryGameWon({int difficulty = 1}) async {}

  @override
  Future<void> onPatternConstructionWon() async {}

  @override
  Future<void> onPuzzleCompleted() async {}

  @override
  Future<void> onQuizCompleted(int score, int total) async {}

  @override
  void refresh() {}

  @override
  Future<void> onSymmetrySolved() async {}
}

void main() {
  group('HomeScreen Widget Tests', () {
    late StorageService storage;
    late MockDailyChallengeService mockChallengeService;

    final dummyProfile = UserProfile(
      xp: 520,
      level: 4,
      levelTitle: 'Kambi Artisan',
      currentStreak: 7,
      longestStreak: 14,
      lastChallengeDate: DateFormat('yyyy-MM-dd').format(DateTime.now()),
      memoryGamesWon: 5,
      puzzlesCompleted: 8,
      symmetryChallengesSolved: 12,
      kolamsCreated: 2,
      learnModulesCompleted: 3,
      badges: const [
        BadgeItem(
          id: 'first_step',
          title: 'First Step',
          description: 'Read your first module',
          iconEmoji: '🌱',
          unlocked: true,
          targetProgress: 1,
        ),
        BadgeItem(
          id: 'memory_master',
          title: 'Memory Master',
          description: 'Win memory game',
          iconEmoji: '🧠',
          unlocked: true,
          targetProgress: 1,
        ),
        BadgeItem(
          id: 'kolam_streak',
          title: 'Kolam Streak',
          description: '7-day streak',
          iconEmoji: '🔥',
          unlocked: true,
          targetProgress: 7,
        ),
        BadgeItem(
          id: 'puzzle_solver',
          title: 'Puzzle Solver',
          description: 'Complete puzzle',
          iconEmoji: '🧩',
          unlocked: false,
          targetProgress: 1,
        ),
      ],
    );

    final sampleModules = [
      const LearnModule(
        id: 'mod_1',
        title: 'Thresholds of the Sacred',
        subtitle: 'The dawn tradition of threshold Kolams',
        category: 'Heritage & Ritual',
        bodyMarkdown: 'Introduction to sacred thresholds...',
        relatedRegion: 'Tamil Nadu',
        xpReward: 25,
        completed: true,
      ),
      const LearnModule(
        id: 'mod_2',
        title: 'The Pulli Grid Blueprint',
        subtitle: 'Brahma Mudi and matrix geometry',
        category: 'Mathematics & Art',
        bodyMarkdown: 'Understanding 5x5 and 7x7 dot arrays...',
        relatedRegion: 'Thanjavur',
        xpReward: 30,
        completed: false,
      ),
      const LearnModule(
        id: 'mod_3',
        title: 'Sikku Endless Loops',
        subtitle: 'Eulerian paths in rice flour knots',
        category: 'Eulerian Geometry',
        bodyMarkdown: 'Continuous closed loops...',
        relatedRegion: 'Madurai',
        xpReward: 35,
        completed: false,
      ),
    ];

    setUp(() {
      storage = StorageService();
      mockChallengeService = MockDailyChallengeService(storage);
    });

    Widget createTestWidget({
      UserProfile? profile,
      List<LearnModule>? modules,
      int initialNavIndex = 0,
    }) {
      return ProviderScope(
        overrides: [
          storageServiceProvider.overrideWithValue(storage),
          dailyChallengeServiceProvider.overrideWithValue(mockChallengeService),
          userProfileProvider.overrideWith((ref) => MockUserProfileNotifier(profile ?? dummyProfile)),
          learnModulesProvider.overrideWith((ref) => modules ?? sampleModules),
          todayChallengeProvider.overrideWith((ref) => mockChallengeService.getTodaysChallenge()),
        ],
        child: const MaterialApp(
          home: HomeScreen(),
        ),
      );
    }

    testWidgets('Renders Greeting header with time-of-day greeting and streak', (tester) async {
      tester.view.physicalSize = const Size(800, 3200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Verify app bar title
      expect(find.text('KolamKari'), findsOneWidget);

      // Verify subtitle in greeting card
      expect(find.text('Continue your Kolam journey'), findsOneWidget);

      // Verify streak badge inside greeting header
      expect(find.text('7 Day Streak'), findsWidgets);

      // Verify devotional quote
      expect(
        find.text('"Every dawn, the threshold becomes a cosmic prayer written in sacred flour."'),
        findsOneWidget,
      );
    });

    testWidgets('Renders Prominent Daily Challenge Card with action button', (tester) async {
      tester.view.physicalSize = const Size(800, 3200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Eulerian Sikku Journey'), findsOneWidget);
      expect(find.text('Observe and recreate the endless cosmic knot.'), findsOneWidget);
      expect(find.text('+100 XP'), findsWidgets);
      expect(find.text('Start Challenge'), findsOneWidget);
    });

    testWidgets('Continue Learning row renders next incomplete module and navigates on tap', (tester) async {
      tester.view.physicalSize = const Size(800, 3200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Next incomplete module is mod_2
      expect(find.text('Continue Learning'), findsOneWidget);
      expect(find.text('The Pulli Grid Blueprint'), findsOneWidget);
      expect(find.text('Mathematics & Art'), findsOneWidget);
      expect(find.text('+30 XP'), findsOneWidget);

      // Tap on the module card
      await tester.tap(find.text('The Pulli Grid Blueprint'));
      await tester.pumpAndSettle();

      // Verify navigates to TopicDetailScreen
      expect(find.byType(TopicDetailScreen), findsOneWidget);
    });

    testWidgets('Continue Learning renders celebratory state when all modules are completed', (tester) async {
      tester.view.physicalSize = const Size(800, 3200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final allCompletedModules = sampleModules.map((m) => m.copyWith(completed: true)).toList();

      await tester.pumpWidget(createTestWidget(modules: allCompletedModules));
      await tester.pumpAndSettle();

      expect(find.text('All Modules Completed!'), findsOneWidget);
      expect(find.text('You have explored all 8 heritage topics. Take the Heritage Quiz to test your wisdom!'), findsOneWidget);
    });

    testWidgets('Quick Play section displays 3 games (Memory, Puzzle, Symmetry) labels', (tester) async {
      tester.view.physicalSize = const Size(800, 3200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Verify 3 game labels
      expect(find.text('Quick Play'), findsOneWidget);
      expect(find.text('Memory'), findsOneWidget);
      expect(find.text('Observe & Recreate'), findsOneWidget);
      expect(find.text('Puzzle'), findsOneWidget);
      expect(find.text('Missing Piece'), findsOneWidget);
      expect(find.text('Symmetry'), findsOneWidget);
      expect(find.text('Geometry AI'), findsOneWidget);
    });

    testWidgets('Quick Play Memory card launches MemoryGameScreen directly', (tester) async {
      tester.view.physicalSize = const Size(800, 3200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Memory'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(MemoryGameScreen), findsOneWidget);
    });

    testWidgets('Quick Play Puzzle card launches KolamPuzzleScreen directly', (tester) async {
      tester.view.physicalSize = const Size(800, 3200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Puzzle'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(KolamPuzzleScreen), findsOneWidget);
    });

    testWidgets('Quick Play Symmetry card launches SymmetryGameScreen directly', (tester) async {
      tester.view.physicalSize = const Size(800, 3200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Symmetry'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(SymmetryGameScreen), findsOneWidget);
    });

    testWidgets('Your Progress card renders metrics and switches to Me tab on tap', (tester) async {
      tester.view.physicalSize = const Size(800, 3200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            storageServiceProvider.overrideWithValue(storage),
            dailyChallengeServiceProvider.overrideWithValue(mockChallengeService),
            userProfileProvider.overrideWith((ref) => MockUserProfileNotifier(dummyProfile)),
            learnModulesProvider.overrideWith((ref) => sampleModules),
            todayChallengeProvider.overrideWith((ref) => mockChallengeService.getTodaysChallenge()),
          ],
          child: Consumer(
            builder: (context, ref, child) {
              return MaterialApp(
                home: Scaffold(
                  body: Column(
                    children: [
                      Text('Current Tab: ${ref.watch(currentNavIndexProvider)}'),
                      const Expanded(child: HomeScreen()),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify progress summary contents
      expect(find.text('Your Progress'), findsOneWidget);
      expect(find.text('Lvl 4'), findsWidgets);
      expect(find.text('Kambi Artisan'), findsOneWidget);
      expect(find.text('520 XP'), findsOneWidget);
      expect(find.text('7 day streak'), findsOneWidget);
      expect(find.text('3 / 7 Badges'), findsOneWidget);

      // Tap progress card to switch tab to Me (index 4)
      await tester.tap(find.text('Your Progress'));
      await tester.pumpAndSettle();

      // Verify tab index updated
      expect(find.text('Current Tab: 4'), findsOneWidget);
    });

    testWidgets('Creative Studio banner navigates to Create tab (index 3)', (tester) async {
      tester.view.physicalSize = const Size(800, 3200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            storageServiceProvider.overrideWithValue(storage),
            dailyChallengeServiceProvider.overrideWithValue(mockChallengeService),
            userProfileProvider.overrideWith((ref) => MockUserProfileNotifier(dummyProfile)),
            learnModulesProvider.overrideWith((ref) => sampleModules),
            todayChallengeProvider.overrideWith((ref) => mockChallengeService.getTodaysChallenge()),
          ],
          child: Consumer(
            builder: (context, ref, child) {
              return MaterialApp(
                home: Scaffold(
                  body: Column(
                    children: [
                      Text('Active Tab: ${ref.watch(currentNavIndexProvider)}'),
                      const Expanded(child: HomeScreen()),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Open Creative Studio'), findsOneWidget);
      await tester.tap(find.text('Open Creative Studio'));
      await tester.pumpAndSettle();

      expect(find.text('Active Tab: 3'), findsOneWidget);
    });

    testWidgets('Pull-to-refresh triggers Daily Challenge check and shows confirmation SnackBar', (tester) async {
      tester.view.physicalSize = const Size(800, 3200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final initialCallCount = mockChallengeService.getTodayChallengeCallCount;

      // Pull down to trigger RefreshIndicator
      await tester.fling(find.byType(SingleChildScrollView), const Offset(0, 350), 1000);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      // Verify that getTodaysChallenge was called again
      expect(mockChallengeService.getTodayChallengeCallCount, greaterThan(initialCallCount));

      // Verify SnackBar message appears
      expect(
        find.text("Refreshed! Today's challenges and progress are up to date."),
        findsOneWidget,
      );
    });
  });
}
