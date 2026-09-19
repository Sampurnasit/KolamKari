import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../data/models/game_result.dart';
import '../../../data/seed/kolam_image_library.dart';
import '../../../providers/app_providers.dart';

/// A sliced quadrant or tile piece of an authentic Kolam image
class KolamImagePiece {
  final String id;
  final String sourceDesignId;
  final String assetPath;
  final int targetRow;
  final int targetCol;
  final int gridSize; // 2 or 3
  final bool isDecoy;

  const KolamImagePiece({
    required this.id,
    required this.sourceDesignId,
    required this.assetPath,
    required this.targetRow,
    required this.targetCol,
    required this.gridSize,
    this.isDecoy = false,
  });
}

class PatternConstructionScreen extends ConsumerStatefulWidget {
  final bool isDailyChallenge;
  final VoidCallback? onChallengeCompleted;

  const PatternConstructionScreen({
    super.key,
    this.isDailyChallenge = false,
    this.onChallengeCompleted,
  });

  @override
  ConsumerState<PatternConstructionScreen> createState() => _PatternConstructionScreenState();
}

class _PatternConstructionScreenState extends ConsumerState<PatternConstructionScreen> {
  final Random _random = Random();

  // Active target design from the 10 authentic images
  int _currentDesignIndex = 0;
  List<KolamImageDesign> get _allDesigns => KolamImageLibrary.allDesigns;
  KolamImageDesign get _currentTarget => _allDesigns[_currentDesignIndex];

  int _gridSize = 2; // 2 for 2x2 (4 pieces), 3 for 3x3 (9 pieces)

  // Board slots: length = gridSize * gridSize
  late List<KolamImagePiece?> _boardSlots;

  // Shuffled pieces available in the tray (includes target pieces + decoys)
  late List<KolamImagePiece> _trayPieces;

  // Selected piece in tray for tap-to-place
  String? _selectedTrayPieceId;

  // Ghost reference opacity overlay
  bool _showGhostReference = false;

  bool _hasSubmitted = false;
  bool _gameWon = false;

  @override
  void initState() {
    super.initState();
    _gridSize = _currentTarget.recommendedGridSize;
    _resetGameForCurrentTarget();
  }

  void _resetGameForCurrentTarget() {
    final totalSlots = _gridSize * _gridSize;
    _boardSlots = List<KolamImagePiece?>.filled(totalSlots, null);
    _selectedTrayPieceId = null;
    _hasSubmitted = false;
    _gameWon = false;

    // Generate correct pieces for the current target
    final pieces = <KolamImagePiece>[];
    for (int r = 0; r < _gridSize; r++) {
      for (int c = 0; c < _gridSize; c++) {
        pieces.add(KolamImagePiece(
          id: '${_currentTarget.id}_r${r}_c$c',
          sourceDesignId: _currentTarget.id,
          assetPath: _currentTarget.assetPath,
          targetRow: r,
          targetCol: c,
          gridSize: _gridSize,
          isDecoy: false,
        ));
      }
    }

    // Add 2 decoy pieces from other authentic Kolams in the library
    final otherDesigns = _allDesigns.where((d) => d.id != _currentTarget.id).toList()..shuffle(_random);
    for (int i = 0; i < min(2, otherDesigns.length); i++) {
      final decoyDesign = otherDesigns[i];
      final decoyR = _random.nextInt(_gridSize);
      final decoyC = _random.nextInt(_gridSize);
      pieces.add(KolamImagePiece(
        id: 'decoy_${decoyDesign.id}_$i',
        sourceDesignId: decoyDesign.id,
        assetPath: decoyDesign.assetPath,
        targetRow: decoyR,
        targetCol: decoyC,
        gridSize: _gridSize,
        isDecoy: true,
      ));
    }

    pieces.shuffle(_random);
    _trayPieces = pieces;
  }

  void _nextTargetPattern() {
    setState(() {
      _currentDesignIndex = (_currentDesignIndex + 1) % _allDesigns.length;
      _gridSize = _currentTarget.recommendedGridSize;
      _resetGameForCurrentTarget();
    });
  }

  void _setGridSize(int size) {
    if (_gridSize == size) return;
    setState(() {
      _gridSize = size;
      _resetGameForCurrentTarget();
    });
  }

  void _onTrayPieceSelected(KolamImagePiece piece) {
    setState(() {
      if (_selectedTrayPieceId == piece.id) {
        _selectedTrayPieceId = null;
      } else {
        _selectedTrayPieceId = piece.id;
      }
    });
  }

  void _onBoardSlotTapped(int slotIndex) {
    // If a tray piece is selected, place it into this slot
    if (_selectedTrayPieceId != null) {
      final pieceIdx = _trayPieces.indexWhere((p) => p.id == _selectedTrayPieceId);
      if (pieceIdx != -1) {
        final piece = _trayPieces[pieceIdx];
        _placePieceInSlot(slotIndex, piece);
      }
      return;
    }

    // If an existing piece is on this slot, remove it back to tray
    if (_boardSlots[slotIndex] != null) {
      _removePieceFromSlot(slotIndex);
    }
  }

  void _placePieceInSlot(int slotIndex, KolamImagePiece piece) {
    setState(() {
      // If slot already has a piece, return old piece to tray
      final existing = _boardSlots[slotIndex];
      if (existing != null) {
        _trayPieces.add(existing);
      }

      // Remove placed piece from tray
      _trayPieces.removeWhere((p) => p.id == piece.id);
      _boardSlots[slotIndex] = piece;
      _selectedTrayPieceId = null;
      _hasSubmitted = false;
    });

    _autoCheckIfComplete();
  }

  void _removePieceFromSlot(int slotIndex) {
    final existing = _boardSlots[slotIndex];
    if (existing == null) return;
    setState(() {
      _boardSlots[slotIndex] = null;
      _trayPieces.add(existing);
      _hasSubmitted = false;
      _gameWon = false;
    });
  }

  void _clearBoard() {
    setState(() {
      for (final p in _boardSlots) {
        if (p != null) _trayPieces.add(p);
      }
      _boardSlots = List<KolamImagePiece?>.filled(_gridSize * _gridSize, null);
      _selectedTrayPieceId = null;
      _hasSubmitted = false;
      _gameWon = false;
    });
  }

  void _autoCheckIfComplete() {
    // If all slots are filled, evaluate solution automatically
    final allFilled = _boardSlots.every((p) => p != null);
    if (allFilled) {
      _verifyReconstruction();
    }
  }

  Future<void> _verifyReconstruction() async {
    bool allCorrect = true;
    for (int r = 0; r < _gridSize; r++) {
      for (int c = 0; c < _gridSize; c++) {
        final slotIndex = r * _gridSize + c;
        final piece = _boardSlots[slotIndex];
        if (piece == null) {
          allCorrect = false;
          break;
        }
        if (piece.sourceDesignId != _currentTarget.id || piece.targetRow != r || piece.targetCol != c) {
          allCorrect = false;
        }
      }
    }

    setState(() {
      _hasSubmitted = true;
      _gameWon = allCorrect;
    });

    if (allCorrect) {
      await ref.read(userProfileProvider.notifier).onPuzzleCompleted();
      if (widget.isDailyChallenge) {
        await ref.read(userProfileProvider.notifier).onDailyChallengeCompleted();
        widget.onChallengeCompleted?.call();
      }

      final storage = ref.read(storageServiceProvider);
      final result = GameResult(
        id: const Uuid().v4(),
        gameType: GameType.patternConstruction,
        score: 100,
        xpEarned: 50,
        timestamp: DateTime.now(),
        difficultyLevel: _gridSize == 2 ? 1 : 2,
        culturalNote: 'Reconstructed ${_currentTarget.name} (${_currentTarget.category}).',
        won: true,
      );
      await storage.recordGameResult(result);
    }
  }

  void _showTargetInspectionDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF221A1D),
        title: Text(
          _currentTarget.name,
          style: AppTypography.cardTitle.copyWith(color: AppColors.turmericGold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.turmericGold, width: 2),
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.asset(
                _currentTarget.assetPath,
                width: 260,
                height: 260,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _currentTarget.culturalLore,
              style: AppTypography.caption.copyWith(color: AppColors.textLight),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Got it', style: TextStyle(color: AppColors.turmericGold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isDailyChallenge ? 'Daily Challenge: Reconstruction' : 'Kolam Reconstruction Game'),
        actions: [
          IconButton(
            icon: const Icon(Icons.zoom_in_rounded),
            tooltip: 'View Target Kolam',
            onPressed: _showTargetInspectionDialog,
          ),
          IconButton(
            icon: const Icon(Icons.shuffle_rounded),
            tooltip: 'Next Authentic Kolam',
            onPressed: _nextTargetPattern,
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

            // Controls & Grid Switcher Bar
            _buildControlBar(isDark),
            const SizedBox(height: 12),

            // Reconstruction Board Area
            Center(
              child: _buildReconstructionBoard(isDark),
            ),
            const SizedBox(height: 16),

            // Win Banner
            if (_hasSubmitted && _gameWon) _buildWinBanner(isDark),

            // Shuffled Piece Tray Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.extension_rounded, size: 16, color: AppColors.turmericAmber),
                    const SizedBox(width: 6),
                    Text(
                      'Piece Tray (${_trayPieces.length} remaining)',
                      style: AppTypography.cardTitle.copyWith(fontSize: 14),
                    ),
                  ],
                ),
                Text(
                  'Drag or Tap to Place',
                  style: AppTypography.caption.copyWith(fontSize: 11),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Piece Tray (Horizontal scrollable catalog)
            _buildPieceTray(isDark),
            const SizedBox(height: 16),

            // Cultural Lore Card
            _buildCulturalLoreCard(isDark),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildTargetHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.slateCard : const Color(0xFFFAF3EA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.turmericGold.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          // Target Image Thumbnail
          GestureDetector(
            onTap: _showTargetInspectionDialog,
            child: Stack(
              children: [
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.turmericGold, width: 1.8),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Image.asset(
                    _currentTarget.assetPath,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  bottom: 2,
                  right: 2,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.black87,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.fullscreen, size: 14, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _currentTarget.name,
                        style: AppTypography.cardTitle.copyWith(fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.terracottaRed.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${_currentDesignIndex + 1}/${_allDesigns.length}',
                        style: AppTypography.caption.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.terracottaRed,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${_currentTarget.tamilName} • ${_currentTarget.category}',
                  style: AppTypography.caption.copyWith(
                    fontSize: 11.5,
                    color: AppColors.turmericAmber,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Reconstruct the sacred pattern from interlocking image tiles.',
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

  Widget _buildControlBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? AppColors.slateLight : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // 2x2 vs 3x3 segmented toggle
          Text('Grid:', style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(width: 6),
          _buildGridSizeButton(2, '2x2 (4 pcs)'),
          const SizedBox(width: 4),
          _buildGridSizeButton(3, '3x3 (9 pcs)'),
          const Spacer(),
          // Ghost Reference Switch
          IconButton(
            icon: Icon(
              _showGhostReference ? Icons.visibility_rounded : Icons.visibility_off_rounded,
              size: 18,
              color: _showGhostReference ? AppColors.turmericAmber : Colors.grey,
            ),
            tooltip: 'Ghost Reference',
            onPressed: () => setState(() => _showGhostReference = !_showGhostReference),
          ),
          // Clear button
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 18),
            tooltip: 'Reset Pieces',
            onPressed: _clearBoard,
          ),
        ],
      ),
    );
  }

  Widget _buildGridSizeButton(int size, String label) {
    final isSelected = _gridSize == size;
    return InkWell(
      onTap: () => _setGridSize(size),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.turmericGold : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.black87 : null,
          ),
        ),
      ),
    );
  }

  Widget _buildReconstructionBoard(bool isDark) {
    const double boardDim = 300.0;
    const double padding = 8.0;
    const double spacing = 6.0;
    final double innerDim = boardDim - (padding * 2);
    final double cellSize = (innerDim - ((_gridSize - 1) * spacing)) / _gridSize;

    return Container(
      width: boardDim,
      height: boardDim,
      padding: const EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: const Color(0xFF221A1D), // Earth slate floor
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (_hasSubmitted && _gameWon) ? AppColors.tulsiGreen : AppColors.kaaviBrick.withValues(alpha: 0.6),
          width: (_hasSubmitted && _gameWon) ? 3.0 : 2.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Ghost Reference Underlay
          if (_showGhostReference)
            Positioned.fill(
              child: Opacity(
                opacity: 0.25,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset(
                    _currentTarget.assetPath,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),

          // Grid of DropTarget slots
          SizedBox(
            width: innerDim,
            height: innerDim,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(_gridSize, (r) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(_gridSize, (c) {
                    final slotIdx = r * _gridSize + c;
                    return _buildBoardSlot(slotIdx, r, c, cellSize);
                  }),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBoardSlot(int slotIndex, int row, int col, double cellSize) {
    final piece = _boardSlots[slotIndex];

    return DragTarget<KolamImagePiece>(
      onWillAcceptWithDetails: (_) => true,
      onAcceptWithDetails: (details) {
        _placePieceInSlot(slotIndex, details.data);
      },
      builder: (context, candidateData, rejectedData) {
        final isHovered = candidateData.isNotEmpty;

        return GestureDetector(
          onTap: () => _onBoardSlotTapped(slotIndex),
          child: Container(
            width: cellSize,
            height: cellSize,
            decoration: BoxDecoration(
              color: isHovered
                  ? AppColors.turmericGold.withValues(alpha: 0.25)
                  : (piece == null ? Colors.white.withValues(alpha: 0.04) : Colors.black),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isHovered
                    ? AppColors.turmericGold
                    : (piece == null
                        ? Colors.white.withValues(alpha: 0.2)
                        : ((_hasSubmitted && _gameWon)
                            ? Colors.transparent // Seamless unified reveal on solve!
                            : AppColors.turmericGold.withValues(alpha: 0.5))),
                width: isHovered ? 2.0 : 1.0,
              ),
            ),
            child: piece == null
                ? Center(
                    child: Icon(
                      Icons.add_rounded,
                      size: 20,
                      color: Colors.white.withValues(alpha: 0.25),
                    ),
                  )
                : Stack(
                    children: [
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: _renderSlicedPiece(piece, cellSize),
                        ),
                      ),
                      // Small remove button on hover / tap
                      if (!_gameWon)
                        Positioned(
                          top: 2,
                          right: 2,
                          child: GestureDetector(
                            onTap: () => _removePieceFromSlot(slotIndex),
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close, size: 12, color: Colors.white70),
                            ),
                          ),
                        ),
                    ],
                  ),
          ),
        );
      },
    );
  }

  Widget _buildPieceTray(bool isDark) {
    if (_trayPieces.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.slateCard : AppColors.riceFlourCard,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            'All pieces placed on board! Check your reconstruction.',
            style: AppTypography.caption.copyWith(color: AppColors.tulsiGreen, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }

    const double trayPieceDim = 68.0;

    return Container(
      height: 86,
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.slateCard : AppColors.riceFlourCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _trayPieces.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final piece = _trayPieces[index];
          final isSelected = _selectedTrayPieceId == piece.id;

          return Draggable<KolamImagePiece>(
            data: piece,
            feedback: Material(
              color: Colors.transparent,
              child: Container(
                width: trayPieceDim,
                height: trayPieceDim,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.turmericGold, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: _renderSlicedPiece(piece, trayPieceDim),
              ),
            ),
            childWhenDragging: Opacity(
              opacity: 0.35,
              child: Container(
                width: trayPieceDim,
                height: trayPieceDim,
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            child: GestureDetector(
              onTap: () => _onTrayPieceSelected(piece),
              child: Container(
                width: trayPieceDim,
                height: trayPieceDim,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? AppColors.turmericGold : Colors.grey.shade400,
                    width: isSelected ? 2.5 : 1.2,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: _renderSlicedPiece(piece, trayPieceDim),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Slices the authentic Kolam image to render the exact quadrant or tile
  Widget _renderSlicedPiece(KolamImagePiece piece, double displaySize) {
    final g = piece.gridSize;
    // Fractional alignment: col in 0..g-1, row in 0..g-1
    // Range maps from -1.0 to +1.0
    final double alignX = g > 1 ? -1.0 + (piece.targetCol / (g - 1)) * 2.0 : 0.0;
    final double alignY = g > 1 ? -1.0 + (piece.targetRow / (g - 1)) * 2.0 : 0.0;

    return ClipRect(
      child: SizedBox(
        width: displaySize,
        height: displaySize,
        child: FittedBox(
          fit: BoxFit.none,
          alignment: Alignment(alignX, alignY),
          child: SizedBox(
            width: displaySize * g,
            height: displaySize * g,
            child: Image.asset(
              piece.assetPath,
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWinBanner(bool isDark) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E3A2B), const Color(0xFF14241B)]
              : [const Color(0xFFE8F5E9), const Color(0xFFC8E6C9)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.tulsiGreen, width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: AppColors.tulsiGreen,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.emoji_events_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sacred Geometry Reconstructed!',
                  style: AppTypography.cardTitle.copyWith(fontSize: 16, color: AppColors.tulsiGreen),
                ),
                const SizedBox(height: 2),
                Text(
                  '+50 XP Earned! Seams dissolved into unified Kolam.',
                  style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: _nextTargetPattern,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.tulsiGreen,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Next', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                SizedBox(width: 2),
                Icon(Icons.arrow_forward_rounded, size: 14, color: Colors.white),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCulturalLoreCard(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.slateLight : const Color(0xFFFAF3EA),
        borderRadius: BorderRadius.circular(14),
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
                  'Cultural Significance: ${_currentTarget.name}',
                  style: AppTypography.cardTitle.copyWith(fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  _currentTarget.culturalLore,
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
    );
  }
}
