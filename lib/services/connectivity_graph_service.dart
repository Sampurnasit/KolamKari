import 'package:flutter/material.dart';
import '../data/models/kolam_shape_primitive.dart';
import 'analysis_service.dart';

/// Represents a snap point node in the Kolam topological graph
class GraphNode {
  final String id;
  final Offset position;
  final bool isGridDot;
  final Set<String> connectedAnchorKeys; // "shapeId:start" or "shapeId:end"

  GraphNode({
    required this.id,
    required this.position,
    this.isGridDot = false,
    Set<String>? connectedAnchorKeys,
  }) : connectedAnchorKeys = connectedAnchorKeys ?? {};

  GraphNode copyWith({
    String? id,
    Offset? position,
    bool? isGridDot,
    Set<String>? connectedAnchorKeys,
  }) {
    return GraphNode(
      id: id ?? this.id,
      position: position ?? this.position,
      isGridDot: isGridDot ?? this.isGridDot,
      connectedAnchorKeys: connectedAnchorKeys ?? Set.from(this.connectedAnchorKeys),
    );
  }
}

/// Represents an edge connecting two snap nodes via a Kolam shape segment
class GraphEdge {
  final String id;
  final String shapeId;
  final String nodeAId;
  final String nodeBId;
  final KolamStroke stroke;

  const GraphEdge({
    required this.id,
    required this.shapeId,
    required this.nodeAId,
    required this.nodeBId,
    required this.stroke,
  });
}

/// Snap result payload containing snapped position and target node
class SnapResult {
  final Offset snappedShapePosition;
  final Offset snappedAnchorPoint;
  final String targetNodeId;
  final bool isGridDot;
  final String anchorType; // "start" or "end"

  const SnapResult({
    required this.snappedShapePosition,
    required this.snappedAnchorPoint,
    required this.targetNodeId,
    required this.isGridDot,
    required this.anchorType,
  });
}

/// Topological connectivity graph for Kolam construction
class KolamConnectivityGraph {
  final Map<String, GraphNode> nodes = {};
  final Map<String, GraphEdge> edges = {};
  final Map<String, Set<String>> adjacency = {}; // nodeA -> set of neighbor nodeBs

  static const double defaultSnapThreshold = 22.0;

  /// Rebuilds the graph from grid pulli dots and placed shapes
  void rebuild({
    required List<Offset> gridDots,
    required List<PlacedKolamShape> shapes,
    double snapThreshold = defaultSnapThreshold,
  }) {
    nodes.clear();
    edges.clear();
    adjacency.clear();

    // 1. Initialize grid dot nodes
    for (int i = 0; i < gridDots.length; i++) {
      final dot = gridDots[i];
      final nodeId = 'dot_$i';
      nodes[nodeId] = GraphNode(
        id: nodeId,
        position: dot,
        isGridDot: true,
      );
      adjacency[nodeId] = {};
    }

    // 2. Connect shapes
    for (final shape in shapes) {
      final startAnchor = shape.worldStartAnchor;
      final endAnchor = shape.worldEndAnchor;

      // Find or create node for start anchor
      final nodeAId = _findOrCreateNode(
        point: startAnchor,
        shapeAnchorKey: '${shape.id}:start',
        snapThreshold: snapThreshold,
      );

      // Find or create node for end anchor
      final nodeBId = _findOrCreateNode(
        point: endAnchor,
        shapeAnchorKey: '${shape.id}:end',
        snapThreshold: snapThreshold,
      );

      // Register edge
      final edgeId = 'edge_${shape.id}';
      edges[edgeId] = GraphEdge(
        id: edgeId,
        shapeId: shape.id,
        nodeAId: nodeAId,
        nodeBId: nodeBId,
        stroke: shape.toStroke(),
      );

      // Add to adjacency list
      adjacency.putIfAbsent(nodeAId, () => {}).add(nodeBId);
      adjacency.putIfAbsent(nodeBId, () => {}).add(nodeAId);
    }
  }

  /// Evaluates magnetic snap for a shape being dragged
  SnapResult? evaluateSnap({
    required PlacedKolamShape shape,
    required List<Offset> gridDots,
    double snapThreshold = defaultSnapThreshold,
  }) {
    final startAnchor = shape.worldStartAnchor;
    final endAnchor = shape.worldEndAnchor;

    // 1. Check if start anchor is close to any candidate node
    final startSnap = _findNearestCandidate(startAnchor, shape.id, gridDots, snapThreshold);
    if (startSnap != null) {
      final delta = startSnap.position - startAnchor;
      return SnapResult(
        snappedShapePosition: shape.position + delta,
        snappedAnchorPoint: startSnap.position,
        targetNodeId: startSnap.id,
        isGridDot: startSnap.isGridDot,
        anchorType: 'start',
      );
    }

    // 2. Check if end anchor is close to any candidate node
    final endSnap = _findNearestCandidate(endAnchor, shape.id, gridDots, snapThreshold);
    if (endSnap != null) {
      final delta = endSnap.position - endAnchor;
      return SnapResult(
        snappedShapePosition: shape.position + delta,
        snappedAnchorPoint: endSnap.position,
        targetNodeId: endSnap.id,
        isGridDot: endSnap.isGridDot,
        anchorType: 'end',
      );
    }

    return null;
  }

  GraphNode? _findNearestCandidate(
    Offset anchor,
    String currentShapeId,
    List<Offset> gridDots,
    double threshold,
  ) {
    GraphNode? bestNode;
    double bestDist = threshold;

    // Check existing nodes in graph
    for (final node in nodes.values) {
      // Don't snap to an anchor of the same shape
      final hasSelfAnchor = node.connectedAnchorKeys.any((k) => k.startsWith('$currentShapeId:'));
      if (hasSelfAnchor && !node.isGridDot) continue;

      final d = (node.position - anchor).distance;
      if (d <= bestDist) {
        bestDist = d;
        bestNode = node;
      }
    }

    // Check raw grid dots if not yet nodes
    if (bestNode == null) {
      for (int i = 0; i < gridDots.length; i++) {
        final dot = gridDots[i];
        final d = (dot - anchor).distance;
        if (d <= bestDist) {
          bestDist = d;
          bestNode = GraphNode(id: 'dot_$i', position: dot, isGridDot: true);
        }
      }
    }

    return bestNode;
  }

  String _findOrCreateNode({
    required Offset point,
    required String shapeAnchorKey,
    required double snapThreshold,
  }) {
    String? matchedNodeId;
    double minDistance = snapThreshold;

    for (final entry in nodes.entries) {
      final d = (entry.value.position - point).distance;
      if (d <= minDistance) {
        minDistance = d;
        matchedNodeId = entry.key;
      }
    }

    if (matchedNodeId != null) {
      nodes[matchedNodeId]!.connectedAnchorKeys.add(shapeAnchorKey);
      return matchedNodeId;
    }

    final newNodeId = 'node_${nodes.length}_${point.dx.round()}_${point.dy.round()}';
    nodes[newNodeId] = GraphNode(
      id: newNodeId,
      position: point,
      isGridDot: false,
      connectedAnchorKeys: {shapeAnchorKey},
    );
    adjacency[newNodeId] = {};
    return newNodeId;
  }

  /// Counts closed loops (cycles) in the connectivity graph using cyclomatic complexity (E - V + C)
  int countClosedLoops() {
    if (edges.isEmpty) return 0;

    // Only consider nodes that have at least one connected edge
    final activeNodeIds = <String>{};
    for (final edge in edges.values) {
      activeNodeIds.add(edge.nodeAId);
      activeNodeIds.add(edge.nodeBId);
    }

    if (activeNodeIds.isEmpty) return 0;

    // Find connected components among active nodes
    final visited = <String>{};
    int totalCycles = 0;

    for (final startNode in activeNodeIds) {
      if (visited.contains(startNode)) continue;

      // BFS to find all nodes and edges in this component
      final componentNodes = <String>{};
      final queue = <String>[startNode];
      visited.add(startNode);
      componentNodes.add(startNode);

      while (queue.isNotEmpty) {
        final curr = queue.removeAt(0);
        final neighbors = adjacency[curr] ?? {};
        for (final next in neighbors) {
          if (!visited.contains(next) && activeNodeIds.contains(next)) {
            visited.add(next);
            componentNodes.add(next);
            queue.add(next);
          }
        }
      }

      // Count edges within this component
      int componentEdges = 0;
      for (final edge in edges.values) {
        if (componentNodes.contains(edge.nodeAId) && componentNodes.contains(edge.nodeBId)) {
          componentEdges++;
        }
      }

      // Cyclomatic formula: E - V + 1 for each connected component
      final v = componentNodes.length;
      final e = componentEdges;
      final cycles = e - v + 1;
      if (cycles > 0) {
        totalCycles += cycles;
      }
    }

    return totalCycles;
  }

  /// Converts connected shapes into continuous merged strokes for AI analysis and saving
  List<KolamStroke> getMergedStrokes() {
    final result = <KolamStroke>[];
    final processedEdges = <String>{};

    for (final edge in edges.values) {
      if (processedEdges.contains(edge.id)) continue;
      processedEdges.add(edge.id);
      result.add(edge.stroke);
    }

    return result;
  }

  /// Returns total number of connection junctions where 2 or more shape anchors meet
  int get joinedJunctionCount {
    int count = 0;
    for (final node in nodes.values) {
      if (node.connectedAnchorKeys.length >= 2) {
        count++;
      }
    }
    return count;
  }
}
