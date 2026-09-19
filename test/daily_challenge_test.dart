import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolamkari/data/models/daily_challenge.dart';
import 'package:kolamkari/providers/app_providers.dart';
import 'package:kolamkari/services/daily_challenge_service.dart';
import 'package:kolamkari/services/gamification_service.dart';
import 'package:kolamkari/services/storage_service.dart';
import 'package:kolamkari/ui/common/daily_challenge_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Deterministic Weekly Rotation', () {
    late StorageService storage;
    late DailyChallengeService service;

    setUp(() {
      storage = StorageService();
      service = DailyChallengeService(storage);
    });

    test('Monday (weekday 1) maps to Observe & Recreate', () {
      final monday = DateTime(2026, 9, 21); // Monday
      expect(monday.weekday, DateTime.monday);
      final challenge = service.getChallengeForDate(monday);
      expect(challenge.type, ChallengeType.observeRecreate);
      expect(challenge.title, contains('Observe & Recreate'));
      expect(challenge.targetModule, 'PLAY');
    });

    test('Tuesday (weekday 2) maps to Complete the Pattern', () {
      final tuesday = DateTime(2026, 9, 22); // Tuesday
      expect(tuesday.weekday, DateTime.tuesday);
      final challenge = service.getChallengeForDate(tuesday);
      expect(challenge.type, ChallengeType.completePattern);
      expect(challenge.title, contains('Complete the Pattern'));
      expect(challenge.targetModule, 'PLAY');
    });

    test('Wednesday (weekday 3) maps to Identify Symmetry', () {
      final wednesday = DateTime(2026, 9, 23); // Wednesday
      expect(wednesday.weekday, DateTime.wednesday);
      final challenge = service.getChallengeForDate(wednesday);
      expect(challenge.type, ChallengeType.identifySymmetry);
      expect(challenge.title, contains('Identify Symmetry'));
      expect(challenge.targetModule, 'PLAY');
    });

    test('Thursday (weekday 4) maps to Memory Challenge (Harder)', () {
      final thursday = DateTime(2026, 9, 24); // Thursday
      expect(thursday.weekday, DateTime.thursday);
      final challenge = service.getChallengeForDate(thursday);
      expect(challenge.type, ChallengeType.memoryChallenge);
      expect(challenge.title, contains('Memory'));
      expect(challenge.targetModule, 'PLAY');
    });

    test('Friday (weekday 5) maps to Build Using Tiles', () {
      final friday = DateTime(2026, 9, 25); // Friday
      expect(friday.weekday, DateTime.friday);
      final challenge = service.getChallengeForDate(friday);
      expect(challenge.type, ChallengeType.buildUsingTiles);
      expect(challenge.title, contains('Tile Assembly'));
      expect(challenge.targetModule, 'PLAY');
    });

    test('Saturday (weekday 6) maps to Create Your Own', () {
      final saturday = DateTime(2026, 9, 26); // Saturday
      expect(saturday.weekday, DateTime.saturday);
      final challenge = service.getChallengeForDate(saturday);
      expect(challenge.type, ChallengeType.createYourOwn);
      expect(challenge.title, contains('Create & Analyse'));
      expect(challenge.targetModule, 'CREATE');
    });

    test('Sunday (weekday 7) maps to Heritage Quiz', () {
      final sunday = DateTime(2026, 9, 27); // Sunday
      expect(sunday.weekday, DateTime.sunday);
      final challenge = service.getChallengeForDate(sunday);
      expect(challenge.type, ChallengeType.heritageQuiz);
      expect(challenge.title, contains('Heritage'));
      expect(challenge.targetModule, 'LEARN');
    });
  });

  group('Calendar Streak Tracking & XP Idempotency', () {
    late StorageService storage;
    late GamificationService gamification;

    setUp(() {
      storage = StorageService();
      gamification = GamificationService(storage);
    });

    test('First completion sets streak to 1 and awards +100 XP', () async {
      final day1 = DateTime(2026, 9, 14);
      final initialXp = gamification.profile.xp;

      final success = await gamification.onDailyChallengeCompleted(day1);
      expect(success, isTrue);
      expect(gamification.profile.currentStreak, 1);
      expect(gamification.profile.longestStreak, 1);
      expect(gamification.profile.xp, initialXp + 100);
      expect(gamification.profile.lastChallengeDate, '2026-09-14');
    });

    test('Same-day second completion does not double-award XP or increment streak', () async {
      final day1 = DateTime(2026, 9, 14, 9, 0); // Morning
      final day1Evening = DateTime(2026, 9, 14, 20, 0); // Evening

      await gamification.onDailyChallengeCompleted(day1);
      final xpAfterFirst = gamification.profile.xp;

      final successSecond = await gamification.onDailyChallengeCompleted(day1Evening);
      expect(successSecond, isFalse);
      expect(gamification.profile.currentStreak, 1);
      expect(gamification.profile.xp, xpAfterFirst); // XP untouched
    });

    test('Consecutive day completion increments streak (1 -> 2 -> 3)', () async {
      final day1 = DateTime(2026, 9, 14);
      final day2 = DateTime(2026, 9, 15);
      final day3 = DateTime(2026, 9, 16);

      await gamification.onDailyChallengeCompleted(day1);
      expect(gamification.profile.currentStreak, 1);

      await gamification.onDailyChallengeCompleted(day2);
      expect(gamification.profile.currentStreak, 2);

      await gamification.onDailyChallengeCompleted(day3);
      expect(gamification.profile.currentStreak, 3);
      expect(gamification.profile.longestStreak, 3);
    });

    test('Skipping a day resets streak to 1', () async {
      final day1 = DateTime(2026, 9, 14);
      final day3 = DateTime(2026, 9, 16); // Skipped Sept 15!

      await gamification.onDailyChallengeCompleted(day1);
      expect(gamification.profile.currentStreak, 1);

      await gamification.onDailyChallengeCompleted(day3);
      expect(gamification.profile.currentStreak, 1); // Reset to 1
      expect(gamification.profile.longestStreak, 1); // Peak was 1
    });
  });

  group('Normal Browsing Auto-Completion', () {
    late StorageService storage;
    late GamificationService gamification;
    late DailyChallengeService dailyService;
    late UserProfileNotifier notifier;

    setUp(() {
      storage = StorageService();
      gamification = GamificationService(storage);
      dailyService = DailyChallengeService(storage);
      notifier = UserProfileNotifier(gamification, dailyService);
    });

    test('Matches today challenge correctly for normal browsing', () {
      final monday = DateTime(2026, 9, 21);
      expect(
        dailyService.matchesTodayChallenge(
          type: ChallengeType.observeRecreate,
          customDate: monday,
        ),
        isTrue,
      );

      // Thursday requires difficulty >= 2
      final thursday = DateTime(2026, 9, 24);
      expect(
        dailyService.matchesTodayChallenge(
          type: ChallengeType.memoryChallenge,
          difficulty: 1,
          customDate: thursday,
        ),
        isFalse,
      );
      expect(
        dailyService.matchesTodayChallenge(
          type: ChallengeType.memoryChallenge,
          difficulty: 3,
          customDate: thursday,
        ),
        isTrue,
      );

      // Saturday requires save + analysis
      final saturday = DateTime(2026, 9, 26);
      expect(
        dailyService.matchesTodayChallenge(
          type: ChallengeType.createYourOwn,
          hasAnalysis: false,
          customDate: saturday,
        ),
        isFalse,
      );
      expect(
        dailyService.matchesTodayChallenge(
          type: ChallengeType.createYourOwn,
          hasAnalysis: true,
          customDate: saturday,
        ),
        isTrue,
      );
    });

    test('Winning underlying game via notifier completes today challenge', () async {
      final initialXp = gamification.profile.xp;
      await notifier.onPuzzleCompleted();
      expect(gamification.profile.puzzlesCompleted, 1);
      expect(gamification.profile.xp >= initialXp + 50, isTrue);
    });
  });

  group('DailyChallengeCard Widget Tests', () {
    testWidgets('Renders challenge details, flame streak, XP badge, and button', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final storage = StorageService();

      const testChallenge = DailyChallenge(
        date: '2026-09-19',
        type: ChallengeType.completePattern,
        title: 'Tuesday: Complete the Pattern',
        description: 'A sacred Kolam is missing a vital quadrant. Identify the matching segment.',
        targetModule: 'PLAY',
        culturalNote: 'Tuesdays honor divine Shakti.',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            storageServiceProvider.overrideWithValue(storage),
            todayChallengeProvider.overrideWith((ref) => testChallenge),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: Padding(
                padding: EdgeInsets.all(16),
                child: DailyChallengeCard(),
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Verify flame streak badge
      expect(find.textContaining('Day Streak'), findsOneWidget);
      expect(find.byIcon(Icons.local_fire_department_rounded), findsOneWidget);

      // Verify XP badge
      expect(find.text('+100 XP'), findsOneWidget);

      // Verify Title & Description
      expect(find.text('Tuesday: Complete the Pattern'), findsOneWidget);
      expect(find.textContaining('missing a vital quadrant'), findsOneWidget);

      // Verify Action Button
      expect(find.text('Start Challenge'), findsOneWidget);
    });

    testWidgets('Renders completed state when challenge is completed', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final storage = StorageService();

      const completedChallenge = DailyChallenge(
        date: '2026-09-19',
        type: ChallengeType.completePattern,
        title: 'Tuesday: Complete the Pattern',
        description: 'A sacred Kolam is missing a vital quadrant. Identify the matching segment.',
        targetModule: 'PLAY',
        culturalNote: 'Tuesdays honor divine Shakti.',
        completed: true,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            storageServiceProvider.overrideWithValue(storage),
            todayChallengeProvider.overrideWith((ref) => completedChallenge),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: Padding(
                padding: EdgeInsets.all(16),
                child: DailyChallengeCard(),
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Verify Completed State
      expect(find.text('Earned +100 XP'), findsOneWidget);
      expect(find.text('Completed Today (+100 XP)'), findsOneWidget);
      expect(find.byIcon(Icons.done_all_rounded), findsOneWidget);
    });
  });
}
