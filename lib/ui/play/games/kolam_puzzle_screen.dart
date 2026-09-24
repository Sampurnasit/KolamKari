import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../data/models/game_result.dart';
import '../../../data/seed/kolam_image_library.dart';
import '../../../providers/app_providers.dart';

enum PuzzleDifficultyTier {
  beginner(2, 'Tier 1: Beginner (2x2)', '1 of 4 quadrants missing • Obvious distractors'),
  skilled(3, 'Tier 2: Skilled (3x3)', '1 of 9 tiles missing • Rotated & mirrored decoys'),
  master(3, 'Tier 3: Master (3x3)', '1 key focal tile missing • Intricate rotational variations');

  final int gridSize;
  final String label;
  final String description;

  const PuzzleDifficultyTier(this.gridSize, this.label, this.description);
}

class PuzzleCandidatePiece {
  final String id;
  final String designId;
  final String assetPath;
  final int row;
  final int col;
  final int gridSize;
  final int rotationTurns; // 0, 1, 2, 3 (each turn = 90 deg clockwise)
  final bool isMirroredX;
  final bool isMirroredY;
  final bool isCorrect;
  final String explanation;

  const PuzzleCandidatePiece({
    required this.id,
    required this.designId,
    required this.assetPath,
    required this.row,
    required this.col,
    required this.gridSize,
    this.rotationTurns = 0,
    this.isMirroredX = false,
    this.isMirroredY = false,
    required this.isCorrect,
    required this.explanation,
  });
}

class KolamPuzzleScreen extends ConsumerStatefulWidget {
  final bool isDailyChallenge;
  final VoidCallback? onChallengeCompleted;

  const KolamPuzzleScreen({
    super.key,
    this.isDailyChallenge = false,
    this.onChallengeCompleted,
  });

  @override
  ConsumerState<KolamPuzzleScreen> createState() => _KolamPuzzleScreenState();
}

class _KolamPuzzleScreenState extends ConsumerState<KolamPuzzleScreen> with SingleTickerProviderStateMixin {
  final Random _random = Random();
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  PuzzleDifficultyTier _selectedTier = PuzzleDifficultyTier.beginner;
  late KolamImageDesign _currentDesign;
  late int _missingRow;
  late int _missingCol;

  late List<PuzzleCandidatePiece> _candidatePieces;
  int? _selectedCandidateIndex;
  bool _submitted = false;
  bool _isCorrect = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _generateNewPuzzle();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _generateNewPuzzle() {
    final designs = KolamImageLibrary.allDesigns;
    // Pick a random design from the 10 authentic drive images
    final design = designs[_random.nextInt(designs.length)];
    final gridSize = _selectedTier.gridSize;

    // Pick random row and col to mask out
    final missingR = _random.nextInt(gridSize);
    final missingC = _random.nextInt(gridSize);

    // Generate 1 authentic piece + 3 distractors
    final candidates = <PuzzleCandidatePiece>[];

    // 1. Correct Authentic Piece
    final correctPiece = PuzzleCandidatePiece(
      id: 'correct_${design.id}_${missingR}_$missingC',
      designId: design.id,
      assetPath: design.assetPath,
      row: missingR,
      col: missingC,
      gridSize: gridSize,
      isCorrect: true,
      explanation: 'Authentic matching piece with perfect symmetry and continuous loop flow.',
    );
    candidates.add(correctPiece);

    if (_selectedTier == PuzzleDifficultyTier.beginner) {
      // Tier 1 Distractors:
      // Decoy 1: Rotated 90° or 180°
      final turns = _random.nextBool() ? 1 : 2;
      candidates.add(PuzzleCandidatePiece(
        id: 'decoy_rot_${design.id}',
        designId: design.id,
        assetPath: design.assetPath,
        row: missingR,
        col: missingC,
        gridSize: gridSize,
        rotationTurns: turns,
        isCorrect: false,
        explanation: 'This piece is rotated ${turns * 90}° and breaks the cardinal symmetry lines.',
      ));

      // Decoy 2: Mirrored horizontally
      candidates.add(PuzzleCandidatePiece(
        id: 'decoy_mirror_${design.id}',
        designId: design.id,
        assetPath: design.assetPath,
        row: missingR,
        col: missingC,
        gridSize: gridSize,
        isMirroredX: true,
        isCorrect: false,
        explanation: 'This piece is horizontally mirrored; its curve exits face the wrong direction.',
      ));

      // Decoy 3: Quadrant from another authentic Kolam image
      final otherDesigns = designs.where((d) => d.id != design.id).toList();
      final otherDesign = otherDesigns[_random.nextInt(otherDesigns.length)];
      candidates.add(PuzzleCandidatePiece(
        id: 'decoy_other_${otherDesign.id}',
        designId: otherDesign.id,
        assetPath: otherDesign.assetPath,
        row: missingR,
        col: missingC,
        gridSize: gridSize,
        isCorrect: false,
        explanation: 'This piece belongs to "${otherDesign.name}" with a completely different motif.',
      ));
    } else if (_selectedTier == PuzzleDifficultyTier.skilled) {
      // Tier 2 Distractors:
      // Decoy 1: 90° rotation
      candidates.add(PuzzleCandidatePiece(
        id: 'decoy_rot90_${design.id}',
        designId: design.id,
        assetPath: design.assetPath,
        row: missingR,
        col: missingC,
        gridSize: gridSize,
        rotationTurns: 1,
        isCorrect: false,
        explanation: 'Rotated 90° clockwise — the loop continuity fails to connect with adjacent dots.',
      ));

      // Decoy 2: 270° rotation or mirrored vertically
      candidates.add(PuzzleCandidatePiece(
        id: 'decoy_mirror_y_${design.id}',
        designId: design.id,
        assetPath: design.assetPath,
        row: missingR,
        col: missingC,
        gridSize: gridSize,
        isMirroredY: true,
        isCorrect: false,
        explanation: 'Mirrored vertically — the top/bottom boundary curves are inverted.',
      ));

      // Decoy 3: Slice from another authentic Kolam image
      final otherDesigns = designs.where((d) => d.id != design.id).toList();
      final otherDesign = otherDesigns[_random.nextInt(otherDesigns.length)];
      candidates.add(PuzzleCandidatePiece(
        id: 'decoy_other_${otherDesign.id}',
        designId: otherDesign.id,
        assetPath: otherDesign.assetPath,
        row: missingR,
        col: missingC,
        gridSize: gridSize,
        isCorrect: false,
        explanation: 'Extracted from "${otherDesign.name}", which has incompatible pulli density.',
      ));
    } else {
      // Tier 3 (Master): All distractors are intricate variations of the SAME authentic tile
      // Decoy 1: 90° clockwise
      candidates.add(PuzzleCandidatePiece(
        id: 'decoy_m_rot1_${design.id}',
        designId: design.id,
        assetPath: design.assetPath,
        row: missingR,
        col: missingC,
        gridSize: gridSize,
        rotationTurns: 1,
        isCorrect: false,
        explanation: 'Rotated 90° clockwise — examine the knot entry angle closely.',
      ));

      // Decoy 2: 180° rotation
      candidates.add(PuzzleCandidatePiece(
        id: 'decoy_m_rot2_${design.id}',
        designId: design.id,
        assetPath: design.assetPath,
        row: missingR,
        col: missingC,
        gridSize: gridSize,
        rotationTurns: 2,
        isCorrect: false,
        explanation: 'Rotated 180° — inverts inner vine flow against the center axis.',
      ));

      // Decoy 3: 270° counter-clockwise or horizontal mirror
      candidates.add(PuzzleCandidatePiece(
        id: 'decoy_m_rot3_${design.id}',
        designId: design.id,
        assetPath: design.assetPath,
        row: missingR,
        col: missingC,
        gridSize: gridSize,
        rotationTurns: 3,
        isCorrect: false,
        explanation: 'Rotated 270° — leaves open loop gap on the perimeter.',
      ));
    }

    candidates.shuffle(_random);

    setState(() {
      _currentDesign = design;
      _missingRow = missingR;
      _missingCol = missingC;
      _candidatePieces = candidates;
      _selectedCandidateIndex = null;
      _submitted = false;
      _isCorrect = false;
    });
  }

  void _selectTier(PuzzleDifficultyTier tier) {
    if (_selectedTier == tier) return;
    setState(() {
      _selectedTier = tier;
    });
    _generateNewPuzzle();
  }

  void _selectCandidate(int index) {
    if (_submitted && _isCorrect) return;
    setState(() {
      _selectedCandidateIndex = index;
      _submitted = false;
    });
  }

  Future<void> _verifyPuzzle() async {
    if (_selectedCandidateIndex == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select one of the 4 candidate pieces below!'),
          backgroundColor: AppColors.kaaviBrick,
        ),
      );
      return;
    }

    final chosen = _candidatePieces[_selectedCandidateIndex!];
    final isWin = chosen.isCorrect;

    setState(() {
      _submitted = true;
      _isCorrect = isWin;
    });

    if (isWin) {
      // Award +50 XP via GamificationService
      await ref.read(userProfileProvider.notifier).onPuzzleCompleted();
      if (widget.isDailyChallenge) {
        await ref.read(userProfileProvider.notifier).onDailyChallengeCompleted();
        widget.onChallengeCompleted?.call();
      }

      // Log GameResult to StorageService
      final storage = ref.read(storageServiceProvider);
      final result = GameResult(
        id: const Uuid().v4(),
        gameType: GameType.kolamPuzzle,
        score: 100,
        xpEarned: 50,
        timestamp: DateTime.now(),
        difficultyLevel: _selectedTier.index + 1,
        culturalNote: 'Restored missing section of ${_currentDesign.name} (${_currentDesign.tamilName}).',
        won: true,
      );
      await storage.recordGameResult(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isDailyChallenge ? 'Daily Challenge: Kolam Puzzle' : 'Kolam Missing Piece Puzzle'),
        actions: [
          IconButton(
            icon: const Icon(Icons.shuffle_rounded),
            tooltip: 'Next Random Kolam Puzzle',
            onPressed: _generateNewPuzzle,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Target Header Banner
            _buildTargetHeader(isDark),
            const SizedBox(height: 12),

            // Tier Selector
            _buildTierSelector(isDark),
            const SizedBox(height: 14),

            // Masked Puzzle Board
            Center(
              child: _buildMaskedKolamBoard(isDark),
            ),
            const SizedBox(height: 16),

            // Feedback Card (if submitted)
            if (_submitted) ...[
              _buildFeedbackCard(isDark),
              const SizedBox(height: 14),
            ],

            // Candidates Section Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.extension_rounded, size: 16, color: AppColors.turmericAmber),
                    const SizedBox(width: 6),
                    Text(
                      'Candidate Pieces',
                      style: AppTypography.cardTitle.copyWith(fontSize: 14),
                    ),
                  ],
                ),
                Text(
                  'Tap to preview & select',
                  style: AppTypography.caption.copyWith(fontSize: 11),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Candidate Cards Grid (4 options)
            _buildCandidateGrid(isDark),
            const SizedBox(height: 16),

            // Action Button
            _buildActionButton(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildTargetHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.slateCard : const Color(0xFFFBF2EA),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.turmericGold.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.terracottaRed.withValues(alpha: 0.6)),
            ),
            clipBehavior: Clip.antiAlias,
            child: Image.asset(
              _currentDesign.assetPath,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        _currentDesign.name,
                        style: AppTypography.cardTitle.copyWith(fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.tulsiGreen.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '+50 XP',
                        style: AppTypography.caption.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.tulsiGreen,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${_currentDesign.tamilName} • ${_currentDesign.category}',
                  style: AppTypography.caption.copyWith(
                    fontSize: 11,
                    color: AppColors.turmericAmber,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Find the authentic missing section among rotated and mirrored decoys.',
                  style: AppTypography.caption.copyWith(fontSize: 10.5),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTierSelector(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.slateLight : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: PuzzleDifficultyTier.values.map((tier) {
          final isSelected = _selectedTier == tier;
          return Expanded(
            child: InkWell(
              onTap: () => _selectTier(tier),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.turmericGold : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  tier == PuzzleDifficultyTier.beginner
                      ? 'Tier 1 (2x2)'
                      : tier == PuzzleDifficultyTier.skilled
                          ? 'Tier 2 (3x3)'
                          : 'Tier 3 (Master)',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? Colors.black87 : (isDark ? Colors.white70 : Colors.black87),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMaskedKolamBoard(bool isDark) {
    const double boardDim = 280.0;
    final int gridSize = _selectedTier.gridSize;
    final double cellSize = boardDim / gridSize;

    return Container(
      width: boardDim,
      height: boardDim,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF221A1D) : AppColors.riceFlourBg, // Earth slate or rice flour floor
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: (_submitted && _isCorrect) ? AppColors.tulsiGreen : AppColors.kaaviBrick,
          width: (_submitted && _isCorrect) ? 3.0 : 2.0,
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
          // Base Authentic Kolam Image
          Positioned.fill(
            child: Image.asset(
              _currentDesign.assetPath,
              fit: BoxFit.cover,
            ),
          ),

          // Missing Slot Cutout Overlay
          Positioned(
            left: _missingCol * cellSize,
            top: _missingRow * cellSize,
            width: cellSize,
            height: cellSize,
            child: (_submitted && _isCorrect)
                ? Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.tulsiGreen.withValues(alpha: 0.8), width: 2),
                    ),
                  )
                : _buildMissingSlotCutout(cellSize, isDark),
          ),

          // Grid Lines Overlay for Clarity
          CustomPaint(
            size: const Size(boardDim, boardDim),
            painter: _GridGuidePainter(gridSize: gridSize),
          ),
        ],
      ),
    );
  }

  Widget _buildMissingSlotCutout(double cellSize, bool isDark) {
    final hasCandidatePreview = _selectedCandidateIndex != null;
    final candidate = hasCandidatePreview ? _candidatePieces[_selectedCandidateIndex!] : null;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1719),
        border: Border.all(
          color: AppColors.turmericGold,
          width: 2.0,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Preview of currently selected candidate in place
          if (candidate != null)
            Opacity(
              opacity: 0.85,
              child: _buildPieceSlice(candidate, cellSize),
            ),

          // Pulsating Mystery Marker if not previewing or semi-translucent over preview
          if (!hasCandidatePreview)
            ScaleTransition(
              scale: _pulseAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.help_outline_rounded,
                    color: AppColors.turmericAmber,
                    size: 32,
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Missing Piece',
                      style: AppTypography.caption.copyWith(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCandidateGrid(bool isDark) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.15,
      ),
      itemCount: _candidatePieces.length,
      itemBuilder: (context, index) {
        final piece = _candidatePieces[index];
        final isSelected = _selectedCandidateIndex == index;

        Color borderColor = isSelected ? AppColors.turmericGold : (isDark ? AppColors.borderDark : AppColors.borderLight);
        if (_submitted) {
          if (piece.isCorrect) {
            borderColor = AppColors.tulsiGreen;
          } else if (isSelected) {
            borderColor = AppColors.crimsonRed;
          }
        }

        return InkWell(
          onTap: () => _selectCandidate(index),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.slateCard : const Color(0xFFFBF4EE),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: borderColor,
                width: isSelected || (_submitted && piece.isCorrect) ? 2.5 : 1.0,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppColors.turmericGold.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Stack(
              children: [
                // Center piece slice preview
                Center(
                  child: Container(
                    width: 78,
                    height: 78,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.black26),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: _buildPieceSlice(piece, 78),
                  ),
                ),

                // Option Label Tag (A, B, C, D)
                Positioned(
                  top: 8,
                  left: 8,
                  child: CircleAvatar(
                    radius: 11,
                    backgroundColor: isSelected ? AppColors.turmericGold : Colors.black54,
                    child: Text(
                      String.fromCharCode(65 + index),
                      style: TextStyle(
                        color: isSelected ? Colors.black87 : Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                // Status Icons
                if (_submitted && piece.isCorrect)
                  const Positioned(
                    top: 8,
                    right: 8,
                    child: Icon(Icons.check_circle_rounded, color: AppColors.tulsiGreen, size: 20),
                  )
                else if (_submitted && isSelected && !piece.isCorrect)
                  const Positioned(
                    top: 8,
                    right: 8,
                    child: Icon(Icons.cancel_rounded, color: AppColors.crimsonRed, size: 20),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPieceSlice(PuzzleCandidatePiece piece, double displaySize) {
    final double alignX = piece.gridSize > 1
        ? -1.0 + (piece.col / (piece.gridSize - 1)) * 2.0
        : 0.0;
    final double alignY = piece.gridSize > 1
        ? -1.0 + (piece.row / (piece.gridSize - 1)) * 2.0
        : 0.0;

    Widget slice = ClipRect(
      child: Container(
        width: displaySize,
        height: displaySize,
        alignment: Alignment(alignX, alignY),
        child: FittedBox(
          fit: BoxFit.none,
          alignment: Alignment(alignX, alignY),
          child: SizedBox(
            width: displaySize * piece.gridSize,
            height: displaySize * piece.gridSize,
            child: Image.asset(
              piece.assetPath,
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    );

    // Apply rotation turns
    if (piece.rotationTurns != 0) {
      slice = Transform.rotate(
        angle: piece.rotationTurns * (pi / 2),
        child: slice,
      );
    }

    // Apply mirroring
    if (piece.isMirroredX || piece.isMirroredY) {
      slice = Transform.scale(
        scaleX: piece.isMirroredX ? -1.0 : 1.0,
        scaleY: piece.isMirroredY ? -1.0 : 1.0,
        child: slice,
      );
    }

    return slice;
  }

  Widget _buildFeedbackCard(bool isDark) {
    final candidate = _selectedCandidateIndex != null ? _candidatePieces[_selectedCandidateIndex!] : null;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _isCorrect
            ? AppColors.tulsiGreen.withValues(alpha: 0.15)
            : AppColors.crimsonRed.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _isCorrect ? AppColors.tulsiGreen : AppColors.crimsonRed,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _isCorrect ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                color: _isCorrect ? AppColors.tulsiGreen : AppColors.crimsonRed,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _isCorrect
                      ? 'Kolam Symmetry Restored! (+50 XP)'
                      : 'Incorrect Choice',
                  style: AppTypography.cardTitle.copyWith(
                    fontSize: 14,
                    color: _isCorrect ? AppColors.tulsiGreen : AppColors.crimsonRed,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            candidate?.explanation ?? (_isCorrect ? _currentDesign.culturalLore : 'Try another candidate piece.'),
            style: AppTypography.bodyText.copyWith(fontSize: 12.5),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton() {
    if (!_submitted || !_isCorrect) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _verifyPuzzle,
          icon: const Icon(Icons.check_rounded, color: Colors.white),
          label: const Text('Verify Missing Piece'),
        ),
      );
    }

    // Solved state
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              setState(() {
                _submitted = false;
                _selectedCandidateIndex = null;
              });
            },
            icon: const Icon(Icons.replay_rounded, size: 16),
            label: const Text('Review Board'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _generateNewPuzzle,
            icon: const Icon(Icons.shuffle_rounded, color: Colors.white, size: 16),
            label: const Text('Next Puzzle'),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.tulsiGreen),
          ),
        ),
      ],
    );
  }
}

class _GridGuidePainter extends CustomPainter {
  final int gridSize;

  const _GridGuidePainter({required this.gridSize});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.18)
      ..strokeWidth = 1.0;

    final step = size.width / gridSize;
    for (int i = 1; i < gridSize; i++) {
      final pos = i * step;
      canvas.drawLine(Offset(pos, 0), Offset(pos, size.height), paint);
      canvas.drawLine(Offset(0, pos), Offset(size.width, pos), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GridGuidePainter oldDelegate) => oldDelegate.gridSize != gridSize;
}
