import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../data/models/user_profile.dart';
import '../../data/models/xp_history_event.dart';
import '../../providers/app_providers.dart';
import '../../services/gamification_service.dart';

class MeProfileScreen extends ConsumerWidget {
  const MeProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider);
    final completedDates = ref.watch(completedChallengeDatesProvider);
    final progressHistory = ref.watch(progressHistoryProvider);
    final themeMode = ref.watch(themeModeProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Heritage Sanctuary'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
            icon: Icon(
              isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              color: isDark ? AppColors.turmericGold : AppColors.terracottaRed,
            ),
            onPressed: () {
              ref.read(themeModeProvider.notifier).toggleTheme(isDark);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 36),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Level & XP Hero Card (Displaying User's Name)
            _buildLevelHeroCard(ref, profile, isDark, context),
            const SizedBox(height: 20),

            // 2. Streak Counter & 28-Day Heatmap Calendar
            _buildStreakAndHeatmapCard(profile, completedDates, isDark, context),
            const SizedBox(height: 24),

            // 3. Heritage Badges Grid (All 7 Badges)
            _buildBadgesSection(profile, isDark, context),
            const SizedBox(height: 24),

            // 4. Progress History (Recent XP-earning events)
            _buildProgressHistorySection(progressHistory, isDark),
            const SizedBox(height: 24),

            // 5. 8 Levels Heritage Guide
            _buildLevelsGuideExpansion(profile.level, isDark),
            const SizedBox(height: 24),

            // 6. App Theme Appearance Settings
            _buildThemeSettingsCard(ref, themeMode, isDark),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // 1. XP + LEVEL SECTION
  // ==========================================

  Widget _buildLevelHeroCard(WidgetRef ref, UserProfile profile, bool isDark, BuildContext context) {
    final (lvl, title, curBase, nextBase) = GamificationService.calculateLevel(profile.xp);
    final progressInTier = nextBase > curBase
        ? ((profile.xp - curBase) / (nextBase - curBase)).clamp(0.0, 1.0)
        : 1.0;
    final xpToNext = nextBase > profile.xp ? (nextBase - profile.xp) : 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF382329), const Color(0xFF24181D)]
              : [const Color(0xFFFBF1E6), const Color(0xFFF6E2CA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.turmericGold.withValues(alpha: 0.45),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.terracottaRed.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Level Emblem with Sacred Glow
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: const RadialGradient(
                    colors: [Color(0xFFE55D3F), AppColors.terracottaRed],
                    radius: 0.85,
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.turmericGold, width: 2.2),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.terracottaRed.withValues(alpha: 0.45),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'LVL',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          color: Colors.white.withValues(alpha: 0.85),
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        '$lvl',
                        style: AppTypography.displayTitle.copyWith(
                          color: Colors.white,
                          fontSize: 22,
                          height: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Name
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            profile.name,
                            style: AppTypography.screenHeading.copyWith(fontSize: 20),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.edit_outlined,
                            size: 18,
                            color: isDark ? AppColors.turmericGold : AppColors.terracottaRed,
                          ),
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          tooltip: 'Edit Name',
                          onPressed: () => _showEditProfileDialog(context, ref, profile, isDark),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),

                    // 2. Generated Username
                    Text(
                      profile.username,
                      style: AppTypography.caption.copyWith(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.turmericGold : AppColors.terracottaRed,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),

                    // 3. Level & Rank Generic Title, beside it Heritage XP (Wrap prevents overflow on compact screens)
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.turmericAmber.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Level $lvl • $title',
                            style: AppTypography.tagText.copyWith(
                              color: AppColors.turmericAmber,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Text(
                          '${profile.xp} Heritage XP',
                          style: AppTypography.caption.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white70 : AppColors.textDark,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Progress indicator to next rank
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  lvl < 8 ? 'Next Rank: ${GamificationService.levelTiers[lvl + 1]!.$2}' : 'Highest Rank Achieved (Heritage Keeper)',
                  style: AppTypography.caption.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                lvl < 8 ? '${profile.xp} / $nextBase XP' : '${profile.xp} XP',
                style: AppTypography.tagText.copyWith(
                  color: AppColors.terracottaRed,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progressInTier,
              minHeight: 10,
              backgroundColor: isDark ? Colors.black38 : AppColors.borderLight,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.turmericGold),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                lvl < 8 ? '$xpToNext XP needed to advance' : 'Sanctuary Mastered',
                style: AppTypography.caption.copyWith(
                  fontSize: 11,
                  color: isDark ? AppColors.textLight.withValues(alpha: 0.7) : AppColors.textMuted,
                ),
              ),
              Text(
                '${(progressInTier * 100).toStringAsFixed(0)}%',
                style: AppTypography.caption.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.turmericAmber,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 2. STREAK SECTION & CALENDAR HEATMAP
  // ==========================================

  Widget _buildStreakAndHeatmapCard(
    UserProfile profile,
    Set<String> completedDates,
    bool isDark,
    BuildContext context,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.slateCard : AppColors.riceFlourCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          Row(
            children: [
              const Icon(Icons.local_fire_department_rounded, color: AppColors.crimsonRed, size: 22),
              const SizedBox(width: 8),
              Text(
                'Sacred Practice Streaks',
                style: AppTypography.cardTitle.copyWith(fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Streak Counter Row
          Row(
            children: [
              // Current Streak
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                  decoration: BoxDecoration(
                    color: AppColors.crimsonRed.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.crimsonRed.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.local_fire_department_rounded, color: AppColors.crimsonRed, size: 28),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${profile.currentStreak} Days',
                              style: AppTypography.cardTitle.copyWith(fontSize: 16, color: AppColors.crimsonRed),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Current Streak',
                              style: AppTypography.caption.copyWith(fontSize: 11),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Longest Streak
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                  decoration: BoxDecoration(
                    color: AppColors.turmericGold.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.turmericGold.withValues(alpha: 0.35)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.emoji_events_rounded, color: AppColors.turmericGold, size: 28),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${profile.longestStreak} Days',
                              style: AppTypography.cardTitle.copyWith(fontSize: 16, color: AppColors.turmericAmber),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Longest Streak',
                              style: AppTypography.caption.copyWith(fontSize: 11),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // 28-Day Heatmap Calendar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '28-Day Challenge Heatmap',
                style: AppTypography.cardTitle.copyWith(fontSize: 13.5),
              ),
              Text(
                'Tap day to inspect',
                style: AppTypography.caption.copyWith(fontSize: 10.5, fontStyle: FontStyle.italic),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Heatmap Grid
          _buildHeatmapGrid(completedDates, isDark, context),
          const SizedBox(height: 12),

          // Legend Row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem(AppColors.tulsiGreen, 'Completed Challenge', isDark),
              const SizedBox(width: 16),
              _buildLegendItem(AppColors.terracottaRed, 'Today', isDark, isBorderOnly: true),
              const SizedBox(width: 16),
              _buildLegendItem(isDark ? AppColors.slateLight : Colors.grey.shade300, 'Rest Day', isDark),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeatmapGrid(Set<String> completedDates, bool isDark, BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final currentWeekday = today.weekday; // 1 = Mon, 7 = Sun
    final thisWeekMonday = today.subtract(Duration(days: currentWeekday - 1));
    final startMonday = thisWeekMonday.subtract(const Duration(days: 21)); // 4 weeks total

    final weekdays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Column(
      children: [
        // Weekday header letters
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: weekdays.map((w) {
            return Expanded(
              child: Center(
                child: Text(
                  w,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.textLight.withValues(alpha: 0.6) : AppColors.textMuted,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 6),

        // 4 rows of 7 days
        Column(
          children: List.generate(4, (row) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2.5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(7, (col) {
                  final dayIndex = (row * 7) + col;
                  final day = startMonday.add(Duration(days: dayIndex));
                  final dateStr = DateFormat('yyyy-MM-dd').format(day);

                  final isToday = day.year == today.year && day.month == today.month && day.day == today.day;
                  final isFuture = day.isAfter(today);
                  final isCompleted = completedDates.contains(dateStr);

                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2.5),
                      child: _buildHeatmapDayCell(
                        day: day,
                        dateStr: dateStr,
                        isToday: isToday,
                        isFuture: isFuture,
                        isCompleted: isCompleted,
                        isDark: isDark,
                        context: context,
                      ),
                    ),
                  );
                }),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildHeatmapDayCell({
    required DateTime day,
    required String dateStr,
    required bool isToday,
    required bool isFuture,
    required bool isCompleted,
    required bool isDark,
    required BuildContext context,
  }) {
    Color cellBg;
    Color? borderColor;

    if (isCompleted) {
      cellBg = AppColors.tulsiGreen;
    } else if (isFuture) {
      cellBg = Colors.transparent;
      borderColor = isDark ? Colors.white10 : Colors.black12;
    } else {
      cellBg = isDark ? AppColors.slateLight : Colors.grey.shade200;
    }

    if (isToday) {
      borderColor = AppColors.terracottaRed;
    }

    return InkWell(
      onTap: () {
        final formattedDate = DateFormat('EEEE, MMM d').format(day);
        String message;
        if (isCompleted) {
          message = '$formattedDate: Daily Challenge Completed (+100 XP) 🔥';
        } else if (isToday) {
          message = '$formattedDate: Today\'s Challenge is available to play!';
        } else if (isFuture) {
          message = '$formattedDate: Upcoming daily challenge';
        } else {
          message = '$formattedDate: Rest day • No challenge recorded';
        }
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            duration: const Duration(seconds: 2),
            backgroundColor: isCompleted ? AppColors.tulsiGreen : AppColors.slateCard,
          ),
        );
      },
      borderRadius: BorderRadius.circular(6),
      child: Container(
        height: 32,
        decoration: BoxDecoration(
          color: cellBg,
          borderRadius: BorderRadius.circular(6),
          border: borderColor != null
              ? Border.all(color: borderColor, width: isToday ? 2.0 : 1.0)
              : null,
          boxShadow: isCompleted
              ? [
                  BoxShadow(
                    color: AppColors.tulsiGreen.withValues(alpha: 0.35),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: isCompleted
              ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
              : Text(
                  '${day.day}',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                    color: isFuture
                        ? (isDark ? Colors.white24 : Colors.black26)
                        : (isDark ? Colors.white70 : AppColors.textDark),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label, bool isDark, {bool isBorderOnly = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: isBorderOnly ? Colors.transparent : color,
            borderRadius: BorderRadius.circular(3),
            border: isBorderOnly ? Border.all(color: color, width: 1.8) : null,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: isDark ? AppColors.textLight.withValues(alpha: 0.7) : AppColors.textMuted,
          ),
        ),
      ],
    );
  }

  // ==========================================
  // 3. BADGE GRID (ALL 7 BADGES)
  // ==========================================

  Widget _buildBadgesSection(UserProfile profile, bool isDark, BuildContext context) {
    final unlockedCount = profile.badges.where((b) => b.unlocked).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.military_tech_rounded, color: AppColors.turmericGold, size: 22),
                const SizedBox(width: 8),
                Text(
                  'Heritage Badges',
                  style: AppTypography.cardTitle.copyWith(fontSize: 16),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.terracottaRed.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.terracottaRed.withValues(alpha: 0.35)),
              ),
              child: Text(
                '$unlockedCount of ${profile.badges.length} Unlocked',
                style: AppTypography.tagText.copyWith(
                  color: AppColors.terracottaRed,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Tap any badge to inspect unlock criteria and progress.',
          style: AppTypography.caption.copyWith(fontSize: 11.5),
        ),
        const SizedBox(height: 12),

        // 2-Column Responsive Grid of All 7 Badges
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: profile.badges.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.15,
          ),
          itemBuilder: (ctx, index) {
            final badge = profile.badges[index];
            return _buildBadgeCard(
              badge: badge,
              isDark: isDark,
              onTap: () => _showBadgeDetails(context, badge, isDark),
            );
          },
        ),
      ],
    );
  }

  Widget _buildBadgeCard({
    required BadgeItem badge,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    final isUnlocked = badge.unlocked;
    final ratio = badge.targetProgress > 0
        ? (badge.currentProgress / badge.targetProgress).clamp(0.0, 1.0)
        : 0.0;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isUnlocked
              ? (isDark ? const Color(0xFF2B221B) : const Color(0xFFFBF4EA))
              : (isDark ? AppColors.slateCard : Colors.grey.shade100),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isUnlocked
                ? AppColors.turmericGold
                : (isDark ? AppColors.borderDark : AppColors.borderLight),
            width: isUnlocked ? 1.6 : 1.0,
          ),
          boxShadow: isUnlocked
              ? [
                  BoxShadow(
                    color: AppColors.turmericGold.withValues(alpha: 0.22),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Badge Emoji with Silhouette effect if locked
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: isUnlocked
                        ? AppColors.turmericGold.withValues(alpha: 0.2)
                        : (isDark ? AppColors.slateLight : Colors.grey.shade300),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: isUnlocked
                        ? Text(badge.iconEmoji, style: const TextStyle(fontSize: 20))
                        : const Text('🔒', style: TextStyle(fontSize: 18)),
                  ),
                ),
                // Status Tag
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: (isUnlocked ? AppColors.tulsiGreen : AppColors.textMuted).withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isUnlocked) ...[
                        const Icon(Icons.check_rounded, size: 10, color: AppColors.tulsiGreen),
                        const SizedBox(width: 2),
                      ],
                      Text(
                        isUnlocked ? 'Unlocked' : '${badge.currentProgress}/${badge.targetProgress}',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          color: isUnlocked ? AppColors.tulsiGreen : AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),

            // Badge Title
            Text(
              badge.title,
              style: AppTypography.cardTitle.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isUnlocked ? null : AppColors.textMuted,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),

            // Short Description
            Text(
              badge.description,
              style: AppTypography.caption.copyWith(
                fontSize: 10,
                color: isDark ? AppColors.textLight.withValues(alpha: 0.65) : AppColors.textMuted,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),

            // Mini Progress Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: isUnlocked ? 1.0 : ratio,
                minHeight: 4,
                backgroundColor: isDark ? Colors.black26 : Colors.grey.shade300,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isUnlocked ? AppColors.tulsiGreen : AppColors.turmericAmber,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBadgeDetails(BuildContext context, BadgeItem badge, bool isDark) {
    final isUnlocked = badge.unlocked;
    final remaining = badge.targetProgress - badge.currentProgress;
    final ratio = badge.targetProgress > 0
        ? (badge.currentProgress / badge.targetProgress).clamp(0.0, 1.0)
        : 0.0;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF241A1E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Drag handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 18),

              // Emblem Icon
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: isUnlocked
                      ? AppColors.turmericGold.withValues(alpha: 0.2)
                      : (isDark ? AppColors.slateCard : const Color(0xFFEDE5D8)),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isUnlocked ? AppColors.turmericGold : Colors.grey,
                    width: 2.0,
                  ),
                ),
                child: Center(
                  child: Text(
                    isUnlocked ? badge.iconEmoji : '🔒',
                    style: const TextStyle(fontSize: 36),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Title
              Text(
                badge.title,
                style: AppTypography.screenHeading.copyWith(fontSize: 20),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),

              // Status Tag
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: (isUnlocked ? AppColors.tulsiGreen : AppColors.turmericAmber).withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: (isUnlocked ? AppColors.tulsiGreen : AppColors.turmericAmber).withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  isUnlocked ? 'Unlocked • Heritage Achievement' : 'Locked • In Progress',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: isUnlocked ? AppColors.tulsiGreen : AppColors.turmericAmber,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Criteria Box
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.slateCard : const Color(0xFFFAF3EA),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Unlock Criteria',
                      style: AppTypography.cardTitle.copyWith(fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      badge.description,
                      style: AppTypography.bodyText.copyWith(fontSize: 12.5),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Progress: ${badge.currentProgress} / ${badge.targetProgress}',
                          style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${(ratio * 100).toStringAsFixed(0)}%',
                          style: AppTypography.caption.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isUnlocked ? AppColors.tulsiGreen : AppColors.turmericAmber,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: isUnlocked ? 1.0 : ratio,
                        minHeight: 8,
                        backgroundColor: isDark ? Colors.black26 : Colors.grey.shade300,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isUnlocked ? AppColors.tulsiGreen : AppColors.turmericAmber,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isUnlocked
                          ? 'Achievement unlocked on ${badge.unlockedAt != null ? DateFormat.yMMMd().format(badge.unlockedAt!) : "earlier practice"}.'
                          : 'Complete $remaining more to unlock this sacred emblem.',
                      style: AppTypography.caption.copyWith(
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                        color: isUnlocked ? AppColors.tulsiGreen : AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.terracottaRed,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Close', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ==========================================
  // 4. PROGRESS HISTORY SECTION
  // ==========================================

  Widget _buildProgressHistorySection(List<XpHistoryEvent> history, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.history_edu_rounded, color: AppColors.turmericAmber, size: 22),
                const SizedBox(width: 8),
                Text(
                  'Recent Heritage Milestones',
                  style: AppTypography.cardTitle.copyWith(fontSize: 16),
                ),
              ],
            ),
            if (history.isNotEmpty)
              Text(
                '${history.length} Events',
                style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Live log of your XP-earning events and challenges.',
          style: AppTypography.caption.copyWith(fontSize: 11.5),
        ),
        const SizedBox(height: 12),

        if (history.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? AppColors.slateCard : AppColors.riceFlourCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
            ),
            child: Column(
              children: [
                const Icon(Icons.stars_rounded, size: 40, color: AppColors.turmericAmber),
                const SizedBox(height: 10),
                Text(
                  'Your Heritage Journey Begins Here',
                  style: AppTypography.cardTitle.copyWith(fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  'Read heritage topics, win games, solve puzzles, or complete daily challenges to record your milestones.',
                  style: AppTypography.caption.copyWith(
                    fontSize: 11.5,
                    color: isDark ? AppColors.textLight.withValues(alpha: 0.7) : AppColors.textMuted,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: history.take(15).length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (ctx, index) {
              final event = history[index];
              return _buildHistoryTile(event, isDark);
            },
          ),
      ],
    );
  }

  Widget _buildHistoryTile(XpHistoryEvent event, bool isDark) {
    IconData icon;
    Color color;

    switch (event.type) {
      case XpEventType.learnModule:
        icon = Icons.menu_book_rounded;
        color = AppColors.tulsiGreen;
        break;
      case XpEventType.gameWon:
        icon = Icons.emoji_events_rounded;
        color = AppColors.turmericAmber;
        break;
      case XpEventType.kolamCreated:
        icon = Icons.brush_rounded;
        color = AppColors.terracottaRed;
        break;
      case XpEventType.challengeCompleted:
        icon = Icons.local_fire_department_rounded;
        color = AppColors.crimsonRed;
        break;
      case XpEventType.quizCompleted:
        icon = Icons.quiz_rounded;
        color = Colors.indigo;
        break;
      case XpEventType.kolamAnalysed:
        icon = Icons.insights_rounded;
        color = Colors.deepPurple;
        break;
    }

    final formattedTime = _formatEventTimestamp(event.timestamp);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.slateCard : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: AppTypography.cardTitle.copyWith(fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  event.description,
                  style: AppTypography.caption.copyWith(
                    fontSize: 11,
                    color: isDark ? AppColors.textLight.withValues(alpha: 0.65) : AppColors.textMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.turmericAmber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '+${event.xpEarned} XP',
                  style: AppTypography.tagText.copyWith(
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.turmericAmber,
                  ),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                formattedTime,
                style: TextStyle(
                  fontSize: 9.5,
                  color: isDark ? Colors.white38 : Colors.black38,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatEventTimestamp(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 1) {
      return 'Just now';
    } else if (diff.inHours < 1) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inDays < 1 && now.day == dt.day) {
      return DateFormat('h:mm a').format(dt);
    } else if (diff.inDays == 1 || (diff.inDays < 2 && now.day != dt.day)) {
      return 'Yesterday';
    } else {
      return DateFormat('MMM d').format(dt);
    }
  }

  // ==========================================
  // 5. 8 HERITAGE LEVELS GUIDE
  // ==========================================

  Widget _buildLevelsGuideExpansion(int currentLevel, bool isDark) {
    return Material(
      color: isDark ? AppColors.slateCard : AppColors.riceFlourCard,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
        ),
        child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: const Icon(Icons.school_rounded, color: AppColors.turmericAmber, size: 22),
        title: Text(
          'View All 8 Heritage Ranks',
          style: AppTypography.cardTitle.copyWith(fontSize: 14.5),
        ),
        subtitle: Text(
          'Progressive wisdom ranks based on Kolam mastery',
          style: AppTypography.caption.copyWith(fontSize: 11),
        ),
        children: GamificationService.levelTiers.entries.map((entry) {
          final isCurrent = currentLevel == entry.key;
          return ListTile(
            dense: true,
            leading: CircleAvatar(
              radius: 14,
              backgroundColor: isCurrent
                  ? AppColors.turmericGold
                  : (isDark ? AppColors.slateLight : AppColors.borderLight),
              child: Text(
                '${entry.key}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isCurrent ? Colors.black : (isDark ? Colors.white70 : AppColors.textDark),
                ),
              ),
            ),
            title: Text(
              entry.value.$2,
              style: AppTypography.cardTitle.copyWith(
                fontSize: 13.5,
                color: isCurrent ? AppColors.turmericAmber : null,
                fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            trailing: Text(
              '${entry.value.$1} XP',
              style: AppTypography.caption.copyWith(
                fontWeight: FontWeight.bold,
                color: isCurrent ? AppColors.turmericAmber : null,
              ),
            ),
          );
        }).toList(),
      ),
    ),
  );
}

  Widget _buildThemeSettingsCard(WidgetRef ref, ThemeMode currentMode, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.slateCard : AppColors.riceFlourCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black26 : AppColors.terracottaRed.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (isDark ? AppColors.turmericGold : AppColors.terracottaRed).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                  size: 20,
                  color: isDark ? AppColors.turmericGold : AppColors.terracottaRed,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'App Appearance',
                      style: AppTypography.cardTitle.copyWith(fontSize: 15),
                    ),
                    Text(
                      'Choose between Temple Slate Dark or Rice Flour Light',
                      style: AppTypography.caption.copyWith(fontSize: 11.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildThemeOption(
                  ref: ref,
                  mode: ThemeMode.system,
                  currentMode: currentMode,
                  label: 'System',
                  icon: Icons.brightness_auto_rounded,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildThemeOption(
                  ref: ref,
                  mode: ThemeMode.light,
                  currentMode: currentMode,
                  label: 'Light',
                  icon: Icons.light_mode_rounded,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildThemeOption(
                  ref: ref,
                  mode: ThemeMode.dark,
                  currentMode: currentMode,
                  label: 'Dark',
                  icon: Icons.dark_mode_rounded,
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context, WidgetRef ref, UserProfile profile, bool isDark) {
    final nameController = TextEditingController(text: profile.name);
    String liveUsername = profile.username;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.slateDark : AppColors.riceFlourBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                24,
                20,
                24,
                MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Edit Profile Name',
                        style: AppTypography.screenHeading.copyWith(fontSize: 20),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameController,
                    autofocus: true,
                    textCapitalization: TextCapitalization.words,
                    style: AppTypography.cardTitle.copyWith(fontSize: 16),
                    onChanged: (val) {
                      setModalState(() {
                        liveUsername = UserProfile.generateUsername(val);
                      });
                    },
                    decoration: InputDecoration(
                      labelText: 'Your Name',
                      hintText: 'e.g. Sampurna',
                      prefixIcon: const Icon(Icons.person_outline_rounded, color: AppColors.terracottaRed),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.alternate_email_rounded, size: 15, color: AppColors.turmericGold),
                      const SizedBox(width: 6),
                      Text(
                        'Auto-generated handle: ',
                        style: AppTypography.caption.copyWith(fontSize: 12),
                      ),
                      Text(
                        liveUsername,
                        style: AppTypography.caption.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.turmericGold : AppColors.terracottaRed,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        final rawName = nameController.text.trim();
                        final finalName = rawName.isNotEmpty ? rawName : 'Kolam Artisan';
                        final finalUsername = UserProfile.generateUsername(finalName);
                        await ref.read(userProfileProvider.notifier).updateProfileName(
                          name: finalName,
                          username: finalUsername,
                        );
                        if (context.mounted) {
                          Navigator.of(ctx).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              backgroundColor: AppColors.tulsiGreen,
                              content: Text('Profile updated successfully!'),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.terracottaRed,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('Save Profile', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildThemeOption({
    required WidgetRef ref,
    required ThemeMode mode,
    required ThemeMode currentMode,
    required String label,
    required IconData icon,
    required bool isDark,
  }) {
    final isSelected = currentMode == mode;
    return InkWell(
      onTap: () => ref.read(themeModeProvider.notifier).setThemeMode(mode),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppColors.crimsonRed.withValues(alpha: 0.25) : AppColors.terracottaRed.withValues(alpha: 0.12))
              : (isDark ? AppColors.slateLight.withValues(alpha: 0.5) : AppColors.riceFlourBg),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? (isDark ? AppColors.turmericGold : AppColors.terracottaRed)
                : (isDark ? AppColors.borderDark : AppColors.borderLight),
            width: isSelected ? 1.8 : 1.0,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected
                  ? (isDark ? AppColors.turmericGold : AppColors.terracottaRed)
                  : (isDark ? Colors.white60 : AppColors.textMuted),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTypography.caption.copyWith(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? (isDark ? AppColors.turmericGold : AppColors.terracottaRed)
                    : (isDark ? Colors.white70 : AppColors.textDark),
                fontSize: 11.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
