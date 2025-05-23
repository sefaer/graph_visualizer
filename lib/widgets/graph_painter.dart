import 'dart:math';

import 'package:graph_visualizer/models/graphs.dart';
import 'package:flutter/material.dart';

class GraphPainter extends CustomPainter {
  // Graph data
  final Graphs graph;
  final List<int> traversalOrder;
  final Map<int, Offset> nodePositions;
  final bool showWeights;
  final bool isMSTVisualization;
  final Set<String>? highlightedEdges;
  final int? currentNode;
  final bool isDirected;
  final int currentStep;
  final int totalSteps;
  final bool isShortestPathVisualization;
  final Map<int, double>? distances;
  final Set<int>? visitedNodes;
  final Map<int, int?>? previousNodes;
  final int? startNode; // For shortest path visualization
  final int? targetNode; // For target node highlighting

  // Edge paints
  final Paint _defaultEdgePaint =
      Paint()
        ..color = Colors.blueGrey.shade300
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke;

  final Paint _mstEdgePaint =
      Paint()
        ..color = Colors.green
        ..strokeWidth = 4.0
        ..style = PaintingStyle.stroke;

  final Paint _rejectedEdgePaint =
      Paint()
        ..color = Colors.red
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke;

  final Paint _processingEdgePaint =
      Paint()
        ..color = Colors.blue
        ..strokeWidth = 3.0
        ..style = PaintingStyle.stroke;

  final Paint _shortestPathEdgePaint =
      Paint()
        ..color = Colors.purple
        ..strokeWidth = 4.0
        ..style = PaintingStyle.stroke;

  // Node paints
  final Paint _defaultNodePaint =
      Paint()
        ..color = Colors.teal.shade400
        ..style = PaintingStyle.fill;

  final Paint _visitedNodePaint =
      Paint()
        ..color = Colors.blue.shade400
        ..style = PaintingStyle.fill;

  final Paint _currentNodePaint =
      Paint()
        ..color = Colors.red.shade400
        ..style = PaintingStyle.fill;

  final Paint _startNodePaint =
      Paint()
        ..color = Colors.green.shade600
        ..style = PaintingStyle.fill;

  final Paint _targetNodePaint =
      Paint()
        ..color = Colors.orange.shade600
        ..style = PaintingStyle.fill;

  final Paint _nodeBorderPaint =
      Paint()
        ..color = Colors.white
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;

  final Paint _distanceNodePaint =
      Paint()
        ..color = Colors.purple.shade300
        ..style = PaintingStyle.fill;

  GraphPainter({
    required this.graph,
    required this.traversalOrder,
    required this.nodePositions,
    this.showWeights = false,
    this.isMSTVisualization = false,
    this.highlightedEdges,
    this.currentNode,
    this.isDirected = false,
    this.currentStep = 0,
    this.totalSteps = 1,
    this.isShortestPathVisualization = false,
    this.distances,
    this.visitedNodes,
    this.previousNodes,
    this.startNode,
    this.targetNode,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawEdges(canvas);

    // For shortest path, draw the path first so nodes appear on top
    if (isShortestPathVisualization &&
        targetNode != null &&
        startNode != null) {
      _drawShortestPath(canvas, startNode!, targetNode!);
    }

    _drawNodes(canvas);

    // Draw distance labels if in shortest path mode
    if (isShortestPathVisualization && distances != null) {
      _drawDistanceLabels(canvas);
    }
  }

  void _drawEdges(Canvas canvas) {
    for (final edge in graph.edges) {
      if (!nodePositions.containsKey(edge.source) ||
          !nodePositions.containsKey(edge.destination)) {
        continue;
      }

      final start = nodePositions[edge.source]!;
      final end = nodePositions[edge.destination]!;
      final edgeKey = _formatEdge(edge.source, edge.destination);

      final edgePaint = _getEdgePaint(edgeKey);

      canvas.drawLine(start, end, edgePaint);

      if (isDirected) {
        _drawArrow(canvas, start, end, edgePaint);
      }

      if ((showWeights || isMSTVisualization || isShortestPathVisualization) &&
          edge.weight != null) {
        _drawWeightLabel(
          canvas,
          start,
          end,
          edge.weight.toString(),
          edgePaint.color,
        );
      }
    }
  }

  void _drawShortestPath(Canvas canvas, int start, int target) {
    if (previousNodes == null || !previousNodes!.containsKey(target)) {
      return;
    }

    final path = <int>[];
    int? current = target;

    while (current != null &&
        current != start &&
        path.length < graph.adjacencyList.length) {
      path.add(current);
      current = previousNodes![current];
    }

    if (current == start) {
      path.add(start);
      path.reversed.toList(); // Reverse to get start->target order

      // Draw the path edges
      for (int i = 0; i < path.length - 1; i++) {
        final source = path[i];
        final dest = path[i + 1];

        if (nodePositions.containsKey(source) &&
            nodePositions.containsKey(dest)) {
          final startPos = nodePositions[source]!;
          final endPos = nodePositions[dest]!;

          canvas.drawLine(
            startPos,
            endPos,
            _shortestPathEdgePaint..strokeWidth = 5.0,
          );

          // Yön oklarını çiz (isDirected true ise)
          if (isDirected) {
            _drawArrow(canvas, startPos, endPos, _shortestPathEdgePaint);
          }
        }
      }
    }
  }

  void _drawNodes(Canvas canvas) {
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    nodePositions.forEach((nodeId, position) {
      // Determine node fill color
      final fillPaint = _getNodePaint(nodeId);

      // Draw node circle
      canvas.drawCircle(position, 24, fillPaint);
      canvas.drawCircle(position, 24, _nodeBorderPaint);

      // Draw node ID
      textPainter.text = TextSpan(
        text: '$nodeId',
        style: TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, position - Offset(8, 10));
    });
  }

  Paint _getNodePaint(int nodeId) {
    // Special cases first
    if (nodeId == startNode) return _startNodePaint;
    if (nodeId == targetNode) return _targetNodePaint;
    if (currentNode == nodeId) return _currentNodePaint;

    // For shortest path visualization
    if (isShortestPathVisualization &&
        visitedNodes != null &&
        visitedNodes!.contains(nodeId)) {
      return _visitedNodePaint;
    }

    // For BFS/DFS traversal
    if (traversalOrder.contains(nodeId)) return _visitedNodePaint;

    return _defaultNodePaint;
  }

  void _drawDistanceLabels(Canvas canvas) {
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    nodePositions.forEach((nodeId, position) {
      if (distances!.containsKey(nodeId)) {
        final distance = distances![nodeId];
        final distanceText =
            distance == double.infinity.toInt() ? "∞" : distance.toString();

        textPainter.text = TextSpan(
          text: distanceText,
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        );

        textPainter.layout();

        // Draw distance label above the node
        final labelPosition = position - Offset(0, 35);

        // Draw background
        final bgRect = RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: labelPosition,
            width: textPainter.width + 8,
            height: textPainter.height + 4,
          ),
          Radius.circular(4),
        );

        canvas.drawRRect(
          bgRect,
          _distanceNodePaint..style = PaintingStyle.fill,
        );
        canvas.drawRRect(bgRect, _nodeBorderPaint..strokeWidth = 1.0);

        // Draw text
        textPainter.paint(
          canvas,
          labelPosition - Offset(textPainter.width / 2, textPainter.height / 2),
        );
      }
    });
  }

  // 6. KENAR FORMATLAMA
  String _formatEdge(int u, int v) => u < v ? "$u-$v" : "$v-$u";

  // 7. KENAR BOYASINI BELİRLEME
  Paint _getEdgePaint(String edgeKey) {
    if (highlightedEdges == null) return _defaultEdgePaint;

    // Tüm olası formatları kontrol et
    bool isRejected = highlightedEdges!.any(
      (e) =>
          e == 'rejected-$edgeKey' ||
          e == 'rejected_$edgeKey' ||
          e == '$edgeKey-rejected' ||
          e.contains('rejected') && e.contains(edgeKey),
    );

    bool isProcessing = highlightedEdges!.any(
      (e) =>
          e == 'processing-$edgeKey' ||
          e == 'processing_$edgeKey' ||
          e == '$edgeKey-processing' ||
          e.contains('processing') && e.contains(edgeKey),
    );

    bool isMST =
        highlightedEdges!.contains(edgeKey) ||
        highlightedEdges!.any(
          (e) => e == 'mst-$edgeKey' || e == 'mst_$edgeKey',
        );

    // Öncelik sırası: rejected > processing > mst > default
    if (isRejected) {
      debugPrint('Edge $edgeKey is REJECTED (red)');
      return _rejectedEdgePaint;
    }
    if (isProcessing) {
      debugPrint('Edge $edgeKey is PROCESSING (blue)');
      return _processingEdgePaint;
    }
    if (isMST) {
      debugPrint('Edge $edgeKey is MST (green)');
      return _mstEdgePaint;
    }

    debugPrint('Edge $edgeKey is DEFAULT (blueGrey)');
    return _defaultEdgePaint;
  }

  void _drawArrow(Canvas canvas, Offset start, Offset end, Paint paint) {
    const arrowSize = 12.0; // Ok boyutu
    const arrowAngle = 0.5; // Ok açısı (radyan)
    const arrowOffset = 25.0; // Okun çizgiden ne kadar içeride olacağı

    final direction = (end - start).normalized();
    final angle = atan2(direction.dy, direction.dx);

    // Okun merkez noktası (çizginin sonundan arrowOffset kadar içeride)
    final arrowCenter = Offset(
      end.dx - direction.dx * arrowOffset,
      end.dy - direction.dy * arrowOffset,
    );

    // Ok başı için iki kanat noktası
    final arrowPoint1 = Offset(
      arrowCenter.dx - arrowSize * cos(angle - arrowAngle),
      arrowCenter.dy - arrowSize * sin(angle - arrowAngle),
    );
    final arrowPoint2 = Offset(
      arrowCenter.dx - arrowSize * cos(angle + arrowAngle),
      arrowCenter.dy - arrowSize * sin(angle + arrowAngle),
    );

    // Ok yolunu çiz
    final path =
        Path()
          ..moveTo(arrowCenter.dx, arrowCenter.dy)
          ..lineTo(arrowPoint1.dx, arrowPoint1.dy)
          ..lineTo(arrowPoint2.dx, arrowPoint2.dy)
          ..close();

    // Ok rengini belirle
    final arrowPaint =
        Paint()
          ..color = const Color.fromARGB(255, 35, 132, 196)
          ..style = PaintingStyle.fill;

    canvas.drawPath(path, arrowPaint);
  }

  // 11. AĞIRLIK ETİKETİ ÇİZME
  void _drawWeightLabel(
    Canvas canvas,
    Offset start,
    Offset end,
    String text,
    Color edgeColor,
  ) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: Colors.black,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final direction = (end - start).normalized();
    final perpendicular = Offset(-direction.dy, direction.dx);
    final center =
        Offset((start.dx + end.dx) / 2, (start.dy + end.dy) / 2) +
        perpendicular * 10;

    final bgRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: center,
        width: textPainter.width + 8,
        height: textPainter.height + 4,
      ),
      const Radius.circular(4),
    );

    // Arkaplan çiz
    canvas.drawRRect(bgRect, Paint()..color = Colors.transparent);

    // Metni çiz
    textPainter.paint(
      canvas,
      center - Offset(textPainter.width / 2, textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant GraphPainter oldDelegate) {
    return traversalOrder != oldDelegate.traversalOrder ||
        nodePositions != oldDelegate.nodePositions ||
        isMSTVisualization != oldDelegate.isMSTVisualization ||
        highlightedEdges != oldDelegate.highlightedEdges ||
        currentNode != oldDelegate.currentNode ||
        currentStep != oldDelegate.currentStep ||
        totalSteps != oldDelegate.totalSteps ||
        isShortestPathVisualization !=
            oldDelegate.isShortestPathVisualization ||
        distances != oldDelegate.distances ||
        visitedNodes != oldDelegate.visitedNodes ||
        previousNodes != oldDelegate.previousNodes ||
        startNode != oldDelegate.startNode ||
        targetNode != oldDelegate.targetNode;
  }
}

extension on Offset {
  Offset normalized() {
    final length = distance;
    return length > 0 ? this / length : this;
  }
}
