import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../data/models/sample_kolam_design.dart';
import '../../services/analysis_service.dart';
import 'create_studio_screen.dart';

class KolamReplayScreen extends StatefulWidget {
  final String title;
  final String? tamilTitle;
  final String? category;
  final int gridSize;
  final List<KolamStroke> strokes;
  final SampleKolamDesign? sampleDesign;

  const KolamReplayScreen({
    super.key,
    required this.title,
    this.tamilTitle,
    this.category,
    required this.gridSize,
    required this.strokes,
    this.sampleDesign,
  });

  @override
  State<KolamReplayScreen> createState() => _KolamReplayScreenState();
}

class _KolamReplayScreenState extends State<KolamReplayScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _playbackSpeed = 1.0;

  // Timeline metadata
  late final int _totalSegments;
  late final List<int> _strokeSegmentOffsets; // Cumulative segment counts

  @override
  void initState() {
    super.initState();

    // 1. Calculate segment distribution across strokes
    _strokeSegmentOffsets = [0];
    int runningSegments = 0;
    for (final s in widget.strokes) {
      final segments = max(1, s.points.length - 1);
      runningSegments += segments;
      _strokeSegmentOffsets.add(runningSegments);
    }
    _totalSegments = max(1, runningSegments);

    // 2. Duration scales with complexity: ~70ms per segment, clamped between 3.5s and 16s
    final baseDurationMs = (_totalSegments * 70).clamp(3500, 16000);

    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: baseDurationMs),
    )..addListener(() {
        setState(() {});
      })
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          setState(() {});
        }
      });

    // Automatically start replay after a brief pause
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    if (_controller.isAnimating) {
      _controller.stop();
    } else {
      if (_controller.isCompleted) {
        _controller.reset();
      }
      _controller.forward();
    }
  }

  void _setSpeed(double speed) {
    setState(() {
      _playbackSpeed = speed;
      final baseDurationMs = (_totalSegments * 70).clamp(3500, 16000);
      final adjustedDuration = (baseDurationMs / speed).round();
      _controller.duration = Duration(milliseconds: adjustedDuration);

      if (_controller.isAnimating) {
        _controller.forward();
      }
    });
  }

  void _stepBackward() {
    final currentProgress = _controller.value;
    final currentGlobalSegment = (currentProgress * _totalSegments).floor();

    // Find current stroke index
    int strokeIdx = 0;
    for (int i = 0; i < _strokeSegmentOffsets.length - 1; i++) {
      if (currentGlobalSegment >= _strokeSegmentOffsets[i]) {
        strokeIdx = i;
      }
    }

    final targetStrokeIdx = max(0, strokeIdx - 1);
    final targetProgress = _strokeSegmentOffsets[targetStrokeIdx] / _totalSegments;
    _controller.animateTo(targetProgress, duration: const Duration(milliseconds: 250));
  }

  void _stepForward() {
    final currentProgress = _controller.value;
    final currentGlobalSegment = (currentProgress * _totalSegments).floor();

    // Find current stroke index
    int strokeIdx = 0;
    for (int i = 0; i < _strokeSegmentOffsets.length - 1; i++) {
      if (currentGlobalSegment >= _strokeSegmentOffsets[i]) {
        strokeIdx = i;
      }
    }

    final targetStrokeIdx = min(widget.strokes.length - 1, strokeIdx + 1);
    final targetProgress = _strokeSegmentOffsets[targetStrokeIdx + 1] / _totalSegments;
    _controller.animateTo(targetProgress, duration: const Duration(milliseconds: 250));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Calculate current stroke index and progress
    final globalProgress = _controller.value;
    final currentSeg = (globalProgress * _totalSegments).clamp(0, _totalSegments - 1);
    int currentStrokeIndex = 0;
    for (int i = 0; i < _strokeSegmentOffsets.length - 1; i++) {
      if (currentSeg >= _strokeSegmentOffsets[i]) {
        currentStrokeIndex = i;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kolam Stroke Replay'),
        actions: [
          if (widget.sampleDesign != null)
            TextButton.icon(
              style: TextButton.styleFrom(foregroundColor: AppColors.turmericAmber),
              icon: const Icon(Icons.gesture_rounded, size: 18),
              label: const Text('Trace This', style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => CreateStudioScreen(
                      initialSampleDesign: widget.sampleDesign,
                    ),
                  ),
                );
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // Header Information Card
          Container(
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: AppTypography.screenHeading.copyWith(fontSize: 16),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (widget.tamilTitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          widget.tamilTitle!,
                          style: AppTypography.caption.copyWith(
                            color: AppColors.turmericGold,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.turmericAmber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.turmericAmber.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.history_edu_rounded, size: 14, color: AppColors.turmericAmber),
                      const SizedBox(width: 5),
                      Text(
                        'Stroke ${currentStrokeIndex + 1} of ${widget.strokes.length}',
                        style: AppTypography.tagText.copyWith(
                          fontSize: 11,
                          color: AppColors.turmericAmber,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Center Replay Canvas
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final canvasDim = min(constraints.maxWidth, constraints.maxHeight);

                    return Container(
                      width: canvasDim,
                      height: canvasDim,
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.slateDark : AppColors.riceFlourBg,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: isDark ? Colors.black.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.08),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                        border: Border.all(
                          color: isDark ? AppColors.turmericGold.withValues(alpha: 0.4) : AppColors.borderLight,
                          width: 2.0,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: CustomPaint(
                          size: Size(canvasDim, canvasDim),
                          painter: _ReplayCanvasPainter(
                            gridSize: widget.gridSize,
                            strokes: widget.strokes,
                            progress: _controller.value,
                            strokeSegmentOffsets: _strokeSegmentOffsets,
                            totalSegments: _totalSegments,
                            isDark: isDark,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

          // Playback Control Panel
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.slateCard : AppColors.riceFlourCard,
              border: Border(
                top: BorderSide(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                ),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Scrubber Seek Bar with Time/Percentage
                Row(
                  children: [
                    Text(
                      '${(_controller.value * 100).round()}%',
                      style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                    Expanded(
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: AppColors.turmericGold,
                          inactiveTrackColor: isDark ? AppColors.slateLight : AppColors.borderLight,
                          thumbColor: AppColors.turmericGold,
                          overlayColor: AppColors.turmericGold.withValues(alpha: 0.2),
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                          trackHeight: 3.5,
                        ),
                        child: Slider(
                          value: _controller.value.clamp(0.0, 1.0),
                          onChanged: (val) {
                            if (_controller.isAnimating) {
                              _controller.stop();
                            }
                            setState(() {
                              _controller.value = val;
                            });
                          },
                        ),
                      ),
                    ),
                    Text(
                      '${widget.strokes.length} strokes',
                      style: AppTypography.caption.copyWith(fontSize: 11),
                    ),
                  ],
                ),

                const SizedBox(height: 6),

                // Playback Controls Row: Speed Chips | Step Back | Play/Pause | Step Forward | Restart
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Speed Selector Chips (0.5x, 1x, 2x)
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.slateLight : AppColors.borderLight,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [0.5, 1.0, 2.0].map((speed) {
                          final isSel = _playbackSpeed == speed;
                          return GestureDetector(
                            onTap: () => _setSpeed(speed),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: isSel ? AppColors.terracottaRed : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${speed == 1.0 ? '1' : speed}x',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                  color: isSel ? Colors.white : AppColors.textMuted,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    // Media Action Controls
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.skip_previous_rounded),
                          tooltip: 'Previous Stroke',
                          onPressed: _stepBackward,
                        ),
                        IconButton(
                          icon: const Icon(Icons.replay_rounded),
                          tooltip: 'Restart',
                          onPressed: () {
                            _controller.reset();
                            _controller.forward();
                          },
                        ),
                        Container(
                          decoration: const BoxDecoration(
                            color: AppColors.terracottaRed,
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: Icon(
                              _controller.isAnimating
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 26,
                            ),
                            tooltip: _controller.isAnimating ? 'Pause' : 'Play',
                            onPressed: _togglePlayPause,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.skip_next_rounded),
                          tooltip: 'Next Stroke',
                          onPressed: _stepForward,
                        ),
                      ],
                    ),

                    // Trace Shortcut or Ghost indicator
                    IconButton(
                      icon: const Icon(Icons.auto_fix_high_rounded, color: AppColors.turmericAmber),
                      tooltip: 'Drawing Guide',
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            duration: Duration(seconds: 2),
                            content: Text(
                              'The glowing golden halo illustrates the continuous fingertip path of the Kolam artist.',
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReplayCanvasPainter extends CustomPainter {
  final int gridSize;
  final List<KolamStroke> strokes;
  final double progress; // 0.0 to 1.0
  final List<int> strokeSegmentOffsets;
  final int totalSegments;
  final bool isDark;

  _ReplayCanvasPainter({
    required this.gridSize,
    required this.strokes,
    required this.progress,
    required this.strokeSegmentOffsets,
    required this.totalSegments,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 350.0;

    // 1. Draw Pulli Dot Grid
    final step = size.width / (gridSize + 1);
    final dotPaint = Paint()
      ..color = (isDark ? const Color(0xFFFBF4E8) : AppColors.kaaviBrick).withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;

    final dotGlowPaint = Paint()
      ..color = AppColors.turmericGold.withValues(alpha: isDark ? 0.35 : 0.15)
      ..style = PaintingStyle.fill;

    for (int r = 1; r <= gridSize; r++) {
      for (int c = 1; c <= gridSize; c++) {
        final center = Offset(c * step, r * step);
        canvas.drawCircle(center, 4.0 * scale, dotGlowPaint);
        canvas.drawCircle(center, 2.2 * scale, dotPaint);
      }
    }

    if (strokes.isEmpty || progress <= 0.0) return;

    // 2. Global segment index from progress
    final globalProgressSegment = (progress * totalSegments).clamp(0.0, totalSegments.toDouble());

    Offset? activeDrawingHead;

    // 3. Draw Completed and In-Progress Strokes
    for (int sIdx = 0; sIdx < strokes.length; sIdx++) {
      final stroke = strokes[sIdx];
      if (stroke.points.isEmpty) continue;

      final startSegment = strokeSegmentOffsets[sIdx];
      final endSegment = strokeSegmentOffsets[sIdx + 1];

      // If stroke hasn't started yet, skip
      if (globalProgressSegment <= startSegment) continue;

      // Check if stroke is fully completed
      if (globalProgressSegment >= endSegment) {
        _renderFullStroke(canvas, stroke, scale);
      } else {
        // Stroke is currently in progress: render up to interpolated segment
        final localSegmentProgress = globalProgressSegment - startSegment;
        activeDrawingHead = _renderPartialStroke(
          canvas,
          stroke,
          localSegmentProgress,
          scale,
        );
      }
    }

    // 4. Highlight Currently-Drawing Tip (Glowing golden halo and chalk tip)
    if (activeDrawingHead != null) {
      // Outer radiant aura
      final auraPaint = Paint()
        ..color = AppColors.turmericGold.withValues(alpha: 0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawCircle(activeDrawingHead, 14.0 * scale, auraPaint);

      // Inner golden ring
      final ringPaint = Paint()
        ..color = AppColors.turmericGold
        ..strokeWidth = 2.0 * scale
        ..style = PaintingStyle.stroke;
      canvas.drawCircle(activeDrawingHead, 8.0 * scale, ringPaint);

      // Center luminous tip
      final tipPaint = Paint()
        ..color = isDark ? Colors.white : AppColors.terracottaRed
        ..style = PaintingStyle.fill;
      canvas.drawCircle(activeDrawingHead, 3.2 * scale, tipPaint);
    }
  }

  void _renderFullStroke(Canvas canvas, KolamStroke stroke, double scale) {
    final rawColor = Color(stroke.colorValue);
    final effectiveColor = (!isDark && (rawColor == const Color(0xFFFFFFFF) || rawColor.toARGB32() == 0xFFFFFFFF))
        ? AppColors.terracottaRed
        : rawColor;

    if (stroke.points.length < 2) {
      final p = stroke.points.first;
      final paint = Paint()
        ..color = effectiveColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(p.x * scale, p.y * scale), stroke.strokeWidth * scale / 2, paint);
      return;
    }

    final paint = Paint()
      ..color = effectiveColor
      ..strokeWidth = stroke.strokeWidth * scale
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

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

    canvas.drawPath(path, paint);
  }

  Offset? _renderPartialStroke(
    Canvas canvas,
    KolamStroke stroke,
    double localProgress,
    double scale,
  ) {
    if (stroke.points.length < 2) {
      final p = stroke.points.first;
      return Offset(p.x * scale, p.y * scale);
    }

    // Determine completed sub-segments and interpolation fraction
    final segmentIdx = localProgress.floor().clamp(0, stroke.points.length - 2);
    final t = (localProgress - segmentIdx).clamp(0.0, 1.0);

    // Active stroke highlight glow
    final glowPaint = Paint()
      ..color = AppColors.turmericGold.withValues(alpha: 0.4)
      ..strokeWidth = (stroke.strokeWidth + 4.0) * scale
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final strokePaint = Paint()
      ..color = Color(stroke.colorValue)
      ..strokeWidth = stroke.strokeWidth * scale
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    path.moveTo(stroke.points.first.x * scale, stroke.points.first.y * scale);

    // Add completed segments
    for (int i = 1; i <= segmentIdx; i++) {
      final p0 = stroke.points[i - 1];
      final p1 = stroke.points[i];
      final midX = ((p0.x + p1.x) / 2) * scale;
      final midY = ((p0.y + p1.y) / 2) * scale;
      path.quadraticBezierTo(p0.x * scale, p0.y * scale, midX, midY);
    }

    // Interpolate active segment
    final pA = stroke.points[segmentIdx];
    final pB = stroke.points[segmentIdx + 1];
    final activeX = (pA.x + (pB.x - pA.x) * t) * scale;
    final activeY = (pA.y + (pB.y - pA.y) * t) * scale;
    final activePoint = Offset(activeX, activeY);

    path.lineTo(activeX, activeY);

    // Draw active stroke with luminous glow underneath
    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, strokePaint);

    return activePoint;
  }

  @override
  bool shouldRepaint(covariant _ReplayCanvasPainter oldDelegate) => true;
}
