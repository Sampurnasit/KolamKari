enum GameType {
  memoryGame,
  patternConstruction,
  kolamPuzzle,
  symmetryGame,
}

class GameResult {
  final String id;
  final GameType gameType;
  final int score;
  final int xpEarned;
  final DateTime timestamp;
  final int difficultyLevel;
  final String? culturalNote;
  final bool won;

  const GameResult({
    required this.id,
    required this.gameType,
    required this.score,
    required this.xpEarned,
    required this.timestamp,
    required this.difficultyLevel,
    this.culturalNote,
    this.won = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'gameType': gameType.name,
      'score': score,
      'xpEarned': xpEarned,
      'timestamp': timestamp.toIso8601String(),
      'difficultyLevel': difficultyLevel,
      'culturalNote': culturalNote,
      'won': won,
    };
  }

  factory GameResult.fromJson(Map<String, dynamic> map) {
    return GameResult(
      id: map['id'] ?? '',
      gameType: GameType.values.firstWhere(
        (e) => e.name == map['gameType'],
        orElse: () => GameType.memoryGame,
      ),
      score: map['score'] ?? 0,
      xpEarned: map['xpEarned'] ?? 0,
      timestamp: DateTime.tryParse(map['timestamp'] ?? '') ?? DateTime.now(),
      difficultyLevel: map['difficultyLevel'] ?? 1,
      culturalNote: map['culturalNote'],
      won: map['won'] ?? true,
    );
  }
}
