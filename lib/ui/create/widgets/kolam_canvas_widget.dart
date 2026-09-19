import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/kolam_shape_primitive.dart';
import '../../../services/analysis_service.dart';

enum SymmetryDrawMode {
  none,
  bilateralVertical,
  bilateralHorizontal,
  fourFoldRadial,
}

class KolamCanvasWidget extends StatelessWidget {
  final int gridSize; // 5, 7, 9
  final bool showDots;
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

  final Function(Offset)? onPanStart;
  final Function(Offset)? onPanUpdate;
  final VoidCallback? onPanEnd;
  final Function(KolamShapePrimitive, Offset)? onShapeDropped;
  final Function(String)? onShapeSelected;
  final Function(String)? onShapeRotated;
  final Function(String)? onShapeDeleted;

  const KolamCanvasWidget({
    super.key,
    required this.gridSize,
    required this.showDots,
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
    this.onShapeDropped,
    this.onShapeSelected,
    this.onShapeRotated,
    this.onShapeDeleted,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
                  color: isDark ? AppColors.slateDark : const Color(0xFF261E21), // Traditional red-earth/temple slate floor
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                  border: Border.all(
                    color: candidateData.isNotEmpty
                        ? AppColors.turmericGold
                        : AppColors.kaaviBrick.withValues(alpha: 0.6),
                    width: candidateData.isNotEmpty ? 3.0 : 2.5,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Stack(
                    children: [
                      // Canvas Surface & Gestures
                      Positioned.fill(
                        child: GestureDetector(
                          onPanStart: (details) => onPanStart?.call(details.localPosition),
                          onPanUpdate: (details) => onPanUpdate?.call(details.localPosition),
                          onPanEnd: (_) => onPanEnd?.call(),
                          child: RepaintBoundary(
                            child: CustomPaint(
                              size: Size(size, size),
                              painter: _KolamPainter(
                                gridSize: gridSize,
                                showDots: showDots,
                                strokes: strokes,
                                activeStroke: activeStroke,
                                placedShapes: placedShapes,
                                selectedShapeId: selectedShapeId,
                                snapHighlightPoint: snapHighlightPoint,
                                referenceStrokes: referenceStrokes,
                                showReferenceLayer: showReferenceLayer,
                                referenceOpacity: referenceOpacity,
                                isDark: isDark,
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Selection Action Overlay Handles (Rotate & Delete buttons on selected shape)
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

  List<Widget> _buildSelectedShapeHandles(double canvasSize) {
    final selectedShape = placedShapes.firstWhere(
      (s) => s.id == selectedShapeId,
      orElse: () => const PlacedKolamShape(
        id: '',
        primitiveId: '',
        position: Offset.zero,
      ),
    );

    if (selectedShape.id.isEmpty) return [];

    final pos = selectedShape.position;
    final halfSize = selectedShape.size * 0.6;

    return [
      // Rotate Handle (Top-Right)
      Positioned(
        left: (pos.dx + halfSize - 12).clamp(4.0, canvasSize - 28.0),
        top: (pos.dy - halfSize - 14).clamp(4.0, canvasSize - 28.0),
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
              color: Colors.black87,
            ),
          ),
        ),
      ),

      // Delete Handle (Top-Left)
      Positioned(
        left: (pos.dx - halfSize - 12).clamp(4.0, canvasSize - 28.0),
        top: (pos.dy - halfSize - 14).clamp(4.0, canvasSize - 28.0),
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
  final bool showDots;
  final List<KolamStroke> strokes;
  final KolamStroke? activeStroke;
  final List<PlacedKolamShape> placedShapes;
  final String? selectedShapeId;
  final Offset? snapHighlightPoint;
  final List<KolamStroke>? referenceStrokes;
  final bool showReferenceLayer;
  final double referenceOpacity;
  final bool isDark;

  _KolamPainter({
    required this.gridSize,
    required this.showDots,
    required this.strokes,
    this.activeStroke,
    this.placedShapes = const [],
    this.selectedShapeId,
    this.snapHighlightPoint,
    this.referenceStrokes,
    this.showReferenceLayer = false,
    this.referenceOpacity = 0.35,
    required this.isDark,
  });

  static final Paint _dotPaint = Paint()
    ..color = const Color(0xFFFBF4E8).withValues(alpha: 0.85)
    ..style = PaintingStyle.fill;

  static final Paint _dotGlowPaint = Paint()
    ..color = AppColors.turmericGold.withValues(alpha: 0.35)
    ..style = PaintingStyle.fill;

  static final Paint _pulsePaint = Paint()
    ..color = AppColors.turmericGold
    ..strokeWidth = 2.5
    ..style = PaintingStyle.stroke;

  static final Paint _pulseInnerPaint = Paint()
    ..color = AppColors.turmericGold.withValues(alpha: 0.5)
    ..style = PaintingStyle.fill;

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw traditional Pulli Dot Grid
    if (showDots) {
      final step = size.width / (gridSize + 1);

      for (int r = 1; r <= gridSize; r++) {
        for (int c = 1; c <= gridSize; c++) {
          final center = Offset(c * step, r * step);
          canvas.drawCircle(center, 4.0, _dotGlowPaint);
          canvas.drawCircle(center, 2.2, _dotPaint);
        }
      }
    }

    // 1.5. Draw Ghost Reference Layer (if in Trace Mode)
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

    // 5. Draw Snap-to-Join Highlight Pulse (if active)
    if (snapHighlightPoint != null) {
      canvas.drawCircle(snapHighlightPoint!, 8.0, _pulsePaint);
      canvas.drawCircle(snapHighlightPoint!, 4.0, _pulseInnerPaint);
    }
  }

  void _drawPlacedShape(Canvas canvas, PlacedKolamShape shape) {
    canvas.save();
    canvas.translate(shape.position.dx, shape.position.dy);
    canvas.rotate(shape.rotationDegrees * pi / 180.0);
    canvas.translate(-shape.size * 0.5, -shape.size * 0.5);

    final path = shape.primitive.generatePath(Size(shape.size, shape.size));

    // Chalk line paint
    final strokePaint = Paint()
      ..color = Color(shape.colorValue)
      ..strokeWidth = shape.strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, strokePaint);

    // If selected, draw glowing bounding frame
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

    // Draw Anchor Points
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
    if (stroke.points.length < 2) {
      if (stroke.points.isNotEmpty) {
        final p = stroke.points.first;
        final paint = Paint()
          ..color = Color(stroke.colorValue)
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(p.x, p.y), stroke.strokeWidth / 2, paint);
      }
      return;
    }

    final paint = Paint()
      ..color = Color(stroke.colorValue)
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

      final ghostPaint = Paint()
        ..color = const Color(0xFFFFF2D0).withValues(alpha: referenceOpacity.clamp(0.05, 0.95))
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
