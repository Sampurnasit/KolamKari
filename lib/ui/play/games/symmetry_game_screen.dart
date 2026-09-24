import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../data/models/algorithmic_kolam_pattern.dart';
import '../../../data/models/analysis_result.dart';
import '../../../data/models/game_result.dart';
import '../../../providers/app_providers.dart';
import '../widgets/algorithmic_kolam_view.dart';

class SymmetryGameScreen extends ConsumerStatefulWidget {
  final bool isDailyChallenge;
  final VoidCallback? onChallengeCompleted;

  const SymmetryGameScreen({
    super.key,
    this.isDailyChallenge = false,
    this.onChallengeCompleted,
  });

  @override
  ConsumerState<SymmetryGameScreen> createState() => _SymmetryGameScreenState();
}

class _SymmetryGameScreenState extends ConsumerState<SymmetryGameScreen>
    with SingleTickerProviderStateMixin {
  final Random _rng = Random();

  static const int _totalRounds = 5;
  int _currentRound = 1;
  int _correctCount = 0;
  int _streakCount = 0;
  int _maxStreak = 0;
  int _totalScore = 0;
  int _totalXpEarned = 0;
  bool _isMatchFinished = false;

  late AlgorithmicKolamPattern _currentPattern;
  late AnimationController _morphController;
  late Animation<double> _morphAnimation;

  AnalysisResult? _computedAnalysis;
  int? _selectedAnswerIndex;
  bool _evaluated = false;
  bool _isCorrect = false;
  String _diagnosticExplanation = '';

  static const List<String> _baseSymmetryOptions = [
    'Vertical',
    'Horizontal',
    'Diagonal',
    'All Axis (8-Way)',
  ];

  late List<String> _shuffledOptions;

  static const List<AlgorithmicSymmetry> _availableSymmetries = [
    AlgorithmicSymmetry.d1Vertical,
    AlgorithmicSymmetry.d1Horizontal,
    AlgorithmicSymmetry.d1Diagonal,
    AlgorithmicSymmetry.d4Multiple,
  ];

  @override
  void initState() {
    super.initState();
    _shuffledOptions = List<String>.from(_baseSymmetryOptions)..shuffle(_rng);

    final initialSymmetry = _availableSymmetries[_rng.nextInt(_availableSymmetries.length)];
    _currentPattern = AlgorithmicKolamPattern(
      tnumber: 9,
      symmetry: initialSymmetry,
    );
    _currentPattern.configTile(forcedSymmetry: initialSymmetry, rng: _rng);
    _computedAnalysis = _currentPattern.toAnalysisResult();

    _morphController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    _morphAnimation = CurvedAnimation(
      parent: _morphController,
      curve: Curves.easeInOutCubic,
    )..addListener(() {
        setState(() {});
      });

    _morphController.forward(from: 0.0);
  }

  @override
  void dispose() {
    _morphController.dispose();
    super.dispose();
  }

  /// Generates a fresh dynamic Kolam with a randomized symmetry type and shuffled options
  void _generateRandomPattern() {
    final candidates = _availableSymmetries.where((s) => s != _currentPattern.symmetry).toList();
    final nextSymmetry = candidates[_rng.nextInt(candidates.length)];

    _currentPattern.configTile(
      forcedSymmetry: nextSymmetry,
      rng: _rng,
    );
    _computedAnalysis = _currentPattern.toAnalysisResult();

    _shuffledOptions = List<String>.from(_baseSymmetryOptions)..shuffle(_rng);

    setState(() {
      _selectedAnswerIndex = null;
      _evaluated = false;
      _isCorrect = false;
      _diagnosticExplanation = '';
    });

    _morphController.forward(from: 0.0);
  }

  void _onNextRoundOrFinish() {
    if (_currentRound < _totalRounds) {
      setState(() {
        _currentRound++;
      });
      _generateRandomPattern();
    } else {
      _finishMatch();
    }
  }

  Future<void> _finishMatch() async {
    setState(() {
      _isMatchFinished = true;
    });

    // Save final match result to storage
    final storage = ref.read(storageServiceProvider);
    final gameResult = GameResult(
      id: const Uuid().v4(),
      gameType: GameType.symmetryGame,
      score: _totalScore,
      xpEarned: _totalXpEarned,
      timestamp: DateTime.now(),
      difficultyLevel: 1,
      culturalNote: 'Completed 5-round Symmetry Discovery Match ($_correctCount/$_totalRounds correct).',
      won: _correctCount >= 3,
    );
    await storage.recordGameResult(gameResult);

    if (widget.isDailyChallenge && _correctCount >= 3) {
      await ref.read(userProfileProvider.notifier).onDailyChallengeCompleted();
      widget.onChallengeCompleted?.call();
    }
  }

  void _restartMatch() {
    setState(() {
      _currentRound = 1;
      _correctCount = 0;
      _streakCount = 0;
      _maxStreak = 0;
      _totalScore = 0;
      _totalXpEarned = 0;
      _isMatchFinished = false;
    });
    _generateRandomPattern();
  }

  String _deriveSymmetryTypeAnswer() {
    switch (_currentPattern.symmetry) {
      case AlgorithmicSymmetry.d1Vertical:
        return 'Vertical';
      case AlgorithmicSymmetry.d1Horizontal:
        return 'Horizontal';
      case AlgorithmicSymmetry.d1Diagonal:
        return 'Diagonal';
      case AlgorithmicSymmetry.d4Multiple:
      default:
        return 'All Axis (8-Way)';
    }
  }

  Future<void> _submitAnswer(int index) async {
    if (_evaluated || _computedAnalysis == null || _isMatchFinished) return;

    final correctAnswer = _deriveSymmetryTypeAnswer();
    final isCorrect = _shuffledOptions[index] == correctAnswer;

    final explanation = 'This Kolam exhibits $correctAnswer Symmetry.';

    int gainedScore = 0;
    int gainedXp = 0;

    if (isCorrect) {
      _streakCount++;
      if (_streakCount > _maxStreak) {
        _maxStreak = _streakCount;
      }
      _correctCount++;
      // Base 100 pts + 25 pts combo bonus per streak
      gainedScore = 100 + (_streakCount - 1) * 25;
      gainedXp = 50;
      _totalScore += gainedScore;
      _totalXpEarned += gainedXp;

      // Award XP to user profile
      await ref.read(userProfileProvider.notifier).onSymmetrySolved();
    } else {
      _streakCount = 0;
    }

    setState(() {
      _selectedAnswerIndex = index;
      _evaluated = true;
      _isCorrect = isCorrect;
      _diagnosticExplanation = explanation;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isDailyChallenge ? 'Daily Challenge: Symmetry' : 'Kolam Symmetry Discovery'),
      ),
      body: _computedAnalysis == null
          ? const Center(child: CircularProgressIndicator(color: AppColors.turmericGold))
          : _isMatchFinished
              ? _buildVictorySummaryScreen(isDark)
              : _buildMatchGameplayScreen(isDark),
    );
  }

  /// Live 5-Round Gameplay Screen
  Widget _buildMatchGameplayScreen(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Round Progress Bar & Match Stats Header
          _buildMatchHeader(isDark),
          const SizedBox(height: 20),

          // Interactive Dynamic Algorithmic Kolam Board
          Center(
            child: _buildKolamBoard(isDark),
          ),
          const SizedBox(height: 36),

          // Question Title
          Text(
            'What symmetry does this dynamic Kolam exhibit?',
            style: AppTypography.cardTitle.copyWith(fontSize: 15),
          ),
          const SizedBox(height: 16),

          // Answer Options
          _buildOptionsList(isDark),
          const SizedBox(height: 16),

          // Clean & Simple Symmetry Diagnostic Card
          if (_evaluated) ...[
            _buildAnalyzerDiagnosticCard(isDark),
            const SizedBox(height: 18),
          ],

          // Next Round / View Summary Action Button
          if (_evaluated)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _onNextRoundOrFinish,
                icon: Icon(
                  _currentRound < _totalRounds
                      ? Icons.arrow_forward_rounded
                      : Icons.emoji_events_rounded,
                  color: Colors.white,
                ),
                label: Text(
                  _currentRound < _totalRounds
                      ? (_isCorrect
                          ? 'Next Round (${_currentRound + 1}/$_totalRounds) (+50 XP)'
                          : 'Next Round (${_currentRound + 1}/$_totalRounds)')
                      : 'Complete Match & View Summary',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  backgroundColor: _currentRound == _totalRounds
                      ? AppColors.turmericGold
                      : (_isCorrect ? AppColors.tulsiGreen : AppColors.terracottaRed),
                  foregroundColor: _currentRound == _totalRounds ? Colors.black87 : Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 3,
                ),
              ),
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  /// Round progress indicator + Live Score Header
  Widget _buildMatchHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.slateCard : AppColors.riceFlourCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.turmericGold.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Round Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.turmericGold.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Round $_currentRound / $_totalRounds',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.turmericAmber,
                  ),
                ),
              ),

              // Score & Streak Badges
              Row(
                children: [
                  if (_streakCount > 0) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: AppColors.turmericGold.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '🔥 $_streakCount',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.tulsiGreen.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '⭐ $_totalScore pts',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: AppColors.tulsiGreen,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),

          // 5 Segmented Dot Progress Indicator
          Row(
            children: List.generate(_totalRounds, (index) {
              final isCurrent = index == _currentRound - 1;
              final isCompleted = index < _currentRound - 1;

              return Expanded(
                child: Container(
                  height: 5,
                  margin: EdgeInsets.only(
                    right: index < _totalRounds - 1 ? 6 : 0,
                  ),
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? AppColors.tulsiGreen
                        : isCurrent
                            ? AppColors.turmericGold
                            : (isDark ? Colors.white12 : Colors.black12),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildKolamBoard(bool isDark) {
    const double boardDim = 270.0;

    return Container(
      width: boardDim,
      height: boardDim,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF221A1D) : AppColors.riceFlourBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: (_evaluated && _isCorrect) ? AppColors.tulsiGreen : AppColors.kaaviBrick,
          width: (_evaluated && _isCorrect) ? 3.0 : 2.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Dynamic Algorithmic Kolam Curves
          Positioned.fill(
            child: Center(
              child: AlgorithmicKolamView(
                pattern: _currentPattern,
                progress: _morphAnimation.value,
                size: boardDim - 12,
                strokeWidth: 2.8,
                showDots: true,
                margin: 6.0,
              ),
            ),
          ),

          // Symmetry Axis Overlays (Vertical, Horizontal & Diagonal Guide Lines)
          CustomPaint(
            size: const Size(boardDim, boardDim),
            painter: _SymmetryGuidePainter(
              showAxes: true,
              isDiagonal: _currentPattern.symmetry == AlgorithmicSymmetry.d1Diagonal ||
                  _currentPattern.symmetry == AlgorithmicSymmetry.d4Multiple,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionsList(bool isDark) {
    return Column(
      children: List.generate(_shuffledOptions.length, (index) {
        final isSelected = _selectedAnswerIndex == index;
        Color? bg;
        BorderSide border = BorderSide(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        );

        if (_evaluated) {
          if (isSelected) {
            if (_isCorrect) {
              bg = AppColors.tulsiGreen.withValues(alpha: 0.15);
              border = const BorderSide(color: AppColors.tulsiGreen, width: 2);
            } else {
              bg = AppColors.crimsonRed.withValues(alpha: 0.15);
              border = const BorderSide(color: AppColors.crimsonRed, width: 2);
            }
          }
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () => _submitAnswer(index),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              decoration: BoxDecoration(
                color: bg ?? (isDark ? AppColors.slateCard : AppColors.riceFlourCard),
                borderRadius: BorderRadius.circular(12),
                border: Border.fromBorderSide(border),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: isSelected
                        ? (_evaluated
                            ? (_isCorrect ? AppColors.tulsiGreen : AppColors.crimsonRed)
                            : AppColors.turmericGold)
                        : (isDark ? AppColors.slateLight : const Color(0xFFEFE8DE)),
                    child: Text(
                      String.fromCharCode(65 + index),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _shuffledOptions[index],
                      style: AppTypography.bodyText.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (_evaluated && isSelected)
                    Icon(
                      _isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
                      color: _isCorrect ? AppColors.tulsiGreen : AppColors.crimsonRed,
                      size: 20,
                    ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildAnalyzerDiagnosticCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _isCorrect
            ? AppColors.tulsiGreen.withValues(alpha: 0.12)
            : AppColors.crimsonRed.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isCorrect ? AppColors.tulsiGreen : AppColors.crimsonRed,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Icon(
            _isCorrect ? Icons.check_circle_rounded : Icons.info_rounded,
            color: _isCorrect ? AppColors.tulsiGreen : AppColors.crimsonRed,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isCorrect ? 'Correct! (+50 XP)' : 'Incorrect',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: _isCorrect ? AppColors.tulsiGreen : AppColors.crimsonRed,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _diagnosticExplanation,
                  style: AppTypography.bodyText.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Celebratory Victory & Match Summary Screen
  Widget _buildVictorySummaryScreen(bool isDark) {
    final double accuracy = (_correctCount / _totalRounds) * 100;
    final bool isMaster = _correctCount == _totalRounds;
    final bool isWinner = _correctCount >= 3;

    final title = isMaster
        ? 'Perfect Symmetry Master! 🏆'
        : isWinner
            ? 'Outstanding Symmetry Vision! 🌟'
            : 'Match Completed! 🕉️';

    final subtitle = isMaster
        ? 'Flawless 5/5 recognition of sacred geometric reflection planes!'
        : isWinner
            ? 'You correctly identified $_correctCount of $_totalRounds dynamic Kolam symmetries.'
            : 'Keep practicing to master all reflection planes of sacred Kolams.';

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Celebratory Trophy Badge Icon
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isWinner
                    ? AppColors.turmericGold.withValues(alpha: 0.18)
                    : AppColors.kaaviBrick.withValues(alpha: 0.18),
                border: Border.all(
                  color: isWinner ? AppColors.turmericGold : AppColors.kaaviBrick,
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (isWinner ? AppColors.turmericGold : AppColors.kaaviBrick)
                        .withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Icon(
                isMaster
                    ? Icons.military_tech_rounded
                    : isWinner
                        ? Icons.emoji_events_rounded
                        : Icons.auto_awesome_rounded,
                size: 48,
                color: isWinner ? AppColors.turmericGold : AppColors.kaaviBrick,
              ),
            ),
            const SizedBox(height: 20),

            // Victory Title
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTypography.screenHeading.copyWith(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isWinner ? AppColors.turmericGold : null,
              ),
            ),
            const SizedBox(height: 8),

            // Subtitle
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: AppTypography.bodyText.copyWith(
                color: isDark ? Colors.white70 : Colors.black54,
                fontSize: 13.5,
              ),
            ),
            const SizedBox(height: 24),

            // 2x2 Match Statistics Card Grid
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.slateCard : AppColors.riceFlourCard,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: AppColors.turmericGold.withValues(alpha: 0.35),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatItem(
                          icon: Icons.check_circle_rounded,
                          iconColor: AppColors.tulsiGreen,
                          label: 'Accuracy',
                          value: '$_correctCount / $_totalRounds (${accuracy.round()}%)',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatItem(
                          icon: Icons.stars_rounded,
                          iconColor: AppColors.turmericGold,
                          label: 'Total Score',
                          value: '$_totalScore pts',
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatItem(
                          icon: Icons.bolt_rounded,
                          iconColor: AppColors.tulsiGreen,
                          label: 'XP Earned',
                          value: '+$_totalXpEarned XP',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatItem(
                          icon: Icons.local_fire_department_rounded,
                          iconColor: AppColors.terracottaRed,
                          label: 'Max Streak',
                          value: '$_maxStreak 🔥',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Action Buttons
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _restartMatch,
                icon: const Icon(Icons.replay_rounded, color: Colors.white),
                label: const Text(
                  'Play Another Match (5 Rounds)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  backgroundColor: AppColors.tulsiGreen,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 2,
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back_rounded),
                label: const Text(
                  'Return to Play Hub',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: BorderSide(
                    color: isDark ? AppColors.borderDark : AppColors.kaaviBrick,
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: iconColor),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTypography.caption.copyWith(fontSize: 11.5),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTypography.cardTitle.copyWith(
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _SymmetryGuidePainter extends CustomPainter {
  final bool showAxes;
  final bool isDiagonal;

  const _SymmetryGuidePainter({
    required this.showAxes,
    this.isDiagonal = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (!showAxes) return;

    final axisPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.22)
      ..strokeWidth = 1.0;

    // Cardinal vertical & horizontal axes
    canvas.drawLine(Offset(size.width / 2, 0), Offset(size.width / 2, size.height), axisPaint);
    canvas.drawLine(Offset(0, size.height / 2), Offset(size.width, size.height / 2), axisPaint);

    // Diagonal axis guide
    if (isDiagonal) {
      final diagPaint = Paint()
        ..color = AppColors.turmericGold.withValues(alpha: 0.25)
        ..strokeWidth = 1.0;
      canvas.drawLine(const Offset(0, 0), Offset(size.width, size.height), diagPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _SymmetryGuidePainter oldDelegate) =>
      oldDelegate.showAxes != showAxes ||
      oldDelegate.isDiagonal != isDiagonal;
}
