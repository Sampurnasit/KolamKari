import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../data/models/saved_kolam.dart';
import '../../data/models/analysis_result.dart';
import '../../data/models/kolam_16_tile.dart';
import '../../data/models/kolam_circle_connection.dart';
import '../../data/models/kolam_shape_primitive.dart';
import '../../data/models/sample_kolam_design.dart';
import '../../providers/app_providers.dart';
import '../../services/analysis_service.dart';
import '../../services/connectivity_graph_service.dart';
import 'widgets/kolam_canvas_widget.dart';
import 'widgets/smart_analysis_sheet.dart';
import 'my_kolams_gallery_screen.dart';

enum StudioToolMode { joinCircles, freehand, shapes }

class CreateStudioScreen extends ConsumerStatefulWidget {
  final SampleKolamDesign? initialSampleDesign;
  final SavedKolam? initialSavedKolam;

  const CreateStudioScreen({
    super.key,
    this.initialSampleDesign,
    this.initialSavedKolam,
  });

  @override
  ConsumerState<CreateStudioScreen> createState() => _CreateStudioScreenState();
}

class _CreateStudioScreenState extends ConsumerState<CreateStudioScreen> {
  // Grid & Orientation Settings
  int _gridSize = 4; // 3, 4, 5, 7, 9
  KolamGridOrientation _gridOrientation = KolamGridOrientation.square; // Default Square grid as in 4x4 reference image
  final CanvasBackgroundTheme _canvasTheme = CanvasBackgroundTheme.templeSlate; // Charcoal temple slate floor
  final bool _showDots = true;

  // Active Tool Mode
  StudioToolMode _toolMode = StudioToolMode.joinCircles;

  // 16-Tile State per Dot (0000 to 1111)
  final Map<int, Kolam16Tile> _tileStates = {};
  final List<Map<int, Kolam16Tile>> _tileUndoStack = [];
  final List<Map<int, Kolam16Tile>> _tileRedoStack = [];
  Kolam16Tile _activeTilePaletteSelection = const Kolam16Tile(0);
  int? _selectedCircleIndex;

  // Canvas Palette Colors (Basic White/Black, Red, Green, Yellow, Blue, Brown) with Light/Dark shades
  KolamPaletteColor _selectedPaletteColor = KolamPaletteColor.basic;
  Color get _selectedColor {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    try {
      return _selectedPaletteColor.getShade(isDark);
    } catch (_) {
      return isDark ? const Color(0xFFFFFFFF) : const Color(0xFF000000);
    }
  }
  final double _strokeWidth = 3.5;
  final SymmetryDrawMode _symmetryMode = SymmetryDrawMode.none;
  final List<KolamStroke> _strokes = [];
  final List<KolamStroke> _redoStack = [];
  KolamStroke? _activeStroke;

  // Shape-based Construction Mode State
  final List<PlacedKolamShape> _placedShapes = [];
  String? _selectedShapeId;
  Offset? _snapHighlightPoint;
  final KolamConnectivityGraph _connectivityGraph = KolamConnectivityGraph();

  // Ghost Trace Mode State
  SampleKolamDesign? _activeSampleDesign;
  bool _showReferenceLayer = true;
  double _referenceOpacity = 0.35;

  // Shape Drag State
  Offset? _dragStartShapePos;
  Offset? _dragStartTouchPos;

  // Studio AI State
  AnalysisResult? _lastAnalysis;
  bool _isAnalyzing = false;

  @override
  void reassemble() {
    super.reassemble();
    _selectedPaletteColor = KolamPaletteColor.basic;
  }

  @override
  void initState() {
    super.initState();
    if (widget.initialSavedKolam != null) {
      _loadSavedKolam(widget.initialSavedKolam!, showToast: false);
    } else if (widget.initialSampleDesign != null) {
      _activeSampleDesign = widget.initialSampleDesign;
      _gridSize = widget.initialSampleDesign!.gridSize;
      _showReferenceLayer = true;
      _referenceOpacity = 0.35;
      _toolMode = StudioToolMode.freehand;
    }
  }

  void _loadSavedKolam(SavedKolam kolam, {bool showToast = true}) {
    setState(() {
      _gridSize = kolam.gridSize;
      _gridOrientation = kolam.gridOrientation;
      _selectedPaletteColor = KolamPaletteColor.fromColor(Color(kolam.colorValue));

      _tileStates.clear();
      _tileStates.addAll(kolam.tileStates);
      _tileUndoStack.clear();
      _tileRedoStack.clear();

      _strokes.clear();
      if (kolam.canvasStrokeData.isNotEmpty) {
        try {
          final list = jsonDecode(kolam.canvasStrokeData) as List;
          _strokes.addAll(list.map((item) => KolamStroke.fromJson(Map<String, dynamic>.from(item))));
        } catch (_) {}
      }
      _redoStack.clear();

      _placedShapes.clear();
      _lastAnalysis = kolam.analysisResult;
      _activeSampleDesign = null;
      _toolMode = StudioToolMode.joinCircles;
    });

    if (showToast && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.tulsiGreen,
          content: Text('Loaded "${kolam.name}" into Canvas!'),
        ),
      );
    }
  }

  List<Offset> _getGridDots(double canvasSize) {
    return KolamGridLayout.generateDots(
      canvasSize: canvasSize,
      gridSize: _gridSize,
      orientation: _gridOrientation,
    );
  }

  void _rebuildConnectivityGraph() {
    final dots = _getGridDots(350.0);
    _connectivityGraph.rebuild(
      gridDots: dots,
      shapes: _placedShapes,
    );
  }

  // --- 16-Tile & Circle Joining Logic ---

  void _saveTileUndoSnapshot() {
    _tileUndoStack.add(Map.from(_tileStates));
    _tileRedoStack.clear();
  }

  /// Toggles connection between circle A and B by updating their facing 16-tile corner bits
  void _toggleJoinCircles(int fromIndex, int toIndex) {
    final dots = _getGridDots(350.0);
    if (fromIndex >= dots.length || toIndex >= dots.length) return;

    final pA = dots[fromIndex];
    final pB = dots[toIndex];
    final delta = pB - pA;

    // Determine relative direction:
    // South (0): dy > |dx|
    // West (1): -dx > |dy|
    // North (2): -dy > |dx|
    // East (3): dx > |dy|
    int bitFrom;
    int bitTo;
    if (delta.dy.abs() >= delta.dx.abs()) {
      if (delta.dy > 0) {
        bitFrom = 0; // South
        bitTo = 2;   // North
      } else {
        bitFrom = 2; // North
        bitTo = 0;   // South
      }
    } else {
      if (delta.dx > 0) {
        bitFrom = 3; // East
        bitTo = 1;   // West
      } else {
        bitFrom = 1; // West
        bitTo = 3;   // East
      }
    }

    setState(() {
      _saveTileUndoSnapshot();

      final currentTileA = _tileStates[fromIndex] ?? Kolam16Tile.circle;
      final currentTileB = _tileStates[toIndex] ?? Kolam16Tile.circle;

      final isAlreadyConnected = currentTileA.mask & (1 << bitFrom) != 0 &&
          currentTileB.mask & (1 << bitTo) != 0;

      if (isAlreadyConnected) {
        // Disconnect both tips
        _tileStates[fromIndex] = currentTileA.setBit(bitFrom, false);
        _tileStates[toIndex] = currentTileB.setBit(bitTo, false);
      } else {
        // Connect both tips towards each other
        _tileStates[fromIndex] = currentTileA.setBit(bitFrom, true);
        _tileStates[toIndex] = currentTileB.setBit(bitTo, true);
      }

      _selectedCircleIndex = toIndex;
      _activeTilePaletteSelection = _tileStates[toIndex] ?? Kolam16Tile.circle;
    });

    _rebuildConnectivityGraph();
  }

  void _onCircleTapped(int dotIndex, int? quadrantBit) {
    if (_toolMode == StudioToolMode.joinCircles) {
      if (quadrantBit != null) {
        // Tapped a specific corner/quadrant: toggle that 1-bit point!
        setState(() {
          _saveTileUndoSnapshot();
          final current = _tileStates[dotIndex] ?? Kolam16Tile.circle;
          final updated = current.toggleBit(quadrantBit);
          _tileStates[dotIndex] = updated;
          _activeTilePaletteSelection = updated;
          _selectedCircleIndex = dotIndex;
        });
      } else {
        // Tapped center of circle: select or cycle
        setState(() {
          if (_selectedCircleIndex == null) {
            _selectedCircleIndex = dotIndex;
            _activeTilePaletteSelection = _tileStates[dotIndex] ?? Kolam16Tile.circle;
          } else if (_selectedCircleIndex == dotIndex) {
            // Cycle tile shape
            _saveTileUndoSnapshot();
            final current = _tileStates[dotIndex] ?? Kolam16Tile.circle;
            final nextMask = (current.mask + 1) % 16;
            final updated = Kolam16Tile(nextMask);
            _tileStates[dotIndex] = updated;
            _activeTilePaletteSelection = updated;
          } else {
            // Join previously selected circle to this circle
            _toggleJoinCircles(_selectedCircleIndex!, dotIndex);
          }
        });
      }
    }
  }

  // --- Canvas Gestures (Pan & Drag) ---

  void _onCanvasPanStart(Offset point) {
    if (_toolMode == StudioToolMode.shapes) {
      PlacedKolamShape? hitShape;
      for (final shape in _placedShapes.reversed) {
        if ((shape.position - point).distance <= (shape.size * 0.7)) {
          hitShape = shape;
          break;
        }
      }

      setState(() {
        if (hitShape != null) {
          _selectedShapeId = hitShape.id;
          _dragStartShapePos = hitShape.position;
          _dragStartTouchPos = point;
        } else {
          _selectedShapeId = null;
          _dragStartShapePos = null;
          _dragStartTouchPos = null;
        }
      });
    } else if (_toolMode == StudioToolMode.freehand) {
      setState(() {
        _redoStack.clear();
        _activeStroke = KolamStroke(
          points: [KolamPoint(point.dx, point.dy)],
          colorValue: _selectedColor.toARGB32(),
          strokeWidth: _strokeWidth,
        );
      });
    } else if (_toolMode == StudioToolMode.joinCircles) {
      final dots = _getGridDots(350.0);
      final ringRadius = KolamGridLayout.getRingRadius(350.0, _gridSize, _gridOrientation);
      final hit = KolamGridLayout.findHitCircleDot(tapPos: point, dots: dots, ringRadius: ringRadius);
      if (hit != null) {
        setState(() {
          _selectedCircleIndex = hit;
          _activeTilePaletteSelection = _tileStates[hit] ?? Kolam16Tile.circle;
        });
      }
    }
  }

  void _onCanvasPanUpdate(Offset point) {
    if (_toolMode == StudioToolMode.shapes) {
      if (_selectedShapeId != null && _dragStartShapePos != null && _dragStartTouchPos != null) {
        final delta = point - _dragStartTouchPos!;
        final tentativePos = _dragStartShapePos! + delta;
        final index = _placedShapes.indexWhere((s) => s.id == _selectedShapeId);
        if (index != -1) {
          final oldShape = _placedShapes[index];
          final movedShape = oldShape.copyWith(position: tentativePos);

          final dots = _getGridDots(350.0);
          final snap = _connectivityGraph.evaluateSnap(
            shape: movedShape,
            gridDots: dots,
          );

          setState(() {
            if (snap != null) {
              _placedShapes[index] = movedShape.copyWith(position: snap.snappedShapePosition);
              _snapHighlightPoint = snap.snappedAnchorPoint;
            } else {
              _placedShapes[index] = movedShape;
              _snapHighlightPoint = null;
            }
          });
        }
      }
    } else if (_toolMode == StudioToolMode.freehand) {
      if (_activeStroke == null) return;
      setState(() {
        final updatedPoints = List<KolamPoint>.from(_activeStroke!.points)
          ..add(KolamPoint(point.dx, point.dy));

        _activeStroke = KolamStroke(
          points: updatedPoints,
          colorValue: _selectedColor.toARGB32(),
          strokeWidth: _strokeWidth,
        );
      });
    } else if (_toolMode == StudioToolMode.joinCircles) {
      final dots = _getGridDots(350.0);
      final ringRadius = KolamGridLayout.getRingRadius(350.0, _gridSize, _gridOrientation);
      final hit = KolamGridLayout.findHitCircleDot(tapPos: point, dots: dots, ringRadius: ringRadius);
      if (hit != null && _selectedCircleIndex != null && hit != _selectedCircleIndex) {
        _toggleJoinCircles(_selectedCircleIndex!, hit);
      }
    }
  }

  void _onCanvasPanEnd() {
    if (_toolMode == StudioToolMode.shapes) {
      _dragStartShapePos = null;
      _dragStartTouchPos = null;
      _snapHighlightPoint = null;
      _rebuildConnectivityGraph();
      setState(() {});
    } else if (_toolMode == StudioToolMode.freehand) {
      if (_activeStroke == null || _activeStroke!.points.isEmpty) return;

      setState(() {
        if (_symmetryMode == SymmetryDrawMode.none) {
          _strokes.add(_activeStroke!);
        } else {
          final mirroredStrokes = _generateSymmetricStrokes(_activeStroke!, _symmetryMode);
          _strokes.addAll(mirroredStrokes);
        }
        _activeStroke = null;
      });
    }
  }

  // --- Shape Placement & Manipulation ---

  void _onShapeDropped(KolamShapePrimitive primitive, Offset dropOffset) {
    final id = const Uuid().v4();
    final defaultSize = (350.0 / (_gridSize + 1) * 1.5).clamp(55.0, 95.0);

    final newShape = PlacedKolamShape(
      id: id,
      primitiveId: primitive.id,
      position: dropOffset,
      size: defaultSize,
      colorValue: _selectedColor.toARGB32(),
      strokeWidth: _strokeWidth,
    );

    final dots = _getGridDots(350.0);
    final snap = _connectivityGraph.evaluateSnap(
      shape: newShape,
      gridDots: dots,
    );

    final finalShape = snap != null
        ? newShape.copyWith(position: snap.snappedShapePosition)
        : newShape;

    setState(() {
      _placedShapes.add(finalShape);
      _selectedShapeId = id;
      if (snap != null) {
        _snapHighlightPoint = snap.snappedAnchorPoint;
        Future.delayed(const Duration(milliseconds: 600), () {
          if (mounted) setState(() => _snapHighlightPoint = null);
        });
      }
    });

    _rebuildConnectivityGraph();
  }

  void _onShapeSelectedFromPalette(KolamShapePrimitive primitive) {
    final center = const Offset(175, 175);
    final stepOffset = _placedShapes.isEmpty
        ? Offset.zero
        : Offset(
            ((_placedShapes.length % 3) - 1) * 35.0,
            ((_placedShapes.length % 3) - 1) * 35.0,
          );
    _onShapeDropped(primitive, center + stepOffset);
  }

  void _onShapeRotated(String shapeId) {
    final index = _placedShapes.indexWhere((s) => s.id == shapeId);
    if (index == -1) return;

    setState(() {
      final shape = _placedShapes[index];
      final nextRotation = (shape.rotationDegrees + 45) % 360;
      _placedShapes[index] = shape.copyWith(rotationDegrees: nextRotation);
    });

    _rebuildConnectivityGraph();
  }

  void _onShapeDeleted(String shapeId) {
    setState(() {
      _placedShapes.removeWhere((s) => s.id == shapeId);
      if (_selectedShapeId == shapeId) {
        _selectedShapeId = null;
      }
    });

    _rebuildConnectivityGraph();
  }

  List<KolamStroke> _generateSymmetricStrokes(KolamStroke baseStroke, SymmetryDrawMode mode) {
    if (baseStroke.points.isEmpty) return [baseStroke];

    const cx = 175.0;
    const cy = 175.0;

    final results = <KolamStroke>[baseStroke];

    if (mode == SymmetryDrawMode.bilateralVertical || mode == SymmetryDrawMode.fourFoldRadial) {
      final mirroredPoints = baseStroke.points.map((p) {
        final dx = p.x - cx;
        return KolamPoint(cx - dx, p.y);
      }).toList();
      results.add(KolamStroke(
        points: mirroredPoints,
        colorValue: baseStroke.colorValue,
        strokeWidth: baseStroke.strokeWidth,
      ));
    }

    if (mode == SymmetryDrawMode.bilateralHorizontal || mode == SymmetryDrawMode.fourFoldRadial) {
      final originalList = List<KolamStroke>.from(results);
      for (final s in originalList) {
        final mirroredPoints = s.points.map((p) {
          final dy = p.y - cy;
          return KolamPoint(p.x, cy - dy);
        }).toList();
        results.add(KolamStroke(
          points: mirroredPoints,
          colorValue: s.colorValue,
          strokeWidth: s.strokeWidth,
        ));
      }
    }

    return results;
  }

  // --- Grid Stepper Methods ---

  bool get _canDecreaseGrid {
    return _gridSize > 1;
  }

  bool get _canIncreaseGrid {
    return _gridSize < 9;
  }

  void _decreaseGrid() {
    if (!_canDecreaseGrid) return;
    setState(() {
      _saveTileUndoSnapshot();
      if (_gridOrientation == KolamGridOrientation.square) {
        _gridSize = max(1, _gridSize - 1);
      } else {
        _gridSize = max(1, _gridSize - 2);
      }
      _tileStates.clear();
      _selectedCircleIndex = null;
    });
    _rebuildConnectivityGraph();
  }

  void _increaseGrid() {
    if (!_canIncreaseGrid) return;
    setState(() {
      _saveTileUndoSnapshot();
      if (_gridOrientation == KolamGridOrientation.square) {
        _gridSize = min(9, _gridSize + 1);
      } else {
        _gridSize = min(9, _gridSize + 2);
      }
      _tileStates.clear();
      _selectedCircleIndex = null;
    });
    _rebuildConnectivityGraph();
  }

  // --- Undo / Redo / Clear ---

  bool get _canUndo => _tileUndoStack.isNotEmpty || _tileStates.isNotEmpty;

  bool get _canRedo => _tileRedoStack.isNotEmpty;

  void _undo() {
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
    _rebuildConnectivityGraph();
  }

  void _redo() {
    if (_tileRedoStack.isNotEmpty) {
      setState(() {
        _tileUndoStack.add(Map.from(_tileStates));
        _tileStates.clear();
        _tileStates.addAll(_tileRedoStack.removeLast());
      });
      _rebuildConnectivityGraph();
    }
  }

  void _clear() {
    if (_tileStates.isEmpty) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Canvas?'),
        content: const Text('Are you sure you want to reset all tiles to pure circles?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              setState(() {
                _saveTileUndoSnapshot();
                _tileStates.clear();
                _selectedCircleIndex = null;
                _lastAnalysis = null;
              });
              _rebuildConnectivityGraph();
            },
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  // --- Smart AI Analysis & Saving ---

  List<KolamStroke> _getAllStrokes() {
    final dots = _getGridDots(350.0);
    final rowCount = _gridOrientation == KolamGridOrientation.square
        ? _gridSize
        : KolamGridLayout.getDiamondRowCounts(_gridSize).length;
    final step = 350.0 / (rowCount + 1);
    final ringRadius = KolamGridLayout.getRingRadius(350.0, _gridSize, _gridOrientation);
    final pointDistance = step * 0.50;

    // Convert 16-tile shapes to strokes
    final tileStrokes = <KolamStroke>[];
    for (int i = 0; i < dots.length; i++) {
      final tile = _tileStates[i] ?? Kolam16Tile.circle;
      tileStrokes.add(tile.toStroke(
        center: dots[i],
        ringRadius: ringRadius,
        pointDistance: pointDistance,
        color: _selectedColor,
        strokeWidth: _strokeWidth,
      ));
    }

    final placedStrokes = _placedShapes.map((s) => s.toStroke()).toList();
    return [..._strokes, ...tileStrokes, ...placedStrokes];
  }

  Future<void> _runSmartAnalysis() async {
    final allStrokes = _getAllStrokes();

    if (allStrokes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Create or customize tile shapes on the canvas to analyze sacred geometry.')),
      );
      return;
    }

    setState(() {
      _isAnalyzing = true;
    });

    final analyzer = ref.read(analysisServiceProvider);
    final data = KolamData(
      strokes: allStrokes,
      placedShapes: _placedShapes,
      connectivityGraph: _connectivityGraph,
      gridSize: _gridSize,
      canvasSize: const Size(350, 350),
    );

    final result = await analyzer.analyze(data);

    final gamification = ref.read(gamificationServiceProvider);
    await gamification.awardXp(30, 'Analyse Kolam');
    ref.read(userProfileProvider.notifier).refresh();

    if (mounted) {
      setState(() {
        _lastAnalysis = result;
        _isAnalyzing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.slateDark,
          content: Row(
            children: [
              const Icon(Icons.auto_awesome_rounded, color: AppColors.turmericGold, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '✨ Kolam Analysed! +30 XP • ${result.complexityScore}/100 (${result.complexityTier})',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          duration: const Duration(seconds: 3),
        ),
      );

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => SmartAnalysisSheet(
          result: result,
          onSavePressed: () {
            Navigator.of(context).pop();
            _promptSaveKolam(result);
          },
        ),
      );
    }
  }

  void _promptSaveKolam([AnalysisResult? analysis]) {
    final allStrokes = _getAllStrokes();
    final nonCircleTiles = _tileStates.values.where((t) => t.mask != 0).length;
    final hasContent = nonCircleTiles > 0 || _strokes.isNotEmpty || _placedShapes.isNotEmpty || _activeSampleDesign != null;

    if (!hasContent) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot save an empty canvas! Draw or tap nodes to create your Kolam.')),
      );
      return;
    }

    final isTraced = _activeSampleDesign != null;
    final defaultName = isTraced
        ? 'Traced ${_activeSampleDesign!.name}'
        : (nonCircleTiles > 0
            ? '${_gridOrientation == KolamGridOrientation.diamond ? "Diamond" : "Square"} ${_gridSize}x$_gridSize Sikku ($nonCircleTiles Nodes)'
            : 'Kolam ${allStrokes.length} Strokes');

    final culturalTag = isTraced
        ? 'Traced: ${_activeSampleDesign!.name}'
        : (_gridOrientation == KolamGridOrientation.diamond ? 'Diamond Sikku Kolam' : 'Square 16-Tile Sikku Kolam');

    final nameController = TextEditingController(text: defaultName);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Save Kolam to Collection'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Kolam Name',
            hintText: 'e.g. 16-Tile Sikku Lotus',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              final id = const Uuid().v4();
              final strokeJson = jsonEncode(_strokes.map((s) => s.toJson()).toList());
              final tileStatesJson = jsonEncode(_tileStates.map((k, v) => MapEntry(k.toString(), v.mask)));

              final newKolam = SavedKolam(
                id: id,
                name: nameController.text.trim().isEmpty ? defaultName : nameController.text.trim(),
                createdDate: DateTime.now(),
                canvasStrokeData: strokeJson,
                gridSize: _gridSize,
                orientation: _gridOrientation.name,
                colorValue: _selectedColor.toARGB32(),
                tileStatesData: tileStatesJson,
                complexityScore: analysis?.complexityScore ?? _lastAnalysis?.complexityScore ?? (nonCircleTiles * 6 + 20).clamp(20, 95),
                symmetryResult: analysis ?? _lastAnalysis,
                culturalTag: culturalTag,
                sourceSampleId: isTraced ? _activeSampleDesign!.id : null,
              );

              await ref.read(savedKolamsProvider.notifier).save(newKolam);

              await ref.read(userProfileProvider.notifier).onKolamCreated(
                hasAnalysis: (analysis != null || _lastAnalysis != null),
              );

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: AppColors.tulsiGreen,
                    content: Text(
                      isTraced ? 'Traced Kolam Saved! (+40 XP)' : 'Original 16-Tile Kolam Saved! (+40 XP)',
                    ),
                  ),
                );
              }
            },
            child: const Text('Save (+40 XP)'),
          ),
        ],
      ),
    );
  }

  String _formatSymmetryName(SymmetryType type) {
    switch (type) {
      case SymmetryType.dihedralD4:
        return '4-Fold Mandala (D4)';
      case SymmetryType.twoFoldReflection:
        return '2-Fold Biharmonic (D2)';
      case SymmetryType.fourFoldReflection:
        return '4-Fold Reflection';
      case SymmetryType.rotational90:
        return '4-Fold Swirl (C4)';
      case SymmetryType.rotational180:
        return '2-Fold Rotational (C2)';
      case SymmetryType.bilateralReflection:
        return 'Bilateral Mirror';
      case SymmetryType.none:
        return 'Organic Freeform';
    }
  }

  // --- UI Builders ---

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kolam Creative Studio'),
        actions: [
          IconButton(
            tooltip: 'Saved Kolams',
            icon: const Icon(Icons.collections_bookmark_rounded),
            onPressed: () async {
              final selectedKolam = await Navigator.of(context).push<SavedKolam>(
                MaterialPageRoute(builder: (_) => const MyKolamsGalleryScreen()),
              );
              if (selectedKolam != null && mounted) {
                _loadSavedKolam(selectedKolam);
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Top Action Toolbar (Undo / Redo on left, Grid Stepper in middle, Clear Canvas in Red on right)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? AppColors.slateCard : AppColors.riceFlourCard,
              border: Border(
                bottom: BorderSide(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                ),
              ),
            ),
            child: Row(
              children: [
                // Left: Undo / Redo
                IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.all(6),
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.undo_rounded, size: 20),
                  tooltip: 'Undo',
                  onPressed: _canUndo ? _undo : null,
                ),
                const SizedBox(width: 8),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.all(6),
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.redo_rounded, size: 20),
                  tooltip: 'Redo',
                  onPressed: _canRedo ? _redo : null,
                ),

                const Spacer(),

                // Middle: Interactive Grid Stepper with + and - buttons
                Text(
                  'Grid: ',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : AppColors.textMuted,
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.remove_circle_outline_rounded, size: 20),
                  tooltip: _gridOrientation == KolamGridOrientation.square
                      ? 'Decrease Grid (-1)'
                      : 'Decrease Diamond Grid (-2)',
                  color: _canDecreaseGrid
                      ? (isDark ? Colors.white : AppColors.terracottaRed)
                      : (isDark ? Colors.white24 : Colors.black26),
                  onPressed: _canDecreaseGrid ? _decreaseGrid : null,
                ),
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.slateLight : AppColors.borderLight,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isDark ? AppColors.borderDark : AppColors.borderLight,
                    ),
                  ),
                  child: Text(
                    '${_gridSize}x$_gridSize',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: isDark ? Colors.white : AppColors.textDark,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
                  tooltip: _gridOrientation == KolamGridOrientation.square
                      ? 'Increase Grid (+1)'
                      : 'Increase Diamond Grid (+2)',
                  color: _canIncreaseGrid
                      ? (isDark ? Colors.white : AppColors.terracottaRed)
                      : (isDark ? Colors.white24 : Colors.black26),
                  onPressed: _canIncreaseGrid ? _increaseGrid : null,
                ),

                const Spacer(),

                // Rightmost: Clear Canvas (in RED)
                IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.all(6),
                  constraints: const BoxConstraints(),
                  icon: Icon(
                    Icons.delete_sweep_rounded,
                    size: 20,
                    color: _tileStates.isNotEmpty
                        ? Colors.redAccent
                        : (isDark ? Colors.redAccent.withValues(alpha: 0.35) : Colors.red.withValues(alpha: 0.35)),
                  ),
                  tooltip: 'Clear Canvas',
                  onPressed: _tileStates.isNotEmpty ? _clear : null,
                ),
              ],
            ),
          ),

          // Central Canvas Area
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  KolamCanvasWidget(
                    gridSize: _gridSize,
                    orientation: _gridOrientation,
                    showDots: _showDots,
                    canvasTheme: _canvasTheme,
                    kolamColor: _selectedColor,
                    tileStates: _tileStates,
                    strokes: _strokes,
                    activeStroke: _activeStroke,
                    symmetryMode: _symmetryMode,
                    selectedCircleIndex: _selectedCircleIndex,
                    isShapesMode: _toolMode == StudioToolMode.shapes,
                    placedShapes: _placedShapes,
                    selectedShapeId: _selectedShapeId,
                    snapHighlightPoint: _snapHighlightPoint,
                    referenceStrokes: _activeSampleDesign?.strokes,
                    showReferenceLayer: _showReferenceLayer && _activeSampleDesign != null,
                    referenceOpacity: _referenceOpacity,
                    onPanStart: _onCanvasPanStart,
                    onPanUpdate: _onCanvasPanUpdate,
                    onPanEnd: _onCanvasPanEnd,
                    onJoinCircles: _toggleJoinCircles,
                    onCircleTapped: _onCircleTapped,
                    onShapeDropped: _onShapeDropped,
                    onShapeSelected: (id) => setState(() => _selectedShapeId = id),
                    onShapeRotated: _onShapeRotated,
                    onShapeDeleted: _onShapeDeleted,
                  ),
                  if (_isAnalyzing)
                    Container(
                      color: Colors.black54,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(color: AppColors.turmericGold),
                            const SizedBox(height: 12),
                            Text(
                              'Analyzing Sacred Geometry...',
                              style: AppTypography.cardTitle.copyWith(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Green Floating Button for Download / Save option
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: FloatingActionButton(
                      heroTag: 'download_kolam_btn',
                      backgroundColor: AppColors.tulsiGreen,
                      foregroundColor: Colors.white,
                      tooltip: 'Download Kolam',
                      onPressed: () => _promptSaveKolam(_lastAnalysis),
                      child: const Icon(Icons.download_rounded, size: 26),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Control Bar: Color Palette & Layout Selector
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? AppColors.slateCard : AppColors.riceFlourCard,
              border: Border(
                top: BorderSide(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                ),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Color Palette Row: Basic (White/Black), Red, Green, Yellow, Blue, Brown (Theme-Adaptive Light & Dark Shades)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Color:',
                        style: AppTypography.cardTitle.copyWith(fontSize: 12),
                      ),
                      const SizedBox(width: 8),
                      ...KolamPaletteColor.values.map((paletteColor) {
                        final isSelected = _selectedPaletteColor == paletteColor;
                        final shade = paletteColor.getShade(isDark);

                        return Tooltip(
                          message: '${paletteColor.getDisplayName(isDark)} (${isDark ? "Dark Theme" : "Light Theme"})',
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedPaletteColor = paletteColor;
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              margin: const EdgeInsets.symmetric(horizontal: 5),
                              width: isSelected ? 28 : 22,
                              height: isSelected ? 28 : 22,
                              decoration: BoxDecoration(
                                color: shade,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.turmericGold
                                      : (isDark ? Colors.white30 : Colors.black26),
                                  width: isSelected ? 2.5 : 1.2,
                                ),
                                boxShadow: [
                                  if (isSelected)
                                    BoxShadow(
                                      color: shade.withValues(alpha: 0.6),
                                      blurRadius: 8,
                                      spreadRadius: 1.5,
                                    ),
                                ],
                              ),
                              child: isSelected
                                  ? Icon(
                                      Icons.check,
                                      size: 14,
                                      color: shade.computeLuminance() > 0.55
                                          ? Colors.black87
                                          : Colors.white,
                                    )
                                  : null,
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 6),

                // Layout / Orientation Selector (Square vs Diamond)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Layout:',
                      style: AppTypography.cardTitle.copyWith(fontSize: 12),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                      labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                      label: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.grid_on_rounded, size: 13),
                          SizedBox(width: 4),
                          Text('Square (Mat)', style: TextStyle(fontSize: 11)),
                        ],
                      ),
                      selected: _gridOrientation == KolamGridOrientation.square,
                      onSelected: (val) {
                        if (val) {
                          setState(() {
                            _gridOrientation = KolamGridOrientation.square;
                            _tileStates.clear();
                            _selectedCircleIndex = null;
                          });
                          _rebuildConnectivityGraph();
                        }
                      },
                    ),
                    const SizedBox(width: 6),
                    ChoiceChip(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                      labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                      label: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.diamond_outlined, size: 13),
                          SizedBox(width: 4),
                          Text('Diamond (Pulli)', style: TextStyle(fontSize: 11)),
                        ],
                      ),
                      selected: _gridOrientation == KolamGridOrientation.diamond,
                      onSelected: (val) {
                        if (val) {
                          setState(() {
                            _gridOrientation = KolamGridOrientation.diamond;
                            if (_gridSize % 2 == 0) {
                              _gridSize = (_gridSize + 1).clamp(1, 9);
                            }
                            _tileStates.clear();
                            _selectedCircleIndex = null;
                          });
                          _rebuildConnectivityGraph();
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

