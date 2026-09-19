import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../data/models/saved_kolam.dart';
import '../../data/models/analysis_result.dart';
import '../../data/models/kolam_shape_primitive.dart';
import '../../data/models/sample_kolam_design.dart';
import '../../data/seed/sample_designs_library.dart';
import '../../providers/app_providers.dart';
import '../../services/analysis_service.dart';
import '../../services/connectivity_graph_service.dart';
import 'widgets/kolam_canvas_widget.dart';
import 'widgets/shape_palette_widget.dart';
import 'widgets/smart_analysis_sheet.dart';
import 'my_kolams_gallery_screen.dart';
import 'sample_designs_gallery_screen.dart';

enum StudioBottomTab { draw, dots, tools, ai }

class CreateStudioScreen extends ConsumerStatefulWidget {
  final SampleKolamDesign? initialSampleDesign;

  const CreateStudioScreen({
    super.key,
    this.initialSampleDesign,
  });

  @override
  ConsumerState<CreateStudioScreen> createState() => _CreateStudioScreenState();
}

class _CreateStudioScreenState extends ConsumerState<CreateStudioScreen> {
  int _gridSize = 5; // 5, 7, 9
  bool _showDots = true;
  Color _selectedColor = AppColors.drawingPigments.first;
  double _strokeWidth = 3.5;
  SymmetryDrawMode _symmetryMode = SymmetryDrawMode.none;

  // Freehand drawing state
  final List<KolamStroke> _strokes = [];
  final List<KolamStroke> _redoStack = [];
  KolamStroke? _activeStroke;

  // Shape-based construction mode state
  bool _isShapesMode = false;
  final List<PlacedKolamShape> _placedShapes = [];
  String? _selectedShapeId;
  Offset? _snapHighlightPoint;
  final KolamConnectivityGraph _connectivityGraph = KolamConnectivityGraph();

  // Ghost Trace Mode state
  SampleKolamDesign? _activeSampleDesign;
  bool _showReferenceLayer = true;
  double _referenceOpacity = 0.35;

  // Shape drag state
  Offset? _dragStartShapePos;
  Offset? _dragStartTouchPos;

  StudioBottomTab _activeTab = StudioBottomTab.draw;
  AnalysisResult? _lastAnalysis;
  bool _isAnalyzing = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialSampleDesign != null) {
      _activeSampleDesign = widget.initialSampleDesign;
      _gridSize = widget.initialSampleDesign!.gridSize;
      _showReferenceLayer = true;
      _referenceOpacity = 0.35;
    }
  }

  List<Offset> _getGridDots(double canvasSize) {
    final step = canvasSize / (_gridSize + 1);
    final dots = <Offset>[];
    for (int r = 1; r <= _gridSize; r++) {
      for (int c = 1; c <= _gridSize; c++) {
        dots.add(Offset(c * step, r * step));
      }
    }
    return dots;
  }

  void _rebuildConnectivityGraph() {
    final dots = _getGridDots(350.0);
    _connectivityGraph.rebuild(
      gridDots: dots,
      shapes: _placedShapes,
    );
  }

  // --- Pan handling for Freehand vs Shapes Mode ---

  void _onCanvasPanStart(Offset point) {
    if (_isShapesMode) {
      // Find if touch hit any placed shape
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
    } else {
      setState(() {
        _redoStack.clear();
        _activeStroke = KolamStroke(
          points: [KolamPoint(point.dx, point.dy)],
          colorValue: _selectedColor.toARGB32(),
          strokeWidth: _strokeWidth,
        );
      });
    }
  }

  void _onCanvasPanUpdate(Offset point) {
    if (_isShapesMode) {
      if (_selectedShapeId != null && _dragStartShapePos != null && _dragStartTouchPos != null) {
        final delta = point - _dragStartTouchPos!;
        final tentativePos = _dragStartShapePos! + delta;
        final index = _placedShapes.indexWhere((s) => s.id == _selectedShapeId);
        if (index != -1) {
          final oldShape = _placedShapes[index];
          final movedShape = oldShape.copyWith(position: tentativePos);

          // Live magnetic snap check against grid dots and other shape anchors
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
    } else {
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
    }
  }

  void _onCanvasPanEnd() {
    if (_isShapesMode) {
      _dragStartShapePos = null;
      _dragStartTouchPos = null;
      _snapHighlightPoint = null;
      _rebuildConnectivityGraph();
      setState(() {});
    } else {
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

  // --- Shape Placement, Manipulation & Topology ---

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

    // Initial snap check
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
    // Tapping palette places the primitive in canvas center or stepped offset
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

  void _undo() {
    if (_isShapesMode) {
      if (_placedShapes.isNotEmpty) {
        setState(() {
          final removed = _placedShapes.removeLast();
          if (_selectedShapeId == removed.id) {
            _selectedShapeId = null;
          }
        });
        _rebuildConnectivityGraph();
      }
    } else {
      if (_strokes.isNotEmpty) {
        setState(() {
          _redoStack.add(_strokes.removeLast());
        });
      }
    }
  }

  void _redo() {
    if (!_isShapesMode && _redoStack.isNotEmpty) {
      setState(() {
        _strokes.add(_redoStack.removeLast());
      });
    }
  }

  void _clear() {
    if (_strokes.isEmpty && _placedShapes.isEmpty) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Canvas?'),
        content: const Text('Are you sure you want to erase all current Kolam lines and placed shapes?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              setState(() {
                _strokes.clear();
                _placedShapes.clear();
                _selectedShapeId = null;
                _redoStack.clear();
                _activeStroke = null;
                _lastAnalysis = null;
                _snapHighlightPoint = null;
              });
              _rebuildConnectivityGraph();
            },
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  Future<void> _runSmartAnalysis() async {
    final allStrokes = [..._strokes, ..._placedShapes.map((s) => s.toStroke())];

    if (allStrokes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Draw lines or place primitives on the canvas to analyze sacred geometry.')),
      );
      return;
    }

    setState(() {
      _isAnalyzing = true;
    });

    final analyzer = ref.read(analysisServiceProvider);
    final data = KolamData(
      strokes: _strokes,
      placedShapes: _placedShapes,
      connectivityGraph: _connectivityGraph,
      gridSize: _gridSize,
      canvasSize: const Size(350, 350),
    );

    final result = await analyzer.analyze(data);

    // Call GamificationService.awardXp(30, "Analyse Kolam")
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

  void _openSampleGallery() async {
    final selected = await Navigator.of(context).push<SampleKolamDesign>(
      MaterialPageRoute(
        builder: (_) => SampleDesignsGalleryScreen(
          onSelectSample: (design) {
            _loadSampleDesign(design);
          },
        ),
      ),
    );
    if (selected != null && mounted) {
      _loadSampleDesign(selected);
    }
  }

  void _loadSampleDesign(SampleKolamDesign design) {
    if (_strokes.isNotEmpty || _placedShapes.isNotEmpty) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Start Tracing Pattern?'),
          content: Text(
            'Load "${design.name}" as reference? Canvas will adjust to ${design.gridSize}x${design.gridSize} pulli grid.',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                setState(() {
                  _activeSampleDesign = design;
                  _gridSize = design.gridSize;
                  _showReferenceLayer = true;
                  _referenceOpacity = 0.35;
                  _strokes.clear();
                  _placedShapes.clear();
                  _selectedShapeId = null;
                  _redoStack.clear();
                  _activeStroke = null;
                  _lastAnalysis = null;
                  _snapHighlightPoint = null;
                });
                _rebuildConnectivityGraph();
              },
              child: const Text('Start Tracing'),
            ),
          ],
        ),
      );
    } else {
      setState(() {
        _activeSampleDesign = design;
        _gridSize = design.gridSize;
        _showReferenceLayer = true;
        _referenceOpacity = 0.35;
      });
      _rebuildConnectivityGraph();
    }
  }

  void _checkTracingAccuracy() async {
    if (_activeSampleDesign == null) return;

    final userStrokes = [..._strokes, ..._connectivityGraph.getMergedStrokes()];
    final result = SampleDesignsLibrary.evaluateTracingMatch(
      userStrokes: userStrokes,
      targetStrokes: _activeSampleDesign!.strokes,
    );

    if (result.awardedXP > 0) {
      await ref.read(userProfileProvider.notifier).awardXp(
            result.awardedXP,
            'Traced ${_activeSampleDesign!.name}',
          );
    }

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.fact_check_rounded, color: AppColors.turmericAmber),
            const SizedBox(width: 8),
            const Text('Tracing Accuracy'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.terracottaRed.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${result.matchPercentage}%',
                  style: AppTypography.displayTitle.copyWith(
                    color: AppColors.terracottaRed,
                    fontSize: 32,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              result.feedback,
              style: AppTypography.bodyText.copyWith(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Coverage:', style: AppTypography.caption),
                Text(
                  '${(result.coverageRatio * 100).round()}% points traced',
                  style: AppTypography.tagText,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Reward:', style: AppTypography.caption),
                Text(
                  '+${result.awardedXP} XP',
                  style: AppTypography.tagText.copyWith(color: AppColors.tulsiGreen),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Continue Tracing'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _promptSaveKolam(_lastAnalysis);
            },
            child: const Text('Save Kolam'),
          ),
        ],
      ),
    );
  }

  void _promptSaveKolam([AnalysisResult? analysis]) {
    final mergedShapeStrokes = _connectivityGraph.getMergedStrokes();
    final allStrokes = [..._strokes, ...mergedShapeStrokes];

    if (allStrokes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot save an empty canvas!')),
      );
      return;
    }

    final isTraced = _activeSampleDesign != null;
    final defaultName = isTraced
        ? 'Traced ${_activeSampleDesign!.name}'
        : (_isShapesMode ? 'Kolam ${_placedShapes.length} Primitives' : 'Kolam ${allStrokes.length} Strokes');

    final culturalTag = isTraced
        ? 'Traced: ${_activeSampleDesign!.name}'
        : (_isShapesMode ? 'Constructed Kolam Primitives' : 'Original Studio Creation');

    final nameController = TextEditingController(text: defaultName);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Save Kolam to Collection'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Kolam Name',
            hintText: 'e.g. Morning Lotus Sikku',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              final id = const Uuid().v4();
              final strokeJson = jsonEncode(allStrokes.map((s) => s.toJson()).toList());

              final newKolam = SavedKolam(
                id: id,
                name: nameController.text.trim().isEmpty ? defaultName : nameController.text.trim(),
                createdDate: DateTime.now(),
                canvasStrokeData: strokeJson,
                gridSize: _gridSize,
                complexityScore: analysis?.complexityScore ?? _lastAnalysis?.complexityScore ?? (allStrokes.length * 5).clamp(10, 85),
                symmetryResult: analysis ?? _lastAnalysis,
                culturalTag: culturalTag,
                sourceSampleId: isTraced ? _activeSampleDesign!.id : null, // Distinct from original freehand
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
                      isTraced ? 'Traced Kolam Saved! (+40 XP)' : 'Original Kolam Saved! (+40 XP)',
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kolam Creative Studio'),
        actions: [
          IconButton(
            tooltip: 'Sample Designs Gallery',
            icon: const Icon(Icons.auto_stories_rounded),
            onPressed: _openSampleGallery,
          ),
          IconButton(
            tooltip: 'My Kolams Gallery',
            icon: const Icon(Icons.collections_bookmark_rounded),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const MyKolamsGalleryScreen()),
              );
            },
          ),
          IconButton(
            tooltip: 'Save Kolam',
            icon: const Icon(Icons.save_alt_rounded),
            onPressed: () => _promptSaveKolam(_lastAnalysis),
          ),
        ],
      ),
      body: Column(
        children: [
          // Top Controls Bar (Undo/Redo/Clear + Mode Switch + Mirror Toggle/Graph Badge)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: isDark ? AppColors.slateCard : AppColors.riceFlourCard,
              border: Border(
                bottom: BorderSide(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                ),
              ),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  // Undo / Redo / Clear
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.all(6),
                        constraints: const BoxConstraints(),
                        icon: const Icon(Icons.undo_rounded, size: 20),
                        tooltip: 'Undo',
                        onPressed: (_isShapesMode ? _placedShapes.isNotEmpty : _strokes.isNotEmpty)
                            ? _undo
                            : null,
                      ),
                      const SizedBox(width: 4),
                      if (!_isShapesMode) ...[
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.all(6),
                          constraints: const BoxConstraints(),
                          icon: const Icon(Icons.redo_rounded, size: 20),
                          tooltip: 'Redo',
                          onPressed: _redoStack.isNotEmpty ? _redo : null,
                        ),
                        const SizedBox(width: 4),
                      ],
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.all(6),
                        constraints: const BoxConstraints(),
                        icon: const Icon(Icons.delete_sweep_rounded, size: 20),
                        tooltip: 'Clear',
                        onPressed: (_strokes.isNotEmpty || _placedShapes.isNotEmpty) ? _clear : null,
                      ),
                    ],
                  ),
                  const SizedBox(width: 10),

                  // Mode Switch Segmented Pill: [ ✏️ Freehand | 🧩 Shapes ]
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.slateLight : AppColors.borderLight,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isDark ? AppColors.borderDark : AppColors.borderLight,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildModePill(
                          label: 'Freehand',
                          icon: Icons.edit_rounded,
                          isSelected: !_isShapesMode,
                          onTap: () {
                            setState(() {
                              _isShapesMode = false;
                              _selectedShapeId = null;
                            });
                          },
                        ),
                        _buildModePill(
                          label: 'Shapes',
                          icon: Icons.category_rounded,
                          isSelected: _isShapesMode,
                          onTap: () {
                            setState(() {
                              _isShapesMode = true;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Right side control: Live Mirror Symmetry (in Freehand) or Snap Topology Badge (in Shapes)
                  if (!_isShapesMode)
                    PopupMenuButton<SymmetryDrawMode>(
                      initialValue: _symmetryMode,
                      tooltip: 'Live Mirror Symmetry Mode',
                      onSelected: (mode) => setState(() => _symmetryMode = mode),
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: SymmetryDrawMode.none,
                          child: Text('Mirror: Off (Freehand)'),
                        ),
                        const PopupMenuItem(
                          value: SymmetryDrawMode.bilateralVertical,
                          child: Text('Mirror: 2-Axis (Vertical)'),
                        ),
                        const PopupMenuItem(
                          value: SymmetryDrawMode.bilateralHorizontal,
                          child: Text('Mirror: 2-Axis (Horizontal)'),
                        ),
                        const PopupMenuItem(
                          value: SymmetryDrawMode.fourFoldRadial,
                          child: Text('Mirror: 4-Axis (Mandala)'),
                        ),
                      ],
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: _symmetryMode != SymmetryDrawMode.none
                              ? AppColors.turmericGold.withValues(alpha: 0.2)
                              : (isDark ? AppColors.slateLight : AppColors.borderLight),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _symmetryMode != SymmetryDrawMode.none
                                ? AppColors.turmericGold
                                : Colors.transparent,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.flip_rounded,
                              size: 16,
                              color: _symmetryMode != SymmetryDrawMode.none
                                  ? AppColors.turmericGold
                                  : AppColors.textMuted,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _symmetryMode == SymmetryDrawMode.none
                                  ? 'Mirror: Off'
                                  : _symmetryMode == SymmetryDrawMode.fourFoldRadial
                                      ? '4-Axis'
                                      : '2-Axis',
                              style: AppTypography.tagText.copyWith(
                                color: _symmetryMode != SymmetryDrawMode.none
                                    ? AppColors.turmericGold
                                    : AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.turmericAmber.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.turmericAmber.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.all_inclusive_rounded, size: 14, color: AppColors.turmericAmber),
                          const SizedBox(width: 5),
                          Text(
                            '${_connectivityGraph.countClosedLoops()} Loops',
                            style: AppTypography.tagText.copyWith(
                              color: AppColors.turmericAmber,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Trace Mode Reference Layer Control Header Bar (when active)
          if (_activeSampleDesign != null)
            _buildTraceModeBanner(isDark),

          // Central Canvas Area
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  KolamCanvasWidget(
                    gridSize: _gridSize,
                    showDots: _showDots,
                    strokes: _strokes,
                    activeStroke: _activeStroke,
                    symmetryMode: _symmetryMode,
                    isShapesMode: _isShapesMode,
                    placedShapes: _placedShapes,
                    selectedShapeId: _selectedShapeId,
                    snapHighlightPoint: _snapHighlightPoint,
                    referenceStrokes: _activeSampleDesign?.strokes,
                    showReferenceLayer: _showReferenceLayer && _activeSampleDesign != null,
                    referenceOpacity: _referenceOpacity,
                    onPanStart: _onCanvasPanStart,
                    onPanUpdate: _onCanvasPanUpdate,
                    onPanEnd: _onCanvasPanEnd,
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
                ],
              ),
            ),
          ),

          // Shape Palette (visible in Shapes mode)
          if (_isShapesMode)
            ShapePaletteWidget(
              onShapeSelected: _onShapeSelectedFromPalette,
              isDark: isDark,
            ),

          // Bottom Tool Control Panel (Pigment Selector / Dots Grid / Stroke Slider)
          _buildToolTabPanel(isDark),

          // Bottom Tabs (Draw / Dots / Tools / AI ✨)
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.slateCard : AppColors.riceFlourCard,
              border: Border(
                top: BorderSide(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                ),
              ),
            ),
            child: Row(
              children: [
                _buildTabButton(
                  tab: StudioBottomTab.draw,
                  label: 'Pigments',
                  icon: Icons.palette_rounded,
                ),
                _buildTabButton(
                  tab: StudioBottomTab.dots,
                  label: 'Grid Pulli',
                  icon: Icons.grid_4x4_rounded,
                ),
                _buildTabButton(
                  tab: StudioBottomTab.tools,
                  label: 'Stroke',
                  icon: Icons.line_weight_rounded,
                ),
                _buildTabButton(
                  tab: StudioBottomTab.ai,
                  label: 'AI ✨',
                  icon: Icons.auto_awesome_rounded,
                  highlight: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModePill({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.terracottaRed : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.terracottaRed.withValues(alpha: 0.35),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? Colors.white : AppColors.textMuted,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: AppTypography.tagText.copyWith(
                color: isSelected ? Colors.white : AppColors.textMuted,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 11.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton({
    required StudioBottomTab tab,
    required String label,
    required IconData icon,
    bool highlight = false,
  }) {
    final isSelected = _activeTab == tab;

    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() => _activeTab = tab);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: isSelected
                    ? (highlight ? AppColors.turmericGold : AppColors.terracottaRed)
                    : Colors.transparent,
                width: 2.5,
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected
                    ? (highlight ? AppColors.turmericGold : AppColors.terracottaRed)
                    : (highlight ? AppColors.turmericAmber : AppColors.textMuted),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: AppTypography.caption.copyWith(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected
                      ? (highlight ? AppColors.turmericGold : AppColors.terracottaRed)
                      : (highlight ? AppColors.turmericAmber : AppColors.textMuted),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToolTabPanel(bool isDark) {
    if (_activeTab == StudioBottomTab.dots) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        color: isDark ? AppColors.slateDark : AppColors.riceFlourBg,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              Text('Grid Pulli:', style: AppTypography.cardTitle.copyWith(fontSize: 13)),
              const SizedBox(width: 12),
              ...[5, 7, 9].map((size) {
                final isSel = _gridSize == size;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text('${size}x$size'),
                    selected: isSel,
                    onSelected: (val) {
                      if (val) {
                        setState(() => _gridSize = size);
                        _rebuildConnectivityGraph();
                      }
                    },
                  ),
                );
              }),
              const SizedBox(width: 16),
              IconButton(
                icon: Icon(_showDots ? Icons.visibility_rounded : Icons.visibility_off_rounded),
                tooltip: _showDots ? 'Hide Grid Dots' : 'Show Grid Dots',
                onPressed: () => setState(() => _showDots = !_showDots),
              ),
            ],
          ),
        ),
      );
    } else if (_activeTab == StudioBottomTab.tools) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        color: isDark ? AppColors.slateDark : AppColors.riceFlourBg,
        child: Row(
          children: [
            Text('Stroke: ', style: AppTypography.cardTitle.copyWith(fontSize: 13)),
            Expanded(
              child: Slider(
                value: _strokeWidth,
                min: 1.5,
                max: 8.0,
                divisions: 6,
                activeColor: AppColors.terracottaRed,
                label: '${_strokeWidth.toStringAsFixed(1)}px',
                onChanged: (val) {
                  setState(() {
                    _strokeWidth = val;
                    if (_isShapesMode && _selectedShapeId != null) {
                      final idx = _placedShapes.indexWhere((s) => s.id == _selectedShapeId);
                      if (idx != -1) {
                        _placedShapes[idx] = _placedShapes[idx].copyWith(strokeWidth: val);
                        _rebuildConnectivityGraph();
                      }
                    }
                  });
                },
              ),
            ),
          ],
        ),
      );
    } else if (_activeTab == StudioBottomTab.ai) {
      // AI Sub-Tab: Dedicated analysis controls and results card
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: isDark ? AppColors.slateDark : AppColors.riceFlourBg,
        child: _isAnalyzing
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.turmericGold),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Analyzing geometry, loops, and symmetry...',
                    style: AppTypography.cardTitle.copyWith(fontSize: 13, color: AppColors.turmericAmber),
                  ),
                ],
              )
            : _lastAnalysis == null
                ? Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.auto_awesome_rounded, size: 16, color: AppColors.turmericAmber),
                                const SizedBox(width: 6),
                                Text(
                                  'Smart Kolam AI Analysis',
                                  style: AppTypography.cardTitle.copyWith(fontSize: 13),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Evaluates symmetry, loops, and 7-factor complexity on-device.',
                              style: AppTypography.caption.copyWith(fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: _runSmartAnalysis,
                        icon: const Icon(Icons.analytics_rounded, size: 16, color: Colors.white),
                        label: const Text('Analyse Kolam (+30 XP)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.terracottaRed,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        ),
                      ),
                    ],
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Results Card Header: Symmetry Type + Degree & Complexity Score
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                const Icon(Icons.auto_awesome_rounded, size: 16, color: AppColors.turmericGold),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    '${_formatSymmetryName(_lastAnalysis!.symmetryType)} (${_lastAnalysis!.rotationalSymmetrySummary != "None" ? "${_lastAnalysis!.rotationalSymmetrySummary} Rot" : "No Rot"})',
                                    style: AppTypography.cardTitle.copyWith(fontSize: 13, color: AppColors.turmericAmber),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.turmericGold.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '★ ${_lastAnalysis!.complexityScore}/100 (${_lastAnalysis!.complexityTier})',
                              style: AppTypography.tagText.copyWith(color: AppColors.turmericAmber, fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Metrics Row: Reflection detected yes/no, Grid size, Closed loops
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Reflection: ${_lastAnalysis!.reflectionDetected ? "Yes (${_lastAnalysis!.reflectionAxesCount} Axes)" : "No"} • Grid: ${_lastAnalysis!.gridSize}',
                              style: AppTypography.caption.copyWith(fontSize: 11),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.tulsiGreen.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${_lastAnalysis!.closedLoopCount} Closed Loops',
                              style: AppTypography.caption.copyWith(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.tulsiGreen,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Action buttons: Re-Analyse, Detailed Breakdown, Save Kolam
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _runSmartAnalysis,
                              icon: const Icon(Icons.refresh_rounded, size: 14),
                              label: const Text('Re-Analyse', style: TextStyle(fontSize: 11)),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (_) => SmartAnalysisSheet(
                                    result: _lastAnalysis!,
                                    onSavePressed: () {
                                      Navigator.of(context).pop();
                                      _promptSaveKolam(_lastAnalysis);
                                    },
                                  ),
                                );
                              },
                              icon: const Icon(Icons.info_outline_rounded, size: 14),
                              label: const Text('Breakdown', style: TextStyle(fontSize: 11)),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _promptSaveKolam(_lastAnalysis),
                              icon: const Icon(Icons.bookmark_add_rounded, size: 14, color: Colors.white),
                              label: const Text('Save Kolam', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.tulsiGreen,
                                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
      );
    } else {
      // Pigments selector (applies to active pen or selected shape)
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: isDark ? AppColors.slateDark : AppColors.riceFlourBg,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: AppColors.drawingPigments.map((color) {
              final isSel = _selectedColor == color;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedColor = color;
                    if (_isShapesMode && _selectedShapeId != null) {
                      final idx = _placedShapes.indexWhere((s) => s.id == _selectedShapeId);
                      if (idx != -1) {
                        _placedShapes[idx] = _placedShapes[idx].copyWith(colorValue: color.toARGB32());
                        _rebuildConnectivityGraph();
                      }
                    }
                  });
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSel ? AppColors.turmericGold : Colors.black26,
                      width: isSel ? 3.0 : 1.0,
                    ),
                    boxShadow: isSel
                        ? [
                            BoxShadow(
                              color: AppColors.turmericGold.withValues(alpha: 0.5),
                              blurRadius: 6,
                            )
                          ]
                        : null,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      );
    }
  }

  Color _getDifficultyColor(KolamDifficulty diff) {
    switch (diff) {
      case KolamDifficulty.easy:
        return AppColors.tulsiGreen;
      case KolamDifficulty.medium:
        return AppColors.turmericAmber;
      case KolamDifficulty.hard:
        return AppColors.crimsonRed;
    }
  }

  Widget _buildTraceModeBanner(bool isDark) {
    final design = _activeSampleDesign!;
    final diffColor = _getDifficultyColor(design.difficulty);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.turmericAmber.withValues(alpha: 0.12)
            : AppColors.turmericAmber.withValues(alpha: 0.08),
        border: Border(
          bottom: BorderSide(
            color: AppColors.turmericAmber.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Row(
        children: [
          // Difficulty badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: diffColor.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              design.difficulty.label,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Title & Tamil Name
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        design.name,
                        style: AppTypography.tagText.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '(${design.gridSize}x${design.gridSize})',
                      style: AppTypography.caption.copyWith(fontSize: 10),
                    ),
                  ],
                ),
                Text(
                  design.tamilName,
                  style: AppTypography.caption.copyWith(
                    fontSize: 10.5,
                    color: AppColors.turmericGold,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Reference Layer Visibility Toggle
          IconButton(
            icon: Icon(
              _showReferenceLayer ? Icons.visibility_rounded : Icons.visibility_off_rounded,
              size: 19,
              color: _showReferenceLayer ? AppColors.turmericAmber : AppColors.textMuted,
            ),
            tooltip: _showReferenceLayer ? 'Hide Ghost Reference' : 'Show Ghost Reference',
            onPressed: () => setState(() => _showReferenceLayer = !_showReferenceLayer),
          ),

          // Reference Opacity Selector
          PopupMenuButton<double>(
            tooltip: 'Ghost Opacity: ${(_referenceOpacity * 100).round()}%',
            icon: const Icon(Icons.opacity_rounded, size: 19, color: AppColors.turmericAmber),
            itemBuilder: (context) => [
              const PopupMenuItem(
                enabled: false,
                child: Text('Reference Opacity', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              ...[0.15, 0.35, 0.55, 0.80].map((val) => PopupMenuItem(
                    value: val,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${(val * 100).round()}%'),
                        if (val == _referenceOpacity)
                          const Icon(Icons.check_rounded, size: 16, color: AppColors.turmericGold),
                      ],
                    ),
                  )),
            ],
            onSelected: (val) => setState(() => _referenceOpacity = val),
          ),

          const SizedBox(width: 4),

          // "Check Tracing" Button
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.terracottaRed,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              minimumSize: const Size(60, 30),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              elevation: 1,
            ),
            icon: const Icon(Icons.fact_check_rounded, size: 13),
            label: const Text(
              'Check',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            ),
            onPressed: _checkTracingAccuracy,
          ),

          const SizedBox(width: 2),

          // Exit Trace Mode button
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 18),
            tooltip: 'Exit Trace Mode',
            onPressed: () {
              setState(() {
                _activeSampleDesign = null;
                _showReferenceLayer = false;
              });
            },
          ),
        ],
      ),
    );
  }

  String _formatSymmetryName(SymmetryType type) {
    switch (type) {
      case SymmetryType.dihedralD4:
        return 'Dihedral D4 (Mandala)';
      case SymmetryType.fourFoldReflection:
        return '4-Fold Reflection';
      case SymmetryType.twoFoldReflection:
        return '2-Fold Dual Mirror';
      case SymmetryType.bilateralReflection:
        return 'Bilateral Reflection';
      case SymmetryType.rotational90:
        return '90° 4-Fold Rotation';
      case SymmetryType.rotational180:
        return '180° 2-Fold Rotation';
      case SymmetryType.none:
        return 'Organic Freeform';
    }
  }
}

