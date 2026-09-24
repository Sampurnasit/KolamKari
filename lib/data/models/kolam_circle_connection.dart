import 'dart:math';
import 'package:flutter/material.dart';
import '../../services/analysis_service.dart';

enum KolamGridOrientation {
  diamond,
  square,
}

enum KolamJoinStyle {
  tangentBridge, // Merges outer rings into peanut/capsule shape
  sikkuLoop,     // Smooth curving loop around and between dots
  straightLine,  // Crisp connecting line
}

/// Represents a connection/link between two grid circles
class KolamCircleConnection {
  final int fromIndex;
  final int toIndex;
  final Offset fromPos;
  final Offset toPos;
  final Color color;
  final double strokeWidth;
  final KolamJoinStyle joinStyle;

  const KolamCircleConnection({
    required this.fromIndex,
    required this.toIndex,
    required this.fromPos,
    required this.toPos,
    this.color = const Color(0xFFFFFFFF),
    this.strokeWidth = 3.5,
    this.joinStyle = KolamJoinStyle.tangentBridge,
  });

  String get id => '${min(fromIndex, toIndex)}_${max(fromIndex, toIndex)}';

  KolamCircleConnection copyWith({
    int? fromIndex,
    int? toIndex,
    Offset? fromPos,
    Offset? toPos,
    Color? color,
    double? strokeWidth,
    KolamJoinStyle? joinStyle,
  }) {
    return KolamCircleConnection(
      fromIndex: fromIndex ?? this.fromIndex,
      toIndex: toIndex ?? this.toIndex,
      fromPos: fromPos ?? this.fromPos,
      toPos: toPos ?? this.toPos,
      color: color ?? this.color,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      joinStyle: joinStyle ?? this.joinStyle,
    );
  }

  /// Converts this connection into a KolamStroke for AI analysis and saving
  KolamStroke toStroke({double ringRadius = 18.0}) {
    final points = <KolamPoint>[];
    
    if (joinStyle == KolamJoinStyle.sikkuLoop) {
      // Create a smooth arc / curve
      final mid = (fromPos + toPos) / 2;
      final dx = toPos.dx - fromPos.dx;
      final dy = toPos.dy - fromPos.dy;
      final normal = Offset(-dy, dx);
      final len = normal.distance;
      final unitNormal = len > 0 ? normal / len : Offset.zero;
      final controlPoint = mid + unitNormal * (ringRadius * 0.8);
      
      for (double t = 0; t <= 1.0; t += 0.08) {
        final x = (1 - t) * (1 - t) * fromPos.dx + 2 * (1 - t) * t * controlPoint.dx + t * t * toPos.dx;
        final y = (1 - t) * (1 - t) * fromPos.dy + 2 * (1 - t) * t * controlPoint.dy + t * t * toPos.dy;
        points.add(KolamPoint(x, y));
      }
    } else {
      // Straight or tangent bridge stroke
      for (double t = 0; t <= 1.0; t += 0.1) {
        final x = fromPos.dx + (toPos.dx - fromPos.dx) * t;
        final y = fromPos.dy + (toPos.dy - fromPos.dy) * t;
        points.add(KolamPoint(x, y));
      }
    }

    return KolamStroke(
      points: points,
      colorValue: color.toARGB32(),
      strokeWidth: strokeWidth,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fromIndex': fromIndex,
      'toIndex': toIndex,
      'fromX': fromPos.dx,
      'fromY': fromPos.dy,
      'toX': toPos.dx,
      'toY': toPos.dy,
      'color': color.toARGB32(),
      'strokeWidth': strokeWidth,
      'joinStyle': joinStyle.index,
    };
  }

  factory KolamCircleConnection.fromJson(Map<String, dynamic> json) {
    return KolamCircleConnection(
      fromIndex: json['fromIndex'] as int,
      toIndex: json['toIndex'] as int,
      fromPos: Offset((json['fromX'] as num).toDouble(), (json['fromY'] as num).toDouble()),
      toPos: Offset((json['toX'] as num).toDouble(), (json['toY'] as num).toDouble()),
      color: Color(json['color'] as int? ?? 0xFFFFFFFF),
      strokeWidth: (json['strokeWidth'] as num?)?.toDouble() ?? 3.5,
      joinStyle: KolamJoinStyle.values[(json['joinStyle'] as int?) ?? 0],
    );
  }
}

/// Helper class to compute dot grid layouts for both Square and Diamond orientations
class KolamGridLayout {
  /// Generates the list of 2D dot coordinates on a square canvas of given size
  static List<Offset> generateDots({
    required double canvasSize,
    required int gridSize,
    required KolamGridOrientation orientation,
  }) {
    final dots = <Offset>[];
    
    if (orientation == KolamGridOrientation.square) {
      final step = canvasSize / (gridSize + 1);
      for (int r = 1; r <= gridSize; r++) {
        for (int c = 1; c <= gridSize; c++) {
          dots.add(Offset(c * step, r * step));
        }
      }
    } else {
      // Diamond Orientation (e.g., 1-3-5-3-1 for 5x5, 1-3-1 for 3x3, 1-3-5-7-5-3-1 for 7x7)
      final rowCounts = getDiamondRowCounts(gridSize);
      final rowCount = rowCounts.length;
      final step = canvasSize / (rowCount + 1);
      final centerX = canvasSize / 2;

      for (int i = 0; i < rowCount; i++) {
        final count = rowCounts[i];
        final y = (i + 1) * step;
        for (int j = 0; j < count; j++) {
          final x = centerX + (j - (count - 1) / 2.0) * step;
          dots.add(Offset(x, y));
        }
      }
    }

    return dots;
  }

  /// Row dot counts for diamond patterns (e.g. 5x5 gives [1, 3, 5, 3, 1])
  static List<int> getDiamondRowCounts(int n) {
    if (n <= 1) return [1];
    
    if (n % 2 == 1) {
      // Odd sizes: 3 -> [1, 3, 1], 5 -> [1, 3, 5, 3, 1], 7 -> [1, 3, 5, 7, 5, 3, 1]
      final mid = (n - 1) ~/ 2;
      final list = <int>[];
      for (int i = 0; i < n; i++) {
        final distFromMid = (i - mid).abs();
        final count = n - distFromMid * 2;
        list.add(max(1, count));
      }
      return list;
    } else {
      // Even sizes: 4 -> [1, 3, 3, 1], 6 -> [1, 3, 5, 5, 3, 1]
      final list = <int>[];
      final half = n ~/ 2;
      for (int i = 0; i < n; i++) {
        final dist = i < half ? (half - 1 - i) : (i - half);
        final count = n - dist * 2;
        list.add(max(1, count > 0 ? count : 1));
      }
      return list;
    }
  }

  /// Calculates dynamic circle ring radius based on canvas size and grid
  static double getRingRadius(double canvasSize, int gridSize, KolamGridOrientation orientation) {
    final effectiveN = orientation == KolamGridOrientation.square ? gridSize : getDiamondRowCounts(gridSize).length;
    final step = canvasSize / (effectiveN + 1);
    return (step * 0.32).clamp(10.0, 32.0);
  }

  /// Calculates center dot radius
  static double getDotRadius(double canvasSize, int gridSize, KolamGridOrientation orientation) {
    final ring = getRingRadius(canvasSize, gridSize, orientation);
    return (ring * 0.28).clamp(2.5, 6.0);
  }

  /// Finds the pair of neighbor dots closest to a tap position between them
  static ({int indexA, int indexB, double distance})? findNearestPairBetweenTaps({
    required Offset tapPos,
    required List<Offset> dots,
    required double canvasSize,
    required int gridSize,
    required KolamGridOrientation orientation,
  }) {
    if (dots.length < 2) return null;

    final effectiveN = orientation == KolamGridOrientation.square ? gridSize : getDiamondRowCounts(gridSize).length;
    final step = canvasSize / (effectiveN + 1);
    final maxNeighborDistance = step * 1.55; // Allows horizontal, vertical, and standard diagonal neighbors

    int? bestA;
    int? bestB;
    double minTapDistanceToSegment = double.infinity;

    for (int i = 0; i < dots.length; i++) {
      for (int j = i + 1; j < dots.length; j++) {
        final a = dots[i];
        final b = dots[j];
        final distAB = (b - a).distance;

        if (distAB > maxNeighborDistance) continue;

        // Project tapPos onto segment AB
        final ab = b - a;
        final abLenSq = ab.dx * ab.dx + ab.dy * ab.dy;
        if (abLenSq == 0) continue;

        final ap = tapPos - a;
        final t = (ap.dx * ab.dx + ap.dy * ab.dy) / abLenSq;

        // Tap must be somewhat between the two circles (not past endpoints)
        if (t < 0.1 || t > 0.9) continue;

        final proj = a + ab * t;
        final distTapToSeg = (tapPos - proj).distance;

        // Threshold: tap must be close to the segment
        if (distTapToSeg < step * 0.45 && distTapToSeg < minTapDistanceToSegment) {
          minTapDistanceToSegment = distTapToSeg;
          bestA = i;
          bestB = j;
        }
      }
    }

    if (bestA != null && bestB != null) {
      return (indexA: bestA, indexB: bestB, distance: minTapDistanceToSegment);
    }
    return null;
  }

  /// Finds if a tap directly hit a specific circle dot
  static int? findHitCircleDot({
    required Offset tapPos,
    required List<Offset> dots,
    required double ringRadius,
  }) {
    final hitRadius = ringRadius * 1.25;
    for (int i = 0; i < dots.length; i++) {
      if ((dots[i] - tapPos).distance <= hitRadius) {
        return i;
      }
    }
    return null;
  }
}
