import 'package:intl/intl.dart';
import '../data/models/user_profile.dart';
import '../data/models/xp_history_event.dart';
import 'storage_service.dart';

class GamificationService {
  final StorageService _storage;
  UserProfile _currentProfile;

  GamificationService(this._storage) : _currentProfile = const UserProfile() {
    _currentProfile = _storage.loadUserProfile();
    if (_currentProfile.badges.isEmpty) {
      _currentProfile = _currentProfile.copyWith(badges: _initializeDefaultBadges());
      _storage.saveUserProfile(_currentProfile);
    }
  }

  UserProfile get profile => _currentProfile;

  // Level thresholds (documented linear-progressive curve)
  static const Map<int, (int, String)> levelTiers = {
    1: (0, 'Kolam Explorer'),
    2: (150, 'Pattern Learner'),
    3: (350, 'Kolam Player'),
    4: (650, 'Kolam Creator'),
    5: (1050, 'Pattern Explorer'),
    6: (1550, 'Symmetry Seeker'),
    7: (2200, 'Kolam Artist'),
    8: (3000, 'Heritage Keeper'),
  };

  static List<BadgeItem> _initializeDefaultBadges() {
    return [
      const BadgeItem(
        id: 'first_step',
        title: 'First Step',
        description: 'Complete your first Heritage Learn module.',
        iconEmoji: '🌱',
        targetProgress: 1,
      ),
      const BadgeItem(
        id: 'memory_master',
        title: 'Memory Master',
        description: 'Complete 20 Kolam Memory challenges.',
        iconEmoji: '🧠',
        targetProgress: 20,
      ),
      const BadgeItem(
        id: 'puzzle_solver',
        title: 'Puzzle Solver',
        description: 'Complete 25 Kolam reconstruction puzzles.',
        iconEmoji: '🧩',
        targetProgress: 25,
      ),
      const BadgeItem(
        id: 'symmetry_seeker',
        title: 'Symmetry Seeker',
        description: 'Solve 20 symmetry challenges correctly.',
        iconEmoji: '🌀',
        targetProgress: 20,
      ),
      const BadgeItem(
        id: 'kolam_creator',
        title: 'Kolam Creator',
        description: 'Draw and save 10 original Kolams in Studio.',
        iconEmoji: '🎨',
        targetProgress: 10,
      ),
      const BadgeItem(
        id: 'heritage_explorer',
        title: 'Heritage Explorer',
        description: 'Complete all 6 core Heritage learning topics.',
        iconEmoji: '📚',
        targetProgress: 6,
      ),
      const BadgeItem(
        id: 'kolam_streak',
        title: 'Kolam Streak',
        description: 'Maintain a 7-day daily challenge streak.',
        iconEmoji: '🔥',
        targetProgress: 7,
      ),
    ];
  }

  /// Calculates level from XP based on the level curve
  static (int level, String title, int currentLevelXp, int nextLevelXp) calculateLevel(int xp) {
    int lvl = 1;
    for (int i = 8; i >= 1; i--) {
      if (xp >= levelTiers[i]!.$1) {
        lvl = i;
        break;
      }
    }
    final title = levelTiers[lvl]!.$2;
    final currentBase = levelTiers[lvl]!.$1;
    final nextBase = lvl < 8 ? levelTiers[lvl + 1]!.$1 : currentBase;
    return (lvl, title, currentBase, nextBase);
  }

  // --- ACTIONS ---

  Future<void> awardXp(int xpToAdd, [String? reason, XpEventType? type]) async {
    final newXp = _currentProfile.xp + xpToAdd;
    final (newLevel, newTitle, _, _) = calculateLevel(newXp);

    _currentProfile = _currentProfile.copyWith(
      xp: newXp,
      level: newLevel,
      levelTitle: newTitle,
    );
    await _storage.saveUserProfile(_currentProfile);

    if (reason != null && xpToAdd > 0) {
      await _storage.logXpEarned(
        title: reason,
        description: '+$xpToAdd Heritage XP awarded',
        xpEarned: xpToAdd,
        type: type ?? XpEventType.gameWon,
      );
    }
  }

  Future<void> onLearnModuleCompleted(String moduleId) async {
    await _storage.markModuleCompleted(moduleId);
    final completedCount = _storage.getCompletedModuleIds().length;

    // Award +20 XP
    await awardXp(20, 'Read Heritage Topic', XpEventType.learnModule);

    // Update profile stats & badges
    _currentProfile = _currentProfile.copyWith(
      learnModulesCompleted: completedCount,
    );
    _checkAndUpdateBadges();
    await _storage.saveUserProfile(_currentProfile);
  }

  Future<void> onQuizCompleted({required int score, required int total}) async {
    // Award +30 XP for completing quiz
    await awardXp(30, 'Complete Heritage Quiz', XpEventType.quizCompleted);
    _checkAndUpdateBadges();
    await _storage.saveUserProfile(_currentProfile);
  }

  Future<void> onMemoryGameWon() async {
    final count = _currentProfile.memoryGamesWon + 1;
    _currentProfile = _currentProfile.copyWith(memoryGamesWon: count);
    await awardXp(50, 'Win Kolam Memory Game', XpEventType.gameWon);
    _checkAndUpdateBadges();
    await _storage.saveUserProfile(_currentProfile);
  }

  Future<void> onPuzzleCompleted() async {
    final count = _currentProfile.puzzlesCompleted + 1;
    _currentProfile = _currentProfile.copyWith(puzzlesCompleted: count);
    await awardXp(50, 'Complete Kolam Puzzle', XpEventType.gameWon);
    _checkAndUpdateBadges();
    await _storage.saveUserProfile(_currentProfile);
  }

  Future<void> onSymmetrySolved() async {
    final count = _currentProfile.symmetryChallengesSolved + 1;
    _currentProfile = _currentProfile.copyWith(symmetryChallengesSolved: count);
    await awardXp(50, 'Solve Symmetry Challenge', XpEventType.gameWon);
    _checkAndUpdateBadges();
    await _storage.saveUserProfile(_currentProfile);
  }

  Future<void> onKolamCreated() async {
    final count = _currentProfile.kolamsCreated + 1;
    _currentProfile = _currentProfile.copyWith(kolamsCreated: count);
    await awardXp(40, 'Create Original Kolam', XpEventType.kolamCreated);
    _checkAndUpdateBadges();
    await _storage.saveUserProfile(_currentProfile);
  }

  Future<void> onKolamAnalysed() async {
    await awardXp(30, 'Analyse Kolam Geometry', XpEventType.kolamAnalysed);
    await _storage.saveUserProfile(_currentProfile);
  }

  Future<bool> onDailyChallengeCompleted([DateTime? customDate]) async {
    final now = customDate ?? DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(now);
    final todayCalendar = DateTime(now.year, now.month, now.day);

    // If already completed on this calendar day, do not award again
    if (_currentProfile.lastChallengeDate != null) {
      final lastParsed = DateTime.tryParse(_currentProfile.lastChallengeDate!);
      if (lastParsed != null) {
        final lastCalendar = DateTime(lastParsed.year, lastParsed.month, lastParsed.day);
        final diffDays = todayCalendar.difference(lastCalendar).inDays;
        if (diffDays == 0) {
          return false; // Already completed today!
        }
      }
    }

    int streak = 1;
    if (_currentProfile.lastChallengeDate != null) {
      final lastParsed = DateTime.tryParse(_currentProfile.lastChallengeDate!);
      if (lastParsed != null) {
        final lastCalendar = DateTime(lastParsed.year, lastParsed.month, lastParsed.day);
        final diffDays = todayCalendar.difference(lastCalendar).inDays;
        if (diffDays == 1) {
          streak = _currentProfile.currentStreak + 1; // Consecutive day streak
        } else {
          streak = 1; // Day skipped or invalid, reset streak
        }
      }
    }

    final longest = streak > _currentProfile.longestStreak ? streak : _currentProfile.longestStreak;

    _currentProfile = _currentProfile.copyWith(
      currentStreak: streak,
      longestStreak: longest,
      lastChallengeDate: todayStr,
    );

    // +100 XP for Daily Challenge
    await awardXp(100, 'Daily Challenge Completed', XpEventType.challengeCompleted);
    _checkAndUpdateBadges();
    await _storage.saveUserProfile(_currentProfile);

    // Update DailyChallenge record in storage if present
    final challenge = _storage.getDailyChallengeForDate(todayStr);
    if (challenge != null) {
      await _storage.saveDailyChallenge(challenge.copyWith(completed: true));
    }

    return true;
  }

  void _checkAndUpdateBadges() {
    final updatedBadges = _currentProfile.badges.map((badge) {
      int progress = badge.currentProgress;
      switch (badge.id) {
        case 'first_step':
          progress = _currentProfile.learnModulesCompleted >= 1 ? 1 : 0;
          break;
        case 'memory_master':
          progress = _currentProfile.memoryGamesWon;
          break;
        case 'puzzle_solver':
          progress = _currentProfile.puzzlesCompleted;
          break;
        case 'symmetry_seeker':
          progress = _currentProfile.symmetryChallengesSolved;
          break;
        case 'kolam_creator':
          progress = _currentProfile.kolamsCreated;
          break;
        case 'heritage_explorer':
          progress = _currentProfile.learnModulesCompleted;
          break;
        case 'kolam_streak':
          progress = _currentProfile.currentStreak;
          break;
      }

      final isNowUnlocked = progress >= badge.targetProgress;
      return badge.copyWith(
        currentProgress: progress,
        unlocked: isNowUnlocked,
        unlockedAt: (isNowUnlocked && !badge.unlocked) ? DateTime.now() : badge.unlockedAt,
      );
    }).toList();

    _currentProfile = _currentProfile.copyWith(badges: updatedBadges);
  }
}
