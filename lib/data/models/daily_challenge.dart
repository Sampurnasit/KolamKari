enum ChallengeType {
  observeRecreate, // Mon (Memory)
  completePattern, // Tue (Puzzle)
  identifySymmetry, // Wed (Symmetry)
  memoryChallenge, // Thu (Memory Hard)
  buildUsingTiles, // Fri (Pattern Construction)
  createYourOwn, // Sat (Create + Analyse)
  heritageQuiz, // Sun (Heritage Quiz)
}

class DailyChallenge {
  final String date; // YYYY-MM-DD
  final ChallengeType type;
  final String title;
  final String description;
  final String targetModule; // 'PLAY', 'CREATE', 'LEARN'
  final bool completed;
  final int xpAwarded;
  final String culturalNote;

  const DailyChallenge({
    required this.date,
    required this.type,
    required this.title,
    required this.description,
    required this.targetModule,
    this.completed = false,
    this.xpAwarded = 100,
    required this.culturalNote,
  });

  DailyChallenge copyWith({
    String? date,
    ChallengeType? type,
    String? title,
    String? description,
    String? targetModule,
    bool? completed,
    int? xpAwarded,
    String? culturalNote,
  }) {
    return DailyChallenge(
      date: date ?? this.date,
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      targetModule: targetModule ?? this.targetModule,
      completed: completed ?? this.completed,
      xpAwarded: xpAwarded ?? this.xpAwarded,
      culturalNote: culturalNote ?? this.culturalNote,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'type': type.name,
      'title': title,
      'description': description,
      'targetModule': targetModule,
      'completed': completed,
      'xpAwarded': xpAwarded,
      'culturalNote': culturalNote,
    };
  }

  factory DailyChallenge.fromJson(Map<String, dynamic> map) {
    return DailyChallenge(
      date: map['date'] ?? '',
      type: ChallengeType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => ChallengeType.observeRecreate,
      ),
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      targetModule: map['targetModule'] ?? 'PLAY',
      completed: map['completed'] ?? false,
      xpAwarded: map['xpAwarded'] ?? 100,
      culturalNote: map['culturalNote'] ?? '',
    );
  }
}
