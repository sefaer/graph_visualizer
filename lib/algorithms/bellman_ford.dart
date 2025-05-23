import 'package:graph_visualizer/models/graphs.dart';
import 'package:graph_visualizer/models/shortespath_models.dart';
import 'package:flutter/material.dart';

class BellmanFordVisualizer {
  final Graphs graph; // Grafik yapısı
  final int animationSpeed; // Animasyon hızı (ms)
  final ValueChanged<BellmanFordStep>
  onStepUpdate; // Her adımda çağrılacak fonksiyon
  final Function(bool hasNegativeCycle)
  onComplete; // Algoritma tamamlandığında çağrılacak fonksiyon

  BellmanFordVisualizer({
    required this.graph,
    required this.animationSpeed,
    required this.onStepUpdate,
    required this.onComplete,
  });

  Future<void> visualize(int start, int? target) async {
    final distances = <int, double>{}; // Düğümlere olan mesafeler
    final previousNodes = <int, int?>{}; // Önceki düğümleri takip etmek için
    int stepCount = 0; // Mevcut adım sayacı
    bool hasNegativeCycle = false; // Negatif döngü var mı?
    bool targetFound = false; // Hedef düğüm bulundu mu?

    // 1. BAŞLANGIÇ AYARLARI
    for (var node in graph.adjacencyList.keys) {
      distances[node] = double.infinity; // Tüm mesafeleri sonsuz yap
      previousNodes[node] = null; // Önceki düğüm yok
    }
    distances[start] = 0; // Başlangıç düğümü mesafesi 0

    final edges = _getAllEdges(); // Tüm kenarları al
    final totalSteps =
        edges.length * graph.adjacencyList.length + 1; // Toplam adım tahmini

    // İlk adımı bildir
    onStepUpdate(
      BellmanFordStep(
        iteration: 0,
        hasNegativeCycle: false,
        distances: Map.from(distances),
        visited: {start},
        description: "Başlangıç: $start düğümüne mesafe 0 olarak ayarlandı",
        currentStep: stepCount++,
        totalSteps: totalSteps,
        previousNodes: Map.from(previousNodes),
      ),
    );
    await _delay();

    // 2. KENAR GEVŞETME (RELAXATION) İŞLEMLERİ
    for (int i = 0; i < graph.adjacencyList.length - 1; i++) {
      for (final edge in edges) {
        final u = edge.source;
        final v = edge.destination;
        final weight = edge.weight.toDouble();

        // Kenar işleme adımı
        onStepUpdate(
          BellmanFordStep(
            iteration: i + 1,
            hasNegativeCycle: false,
            processingEdge: "${u}-${v}",
            distances: Map.from(distances),
            visited: _getVisitedNodes(distances),
            description: "${u}-${v} kenarı işleniyor (ağırlık: $weight)",
            currentStep: stepCount++,
            totalSteps: totalSteps,
            previousNodes: Map.from(previousNodes),
          ),
        );
        await _delay();

        // Mesafe güncelleme kontrolü
        if (distances[u]! + weight < distances[v]!) {
          distances[v] = distances[u]! + weight;
          previousNodes[v] = u;

          // Güncelleme adımı
          onStepUpdate(
            BellmanFordStep(
              iteration: i + 1,
              hasNegativeCycle: false,
              processingEdge: "${u}-${v}",
              distances: Map.from(distances),
              visited: _getVisitedNodes(distances),
              description:
                  "$v düğümüne mesafe güncellendi: ${distances[v]!.toStringAsFixed(1)} ($u üzerinden)",
              currentStep: stepCount++,
              totalSteps: totalSteps,
              previousNodes: Map.from(previousNodes),
            ),
          );
          await _delay();

          // Hedef düğüm kontrolü
          if (target != null && v == target) {
            targetFound = true;
          }
        }
      }

      // Hedef düğüm bulunduysa erken çık
      if (targetFound) break;
    }

    // 3. NEGATİF DÖNGÜ KONTROLÜ
    for (final edge in edges) {
      final u = edge.source;
      final v = edge.destination;
      final weight = edge.weight.toDouble();

      if (distances[u]! + weight < distances[v]!) {
        hasNegativeCycle = true;
        break;
      }
    }

    // 4. SONUÇ ADIMI
    onStepUpdate(
      BellmanFordStep(
        iteration: graph.adjacencyList.length - 1,
        hasNegativeCycle: hasNegativeCycle,
        distances: Map.from(distances),
        visited: _getVisitedNodes(distances),
        description:
            hasNegativeCycle
                ? "Negatif döngü tespit edildi!"
                : targetFound
                ? "Hedef düğüm $target bulundu!"
                : "Algoritma başarıyla tamamlandı",
        currentStep: stepCount++,
        totalSteps: totalSteps,
        previousNodes: Map.from(previousNodes),
      ),
    );
    await _delay();

    onComplete(hasNegativeCycle);
  }

  // Yardımcı metod: Ziyaret edilen düğümleri bul
  Set<int> _getVisitedNodes(Map<int, double> distances) {
    return Set.from(
      distances.keys.where((k) => distances[k]! < double.infinity),
    );
  }

  // Yardımcı metod: Tüm kenarları topla
  List<Edge> _getAllEdges() {
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

  // Yardımcı metod: Animasyon için bekle
  Future<void> _delay() async {
    await Future.delayed(Duration(milliseconds: animationSpeed));
  }
}
