import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../data/models/game_result.dart';
import '../../../data/models/kolam_shape_primitive.dart';
import '../../../data/models/sample_kolam_design.dart';
import '../../../data/seed/kolam_image_library.dart';
import '../../../data/seed/kolam_patterns_library.dart';
import '../../../data/seed/sample_designs_library.dart';
import '../../../providers/app_providers.dart';
import '../../../services/analysis_service.dart';
import '../../create/widgets/kolam_canvas_widget.dart';
import '../../create/widgets/shape_palette_widget.dart';

/// Target definition model for the Memory Game
class MemoryGameTarget {
  final String id;
  final String name;
  final String tamilName;
  final String category;
  final int difficultyLevel; // 1: 10s, 2: 7s, 3: 5s, 4: 3s
  final int gridSize;
  final String culturalLore;
  final String assetPath;
  final List<KolamStroke> strokes;

  const MemoryGameTarget({
    required this.id,
    required this.name,
    required this.tamilName,
    required this.category,
    required this.difficultyLevel,
    required this.gridSize,
    required this.culturalLore,
    required this.assetPath,
    required this.strokes,
  });

  factory MemoryGameTarget.fromImageDesign({
    required KolamImageDesign design,
    required int diffLevel,
    required int gridSize,
    required List<KolamStroke> strokes,
  }) {
    return MemoryGameTarget(
      id: design.id,
      name: design.name,
      tamilName: design.tamilName,
      category: design.category,
      difficultyLevel: diffLevel,
      gridSize: gridSize,
      culturalLore: design.culturalLore,
      assetPath: design.assetPath,
      strokes: strokes,
    );
  }

  factory MemoryGameTarget.fromSample(SampleKolamDesign s, int diffLevel, {String? assetPath}) {
    return MemoryGameTarget(
      id: s.id,
      name: s.name,
      tamilName: s.tamilName,
      category: s.category,
      difficultyLevel: diffLevel,
      gridSize: s.gridSize,
      culturalLore: s.culturalLore,
      assetPath: assetPath ?? 'assets/kolam/kolam.jpeg',
      strokes: s.strokes,
    );
  }

  factory MemoryGameTarget.fromPatternDef(KolamPatternDefinition p, int diffLevel, {String? assetPath}) {
    return MemoryGameTarget(
      id: p.id,
      name: p.name,
      tamilName: p.tamilName,
      category: p.category,
      difficultyLevel: diffLevel,
      gridSize: p.gridSize,
      culturalLore: p.culturalLore,
      assetPath: assetPath ?? 'assets/kolam/kolam.jpeg',
      strokes: p.strokes,
    );
  }
}

/// Catalog of curated targets per difficulty level (1..4) using authentic Kolam images
class MemoryGameCatalog {
  static List<MemoryGameTarget> getTargetsForDifficulty(int difficulty) {
    switch (difficulty) {
      case 1:
        // Level 1: 10s Preview, 5x5 Grid beginner patterns
        return [
          MemoryGameTarget.fromImageDesign(
            design: KolamImageLibrary.getById('kolam_img_1'),
            diffLevel: 1,
            gridSize: 5,
            strokes: SampleDesignsLibrary.kodiVineBorder.strokes,
          ),
          MemoryGameTarget.fromImageDesign(
            design: KolamImageLibrary.getById('kolam_img_2'),
            diffLevel: 1,
            gridSize: 5,
            strokes: SampleDesignsLibrary.crossRibbonKolam.strokes,
          ),
          MemoryGameTarget.fromImageDesign(
            design: KolamImageLibrary.getById('kolam_img_33'),
            diffLevel: 1,
            gridSize: 5,
            strokes: SampleDesignsLibrary.cornerLoops.strokes,
          ),
        ];

      case 2:
        // Level 2: 7s Preview, 5x5 & 7x7 moderate loop patterns
        return [
          MemoryGameTarget.fromImageDesign(
            design: KolamImageLibrary.getById('kolam_img_38'),
            diffLevel: 2,
            gridSize: 5,
            strokes: SampleDesignsLibrary.thaamaraiLotusFloral.strokes,
          ),
          MemoryGameTarget.fromImageDesign(
            design: KolamImageLibrary.getById('kolam_img_32'),
            diffLevel: 2,
            gridSize: 5,
            strokes: SampleDesignsLibrary.rathamChariotDiamond.strokes,
          ),
          MemoryGameTarget.fromImageDesign(
            design: KolamImageLibrary.getById('kolam_img_35'),
            diffLevel: 2,
            gridSize: 5,
            strokes: SampleDesignsLibrary.nelliSikkuLoop.strokes,
          ),
        ];

      case 3:
        // Level 3: 5s Preview, 7x7 intricate curves and knots
        return [
          MemoryGameTarget.fromImageDesign(
            design: KolamImageLibrary.getById('kolam_img_main'),
            diffLevel: 3,
            gridSize: 7,
            strokes: SampleDesignsLibrary.chakraSwirlPinwheel.strokes,
          ),
          MemoryGameTarget.fromImageDesign(
            design: KolamImageLibrary.getById('kolam_img_36'),
            diffLevel: 3,
            gridSize: 7,
            strokes: SampleDesignsLibrary.mayilPeacockFeather.strokes,
          ),
        ];

      case 4:
      default:
        // Level 4: 3s Preview, 7x7 & 9x9 master mandalas
        return [
          MemoryGameTarget.fromImageDesign(
            design: KolamImageLibrary.getById('kolam_img_34'),
            diffLevel: 4,
            gridSize: 7,
            strokes: SampleDesignsLibrary.navagrahaPlanets.strokes,
          ),
          MemoryGameTarget.fromImageDesign(
            design: KolamImageLibrary.getById('kolam_img_37'),
            diffLevel: 4,
            gridSize: 9,
            strokes: SampleDesignsLibrary.mahamandalaPadi.strokes,
          ),
        ];
    }
  }
}

/// Evaluation breakdown result
class MemoryScoreBreakdown {
  final int pathSimilarityScore; // 0 - 50
  final double coveragePercent;
  final double precisionPenalty;
  final int connectionPointsScore; // 0 - 30
  final int matchedConnectionDots;
  final int totalTargetDots;
  final int timeBonusScore; // 0 - 20
  final double elapsedSeconds;
  final int totalScore; // 0 - 100
  final bool isPassing; // >= 60

  const MemoryScoreBreakdown({
    required this.pathSimilarityScore,
    required this.coveragePercent,
    required this.precisionPenalty,
    required this.connectionPointsScore,
    required this.matchedConnectionDots,
    required this.totalTargetDots,
    required this.timeBonusScore,
    required this.elapsedSeconds,
    required this.totalScore,
    required this.isPassing,
  });

  int get stars {
    if (totalScore >= 85) return 3;
    if (totalScore >= 70) return 2;
    if (totalScore >= 60) return 1;
    return 0;
  }
}

enum MemoryPhase {
  difficultySelect,
  preview,
  drawing,
  result,
}

enum DrawingToolMode {
  freehand,
  shapes,
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

class _MemoryGameScreenState extends ConsumerState<MemoryGameScreen> with SingleTickerProviderStateMixin {
  late int _difficulty;
  MemoryPhase _phase = MemoryPhase.difficultySelect;
  int _secondsLeft = 10;
  Timer? _countdownTimer;
  final Stopwatch _drawingStopwatch = Stopwatch();
  Timer? _stopwatchTicker;
  double _elapsedDrawingSeconds = 0.0;

  // Active Kolam target
  late MemoryGameTarget _currentPattern;
  final Random _random = Random();

  // Drawing mode & state
  DrawingToolMode _toolMode = DrawingToolMode.freehand;
  final List<KolamStroke> _playerStrokes = [];
  KolamStroke? _activeStroke;
  Color _currentColor = Colors.white;
  double _strokeWidth = 3.5;

  // Placed shapes state (Prompt 5 reuse)
  final List<PlacedKolamShape> _placedShapes = [];
  String? _selectedShapeId;
  Offset? _snapHighlightPoint;

  // Evaluation breakdown
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

    // If initial difficulty is specified or this is a daily challenge, start immediately
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

  void _selectDifficultyAndStart(int diff) {
    setState(() {
      _difficulty = diff;
    });
    _loadPatternAndStartCountdown(diff);
  }

  void _loadPatternAndStartCountdown(int diff) {
    final pool = MemoryGameCatalog.getTargetsForDifficulty(diff);
    final selected = pool[_random.nextInt(pool.length)];

    setState(() {
      _difficulty = diff;
      _currentPattern = selected;
      _playerStrokes.clear();
      _activeStroke = null;
      _placedShapes.clear();
      _selectedShapeId = null;
      _snapHighlightPoint = null;
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

  // --- FREEHAND GESTURES ---

  void _onPanStart(Offset pt) {
    if (_phase != MemoryPhase.drawing || _toolMode != DrawingToolMode.freehand) return;
    setState(() {
      _activeStroke = KolamStroke(
        points: [KolamPoint(pt.dx, pt.dy)],
        colorValue: _currentColor.toARGB32(),
        strokeWidth: _strokeWidth,
      );
    });
  }

  void _onPanUpdate(Offset pt) {
    if (_phase != MemoryPhase.drawing || _toolMode != DrawingToolMode.freehand || _activeStroke == null) return;
    setState(() {
      final pts = List<KolamPoint>.from(_activeStroke!.points)..add(KolamPoint(pt.dx, pt.dy));
      _activeStroke = KolamStroke(
        points: pts,
        colorValue: _currentColor.toARGB32(),
        strokeWidth: _strokeWidth,
      );
    });
  }

  void _onPanEnd() {
    if (_phase != MemoryPhase.drawing || _toolMode != DrawingToolMode.freehand || _activeStroke == null) return;
    setState(() {
      _playerStrokes.add(_activeStroke!);
      _activeStroke = null;
    });
  }

  // --- SHAPES MODE HANDLERS (Prompt 5 reuse) ---

  void _onShapeSelectedFromPalette(KolamShapePrimitive primitive) {
    if (_phase != MemoryPhase.drawing) return;
    const center = Offset(175.0, 175.0);
    final stepOffset = _placedShapes.isEmpty
        ? Offset.zero
        : Offset(
            ((_placedShapes.length % 3) - 1) * 30.0,
            ((_placedShapes.length % 3) - 1) * 30.0,
          );
    _onShapeDropped(primitive, center + stepOffset);
  }

  void _onShapeDropped(KolamShapePrimitive primitive, Offset dropOffset) {
    if (_phase != MemoryPhase.drawing) return;
    final id = const Uuid().v4();
    final defaultSize = (350.0 / (_currentPattern.gridSize + 1) * 1.5).clamp(45.0, 85.0);

    // Snap to nearest dot
    final snappedPos = _snapToNearestDot(dropOffset, 350.0, _currentPattern.gridSize);

    final shape = PlacedKolamShape(
      id: id,
      primitiveId: primitive.id,
      position: snappedPos,
      size: defaultSize,
      colorValue: _currentColor.toARGB32(),
      strokeWidth: _strokeWidth,
    );

    setState(() {
      _placedShapes.add(shape);
      _selectedShapeId = id;
      _snapHighlightPoint = snappedPos;
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) setState(() => _snapHighlightPoint = null);
      });
    });
  }

  Offset _snapToNearestDot(Offset pos, double canvasDim, int gridSize) {
    final step = canvasDim / (gridSize + 1);
    double minD = double.infinity;
    Offset best = pos;
    for (int r = 1; r <= gridSize; r++) {
      for (int c = 1; c <= gridSize; c++) {
        final dot = Offset(c * step, r * step);
        final d = (dot - pos).distance;
        if (d < minD) {
          minD = d;
          best = dot;
        }
      }
    }
    return minD <= step * 0.75 ? best : pos;
  }

  void _onShapeSelected(String shapeId) {
    setState(() {
      _selectedShapeId = shapeId;
    });
  }

  void _onShapeRotated(String shapeId) {
    final idx = _placedShapes.indexWhere((s) => s.id == shapeId);
    if (idx == -1) return;
    setState(() {
      final s = _placedShapes[idx];
      _placedShapes[idx] = s.copyWith(rotationDegrees: (s.rotationDegrees + 45) % 360);
    });
  }

  void _onShapeDeleted(String shapeId) {
    setState(() {
      _placedShapes.removeWhere((s) => s.id == shapeId);
      if (_selectedShapeId == shapeId) _selectedShapeId = null;
    });
  }

  void _undoLastAction() {
    setState(() {
      if (_toolMode == DrawingToolMode.shapes && _placedShapes.isNotEmpty) {
        if (_selectedShapeId != null) {
          _placedShapes.removeWhere((s) => s.id == _selectedShapeId);
          _selectedShapeId = null;
        } else {
          _placedShapes.removeLast();
        }
      } else if (_playerStrokes.isNotEmpty) {
        _playerStrokes.removeLast();
      } else if (_placedShapes.isNotEmpty) {
        _placedShapes.removeLast();
      }
    });
  }

  void _clearCanvas() {
    setState(() {
      _playerStrokes.clear();
      _activeStroke = null;
      _placedShapes.clear();
      _selectedShapeId = null;
      _snapHighlightPoint = null;
    });
  }

  // --- SCORING ENGINE ---

  Future<void> _evaluateSubmission() async {
    _drawingStopwatch.stop();
    _stopwatchTicker?.cancel();
    final elapsedSec = _drawingStopwatch.elapsedMilliseconds / 1000.0;

    // Convert placed shapes into KolamStrokes
    final shapeStrokes = _placedShapes.map((s) => s.toStroke()).toList();
    final allUserStrokes = [..._playerStrokes, ...shapeStrokes];

    if (allUserStrokes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please draw lines or place shapes before submitting!'),
          backgroundColor: AppColors.terracottaRed,
        ),
      );
      _drawingStopwatch.start();
      return;
    }

    // 1. Resample target strokes at 8px steps
    final targetPoints = <Offset>[];
    for (final stroke in _currentPattern.strokes) {
      if (stroke.points.isEmpty) continue;
      for (int i = 0; i < stroke.points.length - 1; i++) {
        final p1 = Offset(stroke.points[i].x, stroke.points[i].y);
        final p2 = Offset(stroke.points[i + 1].x, stroke.points[i + 1].y);
        final dist = (p2 - p1).distance;
        final steps = max(1, (dist / 8.0).ceil());
        for (int s = 0; s < steps; s++) {
          final t = s / steps;
          targetPoints.add(Offset.lerp(p1, p2, t)!);
        }
      }
      targetPoints.add(Offset(stroke.points.last.x, stroke.points.last.y));
    }

    // 2. Resample user strokes at 8px steps
    final userPoints = <Offset>[];
    for (final stroke in allUserStrokes) {
      if (stroke.points.isEmpty) continue;
      for (int i = 0; i < stroke.points.length - 1; i++) {
        final p1 = Offset(stroke.points[i].x, stroke.points[i].y);
        final p2 = Offset(stroke.points[i + 1].x, stroke.points[i + 1].y);
        final dist = (p2 - p1).distance;
        final steps = max(1, (dist / 8.0).ceil());
        for (int s = 0; s < steps; s++) {
          final t = s / steps;
          userPoints.add(Offset.lerp(p1, p2, t)!);
        }
      }
      userPoints.add(Offset(stroke.points.last.x, stroke.points.last.y));
    }

    // CRITERION 1: Path Similarity (0 to 50 pts)
    const double matchThreshold = 26.0;
    int matchedTargetCount = 0;
    for (final tp in targetPoints) {
      for (final up in userPoints) {
        if ((tp - up).distance <= matchThreshold) {
          matchedTargetCount++;
          break;
        }
      }
    }
    final double coverageRatio = targetPoints.isNotEmpty ? (matchedTargetCount / targetPoints.length) : 0.0;

    // Precision penalty for stray points (> 45px from all target points)
    int strayUserPoints = 0;
    for (final up in userPoints) {
      bool nearTarget = false;
      for (final tp in targetPoints) {
        if ((up - tp).distance <= 45.0) {
          nearTarget = true;
          break;
        }
      }
      if (!nearTarget) strayUserPoints++;
    }
    final double strayRatio = userPoints.isNotEmpty ? (strayUserPoints / userPoints.length) : 0.0;
    final double precisionPenalty = strayRatio * 15.0; // max 15 pts penalty for wild scribbling
    final double rawPathScore = (coverageRatio * 50.0) - precisionPenalty;
    final int pathScore = rawPathScore.clamp(0.0, 50.0).round();

    // CRITERION 2: Sacred Connection Points (0 to 30 pts)
    final step = 350.0 / (_currentPattern.gridSize + 1);
    final targetActiveDots = <Offset>[];
    for (int r = 1; r <= _currentPattern.gridSize; r++) {
      for (int c = 1; c <= _currentPattern.gridSize; c++) {
        final dot = Offset(c * step, r * step);
        bool touchesDot = false;
        for (final tp in targetPoints) {
          if ((tp - dot).distance <= 24.0) {
            touchesDot = true;
            break;
          }
        }
        if (touchesDot) targetActiveDots.add(dot);
      }
    }

    int matchedDotsCount = 0;
    for (final dot in targetActiveDots) {
      for (final up in userPoints) {
        if ((up - dot).distance <= 26.0) {
          matchedDotsCount++;
          break;
        }
      }
    }
    final double connectionRatio = targetActiveDots.isNotEmpty ? (matchedDotsCount / targetActiveDots.length) : 1.0;
    final int connectionScore = (connectionRatio * 30.0).round().clamp(0, 30);

    // CRITERION 3: Time Taken / Speed Bonus (0 to 20 pts)
    // Faster accurate recreation gains higher bonus
    final double expectedSec = 20.0 + (_currentPattern.gridSize * 3.0);
    double rawTimeScore;
    if (elapsedSec <= 15.0) {
      rawTimeScore = 20.0;
    } else if (elapsedSec <= expectedSec) {
      final t = (elapsedSec - 15.0) / (expectedSec - 15.0);
      rawTimeScore = 20.0 - (t * 8.0); // 20 down to 12
    } else {
      final extra = (elapsedSec - expectedSec) / 10.0;
      rawTimeScore = max(6.0, 12.0 - extra); // minimum 6 pts
    }
    final int timeScore = rawTimeScore.round().clamp(0, 20);

    final int finalTotalScore = (pathScore + connectionScore + timeScore).clamp(0, 100);
    final bool isPassing = finalTotalScore >= 60; // 60%+ passing threshold

    final breakdown = MemoryScoreBreakdown(
      pathSimilarityScore: pathScore,
      coveragePercent: coverageRatio * 100.0,
      precisionPenalty: precisionPenalty,
      connectionPointsScore: connectionScore,
      matchedConnectionDots: matchedDotsCount,
      totalTargetDots: targetActiveDots.length,
      timeBonusScore: timeScore,
      elapsedSeconds: elapsedSec,
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
      culturalNote: 'Memorized ${_currentPattern.name} (${_currentPattern.category}).',
      won: isPassing,
    );
    await storage.recordGameResult(result);
  }

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
                        'Sacred Visual Recall',
                        style: AppTypography.cardTitle.copyWith(fontSize: 18),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Select your difficulty tier. Memorize the sacred pulli loops, then recreate the geometry from pure mental memory.',
                        style: AppTypography.caption.copyWith(
                          fontSize: 12.5,
                          color: isDark ? AppColors.textLight.withValues(alpha: 0.8) : AppColors.textMuted,
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
            gridDesc: '5x5 Grid',
            description: 'Creeping vine borders & cardinal crosses with strong bilateral symmetry.',
            examples: 'Eulerian Sikku Vine, Square Padi Cross, Kambi Knot',
            color: AppColors.tulsiGreen,
            isDark: isDark,
          ),
          const SizedBox(height: 12),

          _buildDifficultyCard(
            level: 2,
            title: 'Level 2: Skilled',
            timeSeconds: 7,
            gridDesc: '5x5 Grid',
            description: 'Continuous Eulerian knots and sacred lotus petals wrapping around pulli dots.',
            examples: 'Thaamarai Floral, Ashtalakshmi Mandala, Brahma Mudi',
            color: AppColors.turmericAmber,
            isDark: isDark,
          ),
          const SizedBox(height: 12),

          _buildDifficultyCard(
            level: 3,
            title: 'Level 3: Adept',
            timeSeconds: 5,
            gridDesc: '7x7 Grid',
            description: 'Braided knots & radiating peacock feather curves with 4-fold rotational symmetry.',
            examples: 'Sudarshana Wheel, Mayil Peacock Feather',
            color: AppColors.terracottaRed,
            isDark: isDark,
          ),
          const SizedBox(height: 12),

          _buildDifficultyCard(
            level: 4,
            title: 'Level 4: Master',
            timeSeconds: 3,
            gridDesc: '7x7 & 9x9 Grid',
            description: 'Grand sacred temple Padi mandalas & 9-planet celestial yantras.',
            examples: 'Navagraha Celestial Yantra, Temple Sanctum Step',
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
                    style: AppTypography.tagText.copyWith(color: color, fontWeight: FontWeight.bold),
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    const Icon(Icons.timer_rounded, size: 16, color: AppColors.turmericAmber),
                    const SizedBox(width: 4),
                    Text(
                      '${timeSeconds}s Preview',
                      style: AppTypography.tagText.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.turmericAmber,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
                Icon(Icons.palette_outlined, size: 13, color: color.withValues(alpha: 0.8)),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Patterns: $examples',
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
                      Text('Start', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
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
        // Pattern Cultural Info Header
        _buildPatternHeader(isDark),

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
                'Memorize the sacred pattern: ',
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

        // Authentic Provided Kolam Image Glimpse Area
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
                    // Authentic Provided Kolam Image
                    Image.asset(
                      _currentPattern.assetPath,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                      errorBuilder: (context, error, stackTrace) => Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.image_not_supported_rounded, size: 48, color: AppColors.textMuted),
                            const SizedBox(height: 8),
                            Text('Authentic Kolam: ${_currentPattern.assetPath}', style: AppTypography.caption),
                          ],
                        ),
                      ),
                    ),

                    // Top "Authentic Kolam Glimpse" badge
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
                            const Icon(Icons.visibility_rounded, size: 15, color: AppColors.turmericAmber),
                            const SizedBox(width: 6),
                            Text(
                              'Authentic Kolam Glimpse',
                              style: AppTypography.tagText.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 11.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Bottom info ribbon
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
                            const Icon(Icons.lightbulb_outline_rounded, size: 16, color: AppColors.turmericAmber),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Study loops, petal curves, and pulli alignments',
                                style: AppTypography.caption.copyWith(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontSize: 11.5,
                                  fontStyle: FontStyle.italic,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.terracottaRed,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${_currentPattern.gridSize}x${_currentPattern.gridSize} Grid',
                                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
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
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: OutlinedButton.icon(
            onPressed: _transitionToDrawingPhase,
            icon: const Icon(Icons.flash_on_rounded, color: AppColors.turmericAmber, size: 18),
            label: const Text('Memorized! Start Drawing Now'),
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
  // PHASE 3: DRAWING SCREEN (Blank Canvas + Tools)
  // ==========================================

  Widget _buildDrawingScreen(bool isDark) {
    return Column(
      children: [
        // Pattern Header & Stopwatch
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.slateCard : const Color(0xFFFAF3EA),
            border: Border(
              bottom: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recreating: ${_currentPattern.name}',
                    style: AppTypography.cardTitle.copyWith(fontSize: 13.5),
                  ),
                  Text(
                    'Connect the pulli dots from mental recall',
                    style: AppTypography.caption.copyWith(fontSize: 11, color: AppColors.turmericAmber),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.turmericAmber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.turmericAmber.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.schedule_rounded, size: 14, color: AppColors.turmericAmber),
                    const SizedBox(width: 4),
                    Text(
                      '${_elapsedDrawingSeconds.toStringAsFixed(1)}s',
                      style: AppTypography.tagText.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.turmericAmber,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Tool Mode Switcher Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: isDark ? AppColors.slateLight : Colors.grey.shade100,
            border: Border(
              bottom: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight),
            ),
          ),
          child: Row(
            children: [
              // Freehand vs Shapes Segmented Control
              Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.slateCard : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                ),
                child: Row(
                  children: [
                    _buildToolModeSegment(
                      mode: DrawingToolMode.freehand,
                      icon: Icons.brush_rounded,
                      label: 'Freehand',
                      isDark: isDark,
                    ),
                    _buildToolModeSegment(
                      mode: DrawingToolMode.shapes,
                      icon: Icons.auto_awesome_mosaic_rounded,
                      label: 'Shapes',
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // Undo Action
              IconButton(
                icon: const Icon(Icons.undo_rounded, size: 20),
                tooltip: 'Undo Last',
                onPressed: (_playerStrokes.isNotEmpty || _placedShapes.isNotEmpty) ? _undoLastAction : null,
              ),
              // Clear Action
              IconButton(
                icon: const Icon(Icons.clear_all_rounded, size: 20),
                tooltip: 'Clear All',
                onPressed: (_playerStrokes.isNotEmpty || _placedShapes.isNotEmpty) ? _clearCanvas : null,
              ),
            ],
          ),
        ),

        // Canvas Area (Blank Dot Grid for Recreation)
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: FittedBox(
              fit: BoxFit.contain,
              child: SizedBox(
                width: 350,
                height: 350,
                child: KolamCanvasWidget(
                  gridSize: _currentPattern.gridSize,
                  showDots: true,
                  strokes: _playerStrokes,
                  activeStroke: _activeStroke,
                  isShapesMode: _toolMode == DrawingToolMode.shapes,
                  placedShapes: _placedShapes,
                  selectedShapeId: _selectedShapeId,
                  snapHighlightPoint: _snapHighlightPoint,
                  onPanStart: _onPanStart,
                  onPanUpdate: _onPanUpdate,
                  onPanEnd: _onPanEnd,
                  onShapeDropped: _onShapeDropped,
                  onShapeSelected: _onShapeSelected,
                  onShapeRotated: _onShapeRotated,
                  onShapeDeleted: _onShapeDeleted,
                ),
              ),
            ),
          ),
        ),

        // Tool Palette (Shapes Mode Palette or Freehand Controls)
        if (_toolMode == DrawingToolMode.shapes)
          ShapePaletteWidget(
            onShapeSelected: _onShapeSelectedFromPalette,
            isDark: isDark,
          )
        else
          _buildFreehandControlBar(isDark),

        // Submit Memory Match Action
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isDark ? AppColors.slateCard : AppColors.riceFlourCard,
            border: Border(top: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight)),
          ),
          child: Row(
            children: [
              Text(
                '${_playerStrokes.length} lines  •  ${_placedShapes.length} shapes',
                style: AppTypography.caption.copyWith(fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _evaluateSubmission,
                icon: const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                label: const Text('Submit Memory Match', style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.turmericGold,
                  foregroundColor: Colors.black87,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildToolModeSegment({
    required DrawingToolMode mode,
    required IconData icon,
    required String label,
    required bool isDark,
  }) {
    final isSelected = _toolMode == mode;
    return InkWell(
      onTap: () {
        setState(() {
          _toolMode = mode;
          _selectedShapeId = null;
        });
      },
      borderRadius: BorderRadius.circular(9),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.turmericGold : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected ? Colors.black87 : (isDark ? Colors.white70 : Colors.black54),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.black87 : (isDark ? Colors.white70 : Colors.black54),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFreehandControlBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: isDark ? AppColors.slateCard : AppColors.riceFlourCard,
      child: Row(
        children: [
          Text('Chalk Style:', style: AppTypography.caption.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(width: 10),
          _buildColorDot(Colors.white, 'Rice Flour'),
          _buildColorDot(AppColors.turmericGold, 'Turmeric'),
          _buildColorDot(AppColors.kaaviBrick, 'Kaavi'),
          const Spacer(),
          Text('Width:', style: AppTypography.caption),
          const SizedBox(width: 4),
          _buildStrokeWidthChip(2.5, 'Fine'),
          _buildStrokeWidthChip(3.5, 'Medium'),
          _buildStrokeWidthChip(5.5, 'Thick'),
        ],
      ),
    );
  }

  Widget _buildColorDot(Color color, String label) {
    final isSelected = _currentColor == color;
    return InkWell(
      onTap: () => setState(() => _currentColor = color),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? AppColors.turmericGold : Colors.black26,
            width: isSelected ? 2.5 : 1.0,
          ),
        ),
      ),
    );
  }

  Widget _buildStrokeWidthChip(double width, String label) {
    final isSelected = _strokeWidth == width;
    return InkWell(
      onTap: () => setState(() => _strokeWidth = width),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.terracottaRed : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? AppColors.terracottaRed : Colors.grey.shade400,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : null,
          ),
        ),
      ),
    );
  }

  // ==========================================
  // PHASE 4: RESULT SCREEN (Score Breakdown)
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
                  isWin ? 'Authentic Pattern Recreated!' : 'Pattern Incomplete — Keep Practicing!',
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
                    color: (isWin ? AppColors.tulsiGreen : AppColors.crimsonRed).withValues(alpha: 0.15),
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
                  isWin ? '+50 XP Awarded for Visual Memory Win!' : '+15 XP Practice Effort Awarded',
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
              border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Score Breakdown', style: AppTypography.cardTitle.copyWith(fontSize: 15)),
                const SizedBox(height: 14),

                // 1. Path Similarity (50 pts)
                _buildBreakdownRow(
                  title: 'Stroke / Path Similarity',
                  scoreText: '${breakdown.pathSimilarityScore} / 50 pts',
                  detailText: 'Coverage: ${breakdown.coveragePercent.toStringAsFixed(1)}%'
                      '${breakdown.precisionPenalty > 0 ? " (Stray penalty: -${breakdown.precisionPenalty.toStringAsFixed(1)})" : ""}',
                  progressRatio: (breakdown.pathSimilarityScore / 50.0).clamp(0.0, 1.0),
                  color: AppColors.turmericAmber,
                ),
                const Divider(height: 22),

                // 2. Connection Points (30 pts)
                _buildBreakdownRow(
                  title: 'Sacred Pulli Dots Connected',
                  scoreText: '${breakdown.connectionPointsScore} / 30 pts',
                  detailText: '${breakdown.matchedConnectionDots} of ${breakdown.totalTargetDots} key anchor dots connected',
                  progressRatio: (breakdown.connectionPointsScore / 30.0).clamp(0.0, 1.0),
                  color: AppColors.tulsiGreen,
                ),
                const Divider(height: 22),

                // 3. Time Taken Bonus (20 pts)
                _buildBreakdownRow(
                  title: 'Speed & Recall Bonus',
                  scoreText: '${breakdown.timeBonusScore} / 20 pts',
                  detailText: 'Completed in ${breakdown.elapsedSeconds.toStringAsFixed(1)} seconds',
                  progressRatio: (breakdown.timeBonusScore / 20.0).clamp(0.0, 1.0),
                  color: AppColors.terracottaRed,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Original Authentic Kolam Glimpse Card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? AppColors.slateCard : AppColors.riceFlourCard,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.turmericGold.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 80,
                    height: 80,
                    color: isDark ? Colors.black38 : const Color(0xFFF5ECE0),
                    child: Image.asset(
                      _currentPattern.assetPath,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.medium,
                      errorBuilder: (_, _, _) => const Icon(Icons.image, color: AppColors.textMuted),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.verified_rounded, size: 16, color: AppColors.turmericAmber),
                          const SizedBox(width: 5),
                          Text(
                            'Original Glimpsed Kolam',
                            style: AppTypography.cardTitle.copyWith(fontSize: 13),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${_currentPattern.name} • ${_currentPattern.tamilName}',
                        style: AppTypography.caption.copyWith(
                          fontSize: 11,
                          color: AppColors.turmericAmber,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Compare your memory recreation with the authentic pattern you observed.',
                        style: AppTypography.caption.copyWith(
                          fontSize: 11,
                          color: isDark ? AppColors.textLight.withValues(alpha: 0.75) : AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Cultural Lore Box
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? AppColors.slateLight : const Color(0xFFFAF3EA),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.auto_stories_rounded, size: 20, color: AppColors.turmericAmber),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'About ${_currentPattern.name} (${_currentPattern.tamilName})',
                        style: AppTypography.cardTitle.copyWith(fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _currentPattern.culturalLore,
                        style: AppTypography.caption.copyWith(
                          fontSize: 12,
                          color: isDark ? AppColors.textLight.withValues(alpha: 0.8) : AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _playerStrokes.clear();
                      _activeStroke = null;
                      _placedShapes.clear();
                      _selectedShapeId = null;
                    });
                    _startCountdownTimer();
                    setState(() {
                      _phase = MemoryPhase.preview;
                      _secondsLeft = _getCountdownSeconds(_difficulty);
                    });
                  },
                  icon: const Icon(Icons.refresh_rounded, size: 17),
                  label: const Text('Retry Same'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _loadPatternAndStartCountdown(_difficulty),
                  icon: const Icon(Icons.shuffle_rounded, color: Colors.white, size: 17),
                  label: const Text('Next Kolam', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.terracottaRed,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: () {
              setState(() {
                _phase = MemoryPhase.difficultySelect;
              });
            },
            icon: const Icon(Icons.tune_rounded, size: 16),
            label: const Text('Change Difficulty Level'),
          ),
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
            Text(title, style: AppTypography.cardTitle.copyWith(fontSize: 13)),
            Text(
              scoreText,
              style: AppTypography.cardTitle.copyWith(fontSize: 13, color: color),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(detailText, style: AppTypography.caption.copyWith(fontSize: 11)),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: progressRatio,
            backgroundColor: color.withValues(alpha: 0.15),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  // Cultural Header
  Widget _buildPatternHeader(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.slateCard : const Color(0xFFFAF3EA),
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _currentPattern.name,
                  style: AppTypography.cardTitle.copyWith(fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${_currentPattern.tamilName} • ${_currentPattern.category}',
                  style: AppTypography.caption.copyWith(
                    fontSize: 11,
                    color: AppColors.turmericAmber,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.terracottaRed.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '${_currentPattern.gridSize}x${_currentPattern.gridSize} Grid',
              style: AppTypography.tagText.copyWith(color: AppColors.terracottaRed, fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }
}
