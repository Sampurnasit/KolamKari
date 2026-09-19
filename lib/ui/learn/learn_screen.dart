import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../data/models/learn_module.dart';
import '../../providers/app_providers.dart';
import '../common/empty_state_widget.dart';
import 'topic_detail_screen.dart';
import 'regional_traditions_screen.dart';
import 'heritage_quiz_screen.dart';

class LearnScreen extends ConsumerWidget {
  const LearnScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modules = ref.watch(learnModulesProvider);
    final completedCount = modules.where((m) => m.completed).length;
    final totalCount = modules.length;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (modules.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Sacred Knowledge Hub')),
        body: const EmptyStateWidget(
          icon: Icons.menu_book_rounded,
          title: 'No Heritage Topics Found',
          message: 'The sacred library modules are being loaded from tradition archives.',
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sacred Knowledge Hub'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Knowledge Progress Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [AppColors.slateCard, AppColors.slateLight]
                      : [const Color(0xFFFBF1E6), const Color(0xFFF7E6D2)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.turmericGold.withValues(alpha: 0.35),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.school_rounded, color: AppColors.terracottaRed, size: 24),
                          const SizedBox(width: 8),
                          Text(
                            'Heritage Mastery',
                            style: AppTypography.cardTitle.copyWith(fontSize: 16),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.terracottaRed.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$completedCount / $totalCount Topics',
                          style: AppTypography.tagText.copyWith(color: AppColors.terracottaRed),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: totalCount > 0 ? completedCount / totalCount : 0.0,
                      minHeight: 8,
                      backgroundColor: isDark ? Colors.black38 : AppColors.borderLight,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.turmericGold),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    completedCount == totalCount
                        ? 'All heritage modules mastered! You have unlocked the Heritage Explorer badge.'
                        : 'Read topics to the end to absorb sacred knowledge and earn +20 XP per module.',
                    style: AppTypography.caption.copyWith(fontSize: 12.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Quick action banners: Regional Traditions comparison & Heritage Quiz
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const RegionalTraditionsScreen()),
                      );
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.slateCard : AppColors.riceFlourCard,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.terracottaRed.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.map_rounded, color: AppColors.terracottaRed, size: 24),
                          const SizedBox(height: 8),
                          Text(
                            'Regional Maps',
                            style: AppTypography.cardTitle.copyWith(fontSize: 14),
                          ),
                          Text(
                            'Kolam vs Muggu vs Alpana',
                            style: AppTypography.caption.copyWith(fontSize: 11),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const HeritageQuizScreen()),
                      );
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.slateCard : AppColors.riceFlourCard,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.turmericGold.withValues(alpha: 0.5)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.quiz_rounded, color: AppColors.turmericGold, size: 24),
                          const SizedBox(height: 8),
                          Text(
                            'Ethno Quiz',
                            style: AppTypography.cardTitle.copyWith(fontSize: 14),
                          ),
                          Text(
                            'Test Wisdom (+30 XP)',
                            style: AppTypography.caption.copyWith(fontSize: 11),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),

            // Modules Header
            Text(
              'Sacred Topics & Mathematics',
              style: AppTypography.cardTitle.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 12),

            // Modules List
            ...modules.map((module) => _buildModuleCard(context, module, isDark)),
          ],
        ),
      ),
    );
  }

  Widget _buildModuleCard(BuildContext context, LearnModule module, bool isDark) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: module.completed
              ? AppColors.tulsiGreen.withValues(alpha: 0.5)
              : (isDark ? AppColors.borderDark : AppColors.borderLight),
          width: 1.2,
        ),
      ),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => TopicDetailScreen(module: module),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon avatar
              CircleAvatar(
                radius: 24,
                backgroundColor: module.completed
                    ? AppColors.tulsiGreen.withValues(alpha: 0.15)
                    : AppColors.terracottaRed.withValues(alpha: 0.12),
                child: Icon(
                  module.completed ? Icons.check_circle_rounded : _getIconForCategory(module.id),
                  color: module.completed ? AppColors.tulsiGreen : AppColors.terracottaRed,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),

              // Title and details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.turmericGold.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              module.category,
                              style: AppTypography.tagText.copyWith(
                                fontSize: 10,
                                color: AppColors.turmericAmber,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          module.completed ? 'Mastered' : '+${module.xpReward} XP',
                          style: AppTypography.tagText.copyWith(
                            color: module.completed ? AppColors.tulsiGreen : AppColors.terracottaRed,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      module.title,
                      style: AppTypography.cardTitle.copyWith(fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      module.subtitle,
                      style: AppTypography.caption.copyWith(fontSize: 12.5),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIconForCategory(String id) {
    switch (id) {
      case 'what_is_kolam':
        return Icons.auto_awesome_rounded;
      case 'history_heritage':
        return Icons.history_edu_rounded;
      case 'regional_traditions':
        return Icons.public_rounded;
      case 'festivals_occasions':
        return Icons.celebration_rounded;
      case 'types_of_kolam':
        return Icons.grid_view_rounded;
      case 'mathematics_of_kolam':
        return Icons.functions_rounded;
      default:
        return Icons.menu_book_rounded;
    }
  }
}
