enum SymmetryType {
  none,
  bilateralReflection,
  twoFoldReflection,
  fourFoldReflection,
  rotational90,
  rotational180,
  dihedralD4, // Both 4-fold rotation and reflection (classic mandala/kolam)
}

class AnalysisResult {
  final SymmetryType symmetryType;
  final int rotationalDegree; // 0, 90, 180, 270
  final String rotationalSymmetrySummary; // "90°", "180°", "270°", or "None"
  final bool reflectionDetected;
  final int reflectionAxesCount; // 0 to 4
  final List<String> matchingReflectionAxes; // e.g. ['Vertical Axis', 'Horizontal Axis', 'Main Diagonal (45°)', 'Anti-Diagonal (135°)']
  final int complexityScore; // 0 to 100
  final String gridSize; // e.g. "7x7"
  final int closedLoopCount;
  final int strokeCount;
  final int intersectionCount;
  final double patternDensity; // percentage of dot coverage
  final int uniqueShapePrimitivesCount;
  final int symmetryOperationsCount;
  final String structureSummary; // e.g. "7x7 Grid • 4 Closed Loops"
  final String complexityTier; // Simple, Moderate, Intricate, Masterwork
  final String culturalInterpretation;
  final Map<String, dynamic> formulaBreakdown;

  const AnalysisResult({
    required this.symmetryType,
    required this.rotationalDegree,
    this.rotationalSymmetrySummary = 'None',
    required this.reflectionDetected,
    required this.reflectionAxesCount,
    this.matchingReflectionAxes = const [],
    required this.complexityScore,
    required this.gridSize,
    required this.closedLoopCount,
    required this.strokeCount,
    required this.intersectionCount,
    required this.patternDensity,
    this.uniqueShapePrimitivesCount = 0,
    this.symmetryOperationsCount = 0,
    this.structureSummary = '',
    required this.complexityTier,
    required this.culturalInterpretation,
    required this.formulaBreakdown,
  });

  Map<String, dynamic> toJson() {
    return {
      'symmetryType': symmetryType.name,
      'rotationalDegree': rotationalDegree,
      'rotationalSymmetrySummary': rotationalSymmetrySummary,
      'reflectionDetected': reflectionDetected,
      'reflectionAxesCount': reflectionAxesCount,
      'matchingReflectionAxes': matchingReflectionAxes,
      'complexityScore': complexityScore,
      'gridSize': gridSize,
      'closedLoopCount': closedLoopCount,
      'strokeCount': strokeCount,
      'intersectionCount': intersectionCount,
      'patternDensity': patternDensity,
      'uniqueShapePrimitivesCount': uniqueShapePrimitivesCount,
      'symmetryOperationsCount': symmetryOperationsCount,
      'structureSummary': structureSummary.isNotEmpty ? structureSummary : '$gridSize Grid • $closedLoopCount Closed Loops',
      'complexityTier': complexityTier,
      'culturalInterpretation': culturalInterpretation,
      'formulaBreakdown': formulaBreakdown,
    };
  }

  factory AnalysisResult.fromJson(Map<String, dynamic> map) {
    final gSize = map['gridSize'] ?? '5x5';
    final loops = map['closedLoopCount'] ?? 0;
    final rotDeg = map['rotationalDegree'] ?? 0;

    return AnalysisResult(
      symmetryType: SymmetryType.values.firstWhere(
        (e) => e.name == map['symmetryType'],
        orElse: () => SymmetryType.none,
      ),
      rotationalDegree: rotDeg,
      rotationalSymmetrySummary: map['rotationalSymmetrySummary'] ?? (rotDeg > 0 ? '$rotDeg°' : 'None'),
      reflectionDetected: map['reflectionDetected'] ?? false,
      reflectionAxesCount: map['reflectionAxesCount'] ?? 0,
      matchingReflectionAxes: List<String>.from(map['matchingReflectionAxes'] ?? []),
      complexityScore: map['complexityScore'] ?? 0,
      gridSize: gSize,
      closedLoopCount: loops,
      strokeCount: map['strokeCount'] ?? 0,
      intersectionCount: map['intersectionCount'] ?? 0,
      patternDensity: (map['patternDensity'] as num?)?.toDouble() ?? 0.0,
      uniqueShapePrimitivesCount: map['uniqueShapePrimitivesCount'] ?? 0,
      symmetryOperationsCount: map['symmetryOperationsCount'] ?? 0,
      structureSummary: map['structureSummary'] ?? '$gSize Grid • $loops Closed Loops',
      complexityTier: map['complexityTier'] ?? 'Moderate',
      culturalInterpretation: map['culturalInterpretation'] ?? '',
      formulaBreakdown: Map<String, dynamic>.from(map['formulaBreakdown'] ?? {}),
    );
  }

  AnalysisResult copyWith({
    SymmetryType? symmetryType,
    int? rotationalDegree,
    String? rotationalSymmetrySummary,
    bool? reflectionDetected,
    int? reflectionAxesCount,
    List<String>? matchingReflectionAxes,
    int? complexityScore,
    String? gridSize,
    int? closedLoopCount,
    int? strokeCount,
    int? intersectionCount,
    double? patternDensity,
    int? uniqueShapePrimitivesCount,
    int? symmetryOperationsCount,
    String? structureSummary,
    String? complexityTier,
    String? culturalInterpretation,
    Map<String, dynamic>? formulaBreakdown,
  }) {
    return AnalysisResult(
      symmetryType: symmetryType ?? this.symmetryType,
      rotationalDegree: rotationalDegree ?? this.rotationalDegree,
      rotationalSymmetrySummary: rotationalSymmetrySummary ?? this.rotationalSymmetrySummary,
      reflectionDetected: reflectionDetected ?? this.reflectionDetected,
      reflectionAxesCount: reflectionAxesCount ?? this.reflectionAxesCount,
      matchingReflectionAxes: matchingReflectionAxes ?? this.matchingReflectionAxes,
      complexityScore: complexityScore ?? this.complexityScore,
      gridSize: gridSize ?? this.gridSize,
      closedLoopCount: closedLoopCount ?? this.closedLoopCount,
      strokeCount: strokeCount ?? this.strokeCount,
      intersectionCount: intersectionCount ?? this.intersectionCount,
      patternDensity: patternDensity ?? this.patternDensity,
      uniqueShapePrimitivesCount: uniqueShapePrimitivesCount ?? this.uniqueShapePrimitivesCount,
      symmetryOperationsCount: symmetryOperationsCount ?? this.symmetryOperationsCount,
      structureSummary: structureSummary ?? this.structureSummary,
      complexityTier: complexityTier ?? this.complexityTier,
      culturalInterpretation: culturalInterpretation ?? this.culturalInterpretation,
      formulaBreakdown: formulaBreakdown ?? this.formulaBreakdown,
    );
  }
}
