class BadgeItem {
  final String id;
  final String title;
  final String description;
  final String iconEmoji;
  final bool unlocked;
  final DateTime? unlockedAt;
  final int currentProgress;
  final int targetProgress;

  const BadgeItem({
    required this.id,
    required this.title,
    required this.description,
    required this.iconEmoji,
    this.unlocked = false,
    this.unlockedAt,
    this.currentProgress = 0,
    required this.targetProgress,
  });

  BadgeItem copyWith({
    String? id,
    String? title,
    String? description,
    String? iconEmoji,
    bool? unlocked,
    DateTime? unlockedAt,
    int? currentProgress,
    int? targetProgress,
  }) {
    return BadgeItem(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      iconEmoji: iconEmoji ?? this.iconEmoji,
      unlocked: unlocked ?? this.unlocked,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      currentProgress: currentProgress ?? this.currentProgress,
      targetProgress: targetProgress ?? this.targetProgress,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'iconEmoji': iconEmoji,
      'unlocked': unlocked,
      'unlockedAt': unlockedAt?.toIso8601String(),
      'currentProgress': currentProgress,
      'targetProgress': targetProgress,
    };
  }

  factory BadgeItem.fromJson(Map<String, dynamic> map) {
    return BadgeItem(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      iconEmoji: map['iconEmoji'] ?? '🏅',
      unlocked: map['unlocked'] ?? false,
      unlockedAt: map['unlockedAt'] != null ? DateTime.tryParse(map['unlockedAt']) : null,
      currentProgress: map['currentProgress'] ?? 0,
      targetProgress: map['targetProgress'] ?? 1,
    );
  }
}

class UserProfile {
  final String name;
  final String username;
  final int xp;
  final int level;
  final String levelTitle;
  final List<BadgeItem> badges;
  final int currentStreak;
  final int longestStreak;
  final String? lastChallengeDate;
  final int memoryGamesWon;
  final int puzzlesCompleted;
  final int symmetryChallengesSolved;
  final int kolamsCreated;
  final int learnModulesCompleted;

  const UserProfile({
    this.name = 'Kolam Artisan',
    this.username = '@kolam_artisan',
    this.xp = 0,
    this.level = 1,
    this.levelTitle = 'Kolam Explorer',
    this.badges = const [],
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastChallengeDate,
    this.memoryGamesWon = 0,
    this.puzzlesCompleted = 0,
    this.symmetryChallengesSolved = 0,
    this.kolamsCreated = 0,
    this.learnModulesCompleted = 0,
  });

  /// Automatically generates a clean, unique-styled username handle from a display name
  static String generateUsername(String rawName) {
    final clean = rawName.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    final trimmed = clean.replaceAll(RegExp(r'^_+|_+$'), '');
    if (trimmed.isEmpty) return '@kolam_artisan';
    return '@$trimmed';
  }

  UserProfile copyWith({
    String? name,
    String? username,
    int? xp,
    int? level,
    String? levelTitle,
    List<BadgeItem>? badges,
    int? currentStreak,
    int? longestStreak,
    String? lastChallengeDate,
    int? memoryGamesWon,
    int? puzzlesCompleted,
    int? symmetryChallengesSolved,
    int? kolamsCreated,
    int? learnModulesCompleted,
  }) {
    return UserProfile(
      name: name ?? this.name,
      username: username ?? this.username,
      xp: xp ?? this.xp,
      level: level ?? this.level,
      levelTitle: levelTitle ?? this.levelTitle,
      badges: badges ?? this.badges,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastChallengeDate: lastChallengeDate ?? this.lastChallengeDate,
      memoryGamesWon: memoryGamesWon ?? this.memoryGamesWon,
      puzzlesCompleted: puzzlesCompleted ?? this.puzzlesCompleted,
      symmetryChallengesSolved: symmetryChallengesSolved ?? this.symmetryChallengesSolved,
      kolamsCreated: kolamsCreated ?? this.kolamsCreated,
      learnModulesCompleted: learnModulesCompleted ?? this.learnModulesCompleted,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'username': username,
      'xp': xp,
      'level': level,
      'levelTitle': levelTitle,
      'badges': badges.map((b) => b.toJson()).toList(),
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'lastChallengeDate': lastChallengeDate,
      'memoryGamesWon': memoryGamesWon,
      'puzzlesCompleted': puzzlesCompleted,
      'symmetryChallengesSolved': symmetryChallengesSolved,
      'kolamsCreated': kolamsCreated,
      'learnModulesCompleted': learnModulesCompleted,
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> map) {
    return UserProfile(
      name: map['name'] ?? 'Kolam Artisan',
      username: map['username'] ?? '@kolam_artisan',
      xp: map['xp'] ?? 0,
      level: map['level'] ?? 1,
      levelTitle: map['levelTitle'] ?? 'Kolam Explorer',
      badges: (map['badges'] as List?)?.map((e) => BadgeItem.fromJson(Map<String, dynamic>.from(e))).toList() ?? [],
      currentStreak: map['currentStreak'] ?? 0,
      longestStreak: map['longestStreak'] ?? 0,
      lastChallengeDate: map['lastChallengeDate'],
      memoryGamesWon: map['memoryGamesWon'] ?? 0,
      puzzlesCompleted: map['puzzlesCompleted'] ?? 0,
      symmetryChallengesSolved: map['symmetryChallengesSolved'] ?? 0,
      kolamsCreated: map['kolamsCreated'] ?? 0,
      learnModulesCompleted: map['learnModulesCompleted'] ?? 0,
    );
  }
}
