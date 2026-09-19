import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../data/models/user_profile.dart';
import '../data/models/saved_kolam.dart';
import '../data/models/game_result.dart';
import '../data/models/daily_challenge.dart';
import '../data/models/xp_history_event.dart';

class StorageService {
  static const String _userProfileBoxName = 'kolam_user_profile';
  static const String _savedKolamsBoxName = 'kolam_saved_kolams';
  static const String _completedModulesBoxName = 'kolam_completed_modules';
  static const String _gameResultsBoxName = 'kolam_game_results';
  static const String _dailyChallengesBoxName = 'kolam_daily_challenges';
  static const String _xpEventsBoxName = 'kolam_xp_events';

  late Box _profileBox;
  late Box _savedKolamsBox;
  late Box _completedModulesBox;
  late Box _gameResultsBox;
  late Box _dailyChallengesBox;
  late Box _xpEventsBox;

  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;
    try {
      await Hive.initFlutter();
      _profileBox = await Hive.openBox(_userProfileBoxName);
      _savedKolamsBox = await Hive.openBox(_savedKolamsBoxName);
      _completedModulesBox = await Hive.openBox(_completedModulesBoxName);
      _gameResultsBox = await Hive.openBox(_gameResultsBoxName);
      _dailyChallengesBox = await Hive.openBox(_dailyChallengesBoxName);
      _xpEventsBox = await Hive.openBox(_xpEventsBoxName);
      _isInitialized = true;
    } catch (e) {
      debugPrint('Error initializing Hive storage: $e');
    }
  }

  // --- USER PROFILE ---
  UserProfile loadUserProfile() {
    if (!_isInitialized) return const UserProfile();
    final data = _profileBox.get('profile');
    if (data == null) {
      return const UserProfile();
    }
    try {
      final map = jsonDecode(data as String);
      return UserProfile.fromJson(Map<String, dynamic>.from(map));
    } catch (e) {
      debugPrint('Error decoding user profile: $e');
      return const UserProfile();
    }
  }

  Future<void> saveUserProfile(UserProfile profile) async {
    if (!_isInitialized) return;
    try {
      final jsonStr = jsonEncode(profile.toJson());
      await _profileBox.put('profile', jsonStr);
    } catch (e) {
      debugPrint('Error saving user profile: $e');
    }
  }

  // --- COMPLETED LEARN MODULES ---
  List<String> getCompletedModuleIds() {
    if (!_isInitialized) return [];
    try {
      final raw = _completedModulesBox.get('completed_ids');
      if (raw != null) {
        return List<String>.from(raw);
      }
    } catch (e) {
      debugPrint('Error getting completed modules: $e');
    }
    return [];
  }

  Future<void> markModuleCompleted(String moduleId) async {
    if (!_isInitialized) return;
    try {
      final current = getCompletedModuleIds();
      if (!current.contains(moduleId)) {
        current.add(moduleId);
        await _completedModulesBox.put('completed_ids', current);
      }
    } catch (e) {
      debugPrint('Error marking module completed: $e');
    }
  }

  // --- SAVED KOLAMS ---
  List<SavedKolam> getSavedKolams() {
    if (!_isInitialized) return [];
    try {
      final rawList = _savedKolamsBox.values.toList();
      return rawList.map((item) {
        final map = jsonDecode(item as String);
        return SavedKolam.fromJson(Map<String, dynamic>.from(map));
      }).toList();
    } catch (e) {
      debugPrint('Error getting saved kolams: $e');
      return [];
    }
  }

  Future<void> saveKolam(SavedKolam kolam) async {
    if (!_isInitialized) return;
    try {
      final jsonStr = jsonEncode(kolam.toJson());
      await _savedKolamsBox.put(kolam.id, jsonStr);
    } catch (e) {
      debugPrint('Error saving kolam: $e');
    }
  }

  Future<void> deleteKolam(String kolamId) async {
    if (!_isInitialized) return;
    try {
      await _savedKolamsBox.delete(kolamId);
    } catch (e) {
      debugPrint('Error deleting kolam: $e');
    }
  }

  // --- GAME RESULTS ---
  List<GameResult> getGameResults() {
    if (!_isInitialized) return [];
    try {
      final rawList = _gameResultsBox.values.toList();
      final results = rawList.map((item) {
        final map = jsonDecode(item as String);
        return GameResult.fromJson(Map<String, dynamic>.from(map));
      }).toList();
      results.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return results;
    } catch (e) {
      debugPrint('Error getting game results: $e');
      return [];
    }
  }

  Future<void> recordGameResult(GameResult result) async {
    if (!_isInitialized) return;
    try {
      final jsonStr = jsonEncode(result.toJson());
      await _gameResultsBox.put(result.id, jsonStr);
    } catch (e) {
      debugPrint('Error recording game result: $e');
    }
  }

  // --- DAILY CHALLENGES ---
  DailyChallenge? getDailyChallengeForDate(String dateStr) {
    if (!_isInitialized) return null;
    try {
      final raw = _dailyChallengesBox.get(dateStr);
      if (raw != null) {
        final map = jsonDecode(raw as String);
        return DailyChallenge.fromJson(Map<String, dynamic>.from(map));
      }
    } catch (e) {
      debugPrint('Error getting daily challenge for date: $e');
    }
    return null;
  }

  Future<void> saveDailyChallenge(DailyChallenge challenge) async {
    if (!_isInitialized) return;
    try {
      final jsonStr = jsonEncode(challenge.toJson());
      await _dailyChallengesBox.put(challenge.date, jsonStr);
    } catch (e) {
      debugPrint('Error saving daily challenge: $e');
    }
  }

  List<DailyChallenge> getAllDailyChallenges() {
    if (!_isInitialized) return [];
    try {
      final rawList = _dailyChallengesBox.values.toList();
      return rawList.map((item) {
        final map = jsonDecode(item as String);
        return DailyChallenge.fromJson(Map<String, dynamic>.from(map));
      }).toList();
    } catch (e) {
      debugPrint('Error getting all daily challenges: $e');
      return [];
    }
  }

  Set<String> getCompletedChallengeDates() {
    final set = <String>{};
    for (final c in getAllDailyChallenges()) {
      if (c.completed) set.add(c.date);
    }
    // Also include lastChallengeDate from user profile
    final profile = loadUserProfile();
    if (profile.lastChallengeDate != null) {
      set.add(profile.lastChallengeDate!);
      final last = DateTime.tryParse(profile.lastChallengeDate!);
      if (last != null && profile.currentStreak > 1) {
        for (int i = 1; i < profile.currentStreak; i++) {
          final d = last.subtract(Duration(days: i));
          final y = d.year.toString().padLeft(4, '0');
          final m = d.month.toString().padLeft(2, '0');
          final day = d.day.toString().padLeft(2, '0');
          set.add('$y-$m-$day');
        }
      }
    }
    return set;
  }

  // --- XP HISTORY EVENTS ---
  List<XpHistoryEvent> getXpEvents() {
    if (!_isInitialized) return [];
    try {
      final rawList = _xpEventsBox.values.toList();
      final list = rawList.map((item) {
        final map = jsonDecode(item as String);
        return XpHistoryEvent.fromJson(Map<String, dynamic>.from(map));
      }).toList();
      list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return list;
    } catch (e) {
      debugPrint('Error getting XP events: $e');
      return [];
    }
  }

  Future<void> recordXpEvent(XpHistoryEvent event) async {
    if (!_isInitialized) return;
    try {
      final jsonStr = jsonEncode(event.toJson());
      await _xpEventsBox.put(event.id, jsonStr);
    } catch (e) {
      debugPrint('Error recording XP event: $e');
    }
  }

  Future<void> logXpEarned({
    required String title,
    required String description,
    required int xpEarned,
    required XpEventType type,
    DateTime? timestamp,
  }) async {
    final event = XpHistoryEvent(
      id: const Uuid().v4(),
      title: title,
      description: description,
      xpEarned: xpEarned,
      timestamp: timestamp ?? DateTime.now(),
      type: type,
    );
    await recordXpEvent(event);
  }

  List<XpHistoryEvent> getAllProgressHistory() {
    final events = getXpEvents();
    final eventIds = events.map((e) => e.id).toSet();

    // Incorporate any GameResults not explicitly logged
    for (final gr in getGameResults()) {
      if (!eventIds.contains(gr.id)) {
        String title;
        switch (gr.gameType) {
          case GameType.memoryGame:
            title = 'Kolam Memory Game Won';
            break;
          case GameType.patternConstruction:
            title = 'Tile Reconstruction Solved';
            break;
          case GameType.kolamPuzzle:
            title = 'Kolam Missing Piece Solved';
            break;
          case GameType.symmetryGame:
            title = 'Symmetry Challenge Solved';
            break;
        }
        events.add(XpHistoryEvent(
          id: gr.id,
          title: title,
          description: gr.culturalNote ?? '+${gr.xpEarned} Heritage XP',
          xpEarned: gr.xpEarned,
          timestamp: gr.timestamp,
          type: XpEventType.gameWon,
        ));
        eventIds.add(gr.id);
      }
    }

    // Incorporate any SavedKolams
    for (final sk in getSavedKolams()) {
      final id = 'kolam_${sk.id}';
      if (!eventIds.contains(id)) {
        events.add(XpHistoryEvent(
          id: id,
          title: 'Original Kolam Created: ${sk.name}',
          description: '${sk.gridSize}x${sk.gridSize} Grid • +40 Heritage XP',
          xpEarned: 40,
          timestamp: sk.createdDate,
          type: XpEventType.kolamCreated,
        ));
        eventIds.add(id);
      }
    }

    // Incorporate any DailyChallenges completed
    for (final dc in getAllDailyChallenges().where((c) => c.completed)) {
      final id = 'challenge_${dc.date}';
      if (!eventIds.contains(id)) {
        events.add(XpHistoryEvent(
          id: id,
          title: 'Daily Challenge Completed: ${dc.title}',
          description: dc.culturalNote.isNotEmpty ? dc.culturalNote : '+${dc.xpAwarded} Heritage XP',
          xpEarned: dc.xpAwarded,
          timestamp: DateTime.tryParse(dc.date) ?? DateTime.now(),
          type: XpEventType.challengeCompleted,
        ));
        eventIds.add(id);
      }
    }

    // Sort descending by timestamp
    events.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return events;
  }
}
