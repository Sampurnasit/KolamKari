import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../data/models/analysis_result.dart';

class SmartAnalysisSheet extends StatelessWidget {
  final AnalysisResult result;
  final VoidCallback onSavePressed;

  const SmartAnalysisSheet({
    super.key,
    required this.result,
    required this.onSavePressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.slateCard : AppColors.riceFlourCard,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.auto_awesome_rounded, color: AppColors.turmericGold, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      'AI Pattern Analysis',
                      style: AppTypography.screenHeading.copyWith(fontSize: 20),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.tulsiGreen.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'On-Device Geometry',
                    style: AppTypography.tagText.copyWith(color: AppColors.tulsiGreen),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Computational geometry evaluation of geometric symmetry, loops, and spatial complexity.',
              style: AppTypography.caption,
            ),
            const SizedBox(height: 18),

            // Complexity Metric Score Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [AppColors.slateDark, AppColors.slateLight]
                      : [const Color(0xFFFAF2E6), const Color(0xFFF5E4CE)],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.turmericGold.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  // Circular Score gauge
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 70,
                        height: 70,
                        child: CircularProgressIndicator(
                          value: (result.complexityScore / 100).clamp(0.0, 1.0),
                          strokeWidth: 6,
                          backgroundColor: isDark ? Colors.black38 : Colors.white,
                          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.turmericGold),
                        ),
                      ),
                      Text(
                        '${result.complexityScore}',
                        style: AppTypography.displayTitle.copyWith(
                          fontSize: 22,
                          color: AppColors.turmericAmber,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 18),

                  // Score text
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Complexity Index: ',
                              style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              result.complexityTier,
                              style: AppTypography.cardTitle.copyWith(
                                color: AppColors.terracottaRed,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Evaluated across ${result.strokeCount} strokes, ${result.closedLoopCount} closed loops, and ${result.intersectionCount} intersection nodes.',
                          style: AppTypography.bodyText.copyWith(fontSize: 12.5),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Grid Attributes Grid (2x2)
            Row(
              children: [
                Expanded(
                  child: _buildMetricTile(
                    label: 'Symmetry Family',
                    value: _formatSymmetryName(result.symmetryType),
                    icon: Icons.filter_vintage_rounded,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMetricTile(
                    label: 'Reflection Detected',
                    value: result.reflectionDetected ? 'Yes (${result.reflectionAxesCount} Axes)' : 'None',
                    icon: Icons.flip_rounded,
                    isDark: isDark,
                  ),
                ),
              ],
            ),
            if (result.matchingReflectionAxes.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: result.matchingReflectionAxes.map((axis) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.turmericGold.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.turmericGold.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      '✓ $axis',
                      style: AppTypography.caption.copyWith(
                        fontSize: 10.5,
                        color: AppColors.turmericAmber,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildMetricTile(
                    label: 'Rotational Order',
                    value: result.rotationalSymmetrySummary != 'None'
                        ? '${result.rotationalSymmetrySummary} Invariant'
                        : 'None',
                    icon: Icons.rotate_right_rounded,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMetricTile(
                    label: 'Structure Summary',
                    value: result.structureSummary.isNotEmpty
                        ? result.structureSummary
                        : '${result.gridSize} • ${result.closedLoopCount} Loops',
                    icon: Icons.all_inclusive_rounded,
                    isDark: isDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Cultural Interpretation
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? AppColors.slateDark : const Color(0xFFF9F3EA),
                borderRadius: BorderRadius.circular(12),
                border: const Border(
                  left: BorderSide(color: AppColors.turmericGold, width: 4),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.temple_hindu_rounded, size: 18, color: AppColors.turmericAmber),
                      const SizedBox(width: 6),
                      Text(
                        'Cultural & Geometric Interpretation',
                        style: AppTypography.tagText.copyWith(color: AppColors.turmericAmber),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    result.culturalInterpretation,
                    style: AppTypography.bodyText.copyWith(fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Formula Breakdown Expansion
            ExpansionTile(
              title: Text(
                'View 7-Factor Complexity Weights',
                style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold),
              ),
              tilePadding: EdgeInsets.zero,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text(
                    'Score Formula: C = (2.0 × Strokes) + (7.0 × Loops) + (2.5 × Intersections) + GridScale + Density + ShapeDiversity + SymmetryBonus.',
                    style: AppTypography.caption.copyWith(fontSize: 12),
                  ),
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: result.formulaBreakdown.entries.map((e) {
                    return Chip(
                      label: Text('${e.key}: ${e.value}'),
                      labelStyle: AppTypography.caption.copyWith(fontSize: 11),
                      backgroundColor: isDark ? AppColors.slateDark : AppColors.borderLight,
                      padding: EdgeInsets.zero,
                    );
                  }).toList(),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Save Kolam Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onSavePressed,
                icon: const Icon(Icons.bookmark_add_rounded, color: Colors.white),
                label: const Text('Save Kolam to Collection (+40 XP)'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricTile({
    required String label,
    required String value,
    required IconData icon,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.slateDark : AppColors.riceFlourBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppColors.terracottaRed),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTypography.caption.copyWith(fontSize: 11.5),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: AppTypography.cardTitle.copyWith(fontSize: 13.5),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  String _formatSymmetryName(SymmetryType type) {
    switch (type) {
      case SymmetryType.dihedralD4:
        return 'Dihedral D4 (Mandala)';
      case SymmetryType.fourFoldReflection:
        return '4-Fold Reflection';
      case SymmetryType.twoFoldReflection:
        return '2-Fold Dual Mirror';
      case SymmetryType.bilateralReflection:
        return 'Bilateral Reflection';
      case SymmetryType.rotational90:
        return '90° 4-Fold Rotation';
      case SymmetryType.rotational180:
        return '180° 2-Fold Rotation';
      case SymmetryType.none:
        return 'Organic Freeform';
    }
  }
}
