import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../data/models/algorithmic_kolam_pattern.dart';
import '../../../data/models/game_result.dart';
import '../../../data/models/kolam_16_tile.dart';
import '../../../providers/app_providers.dart';
import '../widgets/kolam_16_tile_view.dart';

class PatternConstructionScreen extends ConsumerStatefulWidget {
  final bool isDailyChallenge;
  final VoidCallback? onChallengeCompleted;

  const PatternConstructionScreen({
    super.key,
    this.isDailyChallenge = false,
    this.onChallengeCompleted,
  });

  @override
  ConsumerState<PatternConstructionScreen> createState() =>
      _PatternConstructionScreenState();
}

class _PatternConstructionScreenState
    extends ConsumerState<PatternConstructionScreen> {
  static const int totalMatchRounds = 5;

  int _currentRound = 1; // 1 to 5
  int _totalMatchScore = 0;
  int _roundSeconds = 0;
  Timer? _roundTimer;
  bool _ghostHintUsedInRound = false;
  bool _isMatchComplete = false;

  late KolamTargetPattern _currentTarget;

  // Board slots (indices 0 to N^2 - 1)
  late List<Kolam16Tile?> _boardSlots;

  // Selected tile in tray for tap-to-place
  Kolam16Tile? _selectedTrayTile;

  // Ghost hint overlay toggle
  bool _showGhostHint = false;

  bool _hasValidated = false;
  bool _isRoundWon = false;

  final ScrollController _trayScrollController = ScrollController();

  // Round progression configuration
  int get _gridDimensionForRound {
    switch (_currentRound) {
      case 1:
      case 2:
        return 4; // 4x4 (16 cells)
      case 3:
      case 4:
        return 6; // 6x6 (36 cells)
      case 5:
      default:
        return 8; // 8x8 (64 cells) - Grand Finale
    }
  }

  String get _roundDifficultyTitle {
    switch (_currentRound) {
      case 1:
        return 'Novice Artisan';
      case 2:
        return 'Skilled Builder';
      case 3:
        return 'Temple Architect';
      case 4:
        return 'Sacred Master';
      case 5:
      default:
        return 'Grand Dihedral Master';
    }
  }

  int get _roundBaseScore {
    switch (_currentRound) {
      case 1:
        return 200;
      case 2:
        return 250;
      case 3:
        return 400;
      case 4:
        return 500;
      case 5:
      default:
        return 750;
    }
  }

  @override
  void initState() {
    super.initState();
    _startRound(_currentRound);
  }

  @override
  void dispose() {
    _roundTimer?.cancel();
    _trayScrollController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _roundTimer?.cancel();
    _roundSeconds = 0;
    _roundTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && !_isRoundWon && !_isMatchComplete) {
        setState(() => _roundSeconds++);
      }
    });
  }

  void _startRound(int roundNumber) {
    _currentRound = roundNumber;
    final dim = _gridDimensionForRound;
    _currentTarget = Kolam16TileLibrary.generateRandomTargetPattern(
      gridDimension: dim,
      forcedSymmetry: AlgorithmicSymmetry.d4Multiple,
    );
    _boardSlots = List<Kolam16Tile?>.filled(dim * dim, null);
    _selectedTrayTile = null;
    _showGhostHint = false;
    _ghostHintUsedInRound = false;
    _hasValidated = false;
    _isRoundWon = false;
    _startTimer();
  }

  void _resetBoardForCurrentRound() {
    setState(() {
      final dim = _currentTarget.gridDimension;
      _boardSlots = List<Kolam16Tile?>.filled(dim * dim, null);
      _selectedTrayTile = null;
      _showGhostHint = false;
      _hasValidated = false;
      _isRoundWon = false;
    });
  }

  void _advanceToNextRound() {
    if (_currentRound < totalMatchRounds) {
      setState(() {
        _startRound(_currentRound + 1);
      });
    } else {
      _finishMatch();
    }
  }

  void _restartFullMatch() {
    setState(() {
      _totalMatchScore = 0;
      _isMatchComplete = false;
      _startRound(1);
    });
  }

  void _placeTile(int slotIndex, Kolam16Tile tile) {
    setState(() {
      _boardSlots[slotIndex] = tile;
      _hasValidated = false;
    });
    _checkAutoVictory();
  }

  void _clearSlot(int slotIndex) {
    setState(() {
      _boardSlots[slotIndex] = null;
      _hasValidated = false;
    });
  }

  void _clearAllSlots() {
    _resetBoardForCurrentRound();
  }

  void _onSlotTapped(int slotIndex) {
    if (_selectedTrayTile != null) {
      _placeTile(slotIndex, _selectedTrayTile!);
    } else if (_boardSlots[slotIndex] != null) {
      _clearSlot(slotIndex);
    }
  }

  void _onTrayTileTapped(Kolam16Tile tile) {
    setState(() {
      if (_selectedTrayTile == tile) {
        _selectedTrayTile = null;
      } else {
        _selectedTrayTile = tile;
      }
    });
  }

  int get _placedCount => _boardSlots.where((t) => t != null).length;
  int get _totalCellCount => _currentTarget.totalCells;

  int get _matchingCount {
    int matches = 0;
    for (int i = 0; i < _totalCellCount; i++) {
      if (_boardSlots[i] == _currentTarget.targetTiles[i]) {
        matches++;
      }
    }
    return matches;
  }

  void _validatePattern() {
    final matches = _matchingCount;
    final isWon = matches == _totalCellCount;

    setState(() {
      _hasValidated = true;
      _isRoundWon = isWon;
    });

    if (isWon) {
      _handleRoundVictory();
    }
  }

  void _checkAutoVictory() {
    if (_placedCount == _totalCellCount && _matchingCount == _totalCellCount) {
      setState(() {
        _hasValidated = true;
        _isRoundWon = true;
      });
      _handleRoundVictory();
    }
  }

  void _handleRoundVictory() {
    _roundTimer?.cancel();

    // Calculate score
    final base = _roundBaseScore;
    final speedBonus = (_totalCellCount * 4 - _roundSeconds).clamp(0, 150);
    final hintBonus = _ghostHintUsedInRound ? 0 : 50;
    final roundEarned = base + speedBonus + hintBonus;

    _totalMatchScore += roundEarned;

    if (_currentRound == totalMatchRounds) {
      _finishMatch();
    }
  }

  Future<void> _finishMatch() async {
    setState(() {
      _isMatchComplete = true;
    });

    // Award XP
    await ref.read(userProfileProvider.notifier).onPatternConstructionWon();
    await ref.read(userProfileProvider.notifier).onPuzzleCompleted();
    if (widget.isDailyChallenge) {
      await ref.read(userProfileProvider.notifier).onDailyChallengeCompleted();
      widget.onChallengeCompleted?.call();
    }

    final storage = ref.read(storageServiceProvider);
    final gameResult = GameResult(
      id: const Uuid().v4(),
      gameType: GameType.patternConstruction,
      score: _totalMatchScore,
      xpEarned: 200,
      timestamp: DateTime.now(),
      difficultyLevel: 3,
      culturalNote:
          'Completed 5-Round Progressive Kolam Construction up to 8x8 D4 Mandala with score $_totalMatchScore.',
      won: true,
    );
    await storage.recordGameResult(gameResult);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isDailyChallenge
            ? 'Daily Challenge: Construction'
            : 'Kolam Pattern Construction'),
        actions: [
          IconButton(
            icon: Icon(
              _showGhostHint
                  ? Icons.visibility_rounded
                  : Icons.visibility_off_rounded,
              color: _showGhostHint ? AppColors.turmericGold : null,
            ),
            tooltip: 'Toggle Ghost Hint Outline',
            onPressed: () {
              setState(() {
                _showGhostHint = !_showGhostHint;
                if (_showGhostHint) _ghostHintUsedInRound = true;
              });
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Match Header Banner (Round X/5, Timer, Score, and Target NxN Preview)
              _buildTopTargetBanner(isDark),
              const SizedBox(height: 20),

              // Main NxN Construction Board (16/36/64 Cells)
              Center(
                child: _buildNxNBoard(isDark),
              ),
              const SizedBox(height: 16),

              // 16-Tile Palette Card directly below the board
              _build16TilesCard(isDark),
              const SizedBox(height: 14),

              // Quick Action Control Bar (Clear, Validate)
              _buildQuickActionControls(isDark),
              const SizedBox(height: 12),

              // Validation Card / Round & Match Celebration
              if (_hasValidated || _isRoundWon || _isMatchComplete)
                _buildValidationStatusCard(isDark),
            ],
          ),
        ),
      ),
    );
  }

  /// Top Banner displaying Round Progression, Time, Score & Target Preview
  Widget _buildTopTargetBanner(bool isDark) {
    final N = _currentTarget.gridDimension;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.slateCard : AppColors.riceFlourCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.turmericGold.withValues(alpha: 0.35),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left: Round, Level Tier, Timer & Placed Counter
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.turmericGold.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Round $_currentRound / $totalMatchRounds (${N}x$N)',
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: AppColors.turmericAmber,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white12 : Colors.black12,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.timer_outlined,
                              size: 11, color: AppColors.kaaviBrick),
                          const SizedBox(width: 3),
                          Text(
                            '${_roundSeconds}s',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  _roundDifficultyTitle,
                  style: AppTypography.cardTitle.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      'Score: $_totalMatchScore pts',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.tulsiGreen : AppColors.terracottaRed,
                      ),
                    ),
                    const Text(' • '),
                    Text(
                      '$_placedCount / $_totalCellCount Placed',
                      style: AppTypography.caption.copyWith(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // Top Right Corner: Target Pattern NxN Miniature Preview
          Container(
            width: 76,
            height: 76,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF221A1D) : AppColors.riceFlourBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.terracottaRed.withValues(alpha: 0.8),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: KolamNxNPreviewView(
              tiles: _currentTarget.targetTiles,
              gridDimension: N,
              size: 70,
              strokeWidth: N == 4 ? 1.8 : (N == 6 ? 1.3 : 1.0),
              showDots: true,
            ),
          ),
        ],
      ),
    );
  }

  /// Main NxN Grid Board (16/36/64 Cells) with DragTarget and Tap-to-Place
  Widget _buildNxNBoard(bool isDark) {
    const double boardDim = 288.0;
    final int N = _currentTarget.gridDimension;
    final double cellSize = boardDim / N;
    final double strokeW = N == 4 ? 2.6 : (N == 6 ? 2.0 : 1.5);

    return Container(
      width: boardDim,
      height: boardDim,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF221A1D) : AppColors.riceFlourBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (_hasValidated && _isRoundWon)
              ? AppColors.tulsiGreen
              : AppColors.kaaviBrick,
          width: (_hasValidated && _isRoundWon) ? 3.0 : 2.0,
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
          // Ghost hint overlay (if enabled)
          if (_showGhostHint)
            Positioned.fill(
              child: Opacity(
                opacity: 0.28,
                child: KolamNxNPreviewView(
                  tiles: _currentTarget.targetTiles,
                  gridDimension: N,
                  size: boardDim,
                  strokeWidth: strokeW + 0.6,
                  showDots: false,
                ),
              ),
            ),

          // NxN Grid of DragTarget Cells
          GridView.builder(
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: N * N,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: N,
            ),
            itemBuilder: (context, index) {
              return _buildBoardSlot(index, cellSize, strokeW, isDark);
            },
          ),
        ],
      ),
    );
  }

  /// Individual Cell on the NxN Board
  Widget _buildBoardSlot(
      int slotIndex, double cellSize, double strokeW, bool isDark) {
    final placedTile = _boardSlots[slotIndex];
    final targetTile = _currentTarget.targetTiles[slotIndex];
    final isCorrect = _hasValidated && (placedTile == targetTile);
    final isIncorrect =
        _hasValidated && (placedTile != null && placedTile != targetTile);

    return DragTarget<Kolam16Tile>(
      onWillAcceptWithDetails: (details) => true,
      onAcceptWithDetails: (details) {
        _placeTile(slotIndex, details.data);
      },
      builder: (context, candidateData, rejectedData) {
        final isHovered = candidateData.isNotEmpty;

        return InkWell(
          onTap: () => _onSlotTapped(slotIndex),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: isHovered
                    ? AppColors.turmericGold
                    : isCorrect
                        ? AppColors.tulsiGreen.withValues(alpha: 0.8)
                        : isIncorrect
                            ? AppColors.crimsonRed.withValues(alpha: 0.8)
                            : (isDark ? Colors.white12 : Colors.black12),
                width: isHovered ? 2.0 : 0.6,
              ),
              color: isHovered
                  ? AppColors.turmericGold.withValues(alpha: 0.15)
                  : isCorrect
                      ? AppColors.tulsiGreen.withValues(alpha: 0.10)
                      : isIncorrect
                          ? AppColors.crimsonRed.withValues(alpha: 0.10)
                          : Colors.transparent,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Render placed tile or central pulli dot
                if (placedTile != null)
                  Kolam16TileView(
                    tile: placedTile,
                    size: cellSize,
                    strokeWidth: strokeW,
                    showDot: true,
                  )
                else
                  Container(
                    width: cellSize > 40 ? 5.0 : 3.5,
                    height: cellSize > 40 ? 5.0 : 3.5,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.turmericGold,
                    ),
                  ),

                // Correct / Incorrect status icon badge when validated
                if (_hasValidated && placedTile != null)
                  Positioned(
                    top: 1,
                    right: 1,
                    child: Icon(
                      isCorrect
                          ? Icons.check_circle_rounded
                          : Icons.cancel_rounded,
                      size: cellSize > 40 ? 13 : 9,
                      color:
                          isCorrect ? AppColors.tulsiGreen : AppColors.crimsonRed,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Action Toolbar (Clear, Validate)
  Widget _buildQuickActionControls(bool isDark) {
    return Row(
      children: [
        // Clear Board Button
        OutlinedButton.icon(
          onPressed: _placedCount > 0 ? _clearAllSlots : null,
          icon: const Icon(Icons.refresh_rounded, size: 18),
          label: const Text('Clear'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            side: BorderSide(
              color: isDark ? AppColors.borderDark : AppColors.kaaviBrick,
            ),
          ),
        ),
        const SizedBox(width: 10),

        // Validate Button
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _placedCount > 0 ? _validatePattern : null,
            icon: Icon(
              _isRoundWon
                  ? Icons.emoji_events_rounded
                  : Icons.check_circle_rounded,
              color: Colors.white,
              size: 20,
            ),
            label: Text(
              _isRoundWon
                  ? (_currentRound == totalMatchRounds
                      ? 'Grand Victory!'
                      : 'Round Cleared! 🏆')
                  : 'Check Match',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 11),
              backgroundColor:
                  _isRoundWon ? AppColors.tulsiGreen : AppColors.kaaviBrick,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Validation Status Card / Round Advance / Grand Victory Celebration
  Widget _buildValidationStatusCard(bool isDark) {
    final matches = _matchingCount;

    if (_isMatchComplete) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.tulsiGreen.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.tulsiGreen, width: 2.0),
        ),
        child: Column(
          children: [
            const Icon(Icons.emoji_events_rounded,
                size: 44, color: AppColors.turmericGold),
            const SizedBox(height: 8),
            const Text(
              '🏆 Match Champion! 🏆',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.tulsiGreen,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'All 5 Progressive Rounds Completed with 8x8 D4 Mastery!',
              style: AppTypography.caption.copyWith(
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.turmericGold.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Final Match Score: $_totalMatchScore pts (+200 XP)',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.turmericAmber,
                ),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _restartFullMatch,
                icon: const Icon(Icons.replay_rounded, color: Colors.white),
                label: const Text('Play Another 5-Round Match'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.tulsiGreen,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: _isRoundWon
            ? AppColors.tulsiGreen.withValues(alpha: 0.12)
            : AppColors.crimsonRed.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _isRoundWon ? AppColors.tulsiGreen : AppColors.crimsonRed,
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                _isRoundWon
                    ? Icons.verified_rounded
                    : Icons.info_outline_rounded,
                color: _isRoundWon ? AppColors.tulsiGreen : AppColors.crimsonRed,
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _isRoundWon
                      ? 'Round $_currentRound Completed Perfectly! (+$_roundBaseScore pts)'
                      : '$matches / $_totalCellCount Tiles Matched Correctly',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color:
                        _isRoundWon ? AppColors.tulsiGreen : AppColors.crimsonRed,
                  ),
                ),
              ),
            ],
          ),
          if (_isRoundWon) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _advanceToNextRound,
                icon: const Icon(Icons.arrow_forward_rounded,
                    color: Colors.white),
                label: Text(
                  _currentRound < totalMatchRounds
                      ? 'Advance to Round ${_currentRound + 1} (${_currentRound >= 2 ? (_currentRound >= 4 ? "8x8" : "6x6") : "4x4"})'
                      : 'View Match Summary',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.tulsiGreen,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _scrollTray(double delta) {
    if (!_trayScrollController.hasClients) return;
    final target = (_trayScrollController.offset + delta).clamp(
      0.0,
      _trayScrollController.position.maxScrollExtent,
    );
    _trayScrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  /// Card displaying all 16 fundamental Sikku tiles in a 2-row scrollable grid with navigation chevrons
  Widget _build16TilesCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.slateCard : AppColors.riceFlourCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.turmericGold.withValues(alpha: 0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 26, minHeight: 80),
            onPressed: () => _scrollTray(-160),
          ),
          Expanded(
            child: SizedBox(
              height: 114,
              child: ScrollConfiguration(
                behavior: const KolamScrollBehavior().copyWith(
                  scrollbars: false,
                ),
                child: GridView.builder(
                  controller: _trayScrollController,
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: Kolam16TileLibrary.all.length,
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 6,
                    crossAxisSpacing: 6,
                    childAspectRatio: 1.0,
                  ),
                  itemBuilder: (context, index) {
                    final tile = Kolam16TileLibrary.all[index];
                    return _buildDraggableTile(tile, isDark);
                  },
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 26, minHeight: 80),
            onPressed: () => _scrollTray(160),
          ),
        ],
      ),
    );
  }

  /// Wraps a single tile with LongPressDraggable and InkWell for Drag & Drop + Tap to place
  Widget _buildDraggableTile(Kolam16Tile tile, bool isDark,
      {bool compact = false}) {
    final isSelected = _selectedTrayTile == tile;

    return LongPressDraggable<Kolam16Tile>(
      data: tile,
      delay: const Duration(milliseconds: 120),
      feedback: Material(
        color: Colors.transparent,
        child: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: (isDark
                    ? const Color(0xFF221A1D)
                    : AppColors.riceFlourBg)
                .withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: AppColors.turmericGold,
              width: 2.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Kolam16TileView(
            tile: tile,
            size: 58,
            strokeWidth: 2.8,
            showDot: true,
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.30,
        child: _buildTrayTileCard(tile, false, isDark, compact: compact),
      ),
      child: InkWell(
        onTap: () => _onTrayTileTapped(tile),
        borderRadius: BorderRadius.circular(compact ? 6 : 10),
        child: _buildTrayTileCard(tile, isSelected, isDark, compact: compact),
      ),
    );
  }

  /// Individual Tile Card inside the bottom tray
  Widget _buildTrayTileCard(
      Kolam16Tile tile, bool isSelected, bool isDark,
      {bool compact = false}) {
    return Container(
      width: compact ? 36 : 52,
      height: compact ? 36 : 52,
      padding: EdgeInsets.all(compact ? 2 : 4),
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.turmericGold.withValues(alpha: 0.25)
            : (isDark ? const Color(0xFF221A1D) : AppColors.riceFlourBg),
        borderRadius: BorderRadius.circular(compact ? 6 : 9),
        border: Border.all(
          color: isSelected
              ? AppColors.turmericGold
              : (isDark ? Colors.white12 : Colors.black12),
          width: isSelected ? (compact ? 1.8 : 2.2) : 1.0,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: AppColors.turmericGold.withValues(alpha: 0.4),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      alignment: Alignment.center,
      child: Kolam16TileView(
        tile: tile,
        size: compact ? 26 : 40,
        strokeWidth: compact ? 1.8 : 2.4,
        showDot: true,
      ),
    );
  }
}

/// Custom scroll behavior enabling drag gestures from Touch, Mouse, Trackpad, and Stylus
class KolamScrollBehavior extends MaterialScrollBehavior {
  const KolamScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
      };
}
