import 'dart:convert';
import 'dart:math';

import 'package:graph_visualizer/algorithms/distributed/messages.dart';
import 'package:graph_visualizer/models/distrubuted_models.dart';
import 'package:graph_visualizer/models/graphs.dart';
import 'package:flutter/material.dart';

class GraphPainter extends CustomPainter {
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
  final int? startNode;
  final int? targetNode;

  // Distributed algorithm specific properties
  final List<Message>? messages;
  final Map<String, String>? routingTables;
  final int? activeMessageIndex;
  final Map<String, List<String>>? messageQueues; // NodeID -> List of messages
  final int? processingNode; // Currently processing node
  final bool showMessagePaths;
  final bool showMessageContents;
  final double messageProgress; // 0.0 to 1.0 for animation

  // Paints
  final Paint _messagePaint =
      Paint()
        ..color = Colors.orange
        ..style = PaintingStyle.fill;

  final Paint _activeMessagePaint =
      Paint()
        ..color = Colors.deepOrange
        ..style = PaintingStyle.fill;

  final Paint _messagePathPaint =
      Paint()
        ..color = Colors.orange.withOpacity(0.3)
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke;

  final Paint _activeMessagePathPaint =
      Paint()
        ..color = Colors.deepOrange
        ..strokeWidth = 4
        ..style = PaintingStyle.stroke;

  final Paint _processingNodePaint =
      Paint()
        ..color = Colors.yellow.shade700
        ..style = PaintingStyle.fill;

  final Paint _routingTablePaint =
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;

  final Paint _routingTableBorderPaint =
      Paint()
        ..color = Colors.blueGrey
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;

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
    this.messages,
    this.routingTables,
    this.activeMessageIndex,
    this.messageQueues,
    this.processingNode,
    this.showMessagePaths = true,
    this.showMessageContents = true,
    this.messageProgress = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawEdges(canvas);

    // Draw message paths if enabled
    if (showMessagePaths && messages != null && messages!.isNotEmpty) {
      _drawMessagePaths(canvas);
    }
    // For shortest path, draw the path first so nodes appear on top
    if (isShortestPathVisualization &&
        targetNode != null &&
        startNode != null) {
      _drawShortestPath(canvas, startNode!, targetNode!);
    }

    _drawNodes(canvas);

    //aktif mesajları çiz
    if (messages != null) {
      _drawMessages(canvas);
    }

    //eğer mevcutsa yönlendirme tablosunu çiz
    if (routingTables != null) {
      // _drawRoutingTables(canvas); // şimdilik bunu göstermeyeceğim konumunu beğenmedim
    }

    // mesaj kuyrugunu çiz
    if (messageQueues != null) {
      _drawMessageQueues(canvas);
    }

    // En kısa yol modundaysa mesafe etiketlerini çizin
    if (isShortestPathVisualization && distances != null) {
      _drawDistanceLabels(canvas);
    }
  }

  void _drawEdges(Canvas canvas) {
    for (final edge in graph.edges) {
      if (!nodePositions.containsKey(edge.source) ||
          !nodePositions.containsKey(edge.destination)) {
        debugPrint(
          'Skipping edge ${edge.source}-${edge.destination} due to missing node positions',
        );
        continue;
      }

      final start = nodePositions[edge.source]!;
      final end = nodePositions[edge.destination]!;
      final edgeKey = _formatEdge(edge.source, edge.destination);

      final edgePaint = _getEdgePaint(edgeKey);

      debugPrint(
        'Drawing edge $edgeKey from $start to $end with paint color ${edgePaint.color}',
      );

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
      debugPrint('No shortest path info for target node $target');
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

      debugPrint('Drawing shortest path: ${path.reversed.toList()}');

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
        } else {
          debugPrint(
            'Missing node positions for edge $source-$dest in shortest path',
          );
        }
      }
    } else {
      debugPrint('Could not complete shortest path from $start to $target');
    }
  }

  void _drawNodes(Canvas canvas) {
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    nodePositions.forEach((nodeId, position) {
      debugPrint('Drawing node $nodeId at $position');

      // Determine node fill color
      final fillPaint = _getNodePaint(nodeId);
      debugPrint('Node $nodeId paint color: ${fillPaint.color}');
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

      // Draw message queue count if exists
      if (messageQueues != null &&
          messageQueues!.containsKey(nodeId.toString())) {
        _drawMessageQueueBadge(canvas, position, nodeId);
      }
    });
  }

  Paint _getNodePaint(int nodeId) {
    if (nodeId == processingNode) {
      debugPrint('Node $nodeId paint: processingNodePaint');
      return _processingNodePaint;
    }
    if (nodeId == startNode) {
      debugPrint('Node $nodeId paint: startNodePaint');
      return _startNodePaint;
    }
    if (nodeId == targetNode) {
      debugPrint('Node $nodeId paint: targetNodePaint');
      return _targetNodePaint;
    }
    if (currentNode == nodeId) {
      debugPrint('Node $nodeId paint: currentNodePaint');
      return _currentNodePaint;
    }
    if (isShortestPathVisualization &&
        visitedNodes != null &&
        visitedNodes!.contains(nodeId)) {
      debugPrint('Node $nodeId paint: visitedNodePaint');
      return _visitedNodePaint;
    }
    if (traversalOrder.contains(nodeId)) {
      debugPrint('Node $nodeId paint: traversalOrderPaint');
      return _visitedNodePaint;
    }
    debugPrint('Node $nodeId paint: defaultNodePaint');
    return _defaultNodePaint;
  }

  void _drawMessageQueueBadge(Canvas canvas, Offset position, int nodeId) {
    final queue = messageQueues![nodeId.toString()];
    if (queue == null || queue.isEmpty) return;

    final textPainter = TextPainter(
      text: TextSpan(
        text: '${queue.length}',
        style: TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final badgePosition = position + Offset(20, -20);
    final badgeRadius = 12.0;

    // Draw badge background
    canvas.drawCircle(
      badgePosition,
      badgeRadius,
      _messagePaint..color = Colors.orange.withOpacity(0.8),
    );

    // Draw text
    textPainter.paint(
      canvas,
      badgePosition - Offset(textPainter.width / 2, textPainter.height / 2),
    );
  }

  void _drawMessagePaths(Canvas canvas) {
    if (messages == null || messages!.isEmpty) return;

    // Draw paths for all messages
    for (int i = 0; i < messages!.length; i++) {
      final message = messages![i];
      final sourcePos = nodePositions[int.parse(message.sourceNodeId)];
      final destPos = nodePositions[int.parse(message.destinationNodeId)];

      if (sourcePos != null && destPos != null) {
        final isActive = i == activeMessageIndex;
        final paint = isActive ? _activeMessagePathPaint : _messagePathPaint;
        canvas.drawLine(sourcePos, destPos, paint);
      }
    }
  }

  void _drawMessages(Canvas canvas) {
    if (messages == null || messages!.isEmpty) return;

    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    for (int i = 0; i < messages!.length; i++) {
      final message = messages![i];
      final sourcePos = nodePositions[int.parse(message.sourceNodeId)];
      final destPos = nodePositions[int.parse(message.destinationNodeId)];

      if (sourcePos == null || destPos == null) continue;

      final isActive = i == activeMessageIndex;
      final progress = isActive ? messageProgress : 1.0;

      // Calculate current position
      final currentPos = Offset(
        sourcePos.dx + (destPos.dx - sourcePos.dx) * progress,
        sourcePos.dy + (destPos.dy - sourcePos.dy) * progress,
      );

      // Draw message bubble
      final paint = isActive ? _activeMessagePaint : _messagePaint;
      canvas.drawCircle(currentPos, 16, paint);

      // Draw message content if enabled
      if (showMessageContents) {
        final displayText =
            message.content.length > 3
                ? '${message.content.substring(0, 3)}..'
                : message.content;

        textPainter.text = TextSpan(
          text: displayText,
          style: TextStyle(color: Colors.white, fontSize: 12),
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          currentPos - Offset(textPainter.width / 2, textPainter.height / 2),
        );
      }

      // Draw arrow for active message
      if (isActive && progress > 0.5) {
        _drawMessageArrow(canvas, sourcePos, currentPos);
      }
    }
  }

  void _drawMessageQueues(Canvas canvas) {
    if (messageQueues == null) return;

    final textStyle = TextStyle(color: Colors.black, fontSize: 10);
    final padding = 4.0;
    final maxMessagesToShow = 3;

    messageQueues!.forEach((nodeId, queue) {
      final nodePos = nodePositions[int.parse(nodeId)];
      if (nodePos == null || queue.isEmpty) return;

      // Benzersiz mesajları al
      var uniqueMessages = queue.toSet().toList();

      // Gösterilecek mesajları ayarla
      if (uniqueMessages.length > maxMessagesToShow) {
        uniqueMessages = uniqueMessages.sublist(0, maxMessagesToShow);
      }

      final textSpans =
          uniqueMessages
              .map(
                (msg) => TextSpan(
                  text:
                      "${msg.length > 10 ? '${msg.substring(0, 7)}...' : msg}\n",
                  style: textStyle,
                ),
              )
              .toList();

      // Dahası mesajını hesapla
      if (queue.toSet().length > maxMessagesToShow) {
        textSpans.add(
          TextSpan(
            text: "+${queue.toSet().length - maxMessagesToShow} dahası",
            style: textStyle,
          ),
        );
      }

      final textPainter = TextPainter(
        text: TextSpan(children: textSpans),
        textDirection: TextDirection.ltr,
      )..layout();

      final bgRect = Rect.fromLTWH(
        nodePos.dx - textPainter.width - padding * 2 - 30,
        nodePos.dy - 50,
        textPainter.width + padding * 2,
        textPainter.height + padding * 2,
      );

      // Kuyruk arka planını çiz
      canvas.drawRect(bgRect, _routingTablePaint);
      canvas.drawRect(bgRect, _routingTableBorderPaint);

      // Kuyruk içeriğini çiz
      textPainter.paint(
        canvas,
        Offset(bgRect.left + padding, bgRect.top + padding),
      );
    });
  }

  void _drawMessageArrow(Canvas canvas, Offset start, Offset currentPos) {
    final arrowPaint =
        Paint()
          ..color = Colors.deepOrange
          ..style = PaintingStyle.fill;

    final direction = (currentPos - start).normalized();
    final angle = atan2(direction.dy, direction.dx);

    final arrowSize = 10.0;
    final arrowPoint1 = Offset(
      currentPos.dx - arrowSize * cos(angle - pi / 6),
      currentPos.dy - arrowSize * sin(angle - pi / 6),
    );
    final arrowPoint2 = Offset(
      currentPos.dx - arrowSize * cos(angle + pi / 6),
      currentPos.dy - arrowSize * sin(angle + pi / 6),
    );

    final path =
        Path()
          ..moveTo(currentPos.dx, currentPos.dy)
          ..lineTo(arrowPoint1.dx, arrowPoint1.dy)
          ..lineTo(arrowPoint2.dx, arrowPoint2.dy)
          ..close();

    canvas.drawPath(path, arrowPaint);
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

  // void _drawMessagePaths(Canvas canvas) {
  //   if (messages!.isEmpty) return;

  //   final pathPaint =
  //       Paint()
  //         ..color = Colors.orange.withOpacity(0.3)
  //         ..strokeWidth = 3
  //         ..style = PaintingStyle.stroke;

  //   // Draw paths for all messages
  //   for (final message in messages!) {
  //     final sourcePos = nodePositions[int.parse(message.sourceNodeId)];
  //     final destPos = nodePositions[int.parse(message.destinationNodeId)];

  //     if (sourcePos != null && destPos != null) {
  //       canvas.drawLine(sourcePos, destPos, pathPaint);
  //     }
  //   }

  //   // Highlight active message path
  //   if (activeMessageIndex != null && activeMessageIndex! < messages!.length) {
  //     final activeMessage = messages![activeMessageIndex!];
  //     final activeSource = nodePositions[int.parse(activeMessage.sourceNodeId)];
  //     final activeDest =
  //         nodePositions[int.parse(activeMessage.destinationNodeId)];

  //     if (activeSource != null && activeDest != null) {
  //       final activePathPaint =
  //           Paint()
  //             ..color = Colors.orange
  //             ..strokeWidth = 4
  //             ..style = PaintingStyle.stroke;

  //       canvas.drawLine(activeSource, activeDest, activePathPaint);
  //     }
  //   }
  // }

  // void _drawMessages(Canvas canvas) {
  //   if (messages == null || messages!.isEmpty) return;

  //   final textPainter = TextPainter(textDirection: TextDirection.ltr);
  //   final messagePaint = Paint()..style = PaintingStyle.fill;

  //   for (int i = 0; i < messages!.length; i++) {
  //     final message = messages![i];
  //     final sourcePos = nodePositions[int.parse(message.sourceNodeId)];
  //     final destPos = nodePositions[int.parse(message.destinationNodeId)];

  //     if (sourcePos == null || destPos == null) continue;

  //     final isActive = i == activeMessageIndex;
  //     final progress = isActive ? currentStep / totalSteps : 1.0;

  //     // Calculate current position
  //     final currentPos = Offset(
  //       sourcePos.dx + (destPos.dx - sourcePos.dx) * progress,
  //       sourcePos.dy + (destPos.dy - sourcePos.dy) * progress,
  //     );

  //     // Draw connection line
  //     if (isActive) {
  //       final pathPaint =
  //           Paint()
  //             ..color = Colors.orange.withOpacity(0.5)
  //             ..strokeWidth = 2
  //             ..style = PaintingStyle.stroke;
  //       canvas.drawLine(sourcePos, destPos, pathPaint);
  //     }

  //     // Draw message bubble
  //     messagePaint.color =
  //         isActive ? Colors.orange : Colors.orange.withOpacity(0.6);
  //     canvas.drawCircle(currentPos, 16, messagePaint);

  //     // Draw message content
  //     final displayText =
  //         message.content.length > 3
  //             ? '${message.content.substring(0, 3)}..'
  //             : message.content;

  //     textPainter.text = TextSpan(
  //       text: displayText,
  //       style: TextStyle(color: Colors.white, fontSize: 12),
  //     );
  //     textPainter.layout();
  //     textPainter.paint(
  //       canvas,
  //       currentPos - Offset(textPainter.width / 2, textPainter.height / 2),
  //     );
  //   }
  // }

  void _drawRoutingTables(Canvas canvas) {
    if (routingTables == null) return;

    final textStyle = TextStyle(color: Colors.black, fontSize: 10);
    final padding = 4.0;
    final arrowLength = 10.0; // Ok uzunluğu
    final arrowWidth = 5.0; // Ok genişliği

    routingTables!.forEach((nodeId, tableJson) {
      final nodePos = nodePositions[int.parse(nodeId)];
      if (nodePos == null) return;

      try {
        final table = jsonDecode(tableJson) as Map<String, dynamic>;
        final entries = table.entries.take(3).toList(); // İlk 3 girişi göster

        final textSpans =
            entries
                .map(
                  (e) =>
                      TextSpan(text: "${e.key}→${e.value}\n", style: textStyle),
                )
                .toList();

        if (table.length > 3) {
          textSpans.add(TextSpan(text: "...", style: textStyle));
        }

        final textPainter = TextPainter(
          text: TextSpan(children: textSpans),
          textDirection: TextDirection.ltr,
        )..layout();

        // Tablonun konumunu düğümün biraz uzağında ayarlama
        final bgRect = Rect.fromLTWH(
          nodePos.dx + 30,
          nodePos.dy - 50,
          textPainter.width + padding * 2,
          textPainter.height + padding * 2,
        );

        // Okun başlangıç ve bitiş noktaları
        final arrowStart = Offset(nodePos.dx, nodePos.dy);
        final arrowEnd = Offset(bgRect.left, bgRect.top + (bgRect.height / 2));

        // // Ok çizecek fonksiyon
        // drawArrowRoutingTable(canvas, nodePos,nodePos , 5.0, 5.0);

        // Tablonun arka planını çiz
        canvas.drawRect(bgRect, _routingTablePaint);
        canvas.drawRect(bgRect, _routingTableBorderPaint);

        // Tablonun içeriğini çiz
        textPainter.paint(
          canvas,
          Offset(bgRect.left + padding, bgRect.top + padding),
        );
      } catch (e) {
        debugPrint('Error drawing routing table: $e');
      }
    });
  }

  // Ok çizen fonksiyon
  void drawArrowRoutingTable(
    Canvas canvas,
    Offset start,
    Offset end,
    double width,
    double spacing, // Düğüm ile ok arasındaki mesafe
  ) {
    final paint =
        Paint()
          ..color = const Color.fromARGB(255, 23, 8, 8)
          ..style = PaintingStyle.fill;

    // Okun başlangıç noktasını, düğüm ile araya mesafe ekleyerek ayarla
    final adjustedStart = Offset(start.dx + spacing, start.dy);

    // Okun gövdesini çiz
    canvas.drawLine(adjustedStart, end, paint);

    // Okun başını çiz
    final arrowHeadPath =
        Path()
          ..moveTo(end.dx, end.dy)
          ..lineTo(end.dx - width, end.dy - width / 2) // Sol kenar
          ..lineTo(end.dx - width, end.dy + width / 2) // Sağ kenar
          ..close();

    canvas.drawPath(arrowHeadPath, paint);
  }

  // Ok çizen fonksiyon

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
        targetNode != oldDelegate.targetNode ||
        messages != oldDelegate.messages ||
        routingTables != oldDelegate.routingTables ||
        activeMessageIndex != oldDelegate.activeMessageIndex ||
        messageQueues != oldDelegate.messageQueues ||
        processingNode != oldDelegate.processingNode ||
        messageProgress != oldDelegate.messageProgress;
  }
}

void _drawMessageArrow(Canvas canvas, Offset start, Offset end) {
  final arrowPaint =
      Paint()
        ..color = Colors.orange
        ..strokeWidth = 2
        ..style = PaintingStyle.fill;

  final path =
      Path()
        ..moveTo(end.dx, end.dy)
        ..lineTo(end.dx - 10, end.dy - 5)
        ..lineTo(end.dx - 10, end.dy + 5)
        ..close();

  canvas.drawPath(path, arrowPaint);
}

extension on Offset {
  Offset normalized() {
    final length = distance;
    return length > 0 ? this / length : this;
  }
}
