import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../data/models/sample_kolam_design.dart';
import '../../data/seed/sample_designs_library.dart';
import '../../services/analysis_service.dart';
import '../common/empty_state_widget.dart';
import 'kolam_replay_screen.dart';

class SampleDesignsGalleryScreen extends StatefulWidget {
  final Function(SampleKolamDesign)? onSelectSample;

  const SampleDesignsGalleryScreen({
    super.key,
    this.onSelectSample,
  });

  @override
  State<SampleDesignsGalleryScreen> createState() => _SampleDesignsGalleryScreenState();
}

class _SampleDesignsGalleryScreenState extends State<SampleDesignsGalleryScreen> {
  KolamDifficulty? _selectedDifficulty; // null = all
  int? _selectedGridSize; // null = all

  void _selectAndTrace(SampleKolamDesign design) {
    if (widget.onSelectSample != null) {
      widget.onSelectSample!(design);
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).pop(design);
    }
  }

  void _openReplay(BuildContext context, SampleKolamDesign design) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => KolamReplayScreen(
          title: design.name,
          tamilTitle: design.tamilName,
          category: design.category,
          gridSize: design.gridSize,
          strokes: design.strokes,
          sampleDesign: design,
        ),
      ),
    );
  }

  void _showDesignDetailModal(BuildContext context, SampleKolamDesign design, bool isDark) {
    final diffColor = _getDifficultyColor(design.difficulty);

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.slateDark : AppColors.riceFlourBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: diffColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: diffColor),
                  ),
                  child: Text(
                    '${design.difficulty.label} • ${design.gridSize}x${design.gridSize} Grid',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: diffColor,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(sheetCtx).pop(),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(design.name, style: AppTypography.screenHeading),
            Text(
              design.tamilName,
              style: AppTypography.caption.copyWith(
                fontSize: 14,
                color: AppColors.turmericGold,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              design.culturalLore,
              style: AppTypography.bodyText.copyWith(color: isDark ? Colors.white70 : Colors.black87),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.turmericAmber,
                      side: const BorderSide(color: AppColors.turmericAmber),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.play_circle_fill_rounded, size: 18),
                    label: const Text(
                      'Watch Replay',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    onPressed: () {
                      Navigator.of(sheetCtx).pop();
                      _openReplay(context, design);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.terracottaRed,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.gesture_rounded, size: 18),
                    label: const Text(
                      'Trace Pattern',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    onPressed: () {
                      Navigator.of(sheetCtx).pop();
                      _selectAndTrace(design);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final allDesigns = SampleDesignsLibrary.allSamples;
    final filteredDesigns = allDesigns.where((design) {
      if (_selectedDifficulty != null && design.difficulty != _selectedDifficulty) {
        return false;
      }
      if (_selectedGridSize != null && design.gridSize != _selectedGridSize) {
        return false;
      }
      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kolam Sample Designs'),
        centerTitle: false,
      ),
      body: Column(
        children: [
          // Filter Chips Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.slateCard : AppColors.riceFlourCard,
              border: Border(
                bottom: BorderSide(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.school_rounded, size: 16, color: AppColors.turmericAmber),
                    const SizedBox(width: 8),
                    Text(
                      'Learn Sacred Patterns by Tracing',
                      style: AppTypography.tagText.copyWith(
                        color: AppColors.turmericAmber,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Difficulty Filter Row
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: FilterChip(
                          label: Text('All (${allDesigns.length})'),
                          selected: _selectedDifficulty == null && _selectedGridSize == null,
                          onSelected: (_) {
                            setState(() {
                              _selectedDifficulty = null;
                              _selectedGridSize = null;
                            });
                          },
                        ),
                      ),
                      ...KolamDifficulty.values.map((diff) {
                        final count = allDesigns.where((d) => d.difficulty == diff).length;
                        final isSel = _selectedDifficulty == diff;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: FilterChip(
                            label: Text('${diff.label} ($count)'),
                            selected: isSel,
                            selectedColor: _getDifficultyColor(diff).withValues(alpha: 0.25),
                            checkmarkColor: _getDifficultyColor(diff),
                            onSelected: (val) {
                              setState(() => _selectedDifficulty = val ? diff : null);
                            },
                          ),
                        );
                      }),
                      const SizedBox(width: 12),
                      // Grid Filter Chips
                      ...[5, 7, 9].map((grid) {
                        final isSel = _selectedGridSize == grid;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: FilterChip(
                            label: Text('${grid}x$grid'),
                            selected: isSel,
                            onSelected: (val) {
                              setState(() => _selectedGridSize = val ? grid : null);
                            },
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Presets Grid
          Expanded(
            child: filteredDesigns.isEmpty
                ? EmptyStateWidget(
                    icon: Icons.search_off_rounded,
                    title: 'No Matching Kolam Patterns',
                    message: 'Try clearing difficulty or grid filters to explore our curated sacred library.',
                    actionLabel: 'Reset Filters',
                    onAction: () {
                      setState(() {
                        _selectedDifficulty = null;
                        _selectedGridSize = null;
                      });
                    },
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      childAspectRatio: 0.65,
                    ),
                    itemCount: filteredDesigns.length,
                    itemBuilder: (context, index) {
                      final design = filteredDesigns[index];
                      return _buildDesignCard(context, design, isDark);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Color _getDifficultyColor(KolamDifficulty diff) {
    switch (diff) {
      case KolamDifficulty.easy:
        return AppColors.tulsiGreen;
      case KolamDifficulty.medium:
        return AppColors.turmericAmber;
      case KolamDifficulty.hard:
        return AppColors.crimsonRed;
    }
  }

  Widget _buildDesignCard(BuildContext context, SampleKolamDesign design, bool isDark) {
    final diffColor = _getDifficultyColor(design.difficulty);

    return InkWell(
      onTap: () => _showDesignDetailModal(context, design, isDark),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.slateCard : AppColors.riceFlourCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Preview Thumbnail Canvas
            Expanded(
              flex: 5,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                child: Container(
                  color: const Color(0xFF261E21), // Traditional red-earth background
                  child: Stack(
                    children: [
                      CustomPaint(
                        size: Size.infinite,
                        painter: _MiniPatternPainter(
                          gridSize: design.gridSize,
                          strokes: design.strokes,
                        ),
                      ),
                      // Difficulty Pill (Top-Left)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: diffColor.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: Text(
                            design.difficulty.label,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      // Grid Size Pill (Top-Right)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.65),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${design.gridSize}x${design.gridSize}',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.white70,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Metadata & Action Buttons
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          design.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.cardTitle.copyWith(fontSize: 12.5),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          design.tamilName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.caption.copyWith(
                            fontSize: 10.5,
                            color: AppColors.turmericGold,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          design.category,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.caption.copyWith(fontSize: 9.5),
                        ),
                      ],
                    ),

                    // Actions Row: Trace Button + Watch Replay Icon Button
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 28,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.terracottaRed,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              icon: const Icon(Icons.gesture_rounded, size: 13),
                              label: const Text(
                                'Trace',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                              onPressed: () => _selectAndTrace(design),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Tooltip(
                          message: 'Watch how this was drawn',
                          child: Material(
                            color: AppColors.turmericGold.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(8),
                              onTap: () => _openReplay(context, design),
                              child: Container(
                                height: 28,
                                width: 32,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: AppColors.turmericGold.withValues(alpha: 0.4),
                                  ),
                                ),
                                child: const Icon(
                                  Icons.play_circle_fill_rounded,
                                  size: 18,
                                  color: AppColors.turmericAmber,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniPatternPainter extends CustomPainter {
  final int gridSize;
  final List<KolamStroke> strokes;

  _MiniPatternPainter({
    required this.gridSize,
    required this.strokes,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw Pulli Dots
    final step = size.width / (gridSize + 1);
    final dotPaint = Paint()
      ..color = const Color(0xFFFBF4E8).withValues(alpha: 0.75)
      ..style = PaintingStyle.fill;

    for (int r = 1; r <= gridSize; r++) {
      for (int c = 1; c <= gridSize; c++) {
        canvas.drawCircle(Offset(c * step, r * step), 1.6, dotPaint);
      }
    }

    // 2. Draw Sample Strokes (scaled from 350x350 canvas coordinate baseline)
    final scale = size.width / 350.0;

    final strokePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = max(1.2, 2.8 * scale)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    for (final stroke in strokes) {
      if (stroke.points.length < 2) continue;

      final path = Path();
      path.moveTo(stroke.points.first.x * scale, stroke.points.first.y * scale);

      for (int i = 1; i < stroke.points.length; i++) {
        final p0 = stroke.points[i - 1];
        final p1 = stroke.points[i];
        final midX = ((p0.x + p1.x) / 2) * scale;
        final midY = ((p0.y + p1.y) / 2) * scale;
        path.quadraticBezierTo(p0.x * scale, p0.y * scale, midX, midY);
      }
      path.lineTo(stroke.points.last.x * scale, stroke.points.last.y * scale);

      canvas.drawPath(path, strokePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _MiniPatternPainter oldDelegate) => false;
}
