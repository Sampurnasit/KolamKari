import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../providers/app_providers.dart';
import '../common/daily_challenge_card.dart';
import 'games/memory_game_screen.dart';
import 'games/pattern_construction_screen.dart';
import 'games/kolam_puzzle_screen.dart';
import 'games/symmetry_game_screen.dart';

class PlayHubScreen extends ConsumerWidget {
  const PlayHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sacred Pattern Arena'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Daily Challenge Mirrored Card
            const DailyChallengeCard(),
            const SizedBox(height: 22),

            // Arena Statistics Row
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: isDark ? AppColors.slateCard : AppColors.riceFlourCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem('Memory Won', '${profile.memoryGamesWon}', Icons.timer_rounded),
                  _buildDivider(isDark),
                  _buildStatItem('Puzzles Solved', '${profile.puzzlesCompleted}', Icons.extension_rounded),
                  _buildDivider(isDark),
                  _buildStatItem('Symmetry Found', '${profile.symmetryChallengesSolved}', Icons.flip_rounded),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 4 Games Header
            Text(
              'Sacred Heritage Games',
              style: AppTypography.cardTitle.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 12),

            // Game 1: Memory Game
            _buildGameCard(
              context: context,
              title: 'Kolam Memory Game',
              subtitle: 'Memorize the dawn Pulli pattern and recreate it on the canvas.',
              tag: 'Visual Memory & Focus',
              xpReward: '+50 XP',
              icon: Icons.psychology_rounded,
              iconColor: AppColors.terracottaRed,
              culturalFact: 'Traditional mothers train young girls to recall hundreds of dot matrices entirely from mental memory.',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const MemoryGameScreen()),
                );
              },
              isDark: isDark,
            ),
            const SizedBox(height: 14),

            // Game 2: Pattern Construction (16 Tiles)
            _buildGameCard(
              context: context,
              title: 'Pattern Construction (16-Tile)',
              subtitle: 'Assemble sacred curve primitives and rotate tiles to recreate target mandalas.',
              tag: 'Modular Construction',
              xpReward: '+50 XP',
              icon: Icons.dashboard_customize_rounded,
              iconColor: AppColors.turmericAmber,
              culturalFact: 'Kolam array grammars break down complex continuous paths into 16 fundamental curve primitives.',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const PatternConstructionScreen()),
                );
              },
              isDark: isDark,
            ),
            const SizedBox(height: 14),

            // Game 3: Kolam Puzzle
            _buildGameCard(
              context: context,
              title: 'Missing Piece Puzzle',
              subtitle: 'Identify the missing quadrant piece amongst tricky rotated decoys.',
              tag: 'Quadrant Geometry',
              xpReward: '+50 XP',
              icon: Icons.extension_rounded,
              iconColor: AppColors.tulsiGreen,
              culturalFact: 'Padi Kolams feature strictly balanced cardinal gates where all four quadrants must correspond in sacred alignment.',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const KolamPuzzleScreen()),
                );
              },
              isDark: isDark,
            ),
            const SizedBox(height: 14),

            // Game 4: Symmetry Game
            _buildGameCard(
              context: context,
              title: 'Symmetry Discovery Game',
              subtitle: 'Detect Dihedral D4 reflections, rotations, and transformation axes.',
              tag: 'Computational Geometry',
              xpReward: '+50 XP',
              icon: Icons.all_inclusive_rounded,
              iconColor: AppColors.templeIndigo,
              culturalFact: 'Verified live with on-device geometry algorithms measuring reflection planes and rotational invariance.',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SymmetryGameScreen()),
                );
              },
              isDark: isDark,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String tag,
    required String xpReward,
    required IconData icon,
    required Color iconColor,
    required String culturalFact,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: iconColor.withValues(alpha: 0.15),
                    child: Icon(icon, color: iconColor, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: iconColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  tag,
                                  style: AppTypography.tagText.copyWith(
                                    color: iconColor,
                                    fontSize: 10,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              xpReward,
                              style: AppTypography.tagText.copyWith(color: AppColors.turmericAmber),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          title,
                          style: AppTypography.cardTitle.copyWith(fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: AppTypography.caption.copyWith(fontSize: 12.5),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.temple_hindu_rounded, size: 14, color: AppColors.turmericAmber),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      culturalFact,
                      style: AppTypography.caption.copyWith(
                        fontSize: 11.5,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 18, color: AppColors.terracottaRed),
        const SizedBox(height: 4),
        Text(value, style: AppTypography.cardTitle.copyWith(fontSize: 16)),
        Text(label, style: AppTypography.caption.copyWith(fontSize: 11)),
      ],
    );
  }

  Widget _buildDivider(bool isDark) {
    return Container(
      height: 30,
      width: 1,
      color: isDark ? AppColors.borderDark : AppColors.borderLight,
    );
  }
}
