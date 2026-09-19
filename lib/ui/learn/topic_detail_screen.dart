import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../data/models/learn_module.dart';
import '../../providers/app_providers.dart';

class TopicDetailScreen extends ConsumerStatefulWidget {
  final LearnModule module;

  const TopicDetailScreen({super.key, required this.module});

  @override
  ConsumerState<TopicDetailScreen> createState() => _TopicDetailScreenState();
}

class _TopicDetailScreenState extends ConsumerState<TopicDetailScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _hasAwardedXp = false;

  @override
  void initState() {
    super.initState();
    _hasAwardedXp = widget.module.completed;
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_hasAwardedXp) return;
    if (_scrollController.hasClients) {
      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.position.pixels;
      // When user reaches near bottom (90% scroll), mark completed and award XP
      if (currentScroll >= maxScroll * 0.85) {
        _markCompleted();
      }
    }
  }

  Future<void> _markCompleted() async {
    if (_hasAwardedXp) return;
    setState(() {
      _hasAwardedXp = true;
    });

    await ref.read(userProfileProvider.notifier).onLearnModuleCompleted(widget.module.id);

    // Refresh modules list
    ref.invalidate(learnModulesProvider);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.tulsiGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          content: Row(
            children: [
              const Icon(Icons.stars_rounded, color: Colors.amber, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Knowledge Absorbed! +${widget.module.xpReward} XP earned.',
                  style: AppTypography.cardTitle.copyWith(color: Colors.white, fontSize: 13),
                ),
              ),
            ],
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.module.category),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _hasAwardedXp
                  ? AppColors.tulsiGreen.withValues(alpha: 0.15)
                  : AppColors.turmericGold.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _hasAwardedXp ? AppColors.tulsiGreen : AppColors.turmericGold,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _hasAwardedXp ? Icons.check_circle_rounded : Icons.star_rounded,
                  size: 16,
                  color: _hasAwardedXp ? AppColors.tulsiGreen : AppColors.turmericGold,
                ),
                const SizedBox(width: 4),
                Text(
                  _hasAwardedXp ? 'Completed (+20 XP)' : '+20 XP',
                  style: AppTypography.tagText.copyWith(
                    color: _hasAwardedXp ? AppColors.tulsiGreen : AppColors.turmericGold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Region Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.terracottaRed.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.place_rounded, size: 14, color: AppColors.terracottaRed),
                  const SizedBox(width: 4),
                  Text(
                    widget.module.relatedRegion,
                    style: AppTypography.tagText.copyWith(color: AppColors.terracottaRed),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Title
            Text(
              widget.module.title,
              style: AppTypography.displayTitle.copyWith(
                color: isDark ? AppColors.textLight : AppColors.textDark,
                fontSize: 26,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              widget.module.subtitle,
              style: AppTypography.cardTitle.copyWith(
                color: AppColors.turmericAmber,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 20),

            // Cultural Quote Banner
            if (widget.module.culturalQuote.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.terracottaRed.withValues(alpha: 0.2)
                      : const Color(0xFFFBF1E6),
                  borderRadius: BorderRadius.circular(12),
                  border: const Border(
                    left: BorderSide(color: AppColors.terracottaRed, width: 4),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.format_quote_rounded, color: AppColors.terracottaRed, size: 28),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.module.culturalQuote,
                        style: AppTypography.bodyText.copyWith(
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w500,
                          color: isDark ? AppColors.textLight : AppColors.textDark,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),

            // Key Takeaways Card
            if (widget.module.keyTakeaways.isNotEmpty) ...[
              Text(
                'Key Cultural Pillars',
                style: AppTypography.cardTitle.copyWith(fontSize: 16),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.slateCard : AppColors.riceFlourCard,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  ),
                ),
                child: Column(
                  children: widget.module.keyTakeaways.map((takeaway) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 4.0),
                            child: Icon(Icons.circle, size: 8, color: AppColors.turmericGold),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              takeaway,
                              style: AppTypography.bodyText.copyWith(fontSize: 13.5),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Body Markdown Content
            MarkdownBody(
              data: widget.module.bodyMarkdown,
              selectable: true,
              styleSheet: MarkdownStyleSheet(
                h1: AppTypography.screenHeading.copyWith(
                  fontSize: 20,
                  color: isDark ? AppColors.textLight : AppColors.terracottaRed,
                ),
                h3: AppTypography.cardTitle.copyWith(
                  fontSize: 16,
                  color: isDark ? AppColors.turmericGold : AppColors.crimsonRed,
                ),
                p: AppTypography.bodyText.copyWith(
                  color: isDark ? AppColors.textLight : AppColors.textDark,
                  fontSize: 14.5,
                  height: 1.6,
                ),
                strong: const TextStyle(fontWeight: FontWeight.bold),
                listBullet: TextStyle(
                  color: isDark ? AppColors.turmericGold : AppColors.terracottaRed,
                ),
                horizontalRuleDecoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: isDark ? AppColors.borderDark : AppColors.borderLight,
                      width: 1,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 36),

            // Bottom completion acknowledgement
            Center(
              child: ElevatedButton.icon(
                onPressed: _hasAwardedXp ? null : _markCompleted,
                icon: Icon(
                  _hasAwardedXp ? Icons.check_circle_rounded : Icons.menu_book_rounded,
                  color: Colors.white,
                ),
                label: Text(
                  _hasAwardedXp ? 'Completed (+20 XP)' : 'Mark as Understood (+20 XP)',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _hasAwardedXp ? AppColors.tulsiGreen : AppColors.terracottaRed,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
