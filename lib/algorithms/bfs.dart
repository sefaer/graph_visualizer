import 'dart:async';
import 'dart:collection';

import 'package:graph_visualizer/models/graphs.dart';

Future<void> bfs(Graphs graph, int startNode, Function(int) onStep, int animationSpeed) async {
  List<int> visited = [];
  Queue<int> queue = Queue();

  queue.add(startNode);
  visited.add(startNode);

  while (queue.isNotEmpty) {
    int currentNode = queue.removeFirst();
    onStep(currentNode); // Adımı bildir

    // Komşuları kontrol et
    for (int neighbor in graph.adjacencyList[currentNode] ?? []) {
      if (!visited.contains(neighbor)) {
        visited.add(neighbor);
        queue.add(neighbor);
      }
    }

    await Future.delayed(Duration(milliseconds: animationSpeed));
  }
}