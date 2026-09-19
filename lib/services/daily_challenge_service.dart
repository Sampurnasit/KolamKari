import 'package:intl/intl.dart';
import '../data/models/daily_challenge.dart';
import 'storage_service.dart';

class DailyChallengeService {
  final StorageService _storage;

  DailyChallengeService(this._storage);

  DailyChallenge getTodaysChallenge([DateTime? customDate]) {
    final now = customDate ?? DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(now);
    final userProfile = _storage.loadUserProfile();
    final isCompletedInProfile = userProfile.lastChallengeDate == todayStr;

    // Check if saved state exists in storage
    final existing = _storage.getDailyChallengeForDate(todayStr);
    if (existing != null) {
      if (isCompletedInProfile && !existing.completed) {
        final synced = existing.copyWith(completed: true);
        _storage.saveDailyChallenge(synced);
        return synced;
      }
      return existing;
    }

    // Generate deterministic challenge based on weekday (1 = Mon ... 7 = Sun)
    final template = _getTemplateForWeekday(now.weekday, todayStr)
        .copyWith(completed: isCompletedInProfile);
    _storage.saveDailyChallenge(template);
    return template;
  }

  DailyChallenge getChallengeForDate(DateTime date) {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    final existing = _storage.getDailyChallengeForDate(dateStr);
    if (existing != null) {
      return existing;
    }
    final template = _getTemplateForWeekday(date.weekday, dateStr);
    _storage.saveDailyChallenge(template);
    return template;
  }

  /// Checks whether an action completed during normal browsing satisfies today's challenge.
  bool matchesTodayChallenge({
    required ChallengeType type,
    int? difficulty,
    bool? hasAnalysis,
    DateTime? customDate,
  }) {
    final todayChallenge = getTodaysChallenge(customDate);
    if (todayChallenge.completed) return false;

    if (todayChallenge.type != type) return false;

    // Specific constraints:
    if (type == ChallengeType.memoryChallenge && (difficulty ?? 1) < 2) {
      // Thursday's memory challenge requires harder difficulty (tier >= 2)
      return false;
    }

    if (type == ChallengeType.createYourOwn && hasAnalysis != true) {
      // Saturday's challenge requires save + analysis
      return false;
    }

    return true;
  }

  DailyChallenge _getTemplateForWeekday(int weekday, String dateStr) {
    switch (weekday) {
      case DateTime.monday:
        return DailyChallenge(
          date: dateStr,
          type: ChallengeType.observeRecreate,
          title: 'Monday: Observe & Recreate',
          description: 'Memorize the dawn 5x5 Brahma Mudi pattern and reconstruct it faithfully.',
          targetModule: 'PLAY',
          culturalNote: 'Mondays are dedicated to Somavara cleansing; simple rhythmic patterns center the spirit.',
        );
      case DateTime.tuesday:
        return DailyChallenge(
          date: dateStr,
          type: ChallengeType.completePattern,
          title: 'Tuesday: Complete the Pattern',
          description: 'A sacred Kolam is missing a vital quadrant. Identify the matching segment.',
          targetModule: 'PLAY',
          culturalNote: 'Tuesdays honor divine Shakti; patterns feature bold red borders and protective motifs.',
        );
      case DateTime.wednesday:
        return DailyChallenge(
          date: dateStr,
          type: ChallengeType.identifySymmetry,
          title: 'Wednesday: Identify Symmetry',
          description: 'Discover the hidden reflection planes and rotational order of a traditional mandala.',
          targetModule: 'PLAY',
          culturalNote: 'Wednesday celebrates Budha (intellect and geometry), reflected in analytical symmetry.',
        );
      case DateTime.thursday:
        return DailyChallenge(
          date: dateStr,
          type: ChallengeType.memoryChallenge,
          title: 'Thursday: Memory Mastery',
          description: 'High-speed challenge: memorize an intricate 7x7 Sikku Kolam in under 5 seconds!',
          targetModule: 'PLAY',
          culturalNote: 'Thursday honors the Guru; masters recall hundreds of intricate matrices without hesitation.',
        );
      case DateTime.friday:
        return DailyChallenge(
          date: dateStr,
          type: ChallengeType.buildUsingTiles,
          title: 'Friday: Sacred Tile Assembly',
          description: 'Assemble 16 traditional geometric tile primitives to reconstruct the target lotus.',
          targetModule: 'PLAY',
          culturalNote: 'Fridays welcome Goddess Lakshmi with grand floral and stepped Padi patterns.',
        );
      case DateTime.saturday:
        return DailyChallenge(
          date: dateStr,
          type: ChallengeType.createYourOwn,
          title: 'Saturday: Create & Analyse',
          description: 'Draw an original Kolam in the Studio with symmetric reflection and run AI analysis.',
          targetModule: 'CREATE',
          culturalNote: 'Saturday invites introspective freehand devotion, testing spatial balance and patience.',
        );
      case DateTime.sunday:
      default:
        return DailyChallenge(
          date: dateStr,
          type: ChallengeType.heritageQuiz,
          title: 'Sunday: Heritage & Ethnomathematics Quiz',
          description: 'Test your scholarly understanding of Kolam history, mathematics, and regional diversity.',
          targetModule: 'LEARN',
          culturalNote: 'Sundays are days of learning, passing down cultural wisdom across generations.',
        );
    }
  }

  Future<void> markChallengeCompleted(DailyChallenge challenge) async {
    final updated = challenge.copyWith(completed: true);
    await _storage.saveDailyChallenge(updated);
  }
}
