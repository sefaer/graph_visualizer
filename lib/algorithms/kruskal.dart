import '../../models/graphs.dart';
import '../../models/mst_models.dart';
import 'package:flutter/material.dart';

class KruskalMSTVisualizer {
  final Graphs graph;
  final int animationSpeed;
  final ValueChanged<KruskalStep> onStepUpdate;
  final VoidCallback onComplete;

  KruskalMSTVisualizer({
    required this.graph,
    required this.animationSpeed,
    required this.onStepUpdate,
    required this.onComplete,
  });

  Future<void> visualize() async {
    final edges = _extractEdges();
    edges.sort((a, b) => a.weight.compareTo(b.weight));

    final parent = List.generate(graph.adjacencyList.keys.length, (i) => i);
    final rank = List.filled(graph.adjacencyList.keys.length, 0);
    final includedEdges = <String>{};
    final rejectedEdges = <String>{};

    onStepUpdate(
      KruskalStep(
        rejectedEdges: {},
        sortedEdges: edges,
        currentEdgeIndex: -1,
        includedEdges: {},
        description: "Kenarlar sıralandı (${edges.length} kenar)",
        parentMap: Map.fromIterables(
          List.generate(parent.length, (i) => i),
          parent,
        ),
        currentStep: 0,
        totalSteps: edges.length
      ),
    );

    await Future.delayed(Duration(milliseconds: animationSpeed));

    for (int i = 0; i < edges.length; i++) {
      final edge = edges[i];
      final x = _find(parent, edge.source);
      final y = _find(parent, edge.destination);
      final edgeKey = "${edge.source}-${edge.destination}";

      if (x == y) {
        rejectedEdges.add(edgeKey);
        onStepUpdate(
          KruskalStep(
            rejectedEdges: {...rejectedEdges},
            sortedEdges: edges,
            currentEdgeIndex: i,
            includedEdges: {...includedEdges},
            description:
                "Kenar ${edge.source}-${edge.destination} (${edge.weight}) atlandı",
            parentMap: Map.fromIterables(
              List.generate(parent.length, (i) => i),
              parent,
            ),
             currentStep: i+1,
        totalSteps: edges.length
          ),
        );
      } else {
        includedEdges.add(edgeKey);
        _union(parent, rank, x, y);
        onStepUpdate(
          KruskalStep(
            rejectedEdges: {...rejectedEdges},
            sortedEdges: edges,
            currentEdgeIndex: i,
            includedEdges: {...includedEdges},
            description:
                "Kenar ${edge.source}-${edge.destination} (${edge.weight}) eklendi",
            parentMap: Map.fromIterables(
              List.generate(parent.length, (i) => i),
              parent,
            ),
                  currentStep: i+1,
        totalSteps: edges.length
            
          ),
        );
      }

      await Future.delayed(Duration(milliseconds: animationSpeed));
    }

    onComplete();
  }

  List<Edge> _extractEdges() {
    final edges = <Edge>[];
    final added = <String>{};

    graph.adjacencyList.forEach((u, neighbors) {
      neighbors.forEach((v) {
        final edgeKey = u < v ? "$u-$v" : "$v-$u";
        if (!added.contains(edgeKey)) {
          edges.add(
            Edge(source: u, destination: v, weight: graph.getEdgeWeight(u, v)),
          );
          added.add(edgeKey);
        }
      });
    });

    return edges;
  }

  int _find(List<int> parent, int i) =>
      parent[i] == i ? i : _find(parent, parent[i]);

  void _union(List<int> parent, List<int> rank, int x, int y) {
    final xroot = _find(parent, x);
    final yroot = _find(parent, y);
    if (rank[xroot] < rank[yroot]) {
      parent[xroot] = yroot;
    } else if (rank[xroot] > rank[yroot]) {
      parent[yroot] = xroot;
    } else {
      parent[yroot] = xroot;
      rank[xroot]++;
    }
  }
}
