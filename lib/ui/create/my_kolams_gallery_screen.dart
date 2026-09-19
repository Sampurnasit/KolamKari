import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../data/models/analysis_result.dart';
import '../../data/models/saved_kolam.dart';
import '../../providers/app_providers.dart';
import '../../services/analysis_service.dart';
import 'widgets/kolam_canvas_widget.dart';
import 'kolam_replay_screen.dart';

enum KolamSortType {
  newest('Newest Date'),
  oldest('Oldest Date'),
  complexityDesc('Highest Complexity'),
  complexityAsc('Lowest Complexity');

  final String label;
  const KolamSortType(this.label);
}

enum KolamFilterType {
  all('All'),
  original('Originals'),
  traced('Traced');

  final String label;
  const KolamFilterType(this.label);
}

class MyKolamsGalleryScreen extends ConsumerStatefulWidget {
  const MyKolamsGalleryScreen({super.key});

  @override
  ConsumerState<MyKolamsGalleryScreen> createState() => _MyKolamsGalleryScreenState();
}

class _MyKolamsGalleryScreenState extends ConsumerState<MyKolamsGalleryScreen> {
  KolamSortType _activeSort = KolamSortType.newest;
  KolamFilterType _activeFilter = KolamFilterType.all;

  @override
  Widget build(BuildContext context) {
    final allKolams = ref.watch(savedKolamsProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Filter and sort the collection
    final filteredKolams = _applyFilterAndSort(allKolams);

    final originalCount = allKolams.where((k) => !k.isTracedCopy).length;
    final tracedCount = allKolams.where((k) => k.isTracedCopy).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Saved Kolams'),
        actions: [
          if (allKolams.isNotEmpty)
            PopupMenuButton<KolamSortType>(
              icon: const Icon(Icons.sort_rounded),
              tooltip: 'Sort Kolams',
              initialValue: _activeSort,
              onSelected: (sort) {
                setState(() => _activeSort = sort);
              },
              itemBuilder: (ctx) => KolamSortType.values.map((sort) {
                final isSelected = sort == _activeSort;
                return PopupMenuItem<KolamSortType>(
                  value: sort,
                  child: Row(
                    children: [
                      Icon(
                        isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                        size: 18,
                        color: isSelected ? AppColors.turmericAmber : AppColors.textMuted,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        sort.label,
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? AppColors.turmericAmber : null,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
      body: allKolams.isEmpty
          ? _buildEmptyGalleryState(context, isDark)
          : Column(
              children: [
                // Filter and Summary Bar
                _buildFilterBar(
                  isDark: isDark,
                  totalCount: allKolams.length,
                  originalCount: originalCount,
                  tracedCount: tracedCount,
                  displayedCount: filteredKolams.length,
                ),

                // Grid of Kolam Cards
                Expanded(
                  child: filteredKolams.isEmpty
                      ? _buildNoFilterMatchState(isDark)
                      : GridView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 14,
                            childAspectRatio: 0.74,
                          ),
                          itemCount: filteredKolams.length,
                          itemBuilder: (context, index) {
                            final kolam = filteredKolams[index];
                            return _buildKolamCard(context, kolam, isDark);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  List<SavedKolam> _applyFilterAndSort(List<SavedKolam> list) {
    List<SavedKolam> result = List.from(list);

    // Filter
    switch (_activeFilter) {
      case KolamFilterType.original:
        result = result.where((k) => !k.isTracedCopy).toList();
        break;
      case KolamFilterType.traced:
        result = result.where((k) => k.isTracedCopy).toList();
        break;
      case KolamFilterType.all:
        break;
    }

    // Sort
    switch (_activeSort) {
      case KolamSortType.newest:
        result.sort((a, b) => b.createdDate.compareTo(a.createdDate));
        break;
      case KolamSortType.oldest:
        result.sort((a, b) => a.createdDate.compareTo(b.createdDate));
        break;
      case KolamSortType.complexityDesc:
        result.sort((a, b) => b.complexityScore.compareTo(a.complexityScore));
        break;
      case KolamSortType.complexityAsc:
        result.sort((a, b) => a.complexityScore.compareTo(b.complexityScore));
        break;
    }

    return result;
  }

  // --- Filter and Sort Bar ---

  Widget _buildFilterBar({
    required bool isDark,
    required int totalCount,
    required int originalCount,
    required int tracedCount,
    required int displayedCount,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.slateCard : AppColors.riceFlourCard,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
      ),
      child: Row(
        children: [
          // Filter Segmented Chips
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip(
                    filter: KolamFilterType.all,
                    label: 'All ($totalCount)',
                    isDark: isDark,
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    filter: KolamFilterType.original,
                    label: 'Originals ($originalCount)',
                    isDark: isDark,
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    filter: KolamFilterType.traced,
                    label: 'Traced ($tracedCount)',
                    isDark: isDark,
                  ),
                ],
              ),
            ),
          ),

          // Active Sort Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isDark ? AppColors.slateLight : AppColors.borderLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.swap_vert_rounded, size: 14, color: AppColors.turmericAmber),
                const SizedBox(width: 4),
                Text(
                  _activeSort.label.split(' ').first,
                  style: AppTypography.caption.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    color: AppColors.turmericAmber,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required KolamFilterType filter,
    required String label,
    required bool isDark,
  }) {
    final isSelected = _activeFilter == filter;
    return InkWell(
      onTap: () => setState(() => _activeFilter = filter),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.terracottaRed
              : (isDark ? AppColors.slateDark : AppColors.riceFlourBg),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.terracottaRed
                : (isDark ? AppColors.borderDark : AppColors.borderLight),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.terracottaRed.withValues(alpha: 0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: AppTypography.tagText.copyWith(
            color: isSelected ? Colors.white : AppColors.textMuted,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 11.5,
          ),
        ),
      ),
    );
  }

  // --- Kolam Card ---

  Widget _buildKolamCard(BuildContext context, SavedKolam kolam, bool isDark) {
    final dateStr = DateFormat('dd MMM yyyy').format(kolam.createdDate);
    final strokes = _decodeStrokes(kolam.canvasStrokeData);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showKolamDetailDialog(context, kolam, strokes, isDark),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Preview thumbnail container with badges overlay
            Expanded(
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    height: double.infinity,
                    color: const Color(0xFF23191D), // Deep authentic earthen background
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: KolamCanvasWidget(
                          gridSize: kolam.gridSize,
                          showDots: true,
                          strokes: strokes,
                          onPanStart: (_) {},
                          onPanUpdate: (_) {},
                          onPanEnd: () {},
                        ),
                      ),
                    ),
                  ),

                  // Complexity score badge: small colored pill (green/yellow/red by score range)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: _buildComplexityBadge(kolam.complexityScore),
                  ),

                  // Traced vs Original tag badge
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: kolam.isTracedCopy
                            ? AppColors.turmericAmber.withValues(alpha: 0.9)
                            : AppColors.tulsiGreen.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        kolam.isTracedCopy ? 'Traced' : 'Original',
                        style: const TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Card details
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    kolam.name,
                    style: AppTypography.cardTitle.copyWith(fontSize: 13.5),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '${kolam.gridSize}x${kolam.gridSize} • $dateStr',
                          style: AppTypography.caption.copyWith(fontSize: 10.5),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => KolamReplayScreen(
                                title: kolam.name,
                                category: kolam.culturalTag ?? (kolam.isTracedCopy ? 'Traced Kolam' : 'Original Creation'),
                                gridSize: kolam.gridSize,
                                strokes: strokes,
                              ),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: const Padding(
                          padding: EdgeInsets.all(2),
                          child: Icon(
                            Icons.play_circle_fill_rounded,
                            size: 20,
                            color: AppColors.turmericAmber,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Complexity score badge pill (green < 40, yellow 40-69, red >= 70)
  Widget _buildComplexityBadge(int score) {
    Color badgeColor;
    if (score < 40) {
      badgeColor = AppColors.tulsiGreen;
    } else if (score < 70) {
      badgeColor = AppColors.turmericAmber;
    } else {
      badgeColor = AppColors.crimsonRed;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: badgeColor.withValues(alpha: 0.4),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, size: 12, color: Colors.white),
          const SizedBox(width: 2.5),
          Text(
            '$score',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 10.5,
            ),
          ),
        ],
      ),
    );
  }

  // --- Detail View Dialog ---

  void _showKolamDetailDialog(
    BuildContext context,
    SavedKolam kolam,
    List<KolamStroke> strokes,
    bool isDark,
  ) {
    final analysis = kolam.analysisResult;
    final formattedDate = DateFormat('EEEE, dd MMMM yyyy • hh:mm a').format(kolam.createdDate);

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            titlePadding: const EdgeInsets.fromLTRB(20, 16, 12, 0),
            contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    kolam.name,
                    style: AppTypography.screenHeading.copyWith(fontSize: 18),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 20),
                      tooltip: 'Rename Kolam',
                      onPressed: () {
                        _promptRenameKolam(context, kolam, () {
                          Navigator.of(dialogCtx).pop();
                        });
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, size: 20, color: AppColors.crimsonRed),
                      tooltip: 'Delete Kolam',
                      onPressed: () {
                        _promptDeleteKolam(context, kolam, () {
                          Navigator.of(dialogCtx).pop();
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
            content: SizedBox(
              width: 320,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Full Pattern Render in traditional canvas box
                    Center(
                      child: Container(
                        height: 230,
                        width: 230,
                        decoration: BoxDecoration(
                          color: const Color(0xFF261E21),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark ? AppColors.borderDark : AppColors.borderLight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: KolamCanvasWidget(
                            gridSize: kolam.gridSize,
                            showDots: true,
                            strokes: strokes,
                            onPanStart: (_) {},
                            onPanUpdate: (_) {},
                            onPanEnd: () {},
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Attribution Banner: Traced from sample vs Original creation
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: kolam.isTracedCopy
                            ? AppColors.turmericAmber.withValues(alpha: 0.12)
                            : AppColors.tulsiGreen.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: kolam.isTracedCopy
                              ? AppColors.turmericAmber.withValues(alpha: 0.3)
                              : AppColors.tulsiGreen.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            kolam.isTracedCopy ? Icons.history_edu_rounded : Icons.brush_rounded,
                            size: 16,
                            color: kolam.isTracedCopy ? AppColors.turmericAmber : AppColors.tulsiGreen,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  kolam.isTracedCopy ? 'Traced from Sample Design' : 'Original Studio Creation',
                                  style: AppTypography.cardTitle.copyWith(
                                    fontSize: 12,
                                    color: kolam.isTracedCopy ? AppColors.turmericAmber : AppColors.tulsiGreen,
                                  ),
                                ),
                                if (kolam.culturalTag != null && kolam.culturalTag!.isNotEmpty)
                                  Text(
                                    kolam.culturalTag!,
                                    style: AppTypography.caption.copyWith(fontSize: 10.5),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Date & Basic Metrics Row
                    Text(
                      'Saved on $formattedDate',
                      style: AppTypography.caption.copyWith(fontSize: 11),
                    ),
                    const SizedBox(height: 12),

                    // Analysis Result Details
                    if (analysis != null) ...[
                      Container(
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
                                const Icon(Icons.auto_awesome_rounded, size: 14, color: AppColors.turmericAmber),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Sacred Geometry Analysis',
                                    style: AppTypography.cardTitle.copyWith(fontSize: 12),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _buildComplexityBadge(kolam.complexityScore),
                              ],
                            ),
                            const Divider(height: 16),
                            _buildDetailRow('Symmetry Family', _formatSymmetryName(analysis.symmetryType)),
                            _buildDetailRow('Rotational Order', analysis.rotationalSymmetrySummary != 'None' ? '${analysis.rotationalSymmetrySummary} Invariant' : 'None'),
                            _buildDetailRow('Reflection Detected', analysis.reflectionDetected ? 'Yes (${analysis.reflectionAxesCount} Axes)' : 'None'),
                            _buildDetailRow('Structure', analysis.structureSummary.isNotEmpty ? analysis.structureSummary : '${kolam.gridSize}x${kolam.gridSize} Grid • ${analysis.closedLoopCount} Loops'),
                            if (analysis.culturalInterpretation.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                analysis.culturalInterpretation,
                                style: AppTypography.bodyText.copyWith(fontSize: 11.5, fontStyle: FontStyle.italic),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ] else ...[
                      // Fallback when analysis is not stored
                      Row(
                        children: [
                          Expanded(child: _buildMiniStat('Grid Size', '${kolam.gridSize}x${kolam.gridSize}')),
                          Expanded(child: _buildMiniStat('Complexity', '${kolam.complexityScore}/100')),
                          Expanded(child: _buildMiniStat('Strokes', '${strokes.length}')),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Prominent Replay Button: "Watch how this was drawn"
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.turmericGold,
                          foregroundColor: Colors.black87,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 3,
                        ),
                        icon: const Icon(Icons.play_circle_fill_rounded, size: 22, color: Colors.black87),
                        label: const Text(
                          'Watch how this was drawn',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        onPressed: () {
                          Navigator.of(dialogCtx).pop();
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => KolamReplayScreen(
                                title: kolam.name,
                                category: kolam.culturalTag ?? (kolam.isTracedCopy ? 'Traced Kolam' : 'Original Creation'),
                                gridSize: kolam.gridSize,
                                strokes: strokes,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogCtx).pop(),
                child: const Text('Close'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTypography.caption.copyWith(fontSize: 11)),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              style: AppTypography.cardTitle.copyWith(fontSize: 11.5),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value) {
    return Column(
      children: [
        Text(label, style: AppTypography.caption),
        const SizedBox(height: 2),
        Text(value, style: AppTypography.cardTitle.copyWith(fontSize: 13)),
      ],
    );
  }

  // --- Rename Action ---

  void _promptRenameKolam(BuildContext context, SavedKolam kolam, [VoidCallback? onRenamed]) {
    final controller = TextEditingController(text: kolam.name);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename Kolam'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Kolam Name',
            hintText: 'e.g. Lotus Sikku Twilight',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                Navigator.of(ctx).pop();
                await ref.read(savedKolamsProvider.notifier).rename(kolam.id, newName);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: AppColors.tulsiGreen,
                      content: Text('Renamed to "$newName"'),
                    ),
                  );
                }
                onRenamed?.call();
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // --- Delete with Confirmation Action ---

  void _promptDeleteKolam(BuildContext context, SavedKolam kolam, [VoidCallback? onDeleted]) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Kolam?'),
        content: Text('Are you sure you want to delete "${kolam.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.crimsonRed),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await ref.read(savedKolamsProvider.notifier).delete(kolam.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: AppColors.slateDark,
                    content: Text('"${kolam.name}" deleted from your gallery.'),
                  ),
                );
              }
              onDeleted?.call();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // --- Empty States ---

  Widget _buildEmptyGalleryState(BuildContext context, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(26),
              decoration: BoxDecoration(
                color: AppColors.terracottaRed.withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.terracottaRed.withValues(alpha: 0.3), width: 1.5),
              ),
              child: const Icon(
                Icons.palette_outlined,
                size: 64,
                color: AppColors.terracottaRed,
              ),
            ),
            const SizedBox(height: 22),
            Text(
              'Your Kolam Gallery is Empty',
              style: AppTypography.screenHeading.copyWith(fontSize: 20),
            ),
            const SizedBox(height: 8),
            Text(
              'Draw sacred patterns upon the pulli grid, analyze geometric symmetry, and curate your personal heritage collection.',
              style: AppTypography.bodyText.copyWith(color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 26),
            ElevatedButton.icon(
              onPressed: () {
                // If can pop (navigated from studio), pop back; otherwise navigate to Create Studio
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                } else {
                  ref.read(currentNavIndexProvider.notifier).state = 3;
                }
              },
              icon: const Icon(Icons.brush_rounded, color: Colors.white),
              label: const Text('Draw in Studio', style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.terracottaRed,
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoFilterMatchState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.filter_list_off_rounded,
              size: 48,
              color: isDark ? Colors.white38 : Colors.black26,
            ),
            const SizedBox(height: 16),
            Text(
              'No Kolams Match Filter',
              style: AppTypography.cardTitle.copyWith(fontSize: 16),
            ),
            const SizedBox(height: 6),
            Text(
              'Try changing your filter settings to view all saved patterns.',
              style: AppTypography.caption,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => setState(() => _activeFilter = KolamFilterType.all),
              child: const Text('Show All Kolams'),
            ),
          ],
        ),
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

  List<KolamStroke> _decodeStrokes(String jsonStr) {
    try {
      final list = jsonDecode(jsonStr) as List;
      return list.map((item) => KolamStroke.fromJson(Map<String, dynamic>.from(item))).toList();
    } catch (_) {
      return [];
    }
  }
}
