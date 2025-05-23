import 'dart:async';

import 'package:graph_visualizer/models/graphs.dart';

import 'dart:collection';

Future<void> dfs(
  Graphs graph,
  int startNode,
  Function(int) onStep,
  int animationSpeed,
) async {
  Set<int> visited = {};
  Stack<int> stack = Stack();
  stack.push(startNode);

  while (!stack.isEmpty) {
    int currentNode = stack.pop();

    if (!visited.contains(currentNode)) {
      visited.add(currentNode);
      onStep(currentNode); // Adımı bildir

      // Komşuları stack'e ekle (ters sırada ekleyerek DFS sırasını koru)
      for (int neighbor in graph.adjacencyList[currentNode] ?? []) {
        if (!visited.contains(neighbor)) {
          stack.push(neighbor);
        }
      }

      // Her adım arasında gecikme ekle
      await Future.delayed(Duration(milliseconds: animationSpeed));
    }
  }
}

class Stack<T> {
  final List<T> _items = [];

  void push(T item) {
    _items.add(item);
  }

  T pop() {
    if (_items.isEmpty) {
      throw StateError("Stack boş!");
    }
    return _items.removeLast();
  }

  bool get isEmpty => _items.isEmpty;
}
