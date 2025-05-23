import '../../models/graphs.dart';
import '../../models/mst_models.dart';
import 'package:flutter/material.dart';

class PrimMSTVisualizer {
  final Graphs graph;
  final int animationSpeed;
  final ValueChanged<PrimStep> onStepUpdate;
  final VoidCallback onComplete;

  PrimMSTVisualizer({
    required this.graph,
    required this.animationSpeed,
    required this.onStepUpdate,
    required this.onComplete,
  });

  Future<void> visualize() async {
    final nodes = graph.adjacencyList.keys.toList();
    if (nodes.isEmpty) return;

    // 1. BAŞLANGIÇ DEĞERLERİNİ AYARLA
    final keyValues = Map<int, int>.fromIterable(nodes, value: (_) => 999999);
    final parentMap = <int, int>{};
    final includedEdges = <String>{};
    final selectedNodes = <int>{};
    final potentialEdges = <String>{};
    int currentStep = 0;
    final totalSteps = nodes.length * 2; // Her düğüm için 2 adım (seçme + güncelleme)

    // 2. BAŞLANGIÇ DÜĞÜMÜNÜ SEÇ
    final startNode = nodes.first;
    keyValues[startNode] = 0;
    parentMap[startNode] = -1;

    _updateStep(
      step: currentStep++,
      totalSteps: totalSteps,
      selectedNodes: selectedNodes,
      keyValues: keyValues,
      includedEdges: includedEdges,
      potentialEdges: potentialEdges,
      parentMap: parentMap,
      description: "Başlangıç düğümü seçildi: $startNode",
    );

    await Future.delayed(Duration(milliseconds: animationSpeed));

    // 3. PRIM ALGORİTMASI ANA DÖNGÜSÜ
    for (var i = 0; i < nodes.length; i++) {
      final currentNode = _findMinKeyNode(keyValues, selectedNodes);
      selectedNodes.add(currentNode);

      // 4. YENİ KENAR EKLEME KONTROLÜ
      if (parentMap[currentNode] != -1 &&
          _edgeExistsInGraph(parentMap[currentNode]!, currentNode)) {
        final edge = _formatEdge(parentMap[currentNode]!, currentNode);
        includedEdges.add(edge);
        potentialEdges.remove(edge);
      }

      _updateStep(
        step: currentStep++,
        totalSteps: totalSteps,
        selectedNodes: selectedNodes,
        keyValues: keyValues,
        includedEdges: includedEdges,
        potentialEdges: potentialEdges,
        parentMap: parentMap,
        description: "Düğüm $currentNode eklendi" +
            (parentMap[currentNode] != -1
                ? "\nKenar ${parentMap[currentNode]}-$currentNode seçildi"
                : ""),
      );

      await Future.delayed(Duration(milliseconds: animationSpeed));

      // 5. KOMŞU DÜĞÜMLERİ GÜNCELLE
      for (final neighbor in graph.adjacencyList[currentNode] ?? []) {
        if (!selectedNodes.contains(neighbor)) {
          final edgeWeight = graph.getEdgeWeight(currentNode, neighbor);
          final edgeKey = _formatEdge(currentNode, neighbor);

          if (edgeWeight < keyValues[neighbor]!) {
            // 6. ESKİ POTANSİYEL KENARI KALDIR
            if (parentMap[neighbor] != null && parentMap[neighbor] != -1) {
              potentialEdges.remove(_formatEdge(parentMap[neighbor]!, neighbor));
            }

            // 7. YENİ DEĞERLERİ GÜNCELLE
            keyValues[neighbor] = edgeWeight;
            parentMap[neighbor] = currentNode;
            potentialEdges.add(edgeKey);

            _updateStep(
              step: currentStep++,
              totalSteps: totalSteps,
              selectedNodes: selectedNodes,
              keyValues: keyValues,
              includedEdges: includedEdges,
              potentialEdges: potentialEdges,
              parentMap: parentMap,
              description: "Düğüm $neighbor güncellendi\nYeni değer: $edgeWeight",
            );

            await Future.delayed(Duration(milliseconds: animationSpeed ~/ 2));
          }
        }
      }
    }

    onComplete();
  }

  // 8. YARDIMCI FONKSİYONLAR
  void _updateStep({
    required int step,
    required int totalSteps,
    required Set<int> selectedNodes,
    required Map<int, int> keyValues,
    required Set<String> includedEdges,
    required Set<String> potentialEdges,
    required Map<int, int> parentMap,
    required String description,
  }) {
    onStepUpdate(PrimStep(
      selectedNodes: {...selectedNodes},
      keyValues: {...keyValues},
      currentNode: selectedNodes.isNotEmpty ? selectedNodes.last : null,
      potentialEdges: {...potentialEdges},
      includedEdges: {...includedEdges},
      description: description,
      parentMap: {...parentMap},
      currentStep: step,
      totalSteps: totalSteps,
    ));
  }

  bool _edgeExistsInGraph(int u, int v) {
    return graph.adjacencyList[u]?.contains(v) ?? false;
  }

  int _findMinKeyNode(Map<int, int> keyValues, Set<int> selectedNodes) {
    return keyValues.entries
        .where((entry) => !selectedNodes.contains(entry.key))
        .reduce((a, b) => a.value < b.value ? a : b)
        .key;
  }

  String _formatEdge(int u, int v) => u < v ? "$u-$v" : "$v-$u";
}