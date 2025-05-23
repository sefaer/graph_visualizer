import '../../models/graphs.dart';
import '../../models/mst_models.dart';
import 'package:flutter/material.dart';

class ReverseDeleteMSTVisualizer {
  // 1. GEREKLİ PARAMETRELER
  final Graphs graph; // İşlenecek graf
  final int animationSpeed; // Animasyon hızı (ms)
  final ValueChanged<ReverseDeleteStep>
  onStepUpdate; // Her adımda çağrılacak fonksiyon
  final VoidCallback
  onComplete; // Algoritma tamamlandığında çağrılacak fonksiyon
  ReverseDeleteMSTVisualizer({
    required this.graph,
    required this.animationSpeed,
    required this.onStepUpdate,
    required this.onComplete,
  });

  // 2. ALGORİTMAYI ÇALIŞTIRMA METODU

  Future<void> visualize() async {
    // Tüm kenarları çıkar ve büyükten küçüğe sırala
    final edges = _extractEdges();
    edges.sort((a, b) => b.weight.compareTo(a.weight));

    // Başlangıç durumu: Tüm kenarlar MST'de
    List<Edge> mstEdges = List.from(edges);
    Set<String> includedEdges =
        mstEdges.map((e) => _formatEdge(e.source, e.destination)).toSet();
    Set<String> rejectedEdges = {};
    int currentStep = 0;
    final totalSteps = edges.length;

    // İlk adımı bildir
    onStepUpdate(
      ReverseDeleteStep(
        rejectedEdges: rejectedEdges,
        sortedEdges: edges,
        currentEdgeIndex: -1,
        processingEdge: "",
        includedEdges: includedEdges,
        description:
            "Kenarlar büyükten küçüğe sıralandı (${edges.length} kenar)",
        parentMap: _createParentMap(mstEdges),
        currentStep: currentStep++,
        totalSteps: totalSteps,
      ),
    );

    await Future.delayed(Duration(milliseconds: animationSpeed));

    // 3. KENARLARI İŞLEME DÖNGÜSÜ
    for (int i = 0; i < edges.length; i++) {
      final edge = edges[i];
      final edgeKey = _formatEdge(edge.source, edge.destination);

      // Kenarı geçici olarak çıkarılmış graf oluştur
      final tempEdges = mstEdges.where((e) => !_edgesEqual(e, edge)).toList();

      // 4. BAĞLANTI KONTROLÜ
      if (_isGraphConnected(tempEdges)) {
        // Bağlantı bozulmuyorsa kenarı sil
        mstEdges = tempEdges;
        includedEdges.remove(edgeKey);
        rejectedEdges.add(edgeKey);

        onStepUpdate(
          ReverseDeleteStep(
            rejectedEdges: rejectedEdges,
            sortedEdges: edges,
            currentEdgeIndex: i,
            processingEdge: edgeKey,
            includedEdges:
                mstEdges
                    .map((e) => _formatEdge(e.source, e.destination))
                    .toSet(),
            description:
                "Kenar ${edge.source}-${edge.destination} (${edge.weight}) silindi",
            parentMap: _createParentMap(mstEdges),
            currentStep: currentStep++,
            totalSteps: totalSteps,
          ),
        );
      } else {
        // Bağlantı bozuluyorsa kenarı koru
        onStepUpdate(
          ReverseDeleteStep(
            rejectedEdges: rejectedEdges,
            sortedEdges: edges,
            currentEdgeIndex: i,
            processingEdge: edgeKey,
            includedEdges:
                mstEdges
                    .map((e) => _formatEdge(e.source, e.destination))
                    .toSet(),
            description:
                "Kenar ${edge.source}-${edge.destination} (${edge.weight}) korundu (bağlantıyı sağlıyor)",
            parentMap: _createParentMap(mstEdges),
            currentStep: currentStep++,
            totalSteps: totalSteps,
          ),
        );
      }

      await Future.delayed(Duration(milliseconds: animationSpeed));
    }

    // 5. ALGORİTMA TAMAMLANDI
    onComplete();
  }

  // 6. YARDIMCI FONKSİYONLAR

  // İki kenarın eşit olup olmadığını kontrol et (yönsüz graf için)
  bool _edgesEqual(Edge a, Edge b) {
    return (a.source == b.source && a.destination == b.destination) ||
        (a.source == b.destination && a.destination == b.source);
  }

  // Kenar için standart format oluştur (1-2 veya 2-1 yerine her zaman "1-2" gibi)
  String _formatEdge(int u, int v) => u < v ? "$u-$v" : "$v-$u";

  // Union-Find veri yapısı için parent haritası oluştur
  Map<int, int> _createParentMap(List<Edge> edges) {
    final parentMap = <int, int>{};
    final nodes = edges.expand((e) => [e.source, e.destination]).toSet();

    // Başlangıçta her düğüm kendine işaret eder
    for (final node in nodes) {
      parentMap[node] = node;
    }

    // Kenarları birleştirerek parent ilişkilerini oluştur
    for (final edge in edges) {
      _union(parentMap, edge.source, edge.destination);
    }

    return parentMap;
  }

  // Union-Find: Kök düğümü bul (path compression ile)
  int _find(Map<int, int> parent, int node) {
    if (parent[node] != node) {
      parent[node] = _find(parent, parent[node]!); // Path compression
    }
    return parent[node]!;
  }

  // Union-Find: İki düğümü birleştir
  void _union(Map<int, int> parent, int x, int y) {
    final xRoot = _find(parent, x);
    final yRoot = _find(parent, y);
    if (xRoot != yRoot) {
      parent[yRoot] = xRoot;
    }
  }

  // Grafın bağlı olup olmadığını kontrol et
  bool _isGraphConnected(List<Edge> edges) {
    if (edges.isEmpty) return false;

    final nodes = edges.expand((e) => [e.source, e.destination]).toSet();
    if (nodes.isEmpty) return false;

    final parentMap = _createParentMap(edges);
    final root = _find(parentMap, nodes.first);

    // Tüm düğümler aynı köke bağlı mı?
    return nodes.every((node) => _find(parentMap, node) == root);
  }

  // Grafdan tüm kenarları çıkar
  List<Edge> _extractEdges() {
    final edges = <Edge>[];
    final added = <String>{};

    graph.adjacencyList.forEach((u, neighbors) {
      neighbors.forEach((v) {
        final edgeKey = _formatEdge(u, v);
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
}
