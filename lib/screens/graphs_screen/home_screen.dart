import 'dart:collection';
import 'dart:convert';
import 'dart:math';

import 'package:graph_visualizer/algorithms/bellman_ford.dart';
import 'package:graph_visualizer/algorithms/dijkstra.dart';
import 'package:graph_visualizer/algorithms/distributed/messages.dart';
import 'package:graph_visualizer/algorithms/kruskal.dart';
import 'package:graph_visualizer/algorithms/prim.dart';
import 'package:graph_visualizer/algorithms/reverse_delete.dart';
import 'package:graph_visualizer/helpers/screenshot_helper.dart';
import 'package:graph_visualizer/helpers/screenshot_helper_web.dart'
    if (dart.library.io) 'package:graph_visualizer/helpers/screenshot_helper_mobile.dart';
import 'package:graph_visualizer/models/routing_step.dart';
import 'package:graph_visualizer/models/shortespath_models.dart';
import 'package:graph_visualizer/widgets/graph_painter.dart';
import 'package:flutter/material.dart';
import 'package:graphview/graphview.dart' as gv;
import '../../models/graphs.dart';
import '../../models/mst_models.dart';
import '../../algorithms/bfs.dart';
import '../../algorithms/dfs.dart';
import 'input_screen.dart';

enum MSTAlgorithm { Prim, Kruskal, ReverseDelete }

enum DijsktraAlgorithm { ShortestPath, BelmanFord }

enum RoutingAlgorithm { SimpleRouting }

MSTAlgorithm? currentAlgorithm;
DijsktraAlgorithm? currentDijkstra;
RoutingAlgorithm? currentRouting;

class HomeScreen extends StatefulWidget {
  final Graphs graph;
  final String graphType;
  const HomeScreen({Key? key, required this.graph, required this.graphType})
    : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Graph state
  late gv.Graph graph;
  late Map<int, gv.Node> nodeMap;
  late gv.FruchtermanReingoldAlgorithm algorithm;
  late gv.BuchheimWalkerAlgorithm algorithm2;
  // Visualization state
  List<int> traversalOrder = [];
  double animationSpeed = 500;
  bool showLabels = true;
  bool _isGraphReady = false;
  bool _isProcessing = false;
  int currentStep = 0;
  int totalSteps = 1;
  int _finalTotalSteps = 1;
  // MST specific state
  BaseMSTStep? currentMSTStep;
  List<RoutingStep> _routingSteps = []; // Algoritma adımlarını saklayacak liste
  RoutingStep? currentRoutingStep; // Ş
  bool isMSTVisualization = false;
  final GlobalKey _screenshotKey = GlobalKey();
  List<BaseMSTStep> _algorithmSteps = [];
  int _currentStepIndex = 0;
  BaseShortestPathStep? currentShortestPathStep;
  bool isShortestPathVisualization = false;
  List<BaseShortestPathStep> _shortestPathSteps = [];
  // Routing specific state
  bool isRoutingVisualization = false;
  List<int>? _routingPath;
  int? _selectedStartNode;
  int? _selectedTargetNode;
  bool _showNodeSelectionError = false;

  @override
  void initState() {
    super.initState();
    _initializeGraph();
  }

  Future<void> _initializeGraph() async {
    try {
      graph = gv.Graph();
      nodeMap = {};
      algorithm = gv.FruchtermanReingoldAlgorithm();

      await Future.delayed(Duration.zero);
      _processGraphData();
      setState(() => _isGraphReady = true);
    } catch (e) {
      debugPrint('Graph init error: $e');
      setState(() => _isGraphReady = false);
    }
  }

  void _processGraphData() {
    if (widget.graphType == "mst") {
      // Eğer minimum spanning tree (MST) ise, getEdge metodunu kullan
      widget.graph.edges.forEach((edge) {
        final sourceNode = nodeMap.putIfAbsent(
          edge.source,
          () => gv.Node.Id(edge.source),
        );
        final targetNode = nodeMap.putIfAbsent(
          edge.destination,
          () => gv.Node.Id(edge.destination),
        );

        graph.addNode(sourceNode);
        graph.addNode(targetNode);

        // getEdge() null dönerse, kenarı çizme
        final mstEdge = widget.graph.getEdge(edge.source, edge.destination);
        if (mstEdge != null && !_edgeExists(sourceNode, targetNode)) {
          graph.addEdge(
            sourceNode,
            targetNode,
            paint:
                Paint()
                  ..color = Colors.blueGrey.shade300
                  ..strokeWidth = 2.5
                  ..style = PaintingStyle.stroke,
          );
        }
      });
    } else {
      // Varsayılan davranış: adjacencyList üzerinden grafik oluşturma
      widget.graph.adjacencyList.keys.forEach((node) {
        if (!nodeMap.containsKey(node)) {
          nodeMap[node] = gv.Node.Id(node);
          graph.addNode(nodeMap[node]!);
        }
      });

      widget.graph.adjacencyList.forEach((node, neighbors) {
        final sourceNode = nodeMap[node];
        if (sourceNode != null) {
          neighbors.forEach((neighbor) {
            final targetNode = nodeMap[neighbor];
            if (targetNode != null && !_edgeExists(sourceNode, targetNode)) {
              graph.addEdge(
                sourceNode,
                targetNode,
                paint:
                    Paint()
                      ..color = Colors.blueGrey.shade300
                      ..strokeWidth = 2.5
                      ..style = PaintingStyle.stroke,
              );
            }
          });
        }
      });
    }
  }

  bool _edgeExists(gv.Node source, gv.Node destination) {
    return graph.edges.any(
      (edge) => edge.source == source && edge.destination == destination,
    );
  }

  Widget _buildNodeWidget(gv.Node node) {
    final nodeId = node.key?.value as int?;
    if (nodeId == null) return Container();

    final isVisited = traversalOrder.contains(nodeId);
    final isCurrent =
        traversalOrder.isNotEmpty && nodeId == traversalOrder.last;
    final isMSTNode =
        isMSTVisualization &&
        (currentMSTStep is PrimStep &&
            (currentMSTStep as PrimStep).selectedNodes.contains(nodeId));

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: Duration(milliseconds: animationSpeed ~/ 2),
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color:
              isCurrent
                  ? Colors.red.shade400
                  : isMSTNode
                  ? Colors.green.shade400
                  : isVisited
                  ? Colors.blue.shade400
                  : Colors.teal.shade400,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 6,
              offset: Offset(2, 2),
            ),
          ],
          border: Border.all(
            color: isCurrent ? Colors.amber : Colors.white,
            width: isCurrent ? 3 : 2,
          ),
        ),
        child: Center(
          child:
              showLabels
                  ? Text(
                    nodeId.toString(),
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  )
                  : null,
        ),
      ),
    );
  }

  Widget _buildGraphVisualization() {
    if (!_isGraphReady) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Grafik yükleniyor...',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }
    widget.graph.edges.forEach((edge) {
      final sourceNode = nodeMap[edge.source];
      final destNode = nodeMap[edge.destination];
      if (sourceNode != null && destNode != null) {
        edge.updatePositions(
          Offset(sourceNode.position.dx, sourceNode.position.dy),
          Offset(destNode.position.dx, destNode.position.dy),
        );
      }
    });
    return RepaintBoundary(
      key: ScreenshotHelper.screenshotKey,
      child: Card(
        elevation: 8,
        margin: EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: InteractiveViewer(
            constrained: false,
            boundaryMargin: EdgeInsets.all(60),
            minScale: 0.001,
            maxScale: 3.0,
            child: Container(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height * 0.6,
              color: Colors.grey.shade50,
              child:
                  widget.graphType == "mst"
                      ? CustomPaint(
                        painter: GraphPainter(
                          currentStep: currentStep,
                          totalSteps: totalSteps,
                          graph: widget.graph,
                          traversalOrder: traversalOrder,
                          nodePositions: _calculateBuchheimWalkerNodePositions(
                            widget.graph,
                            context,
                          ),
                          showWeights: true, // Ağırlıkları göster
                          isMSTVisualization: isMSTVisualization,
                          highlightedEdges: currentMSTStep?.includedEdges,
                          currentNode:
                              currentMSTStep is PrimStep
                                  ? (currentMSTStep as PrimStep).currentNode
                                  : null,
                        ),
                      )
                      : widget.graphType == "shortestpath"
                      ? CustomPaint(
                        painter: GraphPainter(
                          traversalOrder: traversalOrder,
                          graph: widget.graph,
                          distances: currentShortestPathStep?.distances,
                          nodePositions: _calculateBuchheimWalkerNodePositions(
                            widget.graph,
                            context,
                          ),
                          showWeights: true,
                          isShortestPathVisualization: true,
                          startNode: _selectedStartNode,
                          targetNode: _selectedTargetNode,
                          previousNodes: currentShortestPathStep?.previousNodes,
                          currentStep: currentStep,
                          totalSteps: totalSteps,
                          isDirected: true,
                        ),
                      )
                      : widget.graphType == "distributedRoutingExamples"
                      ? CustomPaint(
                        painter: GraphPainter(
                          graph: widget.graph,
                          traversalOrder: traversalOrder,
                          nodePositions: _calculateBuchheimWalkerNodePositions(
                            widget.graph,
                            context,
                          ),
                          showWeights: true,
                          isShortestPathVisualization: false,
                          isMSTVisualization: false,
                          isDirected:
                              false, // Typically true for routing examples
                          currentStep: currentStep,
                          totalSteps: totalSteps,

                          // Distributed routing specific parameters
                          messages:
                              currentRoutingStep?.messages, // List<Message>
                          routingTables:
                              currentRoutingStep
                                  ?.routingTables, // Map<String, String>
                          activeMessageIndex:
                              currentRoutingStep?.activeMessageIndex,
                          messageQueues:
                              currentRoutingStep
                                  ?.messageQueues, // Map<String, List<String>>
                          processingNode: currentRoutingStep?.processingNode,
                          showMessagePaths: true,
                          showMessageContents: true,
                          messageProgress:
                              currentRoutingStep?.messageProgress ?? 0.0,
                        ),
                      )
                      : gv.GraphView(
                        graph: graph,
                        algorithm: algorithm,
                        builder: _buildNodeWidget,
                      ),
            ),
          ),
        ),
      ),
    );
  }

  Map<int, Offset> calculateSmartPathVisualization({
    required Graphs graph,
    required BuildContext context,
    List<int>? traversalOrder,
    Set<int>? visitedNodes,
    Set<String>? highlightedEdges,
  }) {
    final positions = <int, Offset>{};
    final size = Size(
      MediaQuery.of(context).size.width,
      MediaQuery.of(context).size.height * 0.6,
    );

    // 1. Handle empty graph
    if (graph.adjacencyList.isEmpty) return positions;

    // 2. Algorithm progress-based positioning
    if (traversalOrder != null && traversalOrder.isNotEmpty) {
      return _getTraversalBasedLayout(
        graph,
        size,
        traversalOrder,
        visitedNodes,
      );
    }

    // 3. Highlighted edges case (for Bellman-Ford)
    if (highlightedEdges != null && highlightedEdges.isNotEmpty) {
      return _getEdgeHighlightLayout(graph, size, highlightedEdges);
    }

    // 4. Standard layout (for Dijkstra start)
    return _getStandardPathLayout(graph, size);
  }

  Map<int, Offset> _getTraversalBasedLayout(
    Graphs graph,
    Size size,
    List<int> traversalOrder,
    Set<int>? visitedNodes,
  ) {
    final positions = <int, Offset>{};
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) * 0.45;

    // Separate visited and unvisited nodes for better visualization
    final visited = visitedNodes ?? <int>{};
    final unvisited = graph.adjacencyList.keys.toSet().difference(visited);

    // Position visited nodes in a spiral
    double angleStep = 2 * pi / graph.adjacencyList.length;
    double spiralFactor = 0.2;

    for (int i = 0; i < traversalOrder.length; i++) {
      final node = traversalOrder[i];
      if (!graph.adjacencyList.containsKey(node)) continue;

      double angle = angleStep * i;
      double spiralRadius =
          radius * (1 + spiralFactor * (i / traversalOrder.length));

      positions[node] = Offset(
        center.dx + spiralRadius * cos(angle),
        center.dy + spiralRadius * sin(angle),
      );
    }

    // Position unvisited nodes in an outer circle
    double outerRadius = radius * 1.5;
    double outerAngleStep = 2 * pi / (unvisited.length + 1);
    int outerIndex = 0;

    for (final node in unvisited) {
      if (!positions.containsKey(node)) {
        double angle = outerAngleStep * outerIndex++;
        positions[node] = Offset(
          center.dx + outerRadius * cos(angle),
          center.dy + outerRadius * sin(angle),
        );
      }
    }

    return positions;
  }

  Map<int, Offset> _getEdgeHighlightLayout(
    Graphs graph,
    Size size,
    Set<String> highlightedEdges,
  ) {
    final positions = <int, Offset>{};
    final activeEdges =
        highlightedEdges.map((e) {
          final parts = e.split('-');
          return Edge(
            source: int.parse(parts[0]),
            destination: int.parse(parts[1]),
          );
        }).toList();

    // Get all unique nodes from highlighted edges
    final activeNodes = <int>{};
    for (final edge in activeEdges) {
      activeNodes.add(edge.source);
      activeNodes.add(edge.destination);
    }

    // Edge-centered layout with better spacing
    double yStep = size.height / (activeEdges.length + 1);
    double xPadding = size.width * 0.2;

    // First position all nodes that are sources
    for (int i = 0; i < activeEdges.length; i++) {
      final node = activeEdges[i].source;
      if (!positions.containsKey(node)) {
        positions[node] = Offset(xPadding, yStep * (i + 1));
      }
    }

    // Then position destination nodes with column wrapping
    int column = 1;
    double xPosition = size.width - xPadding;
    for (int i = 0; i < activeEdges.length; i++) {
      final node = activeEdges[i].destination;
      if (!positions.containsKey(node)) {
        positions[node] = Offset(xPosition, yStep * (i + 1));
      }
    }

    return positions;
  }

  Map<int, Offset> _getStandardPathLayout(Graphs graph, Size size) {
    final positions = <int, Offset>{};
    final nodes = graph.adjacencyList.keys.toList();
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) * 0.5; // 0.4 → 0.5 (daha geniş)

    if (nodes.isEmpty) return positions;

    // Start node at center
    positions[nodes[0]] = center;

    // Other nodes in concentric circles based on distance from start
    final distances = _calculateDistancesFromStart(graph, nodes[0]);
    final distanceGroups = _groupNodesByDistance(distances);

    double angleStep = 2 * pi / 8; // 8 directions for better spacing
    for (final entry in distanceGroups.entries) {
      final distance = entry.key;
      final groupNodes = entry.value;
      final groupRadius = radius * (0.5 + distance * 0.3);

      for (int i = 0; i < groupNodes.length; i++) {
        positions[groupNodes[i]] = Offset(
          center.dx + groupRadius * cos(angleStep * i),
          center.dy + groupRadius * sin(angleStep * i),
        );
      }
    }

    return positions;
  }

  Map<int, int> _calculateDistancesFromStart(Graphs graph, int startNode) {
    final distances = <int, int>{};
    final queue = Queue<int>();
    queue.add(startNode);
    distances[startNode] = 0;

    while (queue.isNotEmpty) {
      final current = queue.removeFirst();
      for (final neighbor in graph.adjacencyList[current] ?? []) {
        if (!distances.containsKey(neighbor)) {
          distances[neighbor] = distances[current]! + 1;
          queue.add(neighbor);
        }
      }
    }

    return distances;
  }

  Map<int, List<int>> _groupNodesByDistance(Map<int, int> distances) {
    final groups = <int, List<int>>{};
    for (final entry in distances.entries) {
      groups.putIfAbsent(entry.value, () => []).add(entry.key);
    }
    return groups;
  }

  Map<int, Offset> calculateShortestPathNodePositions({
    required Graphs graph,
    required Map<int, int>? distances,
    required BuildContext context,
  }) {
    final positions = <int, Offset>{};
    if (graph.adjacencyList.isEmpty) return positions;

    final size = Size(
      MediaQuery.of(context).size.width,
      MediaQuery.of(context).size.height * 0.6,
    );

    // Grupları mesafeye göre ayır
    final distanceGroups = <int, List<int>>{};
    for (final entry in distances!.entries) {
      final dist = entry.value;
      distanceGroups.putIfAbsent(dist, () => []).add(entry.key);
    }

    final maxLevel = distanceGroups.keys.reduce(max);
    final verticalSpacing = size.height / (maxLevel + 2); // +2 padding
    final horizontalPadding = 60.0;

    for (final entry in distanceGroups.entries) {
      final dist = entry.key;
      final nodes = entry.value;
      final levelY = verticalSpacing * (dist + 1); // padding yukarıdan

      final horizontalSpacing =
          (size.width - 2 * horizontalPadding) / (nodes.length + 1);

      for (int i = 0; i < nodes.length; i++) {
        final x = horizontalPadding + (i + 1) * horizontalSpacing;
        positions[nodes[i]] = Offset(x, levelY);
      }
    }

    return positions;
  }

  Map<int, Offset> _calculateBuchheimWalkerNodePositions(
    Graphs graph,
    BuildContext context,
  ) {
    final positions = <int, Offset>{};
    if (graph.adjacencyList.isEmpty) return positions;

    final containerSize = Size(
      MediaQuery.of(context).size.width,
      MediaQuery.of(context).size.height * 0.6,
    );

    const rootY = 50.0;
    const levelHeight = 120.0;
    const siblingDistance = 100.0;

    final allNodes = graph.adjacencyList.keys.toSet();
    final visited = <int>{};
    final depths = <int, int>{};

    // Buchheim-Walker helper
    void _buchheimWalker(
      int nodeId,
      double x,
      double y,
      Map<int, List<int>> children,
    ) {
      positions[nodeId] = Offset(x, y);
      double childX = x - siblingDistance * (children[nodeId]?.length ?? 0) / 2;

      for (final child in children[nodeId]!) {
        _buchheimWalker(child, childX, y + levelHeight, children);
        childX += siblingDistance;
      }
    }

    // Handle disconnected components (or multiple roots)
    double xOffset = 0;

    while (visited.length < allNodes.length) {
      final rootNode = allNodes.difference(visited).first;
      final queue = Queue<int>();
      final children = <int, List<int>>{};

      queue.add(rootNode);
      visited.add(rootNode);
      depths[rootNode] = 0;

      while (queue.isNotEmpty) {
        final nodeId = queue.removeFirst();
        final nodeChildren = <int>[];

        for (final neighbor in graph.adjacencyList[nodeId] ?? []) {
          if (!visited.contains(neighbor)) {
            visited.add(neighbor);
            nodeChildren.add(neighbor);
            depths[neighbor] = depths[nodeId]! + 1;
            queue.add(neighbor);
          }
        }

        children[nodeId] = nodeChildren;
      }

      _buchheimWalker(
        rootNode,
        containerSize.width / 2 + xOffset,
        rootY,
        children,
      );
      xOffset += 250; // Yeni bileşenleri yana kaydır
    }

    return positions;
  }

  Map<int, Offset> _calculateMSTNodePositions(
    Graphs graph,
    BuildContext context,
  ) {
    final positions = <int, Offset>{};
    if (graph.adjacencyList.isEmpty) return positions;

    final containerSize = Size(
      MediaQuery.of(context).size.width,
      MediaQuery.of(context).size.height * 0.6,
    );

    // Constants for layout
    const rootY = 50.0;
    const levelHeight = 120.0;
    const siblingDistance = 100.0;
    const subtreeDistance = 200.0;

    // Find root node (node with minimum key or first node)
    final rootNode = graph.adjacencyList.keys.first;

    // Data structures
    final children = <int, List<int>>{};
    final depths = <int, int>{};
    final subtreeWidths = <int, double>{};
    final isLeaf = <int, bool>{};
    final visited = <int>{};

    // BFS to calculate depths and build tree structure
    final queue = Queue<int>();
    queue.add(rootNode);
    visited.add(rootNode);
    depths[rootNode] = 0;

    while (queue.isNotEmpty) {
      final nodeId = queue.removeFirst();
      final nodeChildren = <int>[];

      for (final neighbor in graph.adjacencyList[nodeId] ?? []) {
        if (!visited.contains(neighbor)) {
          visited.add(neighbor);
          nodeChildren.add(neighbor);
          depths[neighbor] = depths[nodeId]! + 1;
          queue.add(neighbor);
        }
      }

      children[nodeId] = nodeChildren;
      isLeaf[nodeId] = nodeChildren.isEmpty;
    }

    // Post-order traversal to calculate subtree widths (using stack to avoid recursion)
    final postOrderStack = <int>[];
    final processed = <int>{};
    postOrderStack.add(rootNode);

    while (postOrderStack.isNotEmpty) {
      final nodeId = postOrderStack.last;

      if (isLeaf[nodeId]! || children[nodeId]!.every(processed.contains)) {
        postOrderStack.removeLast();
        processed.add(nodeId);

        if (isLeaf[nodeId]!) {
          subtreeWidths[nodeId] = 0;
        } else {
          double totalWidth = 0;
          for (final child in children[nodeId]!) {
            totalWidth += subtreeWidths[child]! + siblingDistance;
          }
          totalWidth -= siblingDistance; // Remove last extra spacing
          subtreeWidths[nodeId] = totalWidth;
        }
      } else {
        for (final child in children[nodeId]!.reversed) {
          if (!processed.contains(child)) {
            postOrderStack.add(child);
          }
        }
      }
    }

    // Position nodes (using stack to avoid recursion)
    final positionStack = <MapEntry<int, Offset>>[];
    positionStack.add(
      MapEntry(rootNode, Offset(containerSize.width / 2, rootY)),
    );

    while (positionStack.isNotEmpty) {
      final entry = positionStack.removeLast();
      final nodeId = entry.key;
      final position = entry.value;

      positions[nodeId] = position;

      if (!isLeaf[nodeId]!) {
        // Calculate starting x position for children
        double childX = position.dx - subtreeWidths[nodeId]! / 2;
        final childY = position.dy + levelHeight;

        for (final child in children[nodeId]!) {
          final childWidth = subtreeWidths[child]!;
          positionStack.add(
            MapEntry(child, Offset(childX + childWidth / 2, childY)),
          );
          childX += childWidth + siblingDistance;
        }
      }
    }

    return positions;
  }

  // void _updateEdgeStyles() {
  //   if (!isMSTVisualization || currentMSTStep == null) return;

  //   graph.edges.forEach((edge) {
  //     final src = edge.source.key?.value as int;
  //     final dest = edge.destination.key?.value as int;
  //     final edgeKey = src < dest ? "$src-$dest" : "$dest-$src";

  //     // Varsayılan stil
  //     edge.paint =
  //         Paint()
  //           ..color = Colors.blueGrey.shade300
  //           ..strokeWidth = 2.5
  //           ..style = PaintingStyle.stroke;
  //     if (currentMSTStep is ReverseDeleteStep) {
  //       final step = currentMSTStep as ReverseDeleteStep;
  //       if (step.includedEdges.contains(_getEdgeKey(edge))) {
  //         edge.paint =
  //             Paint()
  //               ..color = const Color.fromARGB(255, 7, 7, 7)
  //               ..strokeWidth = 4;
  //       } else if (step.rejectedEdges.contains(_getEdgeKey(edge))) {
  //         edge.paint =
  //             Paint()
  //               ..color = Colors.red
  //               ..strokeWidth = 2;
  //       }
  //     }
  //     if (currentMSTStep is PrimStep) {
  //       final step = currentMSTStep as PrimStep;
  //       if (step.includedEdges.contains(edgeKey)) {
  //         edge.paint =
  //             Paint()
  //               ..color = Colors.green
  //               ..strokeWidth = 4.0
  //               ..style = PaintingStyle.stroke;
  //       }
  //     } else if (currentMSTStep is KruskalStep) {
  //       final step = currentMSTStep as KruskalStep;
  //       if (step.includedEdges.contains(edgeKey)) {
  //         edge.paint =
  //             Paint()
  //               ..color = Colors.green
  //               ..strokeWidth = 4.0
  //               ..style = PaintingStyle.stroke;
  //       } else if (step.rejectedEdges.contains(edgeKey)) {
  //         edge.paint =
  //             Paint()
  //               ..color = Colors.red
  //               ..strokeWidth = 2.0
  //               ..style = PaintingStyle.stroke;
  //       } else if (step.currentEdgeIndex >= 0 &&
  //           step.sortedEdges.length > step.currentEdgeIndex) {
  //         final currentEdge = step.sortedEdges[step.currentEdgeIndex];
  //         if ((currentEdge.source == src && currentEdge.destination == dest) ||
  //             (currentEdge.source == dest && currentEdge.destination == src)) {
  //           edge.paint =
  //               Paint()
  //                 ..color = Colors.blue
  //                 ..strokeWidth = 3.0
  //                 ..style = PaintingStyle.stroke;
  //         }
  //       }
  //     }
  //   });
  // }

  String _getEdgeKey(gv.Edge edge) {
    final src = edge.source.key?.value as int;
    final dest = edge.destination.key?.value as int;
    return src < dest ? "$src-$dest" : "$dest-$src";
  }

  Widget _buildMSTControls() {
    if (!isMSTVisualization || currentMSTStep == null) return SizedBox();
    String algorithmName;
    switch (currentAlgorithm) {
      case MSTAlgorithm.Prim:
        algorithmName = "Prim";
        break;
      case MSTAlgorithm.Kruskal:
        algorithmName = "Kruskal";
        break;
      case MSTAlgorithm.ReverseDelete:
        algorithmName = "Reverse-Delete";
        break;
      default:
        algorithmName = "MST Algoritması";
    }

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          children: [
            Text(
              algorithmName,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(currentMSTStep!.description),
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(Icons.skip_previous),
                  onPressed: _canGoToPreviousStep() ? _goToPreviousStep : null,
                ),
                Text(
                  _getCurrentStepInfo(),
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: Icon(Icons.skip_next),
                  onPressed: _canGoToNextStep() ? _goToNextStep : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  bool _canGoToPreviousStep() {
    return currentStep > 0 && !_isProcessing;
  }

  bool _canGoToNextStep() {
    return currentStep < totalSteps && !_isProcessing;
  }

  void _goToPreviousStep() {
    if (_canGoToPreviousStep()) {
      setState(() {
        _currentStepIndex--;
        currentMSTStep = _algorithmSteps[_currentStepIndex];
        currentStep = currentMSTStep!.currentStep;
        _updateVisualizationForCurrentStep();
      });
      // Burada algoritma durumunu geri almanız gerekir
    }
  }

  void _goToNextStep() {
    if (_canGoToNextStep()) {
      setState(() {
        _currentStepIndex++;
        currentMSTStep = _algorithmSteps[_currentStepIndex];
        currentStep = currentMSTStep!.currentStep;
        _updateVisualizationForCurrentStep();
      });
      // Burada algoritma durumunu ileri almanız gerekir
    }
  }

  String _getCurrentStepInfo() {
    return 'Adım: $currentStep/$totalSteps';
  }

  Widget _buildControlPanel() {
    final bool isWeightedGraph = widget.graph.edgeWeights.isNotEmpty;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.speed, color: Colors.blueGrey),
              SizedBox(width: 8),
              Expanded(
                child: Slider(
                  value: animationSpeed,
                  min: 100,
                  max: 1000,
                  divisions: 9,
                  label: "Animasyon Hızı: ${animationSpeed.round()}ms",
                  onChanged: (value) => setState(() => animationSpeed = value),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              ..._buildAlgorithmButtons(),
              _buildActionButton(
                icon: Icons.settings,
                label: "Ayarlar",
                color: Colors.grey,
                onPressed: _toggleLabels,
              ),
              _buildActionButton(
                icon: Icons.add,
                label: "Yeni",
                color: Colors.teal,
                onPressed: _createNewGraph,
              ),
              _buildActionButton(
                icon: Icons.camera,
                label: "Dışa Aktar",
                color: Colors.red,
                onPressed: _captureAndSaveScreenshot,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Butonları grafik türüne göre oluşturan yardımcı metot
  List<Widget> _buildAlgorithmButtons() {
    if (widget.graphType == "mst") {
      return [
        _buildActionButton(
          icon: Icons.linear_scale,
          label: "Prim",
          color: Colors.orange,
          onPressed: _startPrimVisualization,
          isLoading: _isProcessing,
        ),
        _buildActionButton(
          icon: Icons.merge,
          label: "Kruskal",
          color: Colors.purple,
          onPressed: _startKruskalVisualization,
          isLoading: _isProcessing,
        ),
        _buildActionButton(
          icon: Icons.delete_outline,
          label: "Reverse-Delete",
          color: Colors.redAccent,
          onPressed: _startReverseDeleteVisualization,
        ),
      ];
    } else if (widget.graphType == "shortestpath") {
      return [
        _buildActionButton(
          icon: Icons.linear_scale,
          label: "Dijkstra",
          color: Colors.blue,
          onPressed: () => _showNodeSelectionDialog(true),
          isLoading: _isProcessing,
        ),
        _buildActionButton(
          icon: Icons.warning,
          label: "Bellman-Ford",
          color: Colors.deepPurple,
          onPressed: () => _showNodeSelectionDialog(false),
          isLoading: _isProcessing,
        ),
      ];
    } else if (widget.graphType == "linkedList" ||
        widget.graphType == "matrix" ||
        widget.graphType == "distributedRoutingExamples") {
      return [
        _buildActionButton(
          icon: Icons.play_arrow,
          label: "BFS",
          color: Colors.blue,
          onPressed: () => _runTraversal(startBFS, "BFS"),
          isLoading: _isProcessing,
        ),
        _buildActionButton(
          icon: Icons.play_arrow,
          label: "DFS",
          color: Colors.green,
          onPressed: () => _runTraversal(startDFS, "DFS"),
          isLoading: _isProcessing,
        ),
        _buildActionButton(
          icon: Icons.send,
          label: "Routing",
          color: Colors.deepOrange,
          onPressed: startDistanceVectorRouting,
        ),
      ];
    }
    return [];
  }

  Future<void> startDistanceVectorRouting() async {
    setState(() {
      _isProcessing = true;
      _routingSteps.clear();
      currentRoutingStep = null;
      currentStep = 0;
    });

    final result = await _showRoutingParametersDialog();
    if (result == null) {
      setState(() => _isProcessing = false);
      return;
    }

    final int startNode = result['startNode'];
    final int targetNode = result['targetNode'];
    final String messageContent = result['message'];

    final routingTables = <String, String>{}; // int key
    final messageQueues = <int, List<String>>{};
    final visited = <int>{};
    final queue = Queue<int>()..add(startNode);

    widget.graph.adjacencyList.forEach((int node, List<int> neighbors) {
      final table = <String, dynamic>{
        'düğüm': node.toString(),
        'vektör': {
          for (final neighbor in neighbors)
            neighbor.toString(): {
              'mesafe': widget.graph.getEdge(node, neighbor)?.weight ?? 1,
              'Sıradaki Sıçrama.': neighbor.toString(),
            },
        },
      };
      routingTables[node.toString()] = jsonEncode(table);
      messageQueues[node] = [];
    });

    while (queue.isNotEmpty) {
      final int node = queue.removeFirst();
      visited.add(node);

      setState(() {
        currentRoutingStep = RoutingStep(
          currentStep: currentStep++,
          totalSteps: widget.graph.adjacencyList.length * 2,
          description: '$node düğümü güncellemeleri işliyor',
          messages: [],
          routingTables: Map.of(routingTables),
          processingNode: node,
          messageQueues: Map.fromEntries(
            messageQueues.entries.map(
              (e) => MapEntry(e.key.toString(), e.value),
            ),
          ),
        );
      });
      await Future.delayed(Duration(milliseconds: animationSpeed.round()));

      final neighbors = widget.graph.adjacencyList[node]!;
      for (final int neighbor in neighbors) {
        if (!visited.contains(neighbor)) {
          final message = Message(
            sourceNodeId: node.toString(),
            destinationNodeId: neighbor.toString(),
            content: messageContent,
          );

          if (messageQueues[neighbor]!.isEmpty) {
            messageQueues[neighbor]!.add(message.content);

            for (double progress = 0.0; progress <= 1.0; progress += 0.1) {
              setState(() {
                currentRoutingStep = RoutingStep(
                  currentStep: currentStep++,
                  totalSteps: widget.graph.adjacencyList.length * 2,
                  description: '$node → $neighbor mesaj gönderiyor',
                  messages: [message],
                  routingTables: Map.of(routingTables),
                  activeMessageIndex: 0,
                  processingNode: node,
                  messageQueues: Map.fromEntries(
                    messageQueues.entries.map(
                      (e) => MapEntry(e.key.toString(), e.value),
                    ),
                  ),
                  messageProgress: progress,
                );
              });
              await Future.delayed(
                Duration(milliseconds: animationSpeed.round()),
              );
            }

            queue.add(neighbor);
          }
        }
      }
    }

    final path = await _findPath(startNode, targetNode);

    setState(() {
      _isProcessing = false;
      currentRoutingStep = RoutingStep(
        currentStep: currentStep,
        totalSteps: widget.graph.adjacencyList.length * 2,
        description: 'Yönlendirme tabloları kararlı durumda',
        messages: [],
        routingTables: Map.fromEntries(
          routingTables.entries.map((e) => MapEntry(e.key.toString(), e.value)),
        ),
        messageQueues: Map.fromEntries(
          messageQueues.entries.map((e) => MapEntry(e.key.toString(), e.value)),
        ),
      );
    });

    if (path != null && path.isNotEmpty) {
      _showRoutingResults(path);
    } else {
      _showErrorDialog('Başlangıç ve hedef arasında yol bulunamadı!');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Hata'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Tamam'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showRoutingResults(List<int> path) async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Routing Tamamlandı'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Başlangıç: ${path.first}'),
              Text('Hedef: ${path.last}'),
              SizedBox(height: 10),
              Text('Bulunan Yol:'),
              SizedBox(height: 5),
              Text(
                path.join(' → '),
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text('Toplam Adım: ${path.length - 1}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Tamam'),
            ),
          ],
        );
      },
    );
  }

  Future<Map<String, dynamic>?> _showRoutingParametersDialog() async {
    final availableNodes = widget.graph.adjacencyList.keys.toList();
    int? selectedStartNode;
    int? selectedTargetNode;
    String messageContent = '';

    return await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Routing Parametreleri'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                value: selectedStartNode,
                decoration: InputDecoration(labelText: 'Başlangıç Düğümü'),
                items:
                    availableNodes.map((node) {
                      return DropdownMenuItem<int>(
                        value: node,
                        child: Text('Düğüm $node'),
                      );
                    }).toList(),
                onChanged: (value) {
                  selectedStartNode = value;
                },
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: selectedTargetNode,
                decoration: InputDecoration(labelText: 'Hedef Düğüm'),
                items:
                    availableNodes.map((node) {
                      return DropdownMenuItem<int>(
                        value: node,
                        child: Text('Düğüm $node'),
                      );
                    }).toList(),
                onChanged: (value) {
                  selectedTargetNode = value;
                },
              ),
              SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(labelText: 'Mesaj'),
                onChanged: (value) {
                  messageContent = value;
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('İptal'),
            ),
            TextButton(
              onPressed: () {
                if (selectedStartNode != null && selectedTargetNode != null) {
                  Navigator.pop(context, {
                    'startNode': selectedStartNode,
                    'targetNode': selectedTargetNode,
                    'message': messageContent,
                  });
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Lütfen tüm alanları doldurun!')),
                  );
                }
              },
              child: Text('Başlat'),
            ),
          ],
        );
      },
    );
  }

  Future<List<int>?> _findPath(int start, int target) async {
    final visited = <int>{};
    final queue = Queue<List<int>>();
    queue.add([start]);

    while (queue.isNotEmpty) {
      final currentPath = queue.removeFirst();
      final currentNode = currentPath.last;

      // Eğer hedef düğüme ulaşıldıysa, yolu döndür
      if (currentNode == target) {
        setState(() {
          traversalOrder.add(currentNode); // Yalnızca hedef düğümde güncelle
        });
        return currentPath;
      }

      if (!visited.contains(currentNode)) {
        visited.add(currentNode);

        for (final neighbor in widget.graph.adjacencyList[currentNode] ?? []) {
          if (!visited.contains(neighbor)) {
            final newPath = List<int>.from(currentPath)..add(neighbor);

            // Yalnızca kenar kontrolü için görselleştirme güncellemesi
            setState(() {
              traversalOrder.add(neighbor);
            });
            await Future.delayed(Duration(milliseconds: animationSpeed ~/ 2));

            queue.add(newPath);
          }
        }
      }
    }

    return null; // Yol bulunamadı
  }

  Future<void> _runTraversal(
    Future<void> Function() traversal,
    String algorithmName,
  ) async {
    if (!_isGraphReady || _isProcessing) return;

    setState(() {
      _isProcessing = true;
      traversalOrder.clear();
      isMSTVisualization = false;
      currentMSTStep = null;
    });

    try {
      await traversal();
      _showTraversalResults(algorithmName);
    } catch (e) {
      debugPrint('Traversal error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hata: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
    bool isLoading = false,
  }) {
    return Tooltip(
      message: label,
      child: ElevatedButton.icon(
        icon:
            isLoading
                ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                : Icon(icon, size: 20),
        label: Text(label),
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Grafik Görselleştirici"),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.info_outline),
            onPressed: () {
              bool connected = widget.graph.isConnected();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    connected ? "Graf bağlantılı!" : "Graf bağlantılı değil!",
                  ),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(child: _buildGraphVisualization()),
          _buildMSTControls(),
          _buildControlPanel(),
        ],
      ),
    );
  }

  void _showTraversalResults(String algorithmName) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('$algorithmName Tamamlandı'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Ziyaret Edilen Düğüm Sayısı: ${traversalOrder.length}'),
                SizedBox(height: 10),
                Text('Ziyaret Sırası:'),
                SizedBox(height: 5),
                Text(
                  traversalOrder.join(' → '),
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Tamam'),
              ),
            ],
          ),
    );
  }

  Future<void> _startDijkstraVisualization() async {
    if (!_isGraphReady || _isProcessing) return;

    setState(() {
      _isProcessing = true;
      _shortestPathSteps.clear();
      _currentStepIndex = -1;
      traversalOrder.clear();
      isShortestPathVisualization = true;
      isMSTVisualization = false;
      currentDijkstra = DijsktraAlgorithm.ShortestPath;
      currentStep = 0;
      totalSteps = 1;
    });

    final visualizer = DijkstraVisualizer(
      graph: widget.graph,
      animationSpeed: animationSpeed.round(),
      onStepUpdate: (step) {
        setState(() {
          _shortestPathSteps.add(step);
          _currentStepIndex = _shortestPathSteps.length - 1;
          currentShortestPathStep = step;
          currentStep = step.currentStep;
          totalSteps = step.totalSteps;
        });
      },
      onComplete: () {
        setState(() => _isProcessing = false);
        _showShortestPathResults("Dijkstra");
      },
    );

    await visualizer.visualize(_selectedStartNode!, _selectedTargetNode);
  }

  Future<void> _startBellmanFordVisualization() async {
    if (!_isGraphReady || _isProcessing) return;

    setState(() {
      _isProcessing = true;
      _shortestPathSteps.clear();
      _currentStepIndex = -1;
      traversalOrder.clear();
      isShortestPathVisualization = true;
      isMSTVisualization = false;
      currentDijkstra = DijsktraAlgorithm.BelmanFord;
      currentStep = 0;
      totalSteps = 1;
    });

    final visualizer = BellmanFordVisualizer(
      graph: widget.graph,
      animationSpeed: animationSpeed.round(),
      onStepUpdate: (step) {
        setState(() {
          _shortestPathSteps.add(step);
          _currentStepIndex = _shortestPathSteps.length - 1;
          currentShortestPathStep = step;
          currentStep = step.currentStep;
          totalSteps = step.totalSteps;
        });
      },
      onComplete: (hasNegativeCycle) {
        setState(() => _isProcessing = false);
        _showShortestPathResults(
          "Bellman-Ford",
          hasNegativeCycle: hasNegativeCycle,
        );
      },
    );

    await visualizer.visualize(_selectedStartNode!, _selectedTargetNode);
  }

  void _checkAndRunShortestPathAlgorithm(bool isDijkstra) {
    if (_selectedStartNode == null) {
      setState(() => _showNodeSelectionError = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lütfen bir başlangıç düğümü seçin!'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (isDijkstra) {
      _startDijkstraVisualization();
    } else {
      _startBellmanFordVisualization();
    }
  }

  Future<void> _showNodeSelectionDialog(bool isDijkstra) async {
    final availableNodes = widget.graph.adjacencyList.keys.toList();

    await showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: Text(
                  '${isDijkstra ? 'Dijkstra' : 'Bellman-Ford'} Parametreleri',
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<int>(
                      value: _selectedStartNode,
                      decoration: InputDecoration(
                        labelText: 'Başlangıç Düğümü',
                        errorText:
                            _showNodeSelectionError &&
                                    _selectedStartNode == null
                                ? 'Bu alan zorunludur'
                                : null,
                      ),
                      items:
                          availableNodes.map((node) {
                            return DropdownMenuItem<int>(
                              value: node,
                              child: Text('Düğüm $node'),
                            );
                          }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedStartNode = value;
                          _showNodeSelectionError = false;
                        });
                      },
                    ),
                    SizedBox(height: 16),
                    DropdownButtonFormField<int>(
                      value: _selectedTargetNode,
                      decoration: InputDecoration(
                        labelText: 'Hedef Düğüm (Opsiyonel)',
                      ),
                      items: [
                        DropdownMenuItem<int>(
                          value: null,
                          child: Text('Hedef Düğüm Seç'),
                        ),
                        ...availableNodes.map((node) {
                          return DropdownMenuItem<int>(
                            value: node,
                            child: Text('Düğüm $node'),
                          );
                        }).toList(),
                      ],
                      onChanged:
                          (value) =>
                              setState(() => _selectedTargetNode = value),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('İptal'),
                  ),
                  TextButton(
                    onPressed: () {
                      if (_selectedStartNode != null) {
                        Navigator.pop(context);
                        _checkAndRunShortestPathAlgorithm(isDijkstra);
                      } else {
                        setState(() => _showNodeSelectionError = true);
                      }
                    },
                    child: Text('Başlat'),
                  ),
                ],
              );
            },
          ),
    );
  }

  void _showShortestPathResults(
    String algorithmName, {
    bool hasNegativeCycle = false,
  }) {
    if (hasNegativeCycle) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$algorithmName: Negative cycle detected!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // showDialog(
    //   context: context,
    //   builder:
    //       (context) => AlertDialog(
    //         title: Text('$algorithmName Results'),
    //         content: Column(
    //           mainAxisSize: MainAxisSize.min,
    //           crossAxisAlignment: CrossAxisAlignment.start,
    //           children: [
    //             Text('Kaynak Düğüm: 0'),
    //             SizedBox(height: 10),
    //             Text('Düğüm Mesafeleri:'),
    //             SizedBox(height: 5),
    //             ..._buildDistanceList(),
    //           ],
    //         ),
    //         actions: [
    //           TextButton(
    //             onPressed: () => Navigator.pop(context),
    //             child: Text('Tamam'),
    //           ),
    //         ],
    //       ),
    // );
  }

  List<Widget> _buildDistanceList() {
    final distances = currentShortestPathStep?.distances ?? {};
    return distances.entries.map((entry) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2.0),
        child: Row(
          children: [
            Text('${entry.key}: '),
            Text(
              entry.value == double.infinity ? '∞' : entry.value.toString(),
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }).toList();
  }

  Future<void> _startPrimVisualization() async {
    if (!_isGraphReady || _isProcessing) return;

    setState(() {
      _isProcessing = true;
      _algorithmSteps.clear();
      _currentStepIndex = -1;
      traversalOrder.clear();
      isMSTVisualization = true;
      currentAlgorithm = MSTAlgorithm.Prim;
      currentStep = 0;
      totalSteps = 1; // Başlangıç değeri
    });

    final visualizer = PrimMSTVisualizer(
      graph: widget.graph,
      animationSpeed: animationSpeed.round(),
      onStepUpdate: (step) {
        setState(() {
          _algorithmSteps.add(step); // Adımı listeye ekle
          _currentStepIndex = _algorithmSteps.length - 1;
          currentMSTStep = step;
          currentStep = step.currentStep; // currentStep'i step'ten al
          totalSteps = currentStep; // Geçici olarak totalSteps'i güncelle
        });
      },
      onComplete: () {
        setState(() {
          _isProcessing = false;
          _finalTotalSteps = currentStep; // Son currentStep'i sakla
          totalSteps = _finalTotalSteps; // totalSteps'i sabitle
        });
      },
    );

    await visualizer.visualize();
  }

  Future<void> _startKruskalVisualization() async {
    if (!_isGraphReady || _isProcessing) return;

    setState(() {
      _isProcessing = true;
      _algorithmSteps.clear();
      _currentStepIndex = -1;
      traversalOrder.clear();
      isMSTVisualization = true;
      currentAlgorithm = MSTAlgorithm.Kruskal;
      currentStep = 0;
      totalSteps = 1; // Başlangıç değeri
    });

    final visualizer = KruskalMSTVisualizer(
      graph: widget.graph,
      animationSpeed: animationSpeed.round(),
      onStepUpdate: (step) {
        setState(() {
          _algorithmSteps.add(step); // Adımı listeye ekle
          _currentStepIndex = _algorithmSteps.length - 1;
          currentMSTStep = step;
          currentStep = step.currentStep; // currentStep'i step'ten al
          totalSteps = currentStep; // Geçici olarak totalSteps'i güncelle
        });
      },
      onComplete: () {
        setState(() {
          _isProcessing = false;
          _finalTotalSteps = currentStep; // Son currentStep'i sakla
          totalSteps = _finalTotalSteps; // totalSteps'i sabitle
        });
      },
    );

    await visualizer.visualize();
  }

  Future<void> _startReverseDeleteVisualization() async {
    if (!_isGraphReady || _isProcessing) return;

    setState(() {
      _isProcessing = true;
      _algorithmSteps.clear(); // Adım geçmişini temizle
      _currentStepIndex = -1;
      traversalOrder.clear();
      isMSTVisualization = true;
      currentAlgorithm = MSTAlgorithm.ReverseDelete;
      currentStep = 0;
      // Her kenar için 2 adım (silme denemesi + bağlantı kontrolü)
      totalSteps = currentStep;
    });

    final visualizer = ReverseDeleteMSTVisualizer(
      graph: widget.graph,
      animationSpeed: animationSpeed.round(),
      onStepUpdate: (step) {
        setState(() {
          _algorithmSteps.add(step); // Adımı geçmişe ekle
          _currentStepIndex = _algorithmSteps.length - 1;
          currentMSTStep = step;
          currentStep = step.currentStep;
          _updateVisualizationForCurrentStep(); // Görseli güncelle
        });
      },
      onComplete: () {
        setState(() {
          _isProcessing = false;
          // Son adımda kaldığımızdan emin ol
          _currentStepIndex = _algorithmSteps.length - 1;
          _finalTotalSteps = currentStep; // En son currentStep'i sakla
          totalSteps = _finalTotalSteps;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Reverse-Delete tamamlandı!")));
      },
    );

    await visualizer.visualize();
  }

  Future<void> startBFS() async {
    await bfs(widget.graph, 0, (currentNode) async {
      setState(() => traversalOrder.add(currentNode));
      await Future.delayed(Duration(milliseconds: animationSpeed.round()));
    }, animationSpeed.round());
  }

  void _updateVisualizationForCurrentStep() {
    if (_algorithmSteps.isEmpty || _currentStepIndex < 0) return;

    final step = _algorithmSteps[_currentStepIndex];

    setState(() {
      currentMSTStep = step;
      currentStep = step.currentStep;
      totalSteps = step.totalSteps;
    });
  }

  Future<void> startDFS() async {
    await dfs(widget.graph, 0, (currentNode) async {
      setState(() => traversalOrder.add(currentNode));
      await Future.delayed(Duration(milliseconds: animationSpeed.round()));
    }, animationSpeed.round());
  }

  void _createNewGraph() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => InputScreen()),
    );
  }

  Future<void> _captureAndSaveScreenshot() async {
    await ScreenshotHelper.captureAndSaveGraph(context);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("Ekran görüntüsü kaydedildi!")));
  }

  void _toggleLabels() {
    setState(() => showLabels = !showLabels);
  }
}
