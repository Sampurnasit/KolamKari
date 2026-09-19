import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../data/models/daily_challenge.dart';
import '../../providers/app_providers.dart';
import 'animated_flame_badge.dart';
import '../create/create_studio_screen.dart';
import '../learn/heritage_quiz_screen.dart';
import '../play/games/kolam_puzzle_screen.dart';
import '../play/games/memory_game_screen.dart';
import '../play/games/pattern_construction_screen.dart';
import '../play/games/symmetry_game_screen.dart';

class DailyChallengeCard extends ConsumerWidget {
  final DailyChallenge? challenge;

  const DailyChallengeCard({
    super.key,
    this.challenge,
  });

  IconData _getIconForType(ChallengeType type) {
    switch (type) {
      case ChallengeType.observeRecreate:
        return Icons.visibility_rounded;
      case ChallengeType.completePattern:
        return Icons.extension_rounded;
      case ChallengeType.identifySymmetry:
        return Icons.all_inclusive_rounded;
      case ChallengeType.memoryChallenge:
        return Icons.psychology_rounded;
      case ChallengeType.buildUsingTiles:
        return Icons.dashboard_customize_rounded;
      case ChallengeType.createYourOwn:
        return Icons.draw_rounded;
      case ChallengeType.heritageQuiz:
        return Icons.quiz_rounded;
    }
  }

  void _launchChallenge(BuildContext context, WidgetRef ref, DailyChallenge currentChallenge) {
    if (currentChallenge.completed) return;

    final challengeType = currentChallenge.type;

    if (challengeType == ChallengeType.createYourOwn) {
      // Switch to Create Studio tab (index 3 or push screen)
      ref.read(currentNavIndexProvider.notifier).state = 3;
      return;
    }

    Widget screen;
    switch (challengeType) {
      case ChallengeType.observeRecreate:
        screen = MemoryGameScreen(
          isDailyChallenge: true,
          initialDifficulty: 1, // Beginner level (10s preview)
          onChallengeCompleted: () => ref.invalidate(todayChallengeProvider),
        );
        break;

      case ChallengeType.completePattern:
        screen = KolamPuzzleScreen(
          isDailyChallenge: true,
          onChallengeCompleted: () => ref.invalidate(todayChallengeProvider),
        );
        break;

      case ChallengeType.identifySymmetry:
        screen = SymmetryGameScreen(
          isDailyChallenge: true,
          onChallengeCompleted: () => ref.invalidate(todayChallengeProvider),
        );
        break;

      case ChallengeType.memoryChallenge:
        screen = MemoryGameScreen(
          isDailyChallenge: true,
          initialDifficulty: 3, // Harder tier (5s preview, 7x7 grid)
          onChallengeCompleted: () => ref.invalidate(todayChallengeProvider),
        );
        break;

      case ChallengeType.buildUsingTiles:
        screen = PatternConstructionScreen(
          isDailyChallenge: true,
          onChallengeCompleted: () => ref.invalidate(todayChallengeProvider),
        );
        break;

      case ChallengeType.createYourOwn:
        screen = const CreateStudioScreen();
        break;

      case ChallengeType.heritageQuiz:
        screen = HeritageQuizScreen(
          isDailyChallenge: true,
          onChallengeCompleted: () => ref.invalidate(todayChallengeProvider),
        );
        break;
    }

    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final DailyChallenge activeChallenge = challenge ?? ref.watch(todayChallengeProvider);
    final profile = ref.watch(userProfileProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isDone = activeChallenge.completed;

    final icon = _getIconForType(activeChallenge.type);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? (isDone
                  ? [const Color(0xFF1B3125), const Color(0xFF12221A)]
                  : [const Color(0xFF38262C), const Color(0xFF2C1E23)])
              : (isDone
                  ? [const Color(0xFFEAF5EE), const Color(0xFFDFF0E5)]
                  : [const Color(0xFFFBF1E6), const Color(0xFFF7E5D0)]),
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDone ? AppColors.tulsiGreen : AppColors.turmericGold,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Flame Streak + XP Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Current Streak Badge
              Flexible(
                child: AnimatedFlameBadge(
                  streakDays: profile.currentStreak,
                  backgroundColor: isDark ? Colors.black38 : Colors.white.withValues(alpha: 0.85),
                ),
              ),
              const SizedBox(width: 8),

              // XP Reward Tag
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: (isDone ? AppColors.tulsiGreen : AppColors.turmericGold).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isDone ? Icons.check_circle_rounded : Icons.star_rounded,
                      color: isDone ? AppColors.tulsiGreen : AppColors.turmericAmber,
                      size: 15,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isDone ? 'Earned +100 XP' : '+100 XP',
                      style: AppTypography.tagText.copyWith(
                        color: isDone ? AppColors.tulsiGreen : AppColors.turmericAmber,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Icon + Title Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: (isDone ? AppColors.tulsiGreen : AppColors.terracottaRed).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: (isDone ? AppColors.tulsiGreen : AppColors.terracottaRed).withValues(alpha: 0.35),
                  ),
                ),
                child: Icon(
                  icon,
                  color: isDone ? AppColors.tulsiGreen : AppColors.terracottaRed,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activeChallenge.title,
                      style: AppTypography.cardTitle.copyWith(fontSize: 15.5),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      activeChallenge.description,
                      style: AppTypography.bodyText.copyWith(fontSize: 12.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Launch Action Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: isDone
                  ? null
                  : () {
                      _launchChallenge(context, ref, activeChallenge);
                    },
              icon: Icon(
                isDone ? Icons.done_all_rounded : Icons.play_arrow_rounded,
                color: Colors.white,
                size: 18,
              ),
              label: Text(
                isDone ? 'Completed Today (+100 XP)' : 'Start Challenge',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDone ? AppColors.tulsiGreen : AppColors.terracottaRed,
                disabledBackgroundColor: AppColors.tulsiGreen.withValues(alpha: 0.8),
                disabledForegroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
