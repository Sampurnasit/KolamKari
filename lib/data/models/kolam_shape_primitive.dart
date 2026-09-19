import 'dart:math';
import 'package:flutter/material.dart';
import '../../services/analysis_service.dart';

enum KolamPrimitiveType {
  straightLine,
  diagonalBridge,
  quarterArc,
  halfLoop,
  sCurveWeave,
  petalLoop,
  cornerSikkuTurn,
  crossRibbon,
  cuspArch,
}

/// Definition of a basic Kolam line/curve primitive with normalized anchors (0.0 to 1.0)
class KolamShapePrimitive {
  final String id;
  final String name;
  final String tamilName;
  final KolamPrimitiveType type;
  final String description;

  // Normalized local anchor coordinates in [0.0, 1.0] unit box
  final Offset localStartAnchor;
  final Offset localEndAnchor;

  const KolamShapePrimitive({
    required this.id,
    required this.name,
    required this.tamilName,
    required this.type,
    required this.description,
    required this.localStartAnchor,
    required this.localEndAnchor,
  });

  /// Generates the path within a given bounding dimension [size]
  Path generatePath(Size size) {
    final w = size.width;
    final h = size.height;
    final path = Path();

    switch (type) {
      case KolamPrimitiveType.straightLine:
        // Straight line from mid-left to mid-right
        path.moveTo(0, h * 0.5);
        path.lineTo(w, h * 0.5);
        break;

      case KolamPrimitiveType.diagonalBridge:
        // 45° diagonal line linking opposite corners
        path.moveTo(0, h);
        path.lineTo(w, 0);
        break;

      case KolamPrimitiveType.quarterArc:
        // Quarter curve arching around corner dot
        path.moveTo(0, h * 0.5);
        path.quadraticBezierTo(w * 0.5, h * 0.5, w * 0.5, 0);
        break;

      case KolamPrimitiveType.halfLoop:
        // 180° smooth turnaround loop wrapping around border dot
        path.moveTo(0, h * 0.25);
        path.cubicTo(w * 0.95, h * 0.05, w * 0.95, h * 0.95, 0, h * 0.75);
        break;

      case KolamPrimitiveType.sCurveWeave:
        // S-curve serpentine weaving between two pulli dots
        path.moveTo(0, h * 0.3);
        path.cubicTo(w * 0.35, h * 0.95, w * 0.65, h * 0.05, w, h * 0.7);
        break;

      case KolamPrimitiveType.petalLoop:
        // Auspicious lotus petal loop arching outward
        path.moveTo(0, h * 0.5);
        path.cubicTo(w * 0.25, h * 0.05, w * 0.75, h * 0.05, w, h * 0.5);
        break;

      case KolamPrimitiveType.cornerSikkuTurn:
        // Classic Sikku knot corner wrap for endless loops
        path.moveTo(0, h * 0.5);
        path.cubicTo(w * 0.05, h * 0.05, w * 0.05, h * 0.05, w * 0.5, 0);
        break;

      case KolamPrimitiveType.crossRibbon:
        // Interlocking cross ribbon intersecting at center
        path.moveTo(0, h * 0.5);
        path.lineTo(w, h * 0.5);
        path.moveTo(w * 0.5, 0);
        path.lineTo(w * 0.5, h);
        break;

      case KolamPrimitiveType.cuspArch:
        // Traditional pointed temple gopuram cusp arch
        path.moveTo(0, h * 0.6);
        path.quadraticBezierTo(w * 0.3, h * 0.1, w * 0.5, 0);
        path.quadraticBezierTo(w * 0.7, h * 0.1, w, h * 0.6);
        break;
    }

    return path;
  }
}

/// Catalog of all 9 basic Kolam line/curve primitives
class KolamShapeCatalog {
  static final List<KolamShapePrimitive> primitives = [
    const KolamShapePrimitive(
      id: 'straight_line',
      name: 'Straight Spine',
      tamilName: 'நேர்கோடு',
      type: KolamPrimitiveType.straightLine,
      description: 'Linear connection along coordinate axes linking adjacent pulli dots.',
      localStartAnchor: Offset(0.0, 0.5),
      localEndAnchor: Offset(1.0, 0.5),
    ),
    const KolamShapePrimitive(
      id: 'diagonal_bridge',
      name: 'Diagonal Bridge',
      tamilName: 'மூலைக்கோடு',
      type: KolamPrimitiveType.diagonalBridge,
      description: '45° diagonal link connecting interstitial pulli dots.',
      localStartAnchor: Offset(0.0, 1.0),
      localEndAnchor: Offset(1.0, 0.0),
    ),
    const KolamShapePrimitive(
      id: 'quarter_arc',
      name: 'Quarter Arc',
      tamilName: 'வளைவு',
      type: KolamPrimitiveType.quarterArc,
      description: 'Smooth 90° arc curving around boundary dots.',
      localStartAnchor: Offset(0.0, 0.5),
      localEndAnchor: Offset(0.5, 0.0),
    ),
    const KolamShapePrimitive(
      id: 'half_loop',
      name: 'Turnaround Loop',
      tamilName: 'சுழல் வளைவு',
      type: KolamPrimitiveType.halfLoop,
      description: '180° turnaround loop enclosing an outer pulli dot.',
      localStartAnchor: Offset(0.0, 0.25),
      localEndAnchor: Offset(0.0, 0.75),
    ),
    const KolamShapePrimitive(
      id: 's_curve_weave',
      name: 'S-Curve Weave',
      tamilName: 'பாம்பு வளைவு',
      type: KolamPrimitiveType.sCurveWeave,
      description: 'Serpentine curve weaving fluidly between two dots.',
      localStartAnchor: Offset(0.0, 0.3),
      localEndAnchor: Offset(1.0, 0.7),
    ),
    const KolamShapePrimitive(
      id: 'petal_loop',
      name: 'Lotus Petal',
      tamilName: 'தாமரை இதழ்',
      type: KolamPrimitiveType.petalLoop,
      description: 'Auspicious petal arch for floral kolams and mandalas.',
      localStartAnchor: Offset(0.0, 0.5),
      localEndAnchor: Offset(1.0, 0.5),
    ),
    const KolamShapePrimitive(
      id: 'corner_sikku_turn',
      name: 'Corner Sikku Knot',
      tamilName: 'சிக்கு முடிச்சு',
      type: KolamPrimitiveType.cornerSikkuTurn,
      description: 'Sharp apex turnaround enclosing corner pulli dots.',
      localStartAnchor: Offset(0.0, 0.5),
      localEndAnchor: Offset(0.5, 0.0),
    ),
    const KolamShapePrimitive(
      id: 'cross_ribbon',
      name: 'Orthogonal Cross',
      tamilName: 'சிலுவை முடிச்சு',
      type: KolamPrimitiveType.crossRibbon,
      description: 'Orthogonal ribbon crossing at cardinal midpoints.',
      localStartAnchor: Offset(0.0, 0.5),
      localEndAnchor: Offset(1.0, 0.5),
    ),
    const KolamShapePrimitive(
      id: 'cusp_arch',
      name: 'Temple Cusp Arch',
      tamilName: 'கோபுர வளைவு',
      type: KolamPrimitiveType.cuspArch,
      description: 'Pointed gopuram arch creating stepped Padi borders.',
      localStartAnchor: Offset(0.0, 0.6),
      localEndAnchor: Offset(1.0, 0.6),
    ),
  ];

  static KolamShapePrimitive getById(String id) {
    return primitives.firstWhere(
      (p) => p.id == id,
      orElse: () => primitives.first,
    );
  }
}

/// An instance of a shape placed on the Kolam canvas
class PlacedKolamShape {
  final String id;
  final String primitiveId;
  final Offset position; // center position on canvas
  final int rotationDegrees; // 0, 45, 90, 135, 180, 225, 270, 315
  final double size; // bounding box width & height (typically 1 grid step, e.g. 58.33 px)
  final int colorValue;
  final double strokeWidth;

  const PlacedKolamShape({
    required this.id,
    required this.primitiveId,
    required this.position,
    this.rotationDegrees = 0,
    this.size = 58.33,
    this.colorValue = 0xFFFFFFFF,
    this.strokeWidth = 3.5,
  });

  KolamShapePrimitive get primitive => KolamShapeCatalog.getById(primitiveId);

  PlacedKolamShape copyWith({
    String? id,
    String? primitiveId,
    Offset? position,
    int? rotationDegrees,
    double? size,
    int? colorValue,
    double? strokeWidth,
  }) {
    return PlacedKolamShape(
      id: id ?? this.id,
      primitiveId: primitiveId ?? this.primitiveId,
      position: position ?? this.position,
      rotationDegrees: rotationDegrees ?? this.rotationDegrees,
      size: size ?? this.size,
      colorValue: colorValue ?? this.colorValue,
      strokeWidth: strokeWidth ?? this.strokeWidth,
    );
  }

  /// Calculates world coordinate of local offset after applying rotation and scale
  Offset _localToWorld(Offset localUnitOffset) {
    // 1. Shift relative to center [-0.5, 0.5]
    final cx = (localUnitOffset.dx - 0.5) * size;
    final cy = (localUnitOffset.dy - 0.5) * size;

    // 2. Rotate
    final rad = rotationDegrees * pi / 180.0;
    final cosA = cos(rad);
    final sinA = sin(rad);
    final rx = cx * cosA - cy * sinA;
    final ry = cx * sinA + cy * cosA;

    // 3. Translate to world position
    return Offset(position.dx + rx, position.dy + ry);
  }

  Offset get worldStartAnchor => _localToWorld(primitive.localStartAnchor);
  Offset get worldEndAnchor => _localToWorld(primitive.localEndAnchor);

  Rect get boundingBox => Rect.fromCenter(
        center: position,
        width: size * 1.2,
        height: size * 1.2,
      );

  /// Converts the shape into a discrete KolamStroke with interpolated points
  /// for rendering, saving, and computational geometry analysis
  KolamStroke toStroke() {
    final path = primitive.generatePath(Size(size, size));
    final metrics = path.computeMetrics().toList();
    final points = <KolamPoint>[];

    final rad = rotationDegrees * pi / 180.0;
    final cosA = cos(rad);
    final sinA = sin(rad);

    for (final metric in metrics) {
      final length = metric.length;
      final steps = max(8, (length / 6.0).ceil());

      for (int i = 0; i <= steps; i++) {
        final distance = (i / steps) * length;
        final tangent = metric.getTangentForOffset(distance);
        if (tangent != null) {
          final localPt = tangent.position;
          // Center-relative
          final cx = localPt.dx - size * 0.5;
          final cy = localPt.dy - size * 0.5;
          // Rotate
          final rx = cx * cosA - cy * sinA;
          final ry = cx * sinA + cy * cosA;
          // Translate
          points.add(KolamPoint(position.dx + rx, position.dy + ry));
        }
      }
    }

    return KolamStroke(
      points: points,
      colorValue: colorValue,
      strokeWidth: strokeWidth,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'primitiveId': primitiveId,
        'x': position.dx,
        'y': position.dy,
        'rotationDegrees': rotationDegrees,
        'size': size,
        'colorValue': colorValue,
        'strokeWidth': strokeWidth,
      };

  factory PlacedKolamShape.fromJson(Map<String, dynamic> json) => PlacedKolamShape(
        id: json['id'] as String,
        primitiveId: json['primitiveId'] as String,
        position: Offset((json['x'] as num).toDouble(), (json['y'] as num).toDouble()),
        rotationDegrees: json['rotationDegrees'] as int? ?? 0,
        size: (json['size'] as num?)?.toDouble() ?? 58.33,
        colorValue: json['colorValue'] as int? ?? 0xFFFFFFFF,
        strokeWidth: (json['strokeWidth'] as num?)?.toDouble() ?? 3.5,
      );
}

/// Backward-compatible aliases
typedef PlacedShapePrimitive = PlacedKolamShape;
typedef KolamShapeLibrary = KolamShapeCatalog;
