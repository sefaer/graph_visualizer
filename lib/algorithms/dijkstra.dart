import 'package:graph_visualizer/models/graphs.dart';
import 'package:graph_visualizer/models/shortespath_models.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

class DijkstraVisualizer {
  final Graphs graph;
  final int animationSpeed;
  final ValueChanged<DijkstraStep> onStepUpdate;
  final VoidCallback onComplete;

  DijkstraVisualizer({
    required this.graph,
    required this.animationSpeed,
    required this.onStepUpdate,
    required this.onComplete,
  });

  Future<void> visualize(int start, int? target) async {
    final distances = <int, double>{};
    final visited = <int>{};
    final previousNodes = <int, int?>{};
    final frontier = PriorityQueue<MapEntry<int, double>>(
      (a, b) => a.value.compareTo(b.value),
    );
    int stepCount = 0;
    const double maxDistance = double.infinity;

    // Initialize
    for (var node in graph.adjacencyList.keys) {
      distances[node] = maxDistance;
      previousNodes[node] = null;
    }
    distances[start] = 0;
    frontier.add(MapEntry(start, 0));

    // Toplam adımları tahmin edin (sıfıra bölünmeyi önlemek için en az 1)
    final totalSteps = (graph.adjacencyList.length * 2).clamp(1, 100);

    // Initial step
    _updateStep(
      stepCount++,
      totalSteps,
      currentNode: -1,
      frontier: frontier,
      distances: distances,
      visited: visited,
      previousNodes: previousNodes,
      description: "Initialization: Start node $start with distance 0",
    );
    await _delay();

    while (frontier.isNotEmpty) {
      final current = frontier.removeFirst().key;

      // Zaten ziyaret edildiyse atla
      if (visited.contains(current)) continue;

      // Ziyaret edilenleri işaretle
      visited.add(current);

      // Komşuları işlemeden önce güncelle
      _updateStep(
        stepCount++,
        totalSteps,
        currentNode: current,
        frontier: frontier,
        distances: distances,
        visited: visited,
        previousNodes: previousNodes,
        description: "Processing node $current",
      );
      await _delay();

      // Hedef düğüm bulunursa erken sonlandırma
      if (target != null && current == target) break;

      // Process komşular
      for (final neighbor in graph.adjacencyList[current] ?? []) {
        final weight = graph.getEdgeWeight(current, neighbor).toDouble();
        final newDist = distances[current]! + weight;

        if (newDist < distances[neighbor]!) {
          distances[neighbor] = newDist;
          previousNodes[neighbor] = current;
          frontier.add(MapEntry(neighbor, newDist));

          // Update after relaxation
          _updateStep(
            stepCount++,
            totalSteps,
            currentNode: current,
            frontier: frontier,
            distances: distances,
            visited: visited,
            previousNodes: previousNodes,
            description:
                "Updated distance to $neighbor: ${newDist.toStringAsFixed(1)} via $current",
          );
          await _delay();
        }
      }
    }

    // Final step
    _updateStep(
      stepCount++,
      totalSteps,
      currentNode: -1,
      frontier: frontier,
      distances: distances,
      visited: visited,
      previousNodes: previousNodes,
      description:
          target != null
              ? "Hedef düğüm $target'a en kısa yol bulundu!"
              : "Algoritma tamamlandı! Tüm en kısa yollar hesaplandı",
    );
    await _delay();

    onComplete();
  }

  void _updateStep(
    int currentStep,
    int totalSteps, {
    required int currentNode,
    required PriorityQueue<MapEntry<int, double>> frontier,
    required Map<int, double> distances,
    required Set<int> visited,
    required Map<int, int?> previousNodes,
    required String description,
  }) {
    onStepUpdate(
      DijkstraStep(
        currentNode: currentNode,
        frontier: Set.from(frontier.toList().map((e) => e.key)),
        distances: Map.from(distances),
        visited: Set.from(visited),
        description: description,
        currentStep: currentStep,
        totalSteps: totalSteps,
        previousNodes: Map.from(previousNodes),
      ),
    );
  }

  Future<void> _delay() async {
    await Future.delayed(Duration(milliseconds: animationSpeed));
  }
}
