import 'dart:async';
import 'dart:collection';

import 'package:graph_visualizer/models/graphs.dart';

/// Enhanced BFS algorithm that tracks update relationships between nodes
Future<void> updateBfs(
  Graphs graph,
  int startNode,
  Function(int) onStep,
  int animationSpeed,
) async {
  final visited = <int>{};
  final queue = Queue<int>();
  final updateRelations = <int, int>{}; // Tracks which node updated each node

  queue.add(startNode);
  visited.add(startNode);
  updateRelations[startNode] = -1; // Mark start node as having no updater

  while (queue.isNotEmpty) {
    final currentNode = queue.removeFirst();
    await onStep(currentNode); // Process current node

    // Get and sort neighbors for consistent update order
    final neighbors = (graph.adjacencyList[currentNode] ?? []).toList()..sort();

    for (final neighbor in neighbors) {
      if (!visited.contains(neighbor)) {
        visited.add(neighbor);
        queue.add(neighbor);
        updateRelations[neighbor] =
            currentNode; // Track which node caused the update

        // Optional: Add delay for visualization between neighbor updates
        await Future.delayed(Duration(milliseconds: animationSpeed));
      }
    }
  }

  // Optional: Print update relationships for debugging
  print('Update Relationships:');
  updateRelations.forEach((node, updatedBy) {
    print(
      'Node $node was updated by ${updatedBy == -1 ? 'start' : 'node $updatedBy'}',
    );
  });
}
