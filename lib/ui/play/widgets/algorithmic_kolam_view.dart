import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/algorithmic_kolam_pattern.dart';

class AlgorithmicKolamView extends StatelessWidget {
  final AlgorithmicKolamPattern pattern;
  final double progress;
  final double size;
  final Color? strokeColor;
  final Color? dotColor;
  final double strokeWidth;
  final bool showDots;
  final bool maskRightHalf;
  final int? appliedTransformationIndex;
  final double margin;

  const AlgorithmicKolamView({
    super.key,
    required this.pattern,
    this.progress = 1.0,
    required this.size,
    this.strokeColor,
    this.dotColor,
    this.strokeWidth = 3.0,
    this.showDots = true,
    this.maskRightHalf = false,
    this.appliedTransformationIndex,
    this.margin = 6.0,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveStrokeColor = strokeColor ?? (isDark ? const Color(0xFFFFFDF8) : AppColors.terracottaRed);
    final effectiveDotColor = dotColor ?? AppColors.turmericGold;

    return CustomPaint(
      size: Size(size, size),
      painter: AlgorithmicKolamPainter(
        pattern: pattern,
        progress: progress,
        strokeColor: effectiveStrokeColor,
        dotColor: effectiveDotColor,
        strokeWidth: strokeWidth,
        showDots: showDots,
        maskRightHalf: maskRightHalf,
        appliedTransformationIndex: appliedTransformationIndex,
        margin: margin,
      ),
    );
  }
}

class AlgorithmicKolamPainter extends CustomPainter {
  final AlgorithmicKolamPattern pattern;
  final double progress;
  final Color strokeColor;
  final Color dotColor;
  final double strokeWidth;
  final bool showDots;
  final bool maskRightHalf;
  final int? appliedTransformationIndex;
  final double margin;

  AlgorithmicKolamPainter({
    required this.pattern,
    required this.progress,
    required this.strokeColor,
    required this.dotColor,
    required this.strokeWidth,
    required this.showDots,
    required this.maskRightHalf,
    this.appliedTransformationIndex,
    required this.margin,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final strokePaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final dotPaint = Paint()
      ..color = dotColor
      ..style = PaintingStyle.fill;

    final int tnum = pattern.tnumber;
    final double tsize = (size.width - 2 * margin) / tnum;
    final double dotRadius = (tsize * 0.10).clamp(2.0, 4.5);

    for (int i = 0; i < tnum; i++) {
      for (int j = 0; j < tnum; j++) {
        if ((i + j) % 2 == 0) {
          final bool isRightHalf = i >= (tnum / 2).floor();
          if (maskRightHalf && isRightHalf && appliedTransformationIndex == null) {
            continue;
          }

          double rawTL = lerpDouble(pattern.link[i][j], pattern.nlink[i][j], progress) ?? 1.0;
          double rawTR = lerpDouble(pattern.link[i + 1][j], pattern.nlink[i + 1][j], progress) ?? 1.0;
          double rawBR = lerpDouble(pattern.link[i + 1][j + 1], pattern.nlink[i + 1][j + 1], progress) ?? 1.0;
          double rawBL = lerpDouble(pattern.link[i][j + 1], pattern.nlink[i][j + 1], progress) ?? 1.0;

          if (maskRightHalf && isRightHalf && appliedTransformationIndex != null) {
            final int srcI = (tnum - 1) - i;
            final int srcJ = j;
            switch (appliedTransformationIndex) {
              case 0: // Vertical reflection (Y-axis)
                rawTL = lerpDouble(pattern.link[srcI + 1][srcJ], pattern.nlink[srcI + 1][srcJ], progress) ?? 1.0;
                rawTR = lerpDouble(pattern.link[srcI][srcJ], pattern.nlink[srcI][srcJ], progress) ?? 1.0;
                rawBR = lerpDouble(pattern.link[srcI][srcJ + 1], pattern.nlink[srcI][srcJ + 1], progress) ?? 1.0;
                rawBL = lerpDouble(pattern.link[srcI + 1][srcJ + 1], pattern.nlink[srcI + 1][srcJ + 1], progress) ?? 1.0;
                break;
              case 1: // Horizontal reflection (X-axis)
                rawTL = lerpDouble(pattern.link[i][(tnum - 1) - j + 1], pattern.nlink[i][(tnum - 1) - j + 1], progress) ?? 1.0;
                rawTR = lerpDouble(pattern.link[i + 1][(tnum - 1) - j + 1], pattern.nlink[i + 1][(tnum - 1) - j + 1], progress) ?? 1.0;
                rawBR = lerpDouble(pattern.link[i + 1][(tnum - 1) - j], pattern.nlink[i + 1][(tnum - 1) - j], progress) ?? 1.0;
                rawBL = lerpDouble(pattern.link[i][(tnum - 1) - j], pattern.nlink[i][(tnum - 1) - j], progress) ?? 1.0;
                break;
              case 2: // 180° rotation
                final int rI = (tnum - 1) - i;
                final int rJ = (tnum - 1) - j;
                rawTL = lerpDouble(pattern.link[rI + 1][rJ + 1], pattern.nlink[rI + 1][rJ + 1], progress) ?? 1.0;
                rawTR = lerpDouble(pattern.link[rI][rJ + 1], pattern.nlink[rI][rJ + 1], progress) ?? 1.0;
                rawBR = lerpDouble(pattern.link[rI][rJ], pattern.nlink[rI][rJ], progress) ?? 1.0;
                rawBL = lerpDouble(pattern.link[rI + 1][rJ], pattern.nlink[rI + 1][rJ], progress) ?? 1.0;
                break;
              case 3: // 90° rotation
                final int qI = j;
                final int qJ = (tnum - 1) - i;
                rawTL = lerpDouble(pattern.link[qI][qJ + 1], pattern.nlink[qI][qJ + 1], progress) ?? 1.0;
                rawTR = lerpDouble(pattern.link[qI][qJ], pattern.nlink[qI][qJ], progress) ?? 1.0;
                rawBR = lerpDouble(pattern.link[qI + 1][qJ], pattern.nlink[qI + 1][qJ], progress) ?? 1.0;
                rawBL = lerpDouble(pattern.link[qI + 1][qJ + 1], pattern.nlink[qI + 1][qJ + 1], progress) ?? 1.0;
                break;
            }
          }

          final double topLeft = (tsize / 2) * rawTL;
          final double topRight = (tsize / 2) * rawTR;
          final double bottomRight = (tsize / 2) * rawBR;
          final double bottomLeft = (tsize / 2) * rawBL;

          final rect = Rect.fromLTWH(
            i * tsize + margin,
            j * tsize + margin,
            tsize,
            tsize,
          );

          final rrect = RRect.fromRectAndCorners(
            rect,
            topLeft: Radius.circular(topLeft),
            topRight: Radius.circular(topRight),
            bottomRight: Radius.circular(bottomRight),
            bottomLeft: Radius.circular(bottomLeft),
          );

          canvas.drawRRect(rrect, strokePaint);

          if (showDots) {
            canvas.drawCircle(
              Offset(i * tsize + tsize / 2 + margin, j * tsize + tsize / 2 + margin),
              dotRadius,
              dotPaint,
            );
          }
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant AlgorithmicKolamPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.pattern != pattern ||
        oldDelegate.strokeColor != strokeColor ||
        oldDelegate.dotColor != dotColor ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.maskRightHalf != maskRightHalf ||
        oldDelegate.appliedTransformationIndex != appliedTransformationIndex;
  }
}
