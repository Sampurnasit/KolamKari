import 'dart:math';
import 'package:flutter/material.dart';
import '../../services/analysis_service.dart';
import 'algorithmic_kolam_pattern.dart';

/// Represents one of the 16 classic Sikku Kolam tile shapes
/// based on the 4-bit binary corner encoding:
/// - Bit 0 (`0001`): South / Bottom (+Y)
/// - Bit 1 (`0010`): West / Left (-X)
/// - Bit 2 (`0100`): North / Top (-Y)
/// - Bit 3 (`1000`): East / Right (+X)
class Kolam16Tile {
  final int mask; // 0 to 15 (0000 to 1111)

  const Kolam16Tile(this.mask);

  static const Kolam16Tile circle = Kolam16Tile(0); // 0000

  bool get hasSouth => (mask & 1) != 0;
  bool get hasWest => (mask & 2) != 0;
  bool get hasNorth => (mask & 4) != 0;
  bool get hasEast => (mask & 8) != 0;

  String get binaryCode => mask.toRadixString(2).padLeft(4, '0');

  String get name {
    switch (mask) {
      case 0:
        return 'Circle (0000)';
      case 1:
        return 'South Loop (0001)';
      case 2:
        return 'West Loop (0010)';
      case 3:
        return 'South-West (0011)';
      case 4:
        return 'North Loop (0100)';
      case 5:
        return 'Vertical Almond (0101)';
      case 6:
        return 'North-West (0110)';
      case 7:
        return 'North-West-South (0111)';
      case 8:
        return 'East Loop (1000)';
      case 9:
        return 'East-South (1001)';
      case 10:
        return 'Horizontal Almond (1010)';
      case 11:
        return 'East-West-South (1011)';
      case 12:
        return 'East-North (1100)';
      case 13:
        return 'East-North-South (1101)';
      case 14:
        return 'East-North-West (1110)';
      case 15:
        return '4-Point Square (1111)';
      default:
        return 'Tile $binaryCode';
    }
  }

  /// Toggles a specific direction bit (0: South, 1: West, 2: North, 3: East)
  Kolam16Tile toggleBit(int bitIndex) {
    return Kolam16Tile(mask ^ (1 << bitIndex));
  }

  /// Sets or clears a specific direction bit
  Kolam16Tile setBit(int bitIndex, bool value) {
    if (value) {
      return Kolam16Tile(mask | (1 << bitIndex));
    } else {
      return Kolam16Tile(mask & ~(1 << bitIndex));
    }
  }

  /// Generates the precise path for this 16-tile shape centered at [center].
  Path generatePath({
    required Offset center,
    required double ringRadius,
    required double pointDistance,
    double rotation = 0.0,
  }) {
    final R = ringRadius;
    final D = max(pointDistance, R * 1.08);

    // Tip coordinates relative to (0, 0)
    final pNorth = Offset(0, -D);
    final pSouth = Offset(0, D);
    final pEast = Offset(D, 0);
    final pWest = Offset(-D, 0);

    // Circle boundary touch points
    final cNorth = Offset(0, -R);
    final cSouth = Offset(0, R);
    final cEast = Offset(R, 0);
    final cWest = Offset(-R, 0);

    final localPath = Path();

    if (mask == 0) {
      localPath.addOval(Rect.fromCircle(center: Offset.zero, radius: R));
    } else {
      if (hasNorth) {
        localPath.moveTo(pNorth.dx, pNorth.dy);
      } else {
        localPath.moveTo(cNorth.dx, cNorth.dy);
      }

      // Quadrant 1: North to East (NE)
      if (hasNorth && hasEast) {
        localPath.lineTo(pEast.dx, pEast.dy);
      } else if (hasNorth && !hasEast) {
        final cp1 = Offset(R * 0.35, -D + (D - R) * 0.25);
        final cp2 = Offset(R, -R * 0.45);
        localPath.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, cEast.dx, cEast.dy);
      } else if (!hasNorth && hasEast) {
        final cp1 = Offset(R * 0.45, -R);
        final cp2 = Offset(D - (D - R) * 0.25, -R * 0.35);
        localPath.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, pEast.dx, pEast.dy);
      } else {
        localPath.arcToPoint(cEast, radius: Radius.circular(R), clockwise: true);
      }

      // Quadrant 2: East to South (SE)
      if (hasEast && hasSouth) {
        localPath.lineTo(pSouth.dx, pSouth.dy);
      } else if (hasEast && !hasSouth) {
        final cp1 = Offset(D - (D - R) * 0.25, R * 0.35);
        final cp2 = Offset(R * 0.45, R);
        localPath.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, cSouth.dx, cSouth.dy);
      } else if (!hasEast && hasSouth) {
        final cp1 = Offset(R, R * 0.45);
        final cp2 = Offset(R * 0.35, D - (D - R) * 0.25);
        localPath.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, pSouth.dx, pSouth.dy);
      } else {
        localPath.arcToPoint(cSouth, radius: Radius.circular(R), clockwise: true);
      }

      // Quadrant 3: South to West (SW)
      if (hasSouth && hasWest) {
        localPath.lineTo(pWest.dx, pWest.dy);
      } else if (hasSouth && !hasWest) {
        final cp1 = Offset(-R * 0.35, D - (D - R) * 0.25);
        final cp2 = Offset(-R, R * 0.45);
        localPath.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, cWest.dx, cWest.dy);
      } else if (!hasSouth && hasWest) {
        final cp1 = Offset(-R * 0.45, R);
        final cp2 = Offset(-D + (D - R) * 0.25, R * 0.35);
        localPath.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, pWest.dx, pWest.dy);
      } else {
        localPath.arcToPoint(cWest, radius: Radius.circular(R), clockwise: true);
      }

      // Quadrant 4: West to North (NW)
      if (hasWest && hasNorth) {
        localPath.lineTo(pNorth.dx, pNorth.dy);
      } else if (hasWest && !hasNorth) {
        final cp1 = Offset(-D + (D - R) * 0.25, -R * 0.35);
        final cp2 = Offset(-R * 0.45, -R);
        localPath.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, cNorth.dx, cNorth.dy);
      } else if (!hasWest && hasNorth) {
        final cp1 = Offset(-R, -R * 0.45);
        final cp2 = Offset(-R * 0.35, -D + (D - R) * 0.25);
        localPath.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, pNorth.dx, pNorth.dy);
      } else {
        localPath.arcToPoint(cNorth, radius: Radius.circular(R), clockwise: true);
      }

      localPath.close();
    }

    final matrix = Matrix4.identity()
      ..setTranslationRaw(center.dx, center.dy, 0.0)
      ..rotateZ(rotation);

    return localPath.transform(matrix.storage);
  }

  /// Converts this tile into strokes for AI analysis and export
  KolamStroke toStroke({
    required Offset center,
    required double ringRadius,
    required double pointDistance,
    double rotation = 0.0,
    Color color = const Color(0xFFFFFFFF),
    double strokeWidth = 3.5,
  }) {
    final path = generatePath(
      center: center,
      ringRadius: ringRadius,
      pointDistance: pointDistance,
      rotation: rotation,
    );

    final points = <KolamPoint>[];
    for (final metric in path.computeMetrics()) {
      final length = metric.length;
      final step = max(2.0, length / 45.0);
      for (double d = 0; d < length; d += step) {
        final tangent = metric.getTangentForOffset(d);
        if (tangent != null) {
          points.add(KolamPoint(tangent.position.dx, tangent.position.dy));
        }
      }
    }

    return KolamStroke(
      points: points,
      colorValue: color.toARGB32(),
      strokeWidth: strokeWidth,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Kolam16Tile && other.mask == mask);

  @override
  int get hashCode => mask.hashCode;
}

/// Target Kolam pattern definition for Construction Challenges (4x4, 6x6, 8x8)
class KolamTargetPattern {
  final String id;
  final String name;
  final String tamilName;
  final String category;
  final String culturalLore;
  final int gridDimension; // 4 for 4x4, 6 for 6x6, 8 for 8x8
  final Map<int, Kolam16Tile> targetTiles;

  const KolamTargetPattern({
    required this.id,
    required this.name,
    required this.tamilName,
    required this.category,
    required this.culturalLore,
    this.gridDimension = 4,
    required this.targetTiles,
  });

  int get totalCells => gridDimension * gridDimension;
}

typedef Kolam4x4TargetPattern = KolamTargetPattern;

/// Library of 16 Sikku Kolam Tiles and authentic presets
class Kolam16TileLibrary {
  static const List<Kolam16Tile> all = [
    Kolam16Tile(0),  // 0000
    Kolam16Tile(1),  // 0001
    Kolam16Tile(2),  // 0010
    Kolam16Tile(3),  // 0011
    Kolam16Tile(4),  // 0100
    Kolam16Tile(5),  // 0101
    Kolam16Tile(6),  // 0110
    Kolam16Tile(7),  // 0111
    Kolam16Tile(8),  // 1000
    Kolam16Tile(9),  // 1001
    Kolam16Tile(10), // 1010
    Kolam16Tile(11), // 1011
    Kolam16Tile(12), // 1100
    Kolam16Tile(13), // 1101
    Kolam16Tile(14), // 1110
    Kolam16Tile(15), // 1111
  ];

  /// List of authentic 4x4 target patterns
  static final List<KolamTargetPattern> all4x4Targets = [
    const KolamTargetPattern(
      id: 'target_sudarshana_4x4',
      name: 'Sudarshana 4x4 Mandala',
      tamilName: 'சுதர்சன மண்டலம்',
      category: '4-Way Dihedral Knot',
      culturalLore: 'A classical 4x4 continuous Sikku weave invoking protection and symmetry across all 4 cardinal directions.',
      gridDimension: 4,
      targetTiles: {
        0: Kolam16Tile(1),   1: Kolam16Tile(8),   2: Kolam16Tile(8),   3: Kolam16Tile(3),
        4: Kolam16Tile(5),   5: Kolam16Tile(9),   6: Kolam16Tile(3),   7: Kolam16Tile(5),
        8: Kolam16Tile(5),   9: Kolam16Tile(12),  10: Kolam16Tile(6),  11: Kolam16Tile(5),
        12: Kolam16Tile(12), 13: Kolam16Tile(2),  14: Kolam16Tile(2),  15: Kolam16Tile(6),
      },
    ),
  ];

  /// Generates a procedural NxN Kolam pattern (4x4, 6x6, 8x8) using the exact D4 Dihedral symmetry algorithm
  static KolamTargetPattern generateRandomTargetPattern({
    int gridDimension = 4,
    AlgorithmicSymmetry? forcedSymmetry,
    Random? rng,
  }) {
    final N = gridDimension;
    final random = rng ?? Random();
    final symmetry = forcedSymmetry ?? AlgorithmicSymmetry.d4Multiple;

    final double limit = 0.35 + random.nextDouble() * 0.20;

    // Internal link matrices:
    // H is N rows x (N-1) cols (horizontal links between c and c+1 in row r)
    // V is (N-1) rows x N cols (vertical links between r and r+1 in col c)
    final H = List.generate(
        N, (_) => List.generate(N - 1, (_) => (random.nextDouble() > limit) ? 1 : 0));
    final V = List.generate(
        N - 1, (_) => List.generate(N, (_) => (random.nextDouble() > limit) ? 1 : 0));

    // Outer boundary loops (top, bottom, left, right)
    final top = List.generate(N, (_) => (random.nextDouble() > limit) ? 1 : 0);
    final bottom = List.generate(N, (_) => (random.nextDouble() > limit) ? 1 : 0);
    final left = List.generate(N, (_) => (random.nextDouble() > limit) ? 1 : 0);
    final right = List.generate(N, (_) => (random.nextDouble() > limit) ? 1 : 0);

    final halfN = (N / 2).floor();

    // 1. Horizontal Mirror (r <-> (N-1)-r)
    for (int r = 0; r < halfN; r++) {
      for (int c = 0; c < N - 1; c++) {
        H[(N - 1) - r][c] = H[r][c];
      }
    }
    for (int r = 0; r < halfN; r++) {
      for (int c = 0; c < N; c++) {
        V[(N - 2) - r][c] = V[r][c];
      }
    }

    // 2. Vertical Mirror (c <-> (N-1)-c)
    for (int r = 0; r < N; r++) {
      for (int c = 0; c < halfN; c++) {
        H[r][(N - 2) - c] = H[r][c];
      }
    }
    for (int r = 0; r < N - 1; r++) {
      for (int c = 0; c < halfN; c++) {
        V[r][(N - 1) - c] = V[r][c];
      }
    }

    // 3. Diagonal Mirror ((r, c) <-> (c, r))
    for (int r = 0; r < N - 1; r++) {
      for (int c = 0; c < N - 1; c++) {
        if (c > r) {
          V[r][c] = H[c][r];
        } else if (r > c) {
          H[r][c] = V[c][r];
        }
      }
    }

    // 4. Re-enforce mirrors after diagonal sync
    for (int r = 0; r < N; r++) {
      for (int c = 0; c < halfN; c++) {
        final val = H[r][c];
        H[r][(N - 2) - c] = val;
        H[(N - 1) - r][c] = val;
        H[(N - 1) - r][(N - 2) - c] = val;
      }
    }
    for (int r = 0; r < halfN; r++) {
      for (int c = 0; c < N; c++) {
        final val = V[r][c];
        V[(N - 2) - r][c] = val;
        V[r][(N - 1) - c] = val;
        V[(N - 2) - r][(N - 1) - c] = val;
      }
    }

    // 5. Symmetrize boundary loops
    for (int i = 0; i < halfN; i++) {
      final b = top[i];
      top[(N - 1) - i] = b;
      bottom[i] = b;
      bottom[(N - 1) - i] = b;
      left[i] = b;
      left[(N - 1) - i] = b;
      right[i] = b;
      right[(N - 1) - i] = b;
    }

    // Assemble N x N target tiles
    final targetTiles = <int, Kolam16Tile>{};
    for (int r = 0; r < N; r++) {
      for (int c = 0; c < N; c++) {
        final south = (r < N - 1) ? (V[r][c] != 0) : (bottom[c] != 0);
        final north = (r > 0) ? (V[r - 1][c] != 0) : (top[c] != 0);
        final east = (c < N - 1) ? (H[r][c] != 0) : (right[r] != 0);
        final west = (c > 0) ? (H[r][c - 1] != 0) : (left[r] != 0);

        final mask = (south ? 1 : 0) |
            (west ? 2 : 0) |
            (north ? 4 : 0) |
            (east ? 8 : 0);

        final slotIndex = r * N + c;
        targetTiles[slotIndex] = Kolam16Tile(mask);
      }
    }

    // Ensure not completely blank
    if (targetTiles.values.every((t) => t.mask == 0)) {
      final mid = (N / 2).floor();
      targetTiles[(mid - 1) * N + (mid - 1)] = const Kolam16Tile(15);
      targetTiles[(mid - 1) * N + mid] = const Kolam16Tile(15);
      targetTiles[mid * N + (mid - 1)] = const Kolam16Tile(15);
      targetTiles[mid * N + mid] = const Kolam16Tile(15);
    }

    final id = 'algo_${N}x${N}_${DateTime.now().microsecondsSinceEpoch}_${random.nextInt(1000)}';
    return KolamTargetPattern(
      id: id,
      name: '${N}x$N ${symmetry.label}',
      tamilName: symmetry.name,
      category: symmetry.description,
      culturalLore: 'Algorithmic ${N}x$N Kolam mandala generated with ${symmetry.label}.',
      gridDimension: N,
      targetTiles: targetTiles,
    );
  }

  /// Backward-compatible 4x4 generator
  static KolamTargetPattern generateRandom4x4Target({
    AlgorithmicSymmetry? forcedSymmetry,
    Random? rng,
  }) {
    return generateRandomTargetPattern(
      gridDimension: 4,
      forcedSymmetry: forcedSymmetry,
      rng: rng,
    );
  }
}
