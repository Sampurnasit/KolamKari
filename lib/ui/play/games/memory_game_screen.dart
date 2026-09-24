import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../data/models/algorithmic_kolam_pattern.dart';
import '../../../data/models/game_result.dart';
import '../../../data/models/kolam_16_tile.dart';
import '../../../data/models/kolam_circle_connection.dart';
import '../../../data/models/saved_kolam.dart';
import '../../../providers/app_providers.dart';
import '../../create/widgets/kolam_canvas_widget.dart';
import '../widgets/kolam_16_tile_view.dart';

/// Evaluation score breakdown for the Memory Recall Game
class MemoryScoreBreakdown {
  final int tileScore; // 0 to 70
  final int matchedTiles;
  final int totalTiles;
  final double matchPercentage;
  final int timeBonusScore; // 0 to 10
  final double elapsedSeconds;
  final int maxLives; // 3 or 5
  final int livesRemaining; // 0 to maxLives
  final int livesBonus; // 0 to 20
  final int totalScore; // 0 to 100
  final bool isPassing;

  const MemoryScoreBreakdown({
    required this.tileScore,
    required this.matchedTiles,
    required this.totalTiles,
    required this.matchPercentage,
    required this.timeBonusScore,
    required this.elapsedSeconds,
    required this.maxLives,
    required this.livesRemaining,
    required this.livesBonus,
    required this.totalScore,
    required this.isPassing,
  });

  int get livesUsed => maxLives - livesRemaining;

  int get stars {
    if (totalScore >= 85) return 3;
    if (totalScore >= 70) return 2;
    if (totalScore >= 50) return 1;
    return 0;
  }
}

enum MemoryPhase {
  difficultySelect,
  preview,
  drawing,
  result,
}

class MemoryGameScreen extends ConsumerStatefulWidget {
  final int? initialDifficulty; // 1: 10s, 2: 7s, 3: 5s, 4: 3s
  final bool isDailyChallenge;
  final VoidCallback? onChallengeCompleted;
  final bool startImmediately;

  const MemoryGameScreen({
    super.key,
    this.initialDifficulty,
    this.isDailyChallenge = false,
    this.onChallengeCompleted,
    this.startImmediately = false,
  });

  @override
  ConsumerState<MemoryGameScreen> createState() => _MemoryGameScreenState();
}

class _MemoryGameScreenState extends ConsumerState<MemoryGameScreen>
    with SingleTickerProviderStateMixin {
  late int _difficulty;
  MemoryPhase _phase = MemoryPhase.difficultySelect;
  int _secondsLeft = 10;
  Timer? _countdownTimer;
  final Stopwatch _drawingStopwatch = Stopwatch();
  Timer? _stopwatchTicker;
  double _elapsedDrawingSeconds = 0.0;

  // Unified Hearts / Lives System (Level 4: 5 hearts, Levels 1-3: 3 hearts)
  int get _maxLives => _difficulty == 4 ? 5 : 3;
  int _livesRemaining = 3;

  final Random _rng = Random();

  // Active 16-Tile Target Pattern (same generator as Pattern Construction) & Grid Size
  late KolamTargetPattern _currentTarget;
  int _gridSize = 4;

  // --- 16-TILE STUDIO CANVAS STATE ---
  final Map<int, Kolam16Tile> _tileStates = {};
  final List<Map<int, Kolam16Tile>> _tileUndoStack = [];
  final List<Map<int, Kolam16Tile>> _tileRedoStack = [];
  int? _selectedCircleIndex;

  Color get _selectedColor {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? const Color(0xFFFFFFFF) : const Color(0xFF1E1614);
  }

  // Evaluation Breakdown
  MemoryScoreBreakdown? _scoreBreakdown;

  // Animation controller for countdown pulse
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _difficulty = widget.initialDifficulty ?? 1;

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);

    if (widget.initialDifficulty != null || widget.isDailyChallenge || widget.startImmediately) {
      _loadPatternAndStartCountdown(_difficulty);
    } else {
      _phase = MemoryPhase.difficultySelect;
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _stopwatchTicker?.cancel();
    _drawingStopwatch.stop();
    _pulseController.dispose();
    super.dispose();
  }

  int _getCountdownSeconds(int diff) {
    switch (diff) {
      case 1:
        return 10;
      case 2:
        return 7;
      case 3:
        return 5;
      case 4:
      default:
        return 3;
    }
  }

  int _getGridSizeForDifficulty(int diff) {
    switch (diff) {
      case 1:
        return 4; // 4x4 Bilateral
      case 2:
        return 5; // 5x5 Diagonal/Rotational
      case 3:
        return 6; // 6x6 4-Way D4
      case 4:
      default:
        return 8; // 8x8 Grand D4 Mandala
    }
  }

  AlgorithmicSymmetry _getSymmetryForDifficulty(int diff) {
    switch (diff) {
      case 1:
        return _rng.nextBool()
            ? AlgorithmicSymmetry.d1Vertical
            : AlgorithmicSymmetry.d1Horizontal;
      case 2:
        return _rng.nextBool()
            ? AlgorithmicSymmetry.d1Diagonal
            : AlgorithmicSymmetry.c4Rotational;
      case 3:
        return AlgorithmicSymmetry.d4Multiple;
      case 4:
      default:
        return AlgorithmicSymmetry.d4Multiple;
    }
  }

  void _selectDifficultyAndStart(int diff) {
    setState(() {
      _difficulty = diff;
    });
    _loadPatternAndStartCountdown(diff);
  }

  void _loadPatternAndStartCountdown(int diff) {
    final gridSize = _getGridSizeForDifficulty(diff);
    final symmetry = _getSymmetryForDifficulty(diff);

    final target = Kolam16TileLibrary.generateRandomTargetPattern(
      gridDimension: gridSize,
      forcedSymmetry: symmetry,
      rng: _rng,
    );

    setState(() {
      _difficulty = diff;
      _gridSize = gridSize;
      _currentTarget = target;

      // Reset Lives (3 Hearts = 3 Peek Hint Chances)
      _livesRemaining = _maxLives;

      // Reset Canvas
      _tileStates.clear();
      _tileUndoStack.clear();
      _tileRedoStack.clear();
      _selectedCircleIndex = null;

      _scoreBreakdown = null;
      _phase = MemoryPhase.preview;
      _secondsLeft = _getCountdownSeconds(diff);
      _elapsedDrawingSeconds = 0.0;
    });

    _drawingStopwatch.reset();
    _drawingStopwatch.stop();
    _stopwatchTicker?.cancel();

    _startCountdownTimer();
  }

  void _startCountdownTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft > 1) {
        if (mounted) {
          setState(() {
            _secondsLeft--;
          });
        }
      } else {
        timer.cancel();
        _transitionToDrawingPhase();
      }
    });
  }

  void _transitionToDrawingPhase() {
    _countdownTimer?.cancel();
    if (!mounted) return;

    setState(() {
      _phase = MemoryPhase.drawing;
      _secondsLeft = 0;
    });

    _drawingStopwatch.reset();
    _drawingStopwatch.start();

    _stopwatchTicker?.cancel();
    _stopwatchTicker = Timer.periodic(const Duration(milliseconds: 200), (_) {
      if (mounted && _phase == MemoryPhase.drawing) {
        setState(() {
          _elapsedDrawingSeconds = _drawingStopwatch.elapsedMilliseconds / 1000.0;
        });
      }
    });
  }

  /// Opens the Hint Peek dialog allowing the user to view the target pattern (spends 1 Heart / Life).
  void _openHintPeek() {
    if (_livesRemaining <= 0) return;

    setState(() {
      _livesRemaining--;
    });

    _drawingStopwatch.stop();

    int peekSecondsLeft = 5;
    Timer? peekTimer;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        final isDark = Theme.of(dialogCtx).brightness == Brightness.dark;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            peekTimer ??= Timer.periodic(const Duration(seconds: 1), (timer) {
              if (peekSecondsLeft > 1) {
                setDialogState(() {
                  peekSecondsLeft--;
                });
              } else {
                timer.cancel();
                if (Navigator.of(dialogCtx).canPop()) {
                  Navigator.of(dialogCtx).pop();
                }
              }
            });

            return Dialog(
              backgroundColor: isDark ? AppColors.slateCard : AppColors.riceFlourCard,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.visibility_rounded,
                                color: AppColors.turmericAmber, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Pattern Peek Hint',
                              style: AppTypography.cardTitle.copyWith(fontSize: 16),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.terracottaRed.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${peekSecondsLeft}s',
                            style: const TextStyle(
                              color: AppColors.terracottaRed,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: 260,
                      height: 260,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1B1514) : const Color(0xFFFAF2E7),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.turmericGold.withValues(alpha: 0.4)),
                      ),
                      padding: const EdgeInsets.all(8),
                      child: Center(
                        child: KolamNxNPreviewView(
                          tiles: _currentTarget.targetTiles,
                          gridDimension: _gridSize,
                          size: 244,
                          strokeWidth: _gridSize == 4
                              ? 3.0
                              : (_gridSize == 5 ? 2.6 : (_gridSize == 6 ? 2.2 : 1.8)),
                          showDots: true,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '${_currentTarget.name} (${_currentTarget.category})',
                      style: AppTypography.caption.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.turmericAmber,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.crimsonRed.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.favorite_rounded,
                              color: AppColors.crimsonRed, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            'Spent 1 Heart • $_livesRemaining of $_maxLives Hearts remaining',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.crimsonRed,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () {
                        peekTimer?.cancel();
                        Navigator.of(dialogCtx).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.turmericGold,
                        foregroundColor: Colors.black87,
                        minimumSize: const Size(double.infinity, 38),
                      ),
                      child: const Text(
                        'Got It! Return to Drawing',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).then((_) {
      peekTimer?.cancel();
      if (mounted && _phase == MemoryPhase.drawing) {
        _drawingStopwatch.start();
      }
    });
  }

  // --- GRID DOTS CALCULATION ---

  List<Offset> _getGridDots(double canvasSize) {
    return KolamGridLayout.generateDots(
      canvasSize: canvasSize,
      gridSize: _gridSize,
      orientation: KolamGridOrientation.square,
    );
  }

  // --- 16-TILE ACTIONS & GESTURES ---

  void _saveTileUndoSnapshot() {
    _tileUndoStack.add(Map.from(_tileStates));
    _tileRedoStack.clear();
  }

  void _toggleJoinCircles(int fromIndex, int toIndex) {
    final dots = _getGridDots(350.0);
    if (fromIndex >= dots.length || toIndex >= dots.length) return;

    final pA = dots[fromIndex];
    final pB = dots[toIndex];
    final delta = pB - pA;

    int bitFrom;
    int bitTo;
    if (delta.dy.abs() >= delta.dx.abs()) {
      if (delta.dy > 0) {
        bitFrom = 0; // South
        bitTo = 2; // North
      } else {
        bitFrom = 2; // North
        bitTo = 0; // South
      }
    } else {
      if (delta.dx > 0) {
        bitFrom = 3; // East
        bitTo = 1; // West
      } else {
        bitFrom = 1; // West
        bitTo = 3; // East
      }
    }

    setState(() {
      _saveTileUndoSnapshot();

      final currentTileA = _tileStates[fromIndex] ?? Kolam16Tile.circle;
      final currentTileB = _tileStates[toIndex] ?? Kolam16Tile.circle;

      final isAlreadyConnected = (currentTileA.mask & (1 << bitFrom) != 0) &&
          (currentTileB.mask & (1 << bitTo) != 0);

      if (isAlreadyConnected) {
        _tileStates[fromIndex] = currentTileA.setBit(bitFrom, false);
        _tileStates[toIndex] = currentTileB.setBit(bitTo, false);
      } else {
        _tileStates[fromIndex] = currentTileA.setBit(bitFrom, true);
        _tileStates[toIndex] = currentTileB.setBit(bitTo, true);
      }

      _selectedCircleIndex = toIndex;
    });
  }

  void _onCircleTapped(int dotIndex, int? quadrantBit) {
    if (_phase != MemoryPhase.drawing) return;

    if (quadrantBit != null) {
      setState(() {
        _saveTileUndoSnapshot();
        final current = _tileStates[dotIndex] ?? Kolam16Tile.circle;
        final updated = current.toggleBit(quadrantBit);
        _tileStates[dotIndex] = updated;
        _selectedCircleIndex = dotIndex;
      });
    } else {
      setState(() {
        if (_selectedCircleIndex == null) {
          _selectedCircleIndex = dotIndex;
        } else if (_selectedCircleIndex == dotIndex) {
          _saveTileUndoSnapshot();
          final current = _tileStates[dotIndex] ?? Kolam16Tile.circle;
          final nextMask = (current.mask + 1) % 16;
          final updated = Kolam16Tile(nextMask);
          _tileStates[dotIndex] = updated;
        } else {
          _toggleJoinCircles(_selectedCircleIndex!, dotIndex);
        }
      });
    }
  }

  void _onCanvasPanStart(Offset point) {
    if (_phase != MemoryPhase.drawing) return;
    final dots = _getGridDots(350.0);
    final ringRadius =
        KolamGridLayout.getRingRadius(350.0, _gridSize, KolamGridOrientation.square);
    final hit =
        KolamGridLayout.findHitCircleDot(tapPos: point, dots: dots, ringRadius: ringRadius);
    if (hit != null) {
      setState(() {
        _selectedCircleIndex = hit;
      });
    }
  }

  void _onCanvasPanUpdate(Offset point) {
    if (_phase != MemoryPhase.drawing) return;
    final dots = _getGridDots(350.0);
    final ringRadius =
        KolamGridLayout.getRingRadius(350.0, _gridSize, KolamGridOrientation.square);
    final hit =
        KolamGridLayout.findHitCircleDot(tapPos: point, dots: dots, ringRadius: ringRadius);
    if (hit != null && _selectedCircleIndex != null && hit != _selectedCircleIndex) {
      _toggleJoinCircles(_selectedCircleIndex!, hit);
    }
  }

  // --- UNDO / REDO / CLEAR ---

  bool get _canUndo => _tileUndoStack.isNotEmpty || _tileStates.isNotEmpty;
  bool get _canRedo => _tileRedoStack.isNotEmpty;

  void _undoAction() {
    if (_tileUndoStack.isNotEmpty) {
      setState(() {
        _tileRedoStack.add(Map.from(_tileStates));
        _tileStates.clear();
        _tileStates.addAll(_tileUndoStack.removeLast());
      });
    } else if (_tileStates.isNotEmpty) {
      setState(() {
        _tileRedoStack.add(Map.from(_tileStates));
        _tileStates.clear();
      });
    }
  }

  void _redoAction() {
    if (_tileRedoStack.isNotEmpty) {
      setState(() {
        _tileUndoStack.add(Map.from(_tileStates));
        _tileStates.clear();
        _tileStates.addAll(_tileRedoStack.removeLast());
      });
    }
  }

  void _clearCanvas() {
    if (_tileStates.isEmpty) return;
    setState(() {
      _saveTileUndoSnapshot();
      _tileStates.clear();
      _selectedCircleIndex = null;
    });
  }

  // --- EXTRACT STROKES FOR EVALUATION ---

  // --- SCORING & EVALUATION ENGINE ---

  Future<void> _evaluateSubmission() async {
    _drawingStopwatch.stop();
    _stopwatchTicker?.cancel();
    final elapsedSec = _drawingStopwatch.elapsedMilliseconds / 1000.0;

    if (_tileStates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please place or customize 16-Tile nodes before submitting!'),
          backgroundColor: AppColors.terracottaRed,
        ),
      );
      _drawingStopwatch.start();
      return;
    }

    final totalCells = _currentTarget.totalCells;
    int matchedCount = 0;
    for (int i = 0; i < totalCells; i++) {
      final targetTile = _currentTarget.targetTiles[i] ?? const Kolam16Tile(0);
      final userTile = _tileStates[i] ?? const Kolam16Tile(0);
      if (userTile.mask == targetTile.mask) {
        matchedCount++;
      }
    }

    final double matchPercentage = (matchedCount / totalCells) * 100.0;
    final int tileScore = ((matchedCount / totalCells) * 70.0).round().clamp(0, 70);

    // Speed & Recall Bonus (0 to 10 pts)
    final double expectedSec = 20.0 + (_gridSize * 3.0);
    double rawTimeScore;
    if (elapsedSec <= 15.0) {
      rawTimeScore = 10.0;
    } else if (elapsedSec <= expectedSec) {
      final t = (elapsedSec - 15.0) / (expectedSec - 15.0);
      rawTimeScore = 10.0 - (t * 4.0);
    } else {
      final extra = (elapsedSec - expectedSec) / 10.0;
      rawTimeScore = max(3.0, 6.0 - extra);
    }
    final int timeScore = rawTimeScore.round().clamp(0, 10);

    final bool isExactMatch = matchedCount == totalCells;
    final bool isAccurate = isExactMatch || (matchedCount / totalCells >= 0.70);

    // Check Hearts / Lives if inaccurate
    if (!isExactMatch && _livesRemaining > 1) {
      setState(() {
        _livesRemaining--;
      });

      _drawingStopwatch.start();

      if (!mounted) return;
      showDialog(
        context: context,
        builder: (dialogCtx) {
          final isDark = Theme.of(dialogCtx).brightness == Brightness.dark;
          return AlertDialog(
            backgroundColor: isDark ? AppColors.slateCard : AppColors.riceFlourCard,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                const Icon(Icons.heart_broken_rounded, color: AppColors.crimsonRed, size: 28),
                const SizedBox(width: 8),
                Text(
                  'Pattern Mismatch',
                  style: AppTypography.cardTitle.copyWith(color: AppColors.crimsonRed),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$matchedCount of $totalCells tiles matched (${matchPercentage.toStringAsFixed(0)}% accuracy).',
                  style: AppTypography.bodyText,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('Hearts Left: ', style: TextStyle(fontWeight: FontWeight.bold)),
                    ...List.generate(_maxLives, (i) {
                      final isAlive = i < _livesRemaining;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: Icon(
                          isAlive ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          size: 20,
                          color: isAlive ? AppColors.crimsonRed : Colors.grey,
                        ),
                      );
                    }),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.turmericAmber.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.turmericAmber.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.lightbulb_outline_rounded,
                          size: 18, color: AppColors.turmericAmber),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _livesRemaining > 0
                              ? 'Tip: You can use a Heart (❤️ $_livesRemaining left) to Peek at the pattern again!'
                              : 'Tip: Inspect node curves and symmetries to adjust your tiles.',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.turmericAmber,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              if (_livesRemaining > 0)
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(dialogCtx).pop();
                    _openHintPeek();
                  },
                  icon: const Icon(Icons.visibility_rounded, size: 16),
                  label: const Text('Peek Pattern (Use 1 ❤️)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.turmericAmber,
                    foregroundColor: Colors.white,
                  ),
                ),
              TextButton(
                onPressed: () => Navigator.of(dialogCtx).pop(),
                child: const Text('Continue Editing',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      );
      return;
    }

    if (!isExactMatch && _livesRemaining == 1) {
      _livesRemaining = 0;
    }

    final int livesBonus;
    if (_maxLives == 5) {
      livesBonus = (_livesRemaining * 4).clamp(0, 20); // 4 pts per heart (up to 20 pts)
    } else {
      switch (_livesRemaining) {
        case 3:
          livesBonus = 20; // 3/3 Hearts Preserved (Flawless!)
          break;
        case 2:
          livesBonus = 13; // 2/3 Hearts Preserved
          break;
        case 1:
          livesBonus = 7; // 1/3 Hearts Preserved
          break;
        default:
          livesBonus = 0; // 0 Hearts Preserved
          break;
      }
    }

    final int finalTotalScore = (tileScore + timeScore + livesBonus).clamp(0, 100);
    final bool isPassing = isAccurate && _livesRemaining > 0 && finalTotalScore >= 50;

    final breakdown = MemoryScoreBreakdown(
      tileScore: tileScore,
      matchedTiles: matchedCount,
      totalTiles: totalCells,
      matchPercentage: matchPercentage,
      timeBonusScore: timeScore,
      elapsedSeconds: elapsedSec,
      maxLives: _maxLives,
      livesRemaining: _livesRemaining,
      livesBonus: livesBonus,
      totalScore: finalTotalScore,
      isPassing: isPassing,
    );

    setState(() {
      _scoreBreakdown = breakdown;
      _phase = MemoryPhase.result;
    });

    // Gamification & Logging
    if (isPassing) {
      await ref.read(userProfileProvider.notifier).onMemoryGameWon();
      if (widget.isDailyChallenge) {
        await ref.read(userProfileProvider.notifier).onDailyChallengeCompleted();
        widget.onChallengeCompleted?.call();
      }
    }

    final storage = ref.read(storageServiceProvider);
    final result = GameResult(
      id: const Uuid().v4(),
      gameType: GameType.memoryGame,
      score: finalTotalScore,
      xpEarned: isPassing ? 50 : 15,
      timestamp: DateTime.now(),
      difficultyLevel: _difficulty,
      culturalNote:
          'Memorized 16-Tile ${_currentTarget.name} (${_currentTarget.category}).',
      won: isPassing,
    );
    await storage.recordGameResult(result);
  }

  // --- SAVE RECREATED KOLAM TO GALLERY ---

  void _saveRecreatedKolam() {
    if (_tileStates.isEmpty) return;

    final defaultName = 'Memory ${_currentTarget.name}';
    final nameController = TextEditingController(text: defaultName);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Save to My Kolams'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Kolam Name',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              final id = const Uuid().v4();
              final tileStatesJson =
                  jsonEncode(_tileStates.map((k, v) => MapEntry(k.toString(), v.mask)));

              final newKolam = SavedKolam(
                id: id,
                name: nameController.text.trim().isEmpty ? defaultName : nameController.text.trim(),
                createdDate: DateTime.now(),
                canvasStrokeData: '[]',
                gridSize: _gridSize,
                orientation: KolamGridOrientation.square.name,
                colorValue: _selectedColor.toARGB32(),
                tileStatesData: tileStatesJson,
                complexityScore: _scoreBreakdown?.totalScore ?? 75,
                culturalTag: 'Recreated 16-Tile ${_currentTarget.category}',
              );

              await ref.read(savedKolamsProvider.notifier).save(newKolam);

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: AppColors.tulsiGreen,
                    content: Text('Saved "${newKolam.name}" to My Kolams Gallery!'),
                  ),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // BUILD ROUTER
  // ==========================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isDailyChallenge ? 'Daily Challenge: Memory' : 'Kolam Memory Game'),
        actions: [
          if (_phase != MemoryPhase.difficultySelect) ...[
            IconButton(
              icon: const Icon(Icons.tune_rounded),
              tooltip: 'Change Difficulty',
              onPressed: () {
                setState(() {
                  _countdownTimer?.cancel();
                  _drawingStopwatch.stop();
                  _phase = MemoryPhase.difficultySelect;
                });
              },
            ),
            IconButton(
              icon: const Icon(Icons.shuffle_rounded),
              tooltip: 'New Pattern',
              onPressed: () => _loadPatternAndStartCountdown(_difficulty),
            ),
          ],
        ],
      ),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _buildCurrentPhaseWidget(isDark),
        ),
      ),
    );
  }

  Widget _buildCurrentPhaseWidget(bool isDark) {
    switch (_phase) {
      case MemoryPhase.difficultySelect:
        return _buildDifficultySelectorScreen(isDark);
      case MemoryPhase.preview:
        return _buildPreviewScreen(isDark);
      case MemoryPhase.drawing:
        return _buildDrawingScreen(isDark);
      case MemoryPhase.result:
        return _buildResultScreen(isDark);
    }
  }

  // ==========================================
  // PHASE 1: DIFFICULTY SELECTOR SCREEN
  // ==========================================

  Widget _buildDifficultySelectorScreen(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF382329), const Color(0xFF26191E)]
                    : [const Color(0xFFFBF2E7), const Color(0xFFF6E2CD)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.turmericGold.withValues(alpha: 0.35),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.terracottaRed.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.psychology_rounded,
                    size: 36,
                    color: AppColors.terracottaRed,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '16-Tile Visual Recall',
                        style: AppTypography.cardTitle.copyWith(fontSize: 18),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Select your difficulty tier. Memorize the procedurally generated Kolam, then recreate the 16-Tile curves on the exact studio canvas from mental recall.',
                        style: AppTypography.caption.copyWith(
                          fontSize: 12.5,
                          color: isDark
                              ? AppColors.textLight.withValues(alpha: 0.8)
                              : AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          Text(
            'Choose Difficulty Level',
            style: AppTypography.cardTitle.copyWith(fontSize: 16),
          ),
          const SizedBox(height: 12),

          _buildDifficultyCard(
            level: 1,
            title: 'Level 1: Beginner',
            timeSeconds: 10,
            gridDesc: '4x4 Grid',
            heartsCount: 3,
            description: 'Bilateral reflection across vertical or horizontal axis.',
            examples: 'Bilateral Sikku Vine, Water Lotus Reflection',
            color: AppColors.tulsiGreen,
            isDark: isDark,
          ),
          const SizedBox(height: 12),

          _buildDifficultyCard(
            level: 2,
            title: 'Level 2: Skilled',
            timeSeconds: 7,
            gridDesc: '5x5 Grid',
            heartsCount: 3,
            description: 'Diagonal ray reflection & 90° cyclic rotational invariant loops.',
            examples: 'Sanctum Diagonal, Swirling Chakra Pinwheel',
            color: AppColors.turmericAmber,
            isDark: isDark,
          ),
          const SizedBox(height: 12),

          _buildDifficultyCard(
            level: 3,
            title: 'Level 3: Adept',
            timeSeconds: 5,
            gridDesc: '6x6 Grid',
            heartsCount: 3,
            description: 'Full D4 8-fold dihedral symmetry with 4 reflection planes & rotation.',
            examples: 'Sudarshana 8-Way Mandala, Temple Sanctum',
            color: AppColors.terracottaRed,
            isDark: isDark,
          ),
          const SizedBox(height: 12),

          _buildDifficultyCard(
            level: 4,
            title: 'Level 4: Master',
            timeSeconds: 3,
            gridDesc: '8x8 Grid',
            heartsCount: 5,
            description: 'Grand sacred celestial yantra with intricate multi-loop dihedral weaving.',
            examples: 'Celestial Ashta Dikpala Yantra, Cosmic Mandala',
            color: const Color(0xFF8E24AA),
            isDark: isDark,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildDifficultyCard({
    required int level,
    required String title,
    required int timeSeconds,
    required String gridDesc,
    required int heartsCount,
    required String description,
    required String examples,
    required Color color,
    required bool isDark,
  }) {
    final isSelected = _difficulty == level;

    return InkWell(
      onTap: () => _selectDifficultyAndStart(level),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.slateCard : AppColors.riceFlourCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : (isDark ? AppColors.borderDark : AppColors.borderLight),
            width: isSelected ? 2.2 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: color.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    title,
                    style:
                        AppTypography.tagText.copyWith(color: color, fontWeight: FontWeight.bold),
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    const Icon(Icons.timer_rounded, size: 15, color: AppColors.turmericAmber),
                    const SizedBox(width: 3),
                    Text(
                      '${timeSeconds}s',
                      style: AppTypography.tagText.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.turmericAmber,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                Row(
                  children: [
                    const Icon(Icons.favorite_rounded, size: 14, color: AppColors.crimsonRed),
                    const SizedBox(width: 3),
                    Text(
                      '$heartsCount Hearts',
                      style: AppTypography.tagText.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.crimsonRed,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.slateLight : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(gridDesc, style: AppTypography.caption.copyWith(fontSize: 11)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              description,
              style: AppTypography.bodyText.copyWith(
                fontSize: 12.5,
                color: isDark ? AppColors.textLight.withValues(alpha: 0.8) : AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.auto_awesome_rounded, size: 13, color: color.withValues(alpha: 0.8)),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Archetype: $examples',
                    style: AppTypography.caption.copyWith(
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      color: AppColors.textMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 6),
                ElevatedButton(
                  onPressed: () => _selectDifficultyAndStart(level),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Start',
                          style: TextStyle(
                              color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                      SizedBox(width: 2),
                      Icon(Icons.arrow_forward_rounded, size: 13, color: Colors.white),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // PHASE 2: PREVIEW / COUNTDOWN SCREEN
  // ==========================================

  Widget _buildPreviewScreen(bool isDark) {
    return Column(
      children: [
        // Pattern Header Card
        Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.slateCard : AppColors.riceFlourCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.turmericGold.withValues(alpha: 0.35)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _currentTarget.name,
                      style: AppTypography.cardTitle.copyWith(fontSize: 16),
                    ),
                    Text(
                      '${_currentTarget.tamilName} • ${_currentTarget.category}',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.turmericAmber,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.terracottaRed.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.terracottaRed.withValues(alpha: 0.4)),
                ),
                child: Text(
                  '${_gridSize}x$_gridSize Grid',
                  style: const TextStyle(
                    color: AppColors.terracottaRed,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Countdown Timer Bar
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.terracottaRed.withValues(alpha: 0.15),
            border: Border(
              bottom: BorderSide(color: AppColors.terracottaRed.withValues(alpha: 0.3)),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ScaleTransition(
                scale: Tween<double>(begin: 1.0, end: 1.18).animate(_pulseController),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: AppColors.terracottaRed,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.timer_rounded, size: 16, color: Colors.white),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Memorize the 16-Tile Kolam: ',
                style: AppTypography.caption.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.terracottaRed,
                ),
              ),
              Text(
                '$_secondsLeft seconds',
                style: AppTypography.cardTitle.copyWith(
                  fontSize: 16,
                  color: AppColors.terracottaRed,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),

        // 16-Tile Kolam Preview Area
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1614) : const Color(0xFFFAF2E7),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: AppColors.turmericGold.withValues(alpha: 0.5),
                  width: 2.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.terracottaRed.withValues(alpha: 0.15),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Render the 16-Tile NxN Pattern Preview
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: FittedBox(
                          fit: BoxFit.contain,
                          child: KolamNxNPreviewView(
                            tiles: _currentTarget.targetTiles,
                            gridDimension: _gridSize,
                            size: 320,
                            strokeWidth: _gridSize == 4
                                ? 3.0
                                : (_gridSize == 5 ? 2.6 : (_gridSize == 6 ? 2.2 : 1.8)),
                            showDots: true,
                          ),
                        ),
                      ),
                    ),

                    // Top Badge: Category
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.75),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.turmericGold.withValues(alpha: 0.8),
                            width: 1.2,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.auto_awesome_rounded,
                                size: 15, color: AppColors.turmericAmber),
                            const SizedBox(width: 6),
                            Text(
                              _currentTarget.category,
                              style: AppTypography.tagText.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Bottom Lore Ribbon
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.88),
                              Colors.black.withValues(alpha: 0.0),
                            ],
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.lightbulb_outline_rounded,
                                size: 16, color: AppColors.turmericAmber),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                _currentTarget.culturalLore,
                                style: AppTypography.caption.copyWith(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontSize: 11.5,
                                  fontStyle: FontStyle.italic,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Skip to Drawing Action
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: OutlinedButton.icon(
            onPressed: _transitionToDrawingPhase,
            icon: const Icon(Icons.flash_on_rounded, color: AppColors.turmericAmber, size: 18),
            label: const Text('Memorized! Start Recreating Now'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 44),
              side: const BorderSide(color: AppColors.turmericAmber, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // PHASE 3: DRAWING SCREEN (Exact Studio 16-Tile Canvas)
  // ==========================================

  Widget _buildDrawingScreen(bool isDark) {
    return Column(
      children: [
        // Top Action Header (Lives, Peek Hint, Grid, Live Timer, Undo/Redo/Clear)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? AppColors.slateCard : AppColors.riceFlourCard,
            border: Border(
              bottom: BorderSide(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  // Lives (Hearts)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.crimsonRed.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.crimsonRed.withValues(alpha: 0.35)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(_maxLives, (i) {
                        final isAlive = i < _livesRemaining;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 1.5),
                          child: Icon(
                            isAlive ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            size: 18,
                            color: isAlive ? AppColors.crimsonRed : Colors.grey.shade400,
                          ),
                        );
                      }),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Peek Hint Button (Costs 1 Heart / Life)
                  ElevatedButton.icon(
                    onPressed: _livesRemaining > 0 ? _openHintPeek : null,
                    icon: Icon(
                      Icons.visibility_rounded,
                      size: 14,
                      color: _livesRemaining > 0 ? Colors.white : Colors.grey,
                    ),
                    label: Text(
                      'Peek Hint (❤️ $_livesRemaining left)',
                      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.turmericAmber,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor:
                          isDark ? AppColors.slateLight : Colors.grey.shade300,
                      disabledForegroundColor: Colors.grey,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),

                  const Spacer(),

                  // Matching Grid Indicator
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.slateLight : AppColors.borderLight,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${_gridSize}x$_gridSize',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11.5,
                        color: isDark ? Colors.white : AppColors.textDark,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),

                  // Live Stopwatch Timer
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.turmericAmber.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.turmericAmber.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.schedule_rounded,
                            size: 12, color: AppColors.turmericAmber),
                        const SizedBox(width: 3),
                        Text(
                          '${_elapsedDrawingSeconds.toStringAsFixed(1)}s',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                            color: AppColors.turmericAmber,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.undo_rounded, size: 20),
                    tooltip: 'Undo',
                    onPressed: _canUndo ? _undoAction : null,
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.redo_rounded, size: 20),
                    tooltip: 'Redo',
                    onPressed: _canRedo ? _redoAction : null,
                  ),
                  const Spacer(),
                  Text(
                    'Tap dots to cycle arcs • Drag between dots to link',
                    style: AppTypography.caption.copyWith(
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      color: isDark
                          ? AppColors.textLight.withValues(alpha: 0.7)
                          : AppColors.textMuted,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(),
                    icon: Icon(
                      Icons.delete_sweep_rounded,
                      size: 20,
                      color: _tileStates.isNotEmpty
                          ? Colors.redAccent
                          : (isDark
                              ? Colors.redAccent.withValues(alpha: 0.35)
                              : Colors.red.withValues(alpha: 0.35)),
                    ),
                    tooltip: 'Clear Canvas',
                    onPressed: _tileStates.isNotEmpty ? _clearCanvas : null,
                  ),
                ],
              ),
            ],
          ),
        ),

        // Exact Central Canvas Area (Square NxN Grid)
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Stack(
              alignment: Alignment.center,
              children: [
                KolamCanvasWidget(
                  gridSize: _gridSize,
                  orientation: KolamGridOrientation.square,
                  showDots: true,
                  canvasTheme: CanvasBackgroundTheme.templeSlate,
                  kolamColor: _selectedColor,
                  tileStates: _tileStates,
                  selectedCircleIndex: _selectedCircleIndex,
                  strokes: const [],
                  onPanStart: _onCanvasPanStart,
                  onPanUpdate: _onCanvasPanUpdate,
                  onJoinCircles: _toggleJoinCircles,
                  onCircleTapped: _onCircleTapped,
                ),
              ],
            ),
          ),
        ),

        // Submit Memory Match Action Button
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isDark ? AppColors.slateCard : AppColors.riceFlourCard,
            border: Border(
                top: BorderSide(
                    color: isDark ? AppColors.borderDark : AppColors.borderLight)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '${_tileStates.length} Active Nodes • $_livesRemaining Hearts Left',
                  style: AppTypography.caption
                      .copyWith(fontWeight: FontWeight.w600, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _evaluateSubmission,
                icon: const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                label: const Text('Submit Memory Match',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.turmericGold,
                  foregroundColor: Colors.black87,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==========================================
  // PHASE 4: RESULT SCREEN (Score Breakdown & Replay)
  // ==========================================

  Widget _buildResultScreen(bool isDark) {
    final breakdown = _scoreBreakdown;
    if (breakdown == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final isWin = breakdown.isPassing;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Hero Result Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isWin
                    ? (isDark
                        ? [const Color(0xFF1E3A2B), const Color(0xFF12241A)]
                        : [const Color(0xFFE8F5E9), const Color(0xFFC8E6C9)])
                    : (isDark
                        ? [const Color(0xFF3E1F24), const Color(0xFF261417)]
                        : [const Color(0xFFFFEBEE), const Color(0xFFFFCDD2)]),
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isWin ? AppColors.tulsiGreen : AppColors.crimsonRed,
                width: 1.8,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  isWin ? Icons.emoji_events_rounded : Icons.replay_circle_filled_rounded,
                  size: 54,
                  color: isWin ? AppColors.turmericGold : AppColors.crimsonRed,
                ),
                const SizedBox(height: 10),
                Text(
                  isWin
                      ? 'Sacred 16-Tile Kolam Recreated!'
                      : (breakdown.livesRemaining == 0
                          ? 'Out of Hearts — Keep Practicing!'
                          : 'Pattern Incomplete — Keep Practicing!'),
                  style: AppTypography.screenHeading.copyWith(fontSize: 19),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                // Star Rating
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (index) {
                    final isFilled = index < breakdown.stars;
                    return Icon(
                      Icons.star_rounded,
                      size: 28,
                      color: isFilled ? AppColors.turmericGold : Colors.grey.shade400,
                    );
                  }),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: (isWin ? AppColors.tulsiGreen : AppColors.crimsonRed)
                        .withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'Overall Memory Score: ${breakdown.totalScore}/100',
                    style: AppTypography.cardTitle.copyWith(
                      fontSize: 18,
                      color: isWin ? AppColors.tulsiGreen : AppColors.crimsonRed,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isWin
                      ? '+50 XP Awarded for Visual Memory Mastery!'
                      : '+15 XP Practice Effort Awarded',
                  style: AppTypography.caption.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isWin ? AppColors.turmericAmber : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Detailed Score Breakdown Cards
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.slateCard : AppColors.riceFlourCard,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Score Breakdown',
                    style: AppTypography.cardTitle.copyWith(fontSize: 15)),
                const SizedBox(height: 14),

                // 1. Tile Match Score (70 pts)
                _buildBreakdownRow(
                  title: '16-Tile Pattern Match',
                  scoreText: '${breakdown.tileScore} / 70 pts',
                  detailText:
                      '${breakdown.matchedTiles} of ${breakdown.totalTiles} tiles matched (${breakdown.matchPercentage.toStringAsFixed(0)}%)',
                  progressRatio:
                      (breakdown.tileScore / 70.0).clamp(0.0, 1.0),
                  color: AppColors.turmericAmber,
                ),
                const Divider(height: 22),

                // 2. Time Taken Bonus (10 pts)
                _buildBreakdownRow(
                  title: 'Speed & Recall Bonus',
                  scoreText: '${breakdown.timeBonusScore} / 10 pts',
                  detailText:
                      'Completed in ${breakdown.elapsedSeconds.toStringAsFixed(1)} seconds',
                  progressRatio:
                      (breakdown.timeBonusScore / 10.0).clamp(0.0, 1.0),
                  color: AppColors.tulsiGreen,
                ),
                const Divider(height: 22),

                // 3. Hearts Preserved Bonus (20 pts)
                _buildBreakdownRow(
                  title: 'Hearts Preserved Bonus',
                  scoreText: '+${breakdown.livesBonus} / 20 pts',
                  detailText:
                      '${breakdown.livesRemaining} of ${breakdown.maxLives} Hearts remaining (${breakdown.livesUsed} peek hints spent)${breakdown.livesRemaining == breakdown.maxLives ? " • Flawless Recall!" : ""}',
                  progressRatio:
                      (breakdown.livesBonus / 20.0).clamp(0.0, 1.0),
                  color: AppColors.crimsonRed,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Side-by-side Target 16-Tile Kolam Card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? AppColors.slateCard : AppColors.riceFlourCard,
              borderRadius: BorderRadius.circular(18),
              border:
                  Border.all(color: AppColors.turmericGold.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 80,
                    height: 80,
                    color: isDark
                        ? const Color(0xFF1E1614)
                        : const Color(0xFFFAF2E7),
                    padding: const EdgeInsets.all(4),
                    child: Center(
                      child: KolamNxNPreviewView(
                        tiles: _currentTarget.targetTiles,
                        gridDimension: _gridSize,
                        size: 72,
                        strokeWidth: 1.8,
                        showDots: true,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Target: ${_currentTarget.name}',
                        style: AppTypography.cardTitle.copyWith(fontSize: 14),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_currentTarget.tamilName} • ${_currentTarget.category}',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.turmericAmber,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _currentTarget.culturalLore,
                        style: AppTypography.caption.copyWith(fontSize: 11),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _loadPatternAndStartCountdown(_difficulty),
                  icon: const Icon(Icons.replay_rounded, size: 18),
                  label: const Text('Try Another'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              if (isWin && _difficulty < 4)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _selectDifficultyAndStart(_difficulty + 1),
                    icon: const Icon(Icons.trending_up_rounded, size: 18),
                    label: const Text('Next Level'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.turmericGold,
                      foregroundColor: Colors.black87,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                )
              else
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _saveRecreatedKolam,
                    icon: const Icon(Icons.bookmark_add_rounded, size: 18),
                    label: const Text('Save to Gallery'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.tulsiGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildBreakdownRow({
    required String title,
    required String scoreText,
    required String detailText,
    required double progressRatio,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title,
                style:
                    AppTypography.bodyText.copyWith(fontWeight: FontWeight.bold)),
            Text(scoreText,
                style: AppTypography.caption
                    .copyWith(color: color, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 4),
        Text(detailText, style: AppTypography.caption.copyWith(fontSize: 11.5)),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progressRatio,
            minHeight: 6,
            backgroundColor: Colors.grey.withValues(alpha: 0.2),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}
