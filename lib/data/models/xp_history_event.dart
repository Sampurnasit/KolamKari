enum XpEventType {
  learnModule,
  gameWon,
  kolamCreated,
  challengeCompleted,
  quizCompleted,
  kolamAnalysed,
}

/// Represents an individual XP-earning event in the user's heritage progress history.
class XpHistoryEvent {
  final String id;
  final String title;
  final String description;
  final int xpEarned;
  final DateTime timestamp;
  final XpEventType type;

  const XpHistoryEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.xpEarned,
    required this.timestamp,
    required this.type,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'xpEarned': xpEarned,
      'timestamp': timestamp.toIso8601String(),
      'type': type.name,
    };
  }

  factory XpHistoryEvent.fromJson(Map<String, dynamic> map) {
    return XpHistoryEvent(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      xpEarned: map['xpEarned'] ?? 0,
      timestamp: DateTime.tryParse(map['timestamp'] ?? '') ?? DateTime.now(),
      type: XpEventType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => XpEventType.gameWon,
      ),
    );
  }
}
