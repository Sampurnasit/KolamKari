import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/kolam_16_tile.dart';

/// Renders a single 16-Kolam tile shape with a central pulli dot
class Kolam16TileView extends StatelessWidget {
  final Kolam16Tile tile;
  final double size;
  final Color? strokeColor;
  final Color? dotColor;
  final double strokeWidth;
  final bool showDot;

  const Kolam16TileView({
    super.key,
    required this.tile,
    required this.size,
    this.strokeColor,
    this.dotColor,
    this.strokeWidth = 2.5,
    this.showDot = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveStroke = strokeColor ?? (isDark ? const Color(0xFFFFFDF7) : AppColors.terracottaRed);
    final effectiveDot = dotColor ?? AppColors.turmericGold;

    return CustomPaint(
      size: Size(size, size),
      painter: _SingleTilePainter(
        tile: tile,
        strokeColor: effectiveStroke,
        dotColor: effectiveDot,
        strokeWidth: strokeWidth,
        showDot: showDot,
      ),
    );
  }
}

class _SingleTilePainter extends CustomPainter {
  final Kolam16Tile tile;
  final Color strokeColor;
  final Color dotColor;
  final double strokeWidth;
  final bool showDot;

  _SingleTilePainter({
    required this.tile,
    required this.strokeColor,
    required this.dotColor,
    required this.strokeWidth,
    required this.showDot,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final ringRadius = size.width * 0.28;
    final pointDistance = size.width * 0.46;

    final path = tile.generatePath(
      center: center,
      ringRadius: ringRadius,
      pointDistance: pointDistance,
    );

    final strokePaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, strokePaint);

    if (showDot) {
      final dotPaint = Paint()
        ..color = dotColor
        ..style = PaintingStyle.fill;
      final dotRadius = (size.width * 0.07).clamp(2.0, 4.0);
      canvas.drawCircle(center, dotRadius, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _SingleTilePainter oldDelegate) {
    return oldDelegate.tile != tile ||
        oldDelegate.strokeColor != strokeColor ||
        oldDelegate.dotColor != dotColor ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.showDot != showDot;
  }
}

/// Renders an NxN (4x4, 6x6, 8x8) Kolam pattern preview
class KolamNxNPreviewView extends StatelessWidget {
  final Map<int, Kolam16Tile?> tiles;
  final int gridDimension;
  final double size;
  final Color? strokeColor;
  final Color? dotColor;
  final double strokeWidth;
  final bool showDots;

  const KolamNxNPreviewView({
    super.key,
    required this.tiles,
    this.gridDimension = 4,
    required this.size,
    this.strokeColor,
    this.dotColor,
    this.strokeWidth = 2.0,
    this.showDots = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveStroke = strokeColor ?? (isDark ? const Color(0xFFFFFDF7) : AppColors.terracottaRed);
    final effectiveDot = dotColor ?? AppColors.turmericGold;

    return CustomPaint(
      size: Size(size, size),
      painter: _KolamNxNPainter(
        tiles: tiles,
        gridDimension: gridDimension,
        strokeColor: effectiveStroke,
        dotColor: effectiveDot,
        strokeWidth: strokeWidth,
        showDots: showDots,
      ),
    );
  }
}

/// Backward compatibility alias for 4x4 previews
class Kolam4x4PreviewView extends StatelessWidget {
  final Map<int, Kolam16Tile?> tiles;
  final double size;
  final Color? strokeColor;
  final Color? dotColor;
  final double strokeWidth;
  final bool showDots;

  const Kolam4x4PreviewView({
    super.key,
    required this.tiles,
    required this.size,
    this.strokeColor,
    this.dotColor,
    this.strokeWidth = 2.0,
    this.showDots = true,
  });

  @override
  Widget build(BuildContext context) {
    return KolamNxNPreviewView(
      tiles: tiles,
      gridDimension: 4,
      size: size,
      strokeColor: strokeColor,
      dotColor: dotColor,
      strokeWidth: strokeWidth,
      showDots: showDots,
    );
  }
}

class _KolamNxNPainter extends CustomPainter {
  final Map<int, Kolam16Tile?> tiles;
  final int gridDimension;
  final Color strokeColor;
  final Color dotColor;
  final double strokeWidth;
  final bool showDots;

  _KolamNxNPainter({
    required this.tiles,
    required this.gridDimension,
    required this.strokeColor,
    required this.dotColor,
    required this.strokeWidth,
    required this.showDots,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final int gridSize = gridDimension;
    final cellW = size.width / gridSize;
    final cellH = size.height / gridSize;
    final ringRadius = cellW * 0.28;
    final pointDistance = cellW * 0.46;

    final strokePaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final dotPaint = Paint()
      ..color = dotColor
      ..style = PaintingStyle.fill;

    final dotRadius = (cellW * 0.08).clamp(1.2, 3.5);

    for (int r = 0; r < gridSize; r++) {
      for (int c = 0; c < gridSize; c++) {
        final index = r * gridSize + c;
        final center = Offset(c * cellW + cellW / 2, r * cellH + cellH / 2);
        final tile = tiles[index];

        if (tile != null) {
          final path = tile.generatePath(
            center: center,
            ringRadius: ringRadius,
            pointDistance: pointDistance,
          );
          canvas.drawPath(path, strokePaint);
        }

        if (showDots) {
          canvas.drawCircle(center, dotRadius, dotPaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _KolamNxNPainter oldDelegate) {
    return oldDelegate.tiles != tiles ||
        oldDelegate.gridDimension != gridDimension ||
        oldDelegate.strokeColor != strokeColor ||
        oldDelegate.dotColor != dotColor ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.showDots != showDots;
  }
}
