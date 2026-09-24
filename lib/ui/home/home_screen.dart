import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../data/models/learn_module.dart';
import '../../data/models/user_profile.dart';
import '../../data/seed/heritage_seed_data.dart';
import '../../providers/app_providers.dart';
import '../common/animated_flame_badge.dart';
import '../common/daily_challenge_card.dart';
import '../learn/topic_detail_screen.dart';
import '../learn/heritage_quiz_screen.dart';
import '../play/games/memory_game_screen.dart';
import '../play/games/kolam_puzzle_screen.dart';
import '../play/games/symmetry_game_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  /// Greeting data based on current hour of the day
  ({String greeting, String subtitle, IconData icon, Color iconColor}) _getGreetingData() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return (
        greeting: 'Good Morning!',
        subtitle: 'Continue your Kolam journey',
        icon: Icons.wb_sunny_rounded,
        iconColor: AppColors.turmericAmber,
      );
    } else if (hour >= 12 && hour < 17) {
      return (
        greeting: 'Good Afternoon!',
        subtitle: 'Continue your Kolam journey',
        icon: Icons.wb_twilight_rounded,
        iconColor: AppColors.turmericGold,
      );
    } else if (hour >= 17 && hour < 22) {
      return (
        greeting: 'Good Evening!',
        subtitle: 'Continue your Kolam journey',
        icon: Icons.flare_rounded,
        iconColor: AppColors.terracottaRed,
      );
    } else {
      return (
        greeting: 'Peaceful Night!',
        subtitle: 'Continue your Kolam journey',
        icon: Icons.bedtime_rounded,
        iconColor: AppColors.templeIndigo,
      );
    }
  }

  /// Calculates XP thresholds for compact progress bar
  ({int current, int target, double progress}) _calculateLevelProgress(int xp) {
    const thresholds = [0, 100, 250, 500, 1000, 2000, 3500, 5000];
    for (int i = 0; i < thresholds.length - 1; i++) {
      if (xp < thresholds[i + 1]) {
        final base = thresholds[i];
        final next = thresholds[i + 1];
        final currentInTier = xp - base;
        final requiredInTier = next - base;
        final progress = (currentInTier / requiredInTier).clamp(0.0, 1.0);
        return (current: currentInTier, target: requiredInTier, progress: progress);
      }
    }
    return (current: xp, target: thresholds.last, progress: 1.0);
  }

  /// Refreshes daily challenge and state upon pull-to-refresh
  Future<void> _handleRefresh(BuildContext context, WidgetRef ref) async {
    // 1. Re-check / generate today's daily challenge in case of date rollover
    final dailyChallengeService = ref.read(dailyChallengeServiceProvider);
    final freshTodayChallenge = dailyChallengeService.getTodaysChallenge();
    ref.read(todayChallengeProvider.notifier).state = freshTodayChallenge;

    // 2. Refresh user profile (streak, XP, level, badges)
    ref.read(userProfileProvider.notifier).refresh();

    // 3. Refresh learn modules completion status
    final storage = ref.read(storageServiceProvider);
    final completedIds = storage.getCompletedModuleIds().toSet();
    ref.read(learnModulesProvider.notifier).state = HeritageSeedData.initialModules.map((m) {
      return m.copyWith(completed: completedIds.contains(m.id));
    }).toList();

    // 4. Invalidate computed providers for Me tab & history
    ref.invalidate(progressHistoryProvider);
    ref.invalidate(completedChallengeDatesProvider);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.check_circle_rounded, color: AppColors.tulsiGreen, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Refreshed! Today's challenges and progress are up to date.",
                  style: TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.slateCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider);
    final modules = ref.watch(learnModulesProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Find the next incomplete module
    final incompleteModules = modules.where((m) => !m.completed).toList();
    final LearnModule? nextIncompleteModule =
        incompleteModules.isNotEmpty ? incompleteModules.first : null;

    final greetingData = _getGreetingData();
    final todayDateString = DateFormat('EEEE, d MMMM').format(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.grain_rounded, color: AppColors.terracottaRed, size: 24),
            const SizedBox(width: 8),
            Text(
              'KolamKari',
              style: AppTypography.displayTitle.copyWith(
                fontSize: 22,
                color: isDark ? AppColors.textLight : AppColors.terracottaRed,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          // Theme Quick Toggle
          IconButton(
            tooltip: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
            icon: Icon(
              isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              size: 22,
              color: isDark ? AppColors.turmericGold : AppColors.terracottaRed,
            ),
            onPressed: () {
              ref.read(themeModeProvider.notifier).toggleTheme(isDark);
            },
          ),
          // Me profile quick avatar link
          IconButton(
            tooltip: 'View Profile',
            icon: CircleAvatar(
              radius: 15,
              backgroundColor: AppColors.terracottaRed.withValues(alpha: 0.15),
              child: Text(
                '${profile.level}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.terracottaRed,
                ),
              ),
            ),
            onPressed: () {
              ref.read(currentNavIndexProvider.notifier).state = 4;
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.terracottaRed,
        backgroundColor: isDark ? AppColors.slateCard : Colors.white,
        onRefresh: () => _handleRefresh(context, ref),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Heritage Greeting Header (Dynamic time of day)
              _buildGreetingHeader(
                context,
                profile: profile,
                greetingData: greetingData,
                todayDateString: todayDateString,
                isDark: isDark,
              ),
              const SizedBox(height: 18),

              // 2. Today's Daily Kolam Challenge Card (Prominently placed)
              const DailyChallengeCard(),
              const SizedBox(height: 22),

              // 3. "Continue Learning" Row
              _buildContinueLearningSection(
                context,
                ref,
                nextModule: nextIncompleteModule,
                totalModules: modules.length,
                completedCount: modules.where((m) => m.completed).length,
                isDark: isDark,
              ),
              const SizedBox(height: 22),

              // 4. "Quick Play" Row (Memory, Puzzle, Symmetry direct launch)
              _buildQuickPlaySection(context, ref, isDark: isDark),
              const SizedBox(height: 22),

              // 5. "Your Progress" Compact Summary
              _buildProgressSummaryCard(context, ref, profile: profile, isDark: isDark),
              const SizedBox(height: 20),

              // 6. Creative Studio CTA Banner (Connective hub to Create tab)
              _buildCreativeStudioBanner(context, ref, isDark: isDark),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // 1. GREETING HEADER
  // ==========================================
  Widget _buildGreetingHeader(
    BuildContext context, {
    required UserProfile profile,
    required ({String greeting, String subtitle, IconData icon, Color iconColor}) greetingData,
    required String todayDateString,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF382329), const Color(0xFF22161A)]
              : [const Color(0xFFFBF2E6), const Color(0xFFF7E2C9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.turmericGold.withValues(alpha: 0.4),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Date & Time badge
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(greetingData.icon, color: greetingData.iconColor, size: 16),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        todayDateString,
                        style: AppTypography.tagText.copyWith(
                          color: isDark ? AppColors.turmericGold : AppColors.terracottaRed,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.4,
                          fontSize: 11.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Streak Badge
              AnimatedFlameBadge(streakDays: profile.currentStreak),
            ],
          ),
          const SizedBox(height: 10),

          // Greeting title
          Text(
            greetingData.greeting,
            style: AppTypography.screenHeading.copyWith(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.textLight : AppColors.textDark,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            greetingData.subtitle,
            style: AppTypography.bodyText.copyWith(
              fontSize: 14,
              color: isDark ? AppColors.textLight.withValues(alpha: 0.8) : AppColors.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),

          // Heritage devotional quote
          Text(
            '"Every dawn, the threshold becomes a cosmic prayer written in sacred flour."',
            style: AppTypography.bodyText.copyWith(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: isDark ? AppColors.textLight.withValues(alpha: 0.6) : AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 2. CONTINUE LEARNING ROW
  // ==========================================
  Widget _buildContinueLearningSection(
    BuildContext context,
    WidgetRef ref, {
    required LearnModule? nextModule,
    required int totalModules,
    required int completedCount,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Continue Learning',
                style: AppTypography.cardTitle.copyWith(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: () {
                // Navigate to Learn tab (index 1)
                ref.read(currentNavIndexProvider.notifier).state = 1;
              },
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Text(
                  'View All ($completedCount/$totalModules) →',
                  style: AppTypography.tagText.copyWith(
                    color: AppColors.terracottaRed,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        if (nextModule != null)
          Card(
            elevation: 2,
            shadowColor: Colors.black12,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
            ),
            child: InkWell(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => TopicDetailScreen(module: nextModule),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.terracottaRed.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.terracottaRed.withValues(alpha: 0.3),
                        ),
                      ),
                      child: const Icon(
                        Icons.menu_book_rounded,
                        color: AppColors.terracottaRed,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.turmericGold.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  nextModule.category,
                                  style: AppTypography.tagText.copyWith(
                                    color: AppColors.turmericAmber,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Text(
                                '+${nextModule.xpReward} XP',
                                style: AppTypography.caption.copyWith(
                                  fontSize: 11,
                                  color: AppColors.turmericAmber,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '• ${nextModule.relatedRegion}',
                                style: AppTypography.caption.copyWith(fontSize: 11),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            nextModule.title,
                            style: AppTypography.cardTitle.copyWith(fontSize: 15),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 1),
                          Text(
                            nextModule.subtitle,
                            style: AppTypography.caption.copyWith(fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.terracottaRed,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          // All modules completed celebration banner
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: AppColors.tulsiGreen.withValues(alpha: 0.4),
              ),
            ),
            child: InkWell(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const HeritageQuizScreen()),
                );
              },
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: AppColors.tulsiGreen.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.workspace_premium_rounded,
                        color: AppColors.tulsiGreen,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'All Modules Completed!',
                            style: AppTypography.cardTitle.copyWith(
                              fontSize: 15,
                              color: AppColors.tulsiGreen,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'You have explored all 8 heritage topics. Take the Heritage Quiz to test your wisdom!',
                            style: AppTypography.caption.copyWith(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.tulsiGreen),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ==========================================
  // 3. QUICK PLAY ROW (3 Games)
  // ==========================================
  Widget _buildQuickPlaySection(BuildContext context, WidgetRef ref, {required bool isDark}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Quick Play',
                style: AppTypography.cardTitle.copyWith(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: () {
                // Navigate to Play tab (index 2)
                ref.read(currentNavIndexProvider.notifier).state = 2;
              },
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Text(
                  'Play Hub →',
                  style: AppTypography.tagText.copyWith(
                    color: AppColors.terracottaRed,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            // 1. Memory Game
            Expanded(
              child: _buildQuickPlayCard(
                title: 'Memory',
                subtitle: 'Observe & Recreate',
                icon: Icons.psychology_rounded,
                accentColor: AppColors.terracottaRed,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const MemoryGameScreen()),
                ),
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 10),

            // 2. Kolam Puzzle
            Expanded(
              child: _buildQuickPlayCard(
                title: 'Puzzle',
                subtitle: 'Missing Piece',
                icon: Icons.extension_rounded,
                accentColor: AppColors.tulsiGreen,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const KolamPuzzleScreen()),
                ),
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 10),

            // 3. Symmetry Game
            Expanded(
              child: _buildQuickPlayCard(
                title: 'Symmetry',
                subtitle: 'Geometry AI',
                icon: Icons.all_inclusive_rounded,
                accentColor: AppColors.templeIndigo,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SymmetryGameScreen()),
                ),
                isDark: isDark,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickPlayCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        constraints: const BoxConstraints(minHeight: 120),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.slateCard : AppColors.riceFlourCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: accentColor.withValues(alpha: 0.35),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: accentColor, size: 22),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.cardTitle.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 1),
                Text(
                  subtitle,
                  style: AppTypography.caption.copyWith(fontSize: 10.5),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // 4. "YOUR PROGRESS" SUMMARY CARD
  // ==========================================
  Widget _buildProgressSummaryCard(
    BuildContext context,
    WidgetRef ref, {
    required UserProfile profile,
    required bool isDark,
  }) {
    final progressData = _calculateLevelProgress(profile.xp);
    final badgesCount = profile.badges.where((b) => b.unlocked).length;

    return InkWell(
      onTap: () {
        // Navigate to Me tab (index 4)
        ref.read(currentNavIndexProvider.notifier).state = 4;
      },
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.slateCard : AppColors.riceFlourCard,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: AppColors.turmericGold.withValues(alpha: 0.35),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Title + Me tab link
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.person_rounded, color: AppColors.terracottaRed, size: 20),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Your Progress',
                          style: AppTypography.cardTitle.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Me Profile',
                      style: AppTypography.tagText.copyWith(
                        color: AppColors.terracottaRed,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppColors.terracottaRed),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Metrics row: Level, XP, Streak, Badges
            Row(
              children: [
                // Level Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.terracottaRed,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Lvl ${profile.level}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    profile.levelTitle,
                    style: AppTypography.cardTitle.copyWith(fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // XP pill
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star_rounded, color: AppColors.turmericAmber, size: 18),
                    const SizedBox(width: 3),
                    Text(
                      '${profile.xp} XP',
                      style: AppTypography.tagText.copyWith(
                        color: AppColors.turmericAmber,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),

            // XP Progress Bar to next level
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progressData.progress,
                minHeight: 7,
                backgroundColor: AppColors.turmericGold.withValues(alpha: 0.15),
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.turmericAmber),
              ),
            ),
            const SizedBox(height: 8),

            // Stats Sub-row: Streak & Badges
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.local_fire_department_rounded, color: AppColors.crimsonRed, size: 16),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          '${profile.currentStreak} day streak',
                          style: AppTypography.caption.copyWith(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.military_tech_rounded, color: AppColors.turmericGold, size: 16),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          '$badgesCount / 7 Badges',
                          style: AppTypography.caption.copyWith(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // 5. CREATIVE STUDIO BANNER (Connective hub to Create)
  // ==========================================
  Widget _buildCreativeStudioBanner(BuildContext context, WidgetRef ref, {required bool isDark}) {
    return InkWell(
      onTap: () {
        // Navigate to Create tab (index 3)
        ref.read(currentNavIndexProvider.notifier).state = 3;
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.slateCard : AppColors.riceFlourCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.kaaviBrick.withValues(alpha: 0.45)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.kaaviBrick.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.brush_rounded, color: AppColors.kaaviBrick, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Open Creative Studio',
                    style: AppTypography.cardTitle.copyWith(fontSize: 15),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Draw on 5x5 to 9x9 pulli grids with mirror symmetry & AI analysis.',
                    style: AppTypography.caption.copyWith(fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_rounded, color: AppColors.kaaviBrick, size: 20),
          ],
        ),
      ),
    );
  }
}
