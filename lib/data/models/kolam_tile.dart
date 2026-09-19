enum TilePrimitiveType {
  cornerLoop,
  straightSegment,
  crossIntersection,
  curvedBridge,
  petalArc,
  dotSurround,
  swirlKnot,
  waveLink,
}

class KolamTile {
  final String id;
  final String name;
  final TilePrimitiveType primitiveType;
  final int rotation; // 0, 90, 180, 270
  final List<int> allowedRotations;
  final String culturalMeaning;

  const KolamTile({
    required this.id,
    required this.name,
    required this.primitiveType,
    this.rotation = 0,
    this.allowedRotations = const [0, 90, 180, 270],
    this.culturalMeaning = '',
  });

  KolamTile copyWith({
    String? id,
    String? name,
    TilePrimitiveType? primitiveType,
    int? rotation,
    List<int>? allowedRotations,
    String? culturalMeaning,
  }) {
    return KolamTile(
      id: id ?? this.id,
      name: name ?? this.name,
      primitiveType: primitiveType ?? this.primitiveType,
      rotation: rotation ?? this.rotation,
      allowedRotations: allowedRotations ?? this.allowedRotations,
      culturalMeaning: culturalMeaning ?? this.culturalMeaning,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'primitiveType': primitiveType.name,
      'rotation': rotation,
      'allowedRotations': allowedRotations,
      'culturalMeaning': culturalMeaning,
    };
  }

  factory KolamTile.fromJson(Map<String, dynamic> map) {
    return KolamTile(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      primitiveType: TilePrimitiveType.values.firstWhere(
        (e) => e.name == map['primitiveType'],
        orElse: () => TilePrimitiveType.cornerLoop,
      ),
      rotation: map['rotation'] ?? 0,
      allowedRotations: List<int>.from(map['allowedRotations'] ?? [0, 90, 180, 270]),
      culturalMeaning: map['culturalMeaning'] ?? '',
    );
  }
}
