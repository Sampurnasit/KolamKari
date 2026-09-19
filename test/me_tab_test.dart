import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:kolamkari/data/models/user_profile.dart';
import 'package:kolamkari/data/models/xp_history_event.dart';
import 'package:kolamkari/providers/app_providers.dart';
import 'package:kolamkari/services/gamification_service.dart';
import 'package:kolamkari/services/storage_service.dart';
import 'package:kolamkari/ui/me/me_profile_screen.dart';

void main() {
  group('GamificationService Level Calculation Tests', () {
    test('Calculates level, title, and XP thresholds correctly', () {
      // Level 1: 0 - 149
      final (l1, title1, cur1, next1) = GamificationService.calculateLevel(50);
      expect(l1, equals(1));
      expect(title1, equals('Kolam Explorer'));
      expect(cur1, equals(0));
      expect(next1, equals(150));

      // Level 3: 350 - 649
      final (l3, title3, cur3, next3) = GamificationService.calculateLevel(450);
      expect(l3, equals(3));
      expect(title3, equals('Kolam Player'));
      expect(cur3, equals(350));
      expect(next3, equals(650));

      // Level 8: 3000+
      final (l8, title8, cur8, next8) = GamificationService.calculateLevel(3500);
      expect(l8, equals(8));
      expect(title8, equals('Heritage Keeper'));
      expect(cur8, equals(3000));
      expect(next8, equals(3000));
    });
  });

  group('ME Profile Screen Widget Tests', () {
    late StorageService storage;

    setUp(() {
      storage = StorageService();
    });

    Widget createTestWidget({
      UserProfile? profileOverride,
      List<XpHistoryEvent>? historyOverride,
      Set<String>? completedDatesOverride,
    }) {
      final defaultProfile = profileOverride ??
          UserProfile(
            xp: 420,
            level: 3,
            levelTitle: 'Kolam Player',
            currentStreak: 5,
            longestStreak: 12,
            lastChallengeDate: DateFormat('yyyy-MM-dd').format(DateTime.now()),
            memoryGamesWon: 8,
            puzzlesCompleted: 14,
            symmetryChallengesSolved: 20, // Unlocks symmetry_seeker (target: 20)
            kolamsCreated: 3,
            learnModulesCompleted: 2, // Unlocks first_step (target: 1)
            badges: [
              const BadgeItem(
                id: 'first_step',
                title: 'First Step',
                description: 'Complete your first Heritage Learn module.',
                iconEmoji: '🌱',
                unlocked: true,
                currentProgress: 2,
                targetProgress: 1,
              ),
              const BadgeItem(
                id: 'memory_master',
                title: 'Memory Master',
                description: 'Complete 20 Kolam Memory challenges.',
                iconEmoji: '🧠',
                unlocked: false,
                currentProgress: 8,
                targetProgress: 20,
              ),
              const BadgeItem(
                id: 'puzzle_solver',
                title: 'Puzzle Solver',
                description: 'Complete 25 Kolam reconstruction puzzles.',
                iconEmoji: '🧩',
                unlocked: false,
                currentProgress: 14,
                targetProgress: 25,
              ),
              const BadgeItem(
                id: 'symmetry_seeker',
                title: 'Symmetry Seeker',
                description: 'Solve 20 symmetry challenges correctly.',
                iconEmoji: '🌀',
                unlocked: true,
                currentProgress: 20,
                targetProgress: 20,
              ),
              const BadgeItem(
                id: 'kolam_creator',
                title: 'Kolam Creator',
                description: 'Draw and save 10 original Kolams in Studio.',
                iconEmoji: '🎨',
                unlocked: false,
                currentProgress: 3,
                targetProgress: 10,
              ),
              const BadgeItem(
                id: 'heritage_explorer',
                title: 'Heritage Explorer',
                description: 'Complete all 6 core Heritage learning topics.',
                iconEmoji: '📚',
                unlocked: false,
                currentProgress: 2,
                targetProgress: 6,
              ),
              const BadgeItem(
                id: 'kolam_streak',
                title: 'Kolam Streak',
                description: 'Maintain a 7-day daily challenge streak.',
                iconEmoji: '🔥',
                unlocked: false,
                currentProgress: 5,
                targetProgress: 7,
              ),
            ],
          );

      final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final yesterdayStr = DateFormat('yyyy-MM-dd').format(DateTime.now().subtract(const Duration(days: 1)));

      final defaultHistory = historyOverride ??
          [
            XpHistoryEvent(
              id: 'event_1',
              title: 'Daily Challenge Completed',
              description: 'Completed today challenge',
              xpEarned: 100,
              timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
              type: XpEventType.challengeCompleted,
            ),
            XpHistoryEvent(
              id: 'event_2',
              title: 'Kolam Memory Game Won',
              description: 'Eulerian Sikku Vine memorized',
              xpEarned: 50,
              timestamp: DateTime.now().subtract(const Duration(hours: 2)),
              type: XpEventType.gameWon,
            ),
            XpHistoryEvent(
              id: 'event_3',
              title: 'Original Kolam Created: Temple Sanctum',
              description: '7x7 Grid • Saved in Studio',
              xpEarned: 40,
              timestamp: DateTime.now().subtract(const Duration(days: 1)),
              type: XpEventType.kolamCreated,
            ),
            XpHistoryEvent(
              id: 'event_4',
              title: 'Read Heritage Topic: Sikku Mathematics',
              description: 'Eulerian graphs and pulli loops',
              xpEarned: 20,
              timestamp: DateTime.now().subtract(const Duration(days: 2)),
              type: XpEventType.learnModule,
            ),
          ];

      final defaultCompletedDates = completedDatesOverride ?? {todayStr, yesterdayStr};

      return ProviderScope(
        overrides: [
          storageServiceProvider.overrideWithValue(storage),
          userProfileProvider.overrideWith((ref) => MockUserProfileNotifier(defaultProfile)),
          completedChallengeDatesProvider.overrideWithValue(defaultCompletedDates),
          progressHistoryProvider.overrideWithValue(defaultHistory),
        ],
        child: const MaterialApp(
          home: MeProfileScreen(),
        ),
      );
    }

    testWidgets('Renders XP and Level section with current XP, rank title, and progress bar', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Verify app bar title
      expect(find.text('My Heritage Sanctuary'), findsOneWidget);

      // Verify level emblem and title
      expect(find.text('LVL'), findsOneWidget);
      expect(find.text('3'), findsWidgets);
      expect(find.text('Kolam Player'), findsOneWidget);
      expect(find.text('Level 3'), findsOneWidget);
      expect(find.text('420 Heritage XP'), findsOneWidget);

      // Verify progress to next rank
      expect(find.text('Next Rank: Kolam Creator'), findsOneWidget);
      expect(find.text('420 / 650 XP'), findsOneWidget);
      expect(find.textContaining('XP needed to advance'), findsOneWidget);
    });

    testWidgets('Renders Streak section with current streak, longest streak, and 28-day heatmap', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Sacred Practice Streaks'), findsOneWidget);
      expect(find.text('5 Days'), findsOneWidget);
      expect(find.text('Current Streak'), findsOneWidget);
      expect(find.text('12 Days'), findsOneWidget);
      expect(find.text('Longest Streak'), findsOneWidget);

      // Verify 28-Day heatmap
      expect(find.text('28-Day Challenge Heatmap'), findsOneWidget);
      expect(find.text('Completed Challenge'), findsOneWidget);
      expect(find.text('Today'), findsOneWidget);
      expect(find.text('Rest Day'), findsOneWidget);
    });

    testWidgets('Renders all 7 badges in the grid with locked and unlocked states', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Heritage Badges'), findsOneWidget);
      expect(find.text('2 of 7 Unlocked'), findsOneWidget);

      // Verify all 7 badges exist
      expect(find.text('First Step'), findsOneWidget);
      expect(find.text('Memory Master'), findsOneWidget);
      expect(find.text('Puzzle Solver'), findsOneWidget);
      expect(find.text('Symmetry Seeker'), findsOneWidget);
      expect(find.text('Kolam Creator'), findsOneWidget);
      expect(find.text('Heritage Explorer'), findsOneWidget);
      expect(find.text('Kolam Streak'), findsOneWidget);

      // Verify unlocked tags vs locked progress fractions
      expect(find.text('Unlocked'), findsWidgets);
      expect(find.text('8/20'), findsOneWidget); // Memory Master progress
      expect(find.text('14/25'), findsOneWidget); // Puzzle Solver progress
      expect(find.text('3/10'), findsOneWidget); // Kolam Creator progress
      expect(find.text('5/7'), findsOneWidget); // Kolam Streak progress
    });

    testWidgets('Tapping a locked badge opens criteria modal with progress and remaining count', (tester) async {
      tester.view.physicalSize = const Size(800, 3200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Tap locked badge: Memory Master (8 of 20)
      await tester.tap(find.text('Memory Master'));
      await tester.pumpAndSettle();

      // Verify modal sheet appears with unlock criteria and progress
      expect(find.text('Unlock Criteria'), findsOneWidget);
      expect(find.text('Complete 20 Kolam Memory challenges.'), findsWidgets);
      expect(find.text('Progress: 8 / 20'), findsOneWidget);
      expect(find.text('40%'), findsOneWidget);
      expect(find.textContaining('Complete 12 more to unlock'), findsOneWidget);
      expect(find.text('Locked • In Progress'), findsOneWidget);

      // Close modal
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
    });

    testWidgets('Tapping an unlocked badge opens modal confirming mastery', (tester) async {
      tester.view.physicalSize = const Size(800, 3200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Tap unlocked badge: First Step
      await tester.tap(find.text('First Step'));
      await tester.pumpAndSettle();

      expect(find.text('Unlocked • Heritage Achievement'), findsOneWidget);
      expect(find.text('Complete your first Heritage Learn module.'), findsWidgets);
      expect(find.text('Progress: 2 / 1'), findsOneWidget);
      expect(find.text('100%'), findsOneWidget);

      // Close modal
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
    });

    testWidgets('Renders Progress History with recent XP-earning events', (tester) async {
      tester.view.physicalSize = const Size(800, 3200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Recent Heritage Milestones'), findsOneWidget);
      expect(find.text('4 Events'), findsOneWidget);

      // Verify individual event titles and XP tags
      expect(find.text('Daily Challenge Completed'), findsOneWidget);
      expect(find.text('+100 XP'), findsOneWidget);

      expect(find.text('Kolam Memory Game Won'), findsOneWidget);
      expect(find.text('+50 XP'), findsOneWidget);

      expect(find.text('Original Kolam Created: Temple Sanctum'), findsOneWidget);
      expect(find.text('+40 XP'), findsOneWidget);

      expect(find.text('Read Heritage Topic: Sikku Mathematics'), findsOneWidget);
      expect(find.text('+20 XP'), findsOneWidget);
    });

    testWidgets('Expands 8 Heritage Ranks Guide to inspect all level tiers', (tester) async {
      tester.view.physicalSize = const Size(800, 3200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('View All 8 Heritage Ranks'), findsOneWidget);

      // Tap expansion tile
      await tester.tap(find.text('View All 8 Heritage Ranks'));
      await tester.pumpAndSettle();

      expect(find.text('Heritage Keeper'), findsWidgets);
      expect(find.text('3000 XP'), findsOneWidget);
      expect(find.text('Symmetry Seeker'), findsWidgets); // Title and badge
    });
  });
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
