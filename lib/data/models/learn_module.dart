class LearnModule {
  final String id;
  final String title;
  final String subtitle;
  final String category;
  final String bodyMarkdown;
  final String? imageAssetPath;
  final String relatedRegion;
  final int xpReward;
  final bool completed;
  final String culturalQuote;
  final List<String> keyTakeaways;

  const LearnModule({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.category,
    required this.bodyMarkdown,
    this.imageAssetPath,
    required this.relatedRegion,
    this.xpReward = 20,
    this.completed = false,
    this.culturalQuote = '',
    this.keyTakeaways = const [],
  });

  LearnModule copyWith({
    String? id,
    String? title,
    String? subtitle,
    String? category,
    String? bodyMarkdown,
    String? imageAssetPath,
    String? relatedRegion,
    int? xpReward,
    bool? completed,
    String? culturalQuote,
    List<String>? keyTakeaways,
  }) {
    return LearnModule(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      category: category ?? this.category,
      bodyMarkdown: bodyMarkdown ?? this.bodyMarkdown,
      imageAssetPath: imageAssetPath ?? this.imageAssetPath,
      relatedRegion: relatedRegion ?? this.relatedRegion,
      xpReward: xpReward ?? this.xpReward,
      completed: completed ?? this.completed,
      culturalQuote: culturalQuote ?? this.culturalQuote,
      keyTakeaways: keyTakeaways ?? this.keyTakeaways,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'category': category,
      'bodyMarkdown': bodyMarkdown,
      'imageAssetPath': imageAssetPath,
      'relatedRegion': relatedRegion,
      'xpReward': xpReward,
      'completed': completed,
      'culturalQuote': culturalQuote,
      'keyTakeaways': keyTakeaways,
    };
  }

  factory LearnModule.fromJson(Map<String, dynamic> map) {
    return LearnModule(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      subtitle: map['subtitle'] ?? '',
      category: map['category'] ?? '',
      bodyMarkdown: map['bodyMarkdown'] ?? '',
      imageAssetPath: map['imageAssetPath'],
      relatedRegion: map['relatedRegion'] ?? '',
      xpReward: map['xpReward'] ?? 20,
      completed: map['completed'] ?? false,
      culturalQuote: map['culturalQuote'] ?? '',
      keyTakeaways: List<String>.from(map['keyTakeaways'] ?? const []),
    );
  }
}
