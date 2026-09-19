import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/storage_service.dart';
import '../services/gamification_service.dart';
import '../services/analysis_service.dart';
import '../services/daily_challenge_service.dart';
import '../data/models/user_profile.dart';
import '../data/models/saved_kolam.dart';
import '../data/models/learn_module.dart';
import '../data/models/daily_challenge.dart';
import '../data/models/xp_history_event.dart';
import '../data/seed/heritage_seed_data.dart';

// Service singletons
final storageServiceProvider = Provider<StorageService>((ref) {
  throw UnimplementedError('StorageService must be overridden in main()');
});

final analysisServiceProvider = Provider<AnalysisService>((ref) {
  return LocalGeometryAnalyzer();
});

final gamificationServiceProvider = Provider<GamificationService>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return GamificationService(storage);
});

final dailyChallengeServiceProvider = Provider<DailyChallengeService>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return DailyChallengeService(storage);
});

// User Profile StateNotifier for reactive UI updates
class UserProfileNotifier extends StateNotifier<UserProfile> {
  final GamificationService _gamificationService;
  final DailyChallengeService? _dailyChallengeService;

  UserProfileNotifier(this._gamificationService, [this._dailyChallengeService])
      : super(_gamificationService.profile);

  void refresh() {
    state = _gamificationService.profile;
  }

  Future<void> awardXp(int xp, [String? reason]) async {
    await _gamificationService.awardXp(xp, reason);
    refresh();
  }

  Future<void> onLearnModuleCompleted(String moduleId) async {
    await _gamificationService.onLearnModuleCompleted(moduleId);
    refresh();
  }

  Future<void> onQuizCompleted(int score, int total) async {
    await _gamificationService.onQuizCompleted(score: score, total: total);
    // Sunday daily challenge auto-completion
    if (_dailyChallengeService != null && score >= (total * 0.6).ceil()) {
      if (_dailyChallengeService.matchesTodayChallenge(type: ChallengeType.heritageQuiz)) {
        await _gamificationService.onDailyChallengeCompleted();
      }
    }
    refresh();
  }

  Future<void> onMemoryGameWon({int difficulty = 1}) async {
    await _gamificationService.onMemoryGameWon();
    // Monday or Thursday daily challenge auto-completion
    if (_dailyChallengeService != null) {
      if (_dailyChallengeService.matchesTodayChallenge(type: ChallengeType.observeRecreate) ||
          _dailyChallengeService.matchesTodayChallenge(type: ChallengeType.memoryChallenge, difficulty: difficulty)) {
        await _gamificationService.onDailyChallengeCompleted();
      }
    }
    refresh();
  }

  Future<void> onPuzzleCompleted() async {
    await _gamificationService.onPuzzleCompleted();
    // Tuesday daily challenge auto-completion
    if (_dailyChallengeService != null) {
      if (_dailyChallengeService.matchesTodayChallenge(type: ChallengeType.completePattern)) {
        await _gamificationService.onDailyChallengeCompleted();
      }
    }
    refresh();
  }

  Future<void> onSymmetrySolved() async {
    await _gamificationService.onSymmetrySolved();
    // Wednesday daily challenge auto-completion
    if (_dailyChallengeService != null) {
      if (_dailyChallengeService.matchesTodayChallenge(type: ChallengeType.identifySymmetry)) {
        await _gamificationService.onDailyChallengeCompleted();
      }
    }
    refresh();
  }

  Future<void> onPatternConstructionWon() async {
    // Friday daily challenge auto-completion
    if (_dailyChallengeService != null) {
      if (_dailyChallengeService.matchesTodayChallenge(type: ChallengeType.buildUsingTiles)) {
        await _gamificationService.onDailyChallengeCompleted();
      }
    }
    refresh();
  }

  Future<void> onKolamCreated({bool hasAnalysis = false}) async {
    await _gamificationService.onKolamCreated();
    // Saturday daily challenge auto-completion (requires save + analysis)
    if (_dailyChallengeService != null && hasAnalysis) {
      if (_dailyChallengeService.matchesTodayChallenge(type: ChallengeType.createYourOwn, hasAnalysis: true)) {
        await _gamificationService.onDailyChallengeCompleted();
      }
    }
    refresh();
  }

  Future<void> onKolamAnalysed() async {
    await _gamificationService.onKolamAnalysed();
    refresh();
  }

  Future<bool> onDailyChallengeCompleted([DateTime? customDate]) async {
    final success = await _gamificationService.onDailyChallengeCompleted(customDate);
    refresh();
    return success;
  }
}

final userProfileProvider = StateNotifierProvider<UserProfileNotifier, UserProfile>((ref) {
  final gamification = ref.watch(gamificationServiceProvider);
  final dailyChallenge = ref.watch(dailyChallengeServiceProvider);
  return UserProfileNotifier(gamification, dailyChallenge);
});

// Learn Modules Provider with reactive completed status
final learnModulesProvider = StateProvider<List<LearnModule>>((ref) {
  final storage = ref.watch(storageServiceProvider);
  final completedIds = storage.getCompletedModuleIds().toSet();

  return HeritageSeedData.initialModules.map((m) {
    return m.copyWith(completed: completedIds.contains(m.id));
  }).toList();
});

// Saved Kolams Provider
class SavedKolamsNotifier extends StateNotifier<List<SavedKolam>> {
  final StorageService _storage;

  SavedKolamsNotifier(this._storage) : super(_storage.getSavedKolams());

  void refresh() {
    state = _storage.getSavedKolams();
  }

  Future<void> save(SavedKolam kolam) async {
    await _storage.saveKolam(kolam);
    refresh();
  }

  Future<void> update(SavedKolam kolam) async {
    await _storage.saveKolam(kolam);
    refresh();
  }

  Future<void> rename(String id, String newName) async {
    final list = _storage.getSavedKolams();
    final index = list.indexWhere((k) => k.id == id);
    if (index != -1) {
      final updated = list[index].copyWith(name: newName);
      await _storage.saveKolam(updated);
      refresh();
    }
  }

  Future<void> delete(String id) async {
    await _storage.deleteKolam(id);
    refresh();
  }
}

final savedKolamsProvider = StateNotifierProvider<SavedKolamsNotifier, List<SavedKolam>>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return SavedKolamsNotifier(storage);
});

// Daily Challenge Provider
final todayChallengeProvider = StateProvider<DailyChallenge>((ref) {
  final challengeService = ref.watch(dailyChallengeServiceProvider);
  return challengeService.getTodaysChallenge();
});

// Completed challenge dates set provider (for heatmap calendar)
final completedChallengeDatesProvider = Provider<Set<String>>((ref) {
  final storage = ref.watch(storageServiceProvider);
  ref.watch(userProfileProvider);
  return storage.getCompletedChallengeDates();
});

// Progress History Provider (recent XP events)
final progressHistoryProvider = Provider<List<XpHistoryEvent>>((ref) {
  final storage = ref.watch(storageServiceProvider);
  ref.watch(userProfileProvider);
  return storage.getAllProgressHistory();
});

// Navigation state
final currentNavIndexProvider = StateProvider<int>((ref) => 0);
