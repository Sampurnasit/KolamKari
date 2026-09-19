import 'analysis_result.dart';

class SavedKolam {
  final String id;
  final String name;
  final DateTime createdDate;
  final String canvasStrokeData; // JSON serialized strokes
  final String? thumbnailImage; // optional base64 or placeholder
  final int gridSize; // 5, 7, 9
  final AnalysisResult? symmetryResult;
  final int complexityScore;
  final String? culturalTag;
  final String? sourceSampleId; // If created via Trace Mode copying a sample design

  const SavedKolam({
    required this.id,
    required this.name,
    required this.createdDate,
    required this.canvasStrokeData,
    this.thumbnailImage,
    required this.gridSize,
    AnalysisResult? symmetryResult,
    AnalysisResult? analysisResult,
    required this.complexityScore,
    this.culturalTag,
    this.sourceSampleId,
  }) : symmetryResult = symmetryResult ?? analysisResult;

  /// Analysis result accessor alongside symmetryResult
  AnalysisResult? get analysisResult => symmetryResult;

  bool get isTracedCopy => sourceSampleId != null && sourceSampleId!.isNotEmpty;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'createdDate': createdDate.toIso8601String(),
      'canvasStrokeData': canvasStrokeData,
      'thumbnailImage': thumbnailImage,
      'gridSize': gridSize,
      'symmetryResult': symmetryResult?.toJson(),
      'analysisResult': symmetryResult?.toJson(),
      'complexityScore': complexityScore,
      'culturalTag': culturalTag,
      'sourceSampleId': sourceSampleId,
    };
  }

  factory SavedKolam.fromJson(Map<String, dynamic> map) {
    final resultJson = map['analysisResult'] ?? map['symmetryResult'];
    return SavedKolam(
      id: map['id'] ?? '',
      name: map['name'] ?? 'Untitled Kolam',
      createdDate: DateTime.tryParse(map['createdDate'] ?? '') ?? DateTime.now(),
      canvasStrokeData: map['canvasStrokeData'] ?? '[]',
      thumbnailImage: map['thumbnailImage'],
      gridSize: map['gridSize'] ?? 5,
      symmetryResult: resultJson != null
          ? AnalysisResult.fromJson(Map<String, dynamic>.from(resultJson))
          : null,
      complexityScore: map['complexityScore'] ?? 0,
      culturalTag: map['culturalTag'],
      sourceSampleId: map['sourceSampleId'],
    );
  }

  SavedKolam copyWith({
    String? id,
    String? name,
    DateTime? createdDate,
    String? canvasStrokeData,
    String? thumbnailImage,
    int? gridSize,
    AnalysisResult? symmetryResult,
    int? complexityScore,
    String? culturalTag,
    String? sourceSampleId,
  }) {
    return SavedKolam(
      id: id ?? this.id,
      name: name ?? this.name,
      createdDate: createdDate ?? this.createdDate,
      canvasStrokeData: canvasStrokeData ?? this.canvasStrokeData,
      thumbnailImage: thumbnailImage ?? this.thumbnailImage,
      gridSize: gridSize ?? this.gridSize,
      symmetryResult: symmetryResult ?? this.symmetryResult,
      complexityScore: complexityScore ?? this.complexityScore,
      culturalTag: culturalTag ?? this.culturalTag,
      sourceSampleId: sourceSampleId ?? this.sourceSampleId,
    );
  }
}
