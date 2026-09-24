import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/kolam_16_tile.dart';
import '../../../data/models/kolam_circle_connection.dart';
import '../../../data/models/kolam_shape_primitive.dart';
import '../../../services/analysis_service.dart';

enum SymmetryDrawMode {
  none,
  bilateralVertical,
  bilateralHorizontal,
  fourFoldRadial,
}

enum CanvasBackgroundTheme {
  kaaviTerracotta, // Traditional Kaavi Ochre/Terracotta brown from reference image
  ceruleanBlue,    // Vibrant Cerulean Blue
  templeSlate,     // Charcoal temple floor
  riceFlourWarm,   // Warm ivory sandstone
}

class KolamCanvasWidget extends StatelessWidget {
  final int gridSize; // 3, 4, 5, 7, 9
  final KolamGridOrientation orientation; // diamond or square
  final bool showDots;
  final CanvasBackgroundTheme canvasTheme;
  final Color? customCanvasBgColor;
  final Color kolamColor;

  // 16-Tile State per Dot (0000 to 1111)
  final Map<int, Kolam16Tile> tileStates;
  final int? selectedCircleIndex;

  // Freehand Strokes
  final List<KolamStroke> strokes;
  final KolamStroke? activeStroke;
  final SymmetryDrawMode symmetryMode;

  // Shapes Construction Mode extensions
  final bool isShapesMode;
  final List<PlacedKolamShape> placedShapes;
  final String? selectedShapeId;
  final Offset? snapHighlightPoint;

  // Ghost Trace Mode extensions
  final List<KolamStroke>? referenceStrokes;
  final bool showReferenceLayer;
  final double referenceOpacity;

  // Gesture Callbacks
  final Function(Offset)? onPanStart;
  final Function(Offset)? onPanUpdate;
  final VoidCallback? onPanEnd;
  final Function(Offset)? onTapCanvas;
  final Function(int fromIndex, int toIndex)? onJoinCircles;
  final Function(int circleIndex, int? quadrantBit)? onCircleTapped;
  final Function(KolamShapePrimitive, Offset)? onShapeDropped;
  final Function(String)? onShapeSelected;
  final Function(String)? onShapeRotated;
  final Function(String)? onShapeDeleted;

  const KolamCanvasWidget({
    super.key,
    required this.gridSize,
    this.orientation = KolamGridOrientation.square,
    required this.showDots,
    this.canvasTheme = CanvasBackgroundTheme.templeSlate,
    this.customCanvasBgColor,
    this.kolamColor = const Color(0xFFFFFFFF),
    this.tileStates = const {},
    this.selectedCircleIndex,
    required this.strokes,
    this.activeStroke,
    this.symmetryMode = SymmetryDrawMode.none,
    this.isShapesMode = false,
    this.placedShapes = const [],
    this.selectedShapeId,
    this.snapHighlightPoint,
    this.referenceStrokes,
    this.showReferenceLayer = false,
    this.referenceOpacity = 0.35,
    this.onPanStart,
    this.onPanUpdate,
    this.onPanEnd,
    this.onTapCanvas,
    this.onJoinCircles,
    this.onCircleTapped,
    this.onShapeDropped,
    this.onShapeSelected,
    this.onShapeRotated,
    this.onShapeDeleted,
  });

  Color _getBackgroundColor(bool isDark) {
    if (customCanvasBgColor != null) return customCanvasBgColor!;
    return isDark ? AppColors.slateDark : AppColors.riceFlourBg;
  }

  Color _getBorderColor(bool isDark) {
    return isDark
        ? AppColors.turmericGold.withValues(alpha: 0.6)
        : AppColors.borderLight;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = _getBackgroundColor(isDark);
    final borderColor = _getBorderColor(isDark);

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = min(constraints.maxWidth, constraints.maxHeight);

        return Center(
          child: DragTarget<KolamShapePrimitive>(
            onWillAcceptWithDetails: (_) => isShapesMode,
            onAcceptWithDetails: (details) {
              final box = context.findRenderObject() as RenderBox?;
              if (box != null) {
                final localOffset = box.globalToLocal(details.offset);
                onShapeDropped?.call(details.data, localOffset);
              }
            },
            builder: (context, candidateData, rejectedData) {
              return Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: isDark ? Colors.black.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.08),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                    BoxShadow(
                      color: isDark ? bgColor.withValues(alpha: 0.25) : AppColors.terracottaRed.withValues(alpha: 0.06),
                      blurRadius: 28,
                      spreadRadius: -4,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(
                    color: candidateData.isNotEmpty ? AppColors.turmericGold : borderColor,
                    width: candidateData.isNotEmpty ? 3.5 : (isDark ? 2.5 : 2.0),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    children: [
                      // Canvas Surface & Gestures
                      Positioned.fill(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTapUp: (details) {
                            final localPos = details.localPosition;
                            _handleTap(localPos, size);
                          },
                          onPanStart: (details) => onPanStart?.call(details.localPosition),
                          onPanUpdate: (details) => onPanUpdate?.call(details.localPosition),
                          onPanEnd: (_) => onPanEnd?.call(),
                          child: RepaintBoundary(
                            child: CustomPaint(
                              size: Size(size, size),
                              painter: _KolamPainter(
                                gridSize: gridSize,
                                orientation: orientation,
                                showDots: showDots,
                                kolamColor: kolamColor,
                                tileStates: tileStates,
                                strokes: strokes,
                                activeStroke: activeStroke,
                                selectedCircleIndex: selectedCircleIndex,
                                placedShapes: placedShapes,
                                selectedShapeId: selectedShapeId,
                                snapHighlightPoint: snapHighlightPoint,
                                referenceStrokes: referenceStrokes,
                                showReferenceLayer: showReferenceLayer,
                                referenceOpacity: referenceOpacity,
                                canvasTheme: canvasTheme,
                                isDark: isDark,
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Selection Action Overlay Handles
                      if (isShapesMode && selectedShapeId != null)
                        ..._buildSelectedShapeHandles(size),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _handleTap(Offset tapPos, double canvasSize) {
    onTapCanvas?.call(tapPos);

    final dots = KolamGridLayout.generateDots(
      canvasSize: canvasSize,
      gridSize: gridSize,
      orientation: orientation,
    );

    final ringRadius = KolamGridLayout.getRingRadius(canvasSize, gridSize, orientation);

    // 1. Check if direct tap on or near a circle dot
    final hitCircle = KolamGridLayout.findHitCircleDot(
      tapPos: tapPos,
      dots: dots,
      ringRadius: ringRadius,
    );

    if (hitCircle != null) {
      final center = dots[hitCircle];
      final delta = tapPos - center;
      final distFromCenter = delta.distance;

      int? quadrantBit;
      if (distFromCenter > ringRadius * 0.45) {
        if (delta.dy > delta.dx.abs()) {
          quadrantBit = 0; // South
        } else if (-delta.dx > delta.dy.abs()) {
          quadrantBit = 1; // West
        } else if (-delta.dy > delta.dx.abs()) {
          quadrantBit = 2; // North
        } else if (delta.dx > delta.dy.abs()) {
          quadrantBit = 3; // East
        }
      }

      onCircleTapped?.call(hitCircle, quadrantBit);
      return;
    }

    // 2. Check if tap is between two circles (Click between two circles to join their corner tips)
    final pair = KolamGridLayout.findNearestPairBetweenTaps(
      tapPos: tapPos,
      dots: dots,
      canvasSize: canvasSize,
      gridSize: gridSize,
      orientation: orientation,
    );

    if (pair != null) {
      onJoinCircles?.call(pair.indexA, pair.indexB);
    }
  }

  List<Widget> _buildSelectedShapeHandles(double canvasSize) {
    final selectedShape = placedShapes.firstWhere(
      (s) => s.id == selectedShapeId,
      orElse: () => placedShapes.first,
    );

    final halfSize = selectedShape.size * 0.5;
    final pos = selectedShape.position;

    return [
      // Rotate Handle (Top-Right)
      Positioned(
        left: (pos.dx + halfSize + 4).clamp(0.0, canvasSize - 32),
        top: (pos.dy - halfSize - 20).clamp(0.0, canvasSize - 32),
        child: GestureDetector(
          onTap: () => onShapeRotated?.call(selectedShape.id),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.turmericGold,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 4,
                ),
              ],
            ),
            child: const Icon(
              Icons.rotate_right_rounded,
              size: 16,
              color: AppColors.slateDark,
            ),
          ),
        ),
      ),

      // Delete Handle (Top-Left)
      Positioned(
        left: (pos.dx - halfSize - 20).clamp(0.0, canvasSize - 32),
        top: (pos.dy - halfSize - 20).clamp(0.0, canvasSize - 32),
        child: GestureDetector(
          onTap: () => onShapeDeleted?.call(selectedShape.id),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.crimsonRed,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 4,
                ),
              ],
            ),
            child: const Icon(
              Icons.delete_outline_rounded,
              size: 16,
              color: Colors.white,
            ),
          ),
        ),
      ),
    ];
  }
}

class _KolamPainter extends CustomPainter {
  final int gridSize;
  final KolamGridOrientation orientation;
  final bool showDots;
  final Color kolamColor;
  final Map<int, Kolam16Tile> tileStates;
  final List<KolamStroke> strokes;
  final KolamStroke? activeStroke;
  final int? selectedCircleIndex;
  final List<PlacedKolamShape> placedShapes;
  final String? selectedShapeId;
  final Offset? snapHighlightPoint;
  final List<KolamStroke>? referenceStrokes;
  final bool showReferenceLayer;
  final double referenceOpacity;
  final CanvasBackgroundTheme canvasTheme;
  final bool isDark;

  _KolamPainter({
    required this.gridSize,
    required this.orientation,
    required this.showDots,
    required this.kolamColor,
    required this.tileStates,
    required this.strokes,
    this.activeStroke,
    this.selectedCircleIndex,
    this.placedShapes = const [],
    this.selectedShapeId,
    this.snapHighlightPoint,
    this.referenceStrokes,
    this.showReferenceLayer = false,
    this.referenceOpacity = 0.35,
    required this.canvasTheme,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final canvasSize = size.width;
    final dots = KolamGridLayout.generateDots(
      canvasSize: canvasSize,
      gridSize: gridSize,
      orientation: orientation,
    );

    final rowCount = orientation == KolamGridOrientation.square
        ? gridSize
        : KolamGridLayout.getDiamondRowCounts(gridSize).length;
    final step = canvasSize / (rowCount + 1);
    final ringRadius = KolamGridLayout.getRingRadius(canvasSize, gridSize, orientation);
    final dotRadius = KolamGridLayout.getDotRadius(canvasSize, gridSize, orientation);
    final pointDistance = step * 0.50; // Exactly touches neighbor tips at the cell boundary

    // 1. Draw Ghost Reference Layer (if in Trace Mode)
    if (showReferenceLayer && referenceStrokes != null && referenceStrokes!.isNotEmpty) {
      _drawReferenceLayer(canvas, size);
    }

    // 2. Draw Committed Freehand Strokes
    for (final stroke in strokes) {
      _drawStroke(canvas, stroke);
    }

    // 3. Draw Placed Shapes
    for (final shape in placedShapes) {
      _drawPlacedShape(canvas, shape);
    }

    // 4. Draw Active Freehand Stroke
    if (activeStroke != null && activeStroke!.points.isNotEmpty) {
      _drawStroke(canvas, activeStroke!);
    }

    // 5. Draw the 16-Tile Shapes and Central Dots (Pure Kolam without any capsule overlay)
    if (showDots) {
      _draw16TileGridAndDots(canvas, dots, ringRadius, dotRadius, pointDistance);
    }

    // 6. Draw Snap-to-Join Highlight Pulse (if active in Shapes mode)
    if (snapHighlightPoint != null) {
      final pulsePaint = Paint()
        ..color = AppColors.turmericGold
        ..strokeWidth = 3.0
        ..style = PaintingStyle.stroke;
      final pulseInner = Paint()
        ..color = AppColors.turmericGold.withValues(alpha: 0.5)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(snapHighlightPoint!, 9.0, pulsePaint);
      canvas.drawCircle(snapHighlightPoint!, 5.0, pulseInner);
    }
  }

  /// Draws the 16 Sikku Tile curves and central solid dots (matching reference images)
  void _draw16TileGridAndDots(
    Canvas canvas,
    List<Offset> dots,
    double ringRadius,
    double dotRadius,
    double pointDistance,
  ) {
    final strokeW = (ringRadius * 0.24).clamp(3.2, 5.2);

    final effectiveColor = KolamPaletteColor.fromColor(kolamColor).getShade(isDark);

    final tileStrokePaint = Paint()
      ..color = effectiveColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    final tileGlowPaint = Paint()
      ..color = effectiveColor.withValues(alpha: isDark ? 0.25 : 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW + (isDark ? 3.0 : 1.5)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    final dotPaint = Paint()
      ..color = effectiveColor
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    for (int i = 0; i < dots.length; i++) {
      final center = dots[i];
      final tile = tileStates[i] ?? Kolam16Tile.circle;

      final path = tile.generatePath(
        center: center,
        ringRadius: ringRadius,
        pointDistance: pointDistance,
      );

      // Draw subtle glow and clean stroke
      canvas.drawPath(path, tileGlowPaint);
      canvas.drawPath(path, tileStrokePaint);

      // Draw central solid pulli dot
      canvas.drawCircle(center, dotRadius, dotPaint);
    }
  }

  void _drawPlacedShape(Canvas canvas, PlacedKolamShape shape) {
    canvas.save();
    canvas.translate(shape.position.dx, shape.position.dy);
    canvas.rotate(shape.rotationDegrees * pi / 180.0);
    canvas.translate(-shape.size * 0.5, -shape.size * 0.5);

    final path = shape.primitive.generatePath(Size(shape.size, shape.size));

    final rawShapeColor = Color(shape.colorValue);
    final effectiveShapeColor = KolamPaletteColor.fromColor(rawShapeColor).getShade(isDark);

    final strokePaint = Paint()
      ..color = effectiveShapeColor
      ..strokeWidth = shape.strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, strokePaint);

    final isSelected = shape.id == selectedShapeId;
    if (isSelected) {
      final selectPaint = Paint()
        ..color = AppColors.turmericGold.withValues(alpha: 0.8)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;

      final selectBg = Paint()
        ..color = AppColors.turmericGold.withValues(alpha: 0.08)
        ..style = PaintingStyle.fill;

      final rect = Rect.fromLTWH(-4, -4, shape.size + 8, shape.size + 8);
      canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(8)), selectBg);
      canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(8)), selectPaint);
    }

    final dotPaint = Paint()
      ..color = const Color(0xFFE59500)
      ..style = PaintingStyle.fill;

    final startOffset = Offset(
      shape.primitive.localStartAnchor.dx * shape.size,
      shape.primitive.localStartAnchor.dy * shape.size,
    );
    final endOffset = Offset(
      shape.primitive.localEndAnchor.dx * shape.size,
      shape.primitive.localEndAnchor.dy * shape.size,
    );

    canvas.drawCircle(startOffset, 2.5, dotPaint);
    canvas.drawCircle(endOffset, 2.5, dotPaint);

    canvas.restore();
  }

  void _drawStroke(Canvas canvas, KolamStroke stroke) {
    final strokeColor = Color(stroke.colorValue);
    final effectiveStrokeColor = KolamPaletteColor.fromColor(strokeColor).getShade(isDark);

    if (stroke.points.length < 2) {
      if (stroke.points.isNotEmpty) {
        final p = stroke.points.first;
        final paint = Paint()
          ..color = effectiveStrokeColor
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(p.x, p.y), stroke.strokeWidth / 2, paint);
      }
      return;
    }

    final paint = Paint()
      ..color = effectiveStrokeColor
      ..strokeWidth = stroke.strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    path.moveTo(stroke.points.first.x, stroke.points.first.y);

    for (int i = 1; i < stroke.points.length; i++) {
      final p0 = stroke.points[i - 1];
      final p1 = stroke.points[i];
      final midX = (p0.x + p1.x) / 2;
      final midY = (p0.y + p1.y) / 2;
      path.quadraticBezierTo(p0.x, p0.y, midX, midY);
    }
    path.lineTo(stroke.points.last.x, stroke.points.last.y);

    canvas.drawPath(path, paint);
  }

  void _drawReferenceLayer(Canvas canvas, Size size) {
    if (referenceStrokes == null) return;

    for (final stroke in referenceStrokes!) {
      if (stroke.points.isEmpty) continue;

      final ghostColor = isDark ? const Color(0xFFFFF2D0) : AppColors.terracottaRed;

      final ghostPaint = Paint()
        ..color = ghostColor.withValues(alpha: referenceOpacity.clamp(0.05, 0.95))
        ..strokeWidth = stroke.strokeWidth * 1.15
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      final glowPaint = Paint()
        ..color = AppColors.turmericGold.withValues(alpha: (referenceOpacity * 0.45).clamp(0.02, 0.4))
        ..strokeWidth = stroke.strokeWidth + 3.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      if (stroke.points.length < 2) {
        final p = stroke.points.first;
        canvas.drawCircle(Offset(p.x, p.y), stroke.strokeWidth / 2, ghostPaint);
      } else {
        final path = Path();
        path.moveTo(stroke.points.first.x, stroke.points.first.y);

        for (int i = 1; i < stroke.points.length; i++) {
          final p0 = stroke.points[i - 1];
          final p1 = stroke.points[i];
          final midX = (p0.x + p1.x) / 2;
          final midY = (p0.y + p1.y) / 2;
          path.quadraticBezierTo(p0.x, p0.y, midX, midY);
        }
        path.lineTo(stroke.points.last.x, stroke.points.last.y);

        canvas.drawPath(path, glowPaint);
        canvas.drawPath(path, ghostPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _KolamPainter oldDelegate) => true;
}
