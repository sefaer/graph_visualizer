import 'dart:ui';

import 'package:graphview/graphview.dart' as gv;
import 'dart:collection';
import 'dart:convert';

class Graphs {
  Map<int, List<int>> adjacencyList = {};
  Map<String, int> edgeWeights = {};
  List<Edge> edges = [];
  void addNode(int node) {
    if (!adjacencyList.containsKey(node)) {
      adjacencyList[node] = [];
      print('Added node: $node');
    }
  }

  void addEdge(int node1, int node2) {
    print('Adding edge between $node1 and $node2');
    if (!adjacencyList.containsKey(node1)) {
      addNode(node1);
    }
    if (!adjacencyList.containsKey(node2)) {
      addNode(node2);
    }

    if (!adjacencyList[node1]!.contains(node2)) {
      adjacencyList[node1]!.add(node2);
    }
    if (!adjacencyList[node2]!.contains(node1)) {
      adjacencyList[node2]!.add(node1);
    }
    print('Current adjacency list: $adjacencyList');
  }

  // Yeni eklenen metod: Ağırlıklı kenarlardan grafik oluşturma
  static Graphs fromWeightedEdges(Map<int, List<Edge>> weightedEdges) {
    print('\n=== GRAFİK AĞIRLIKLI KENARLARDAN OLUŞTURULUYOR ===');
    print('Toplam düğüm sayısı: ${weightedEdges.keys.length}');
    print('Düğümler: ${weightedEdges.keys.toList()}');

    final graph = Graphs();
    int totalEdgesAdded = 0;
    int totalWeightsAdded = 0;

    // Tüm düğümleri ekle
    print('\nDÜĞÜMLER EKLENİYOR:');
    weightedEdges.keys.forEach((node) {
      graph.addNode(node);
      print(' - Düğüm eklendi: $node');
    });

    // Kenarları ve ağırlıkları ekle
    print('\nKENARLAR VE AĞIRLIKLAR EKLENİYOR:');
    weightedEdges.forEach((source, edges) {
      print('\nKaynak düğüm $source için kenarlar:');

      if (edges.isEmpty) {
        print('  ! Bu düğümün çıkan kenarı yok (yalıtılmış düğüm)');
      }

      for (Edge edge in edges) {
        // Kenar ekleme öncesi kontrol
        if (!weightedEdges.containsKey(edge.destination)) {
          print('  ! UYARI: Hedef düğüm ${edge.destination} ana listede yok!');
        }

        // Eğer ağırlık yoksa, kenar eklenmesin
        if (edge.weight == null) {
          print(
            '  ! UYARI: Kenar $source -> ${edge.destination} ağırlıksız, çizilmiyor',
          );
          continue; // Bu kenarı atla
        }

        // Kenarı ekle
        graph.addEdge(source, edge.destination);
        print('  - Kenar eklendi: $source -> ${edge.destination}');

        // Ağırlık ekle
        graph.addEdgeWithWeight(source, edge.destination, edge.weight);
        print('    • Ağırlık: ${edge.weight} eklendi');

        totalEdgesAdded++;
        totalWeightsAdded++;
      }
    });

    print('\nSONUÇ:');
    print(' - Toplam eklenen düğüm: ${graph.adjacencyList.length}');
    print(' - Toplam eklenen kenar: $totalEdgesAdded');
    print(' - Toplam eklenen ağırlık: $totalWeightsAdded');

    // Komşuluk listesini debug için yazdır
    print('\nOLUŞAN GRAFİK YAPISI:');
    graph.adjacencyList.forEach((node, neighbors) {
      print(' - Düğüm $node komşuları: $neighbors');
    });

    return graph;
  }

  bool isConnected() {
    print('Checking if graph is connected...');
    if (adjacencyList.isEmpty) {
      print('Graph is empty, returning false');
      return false;
    }

    List<int> visited = [];
    Queue<int> queue = Queue();
    int firstNode = adjacencyList.keys.first;
    queue.add(firstNode);
    visited.add(firstNode);
    print('Starting BFS from node $firstNode');

    while (queue.isNotEmpty) {
      int currentNode = queue.removeFirst();
      print('Visiting node $currentNode');
      for (int neighbor in adjacencyList[currentNode] ?? []) {
        if (!visited.contains(neighbor)) {
          visited.add(neighbor);
          queue.add(neighbor);
          print('Discovered neighbor $neighbor');
        }
      }
    }

    bool connected = visited.length == adjacencyList.length;
    print(
      'Graph connected: $connected (Visited ${visited.length} of ${adjacencyList.length} nodes)',
    );
    return connected;
  }

  static Graphs fromAdjacencyMatrix(List<List<int>> matrix) {
    print('Creating graph from adjacency matrix...');
    final graph = Graphs();
    for (int i = 0; i < matrix.length; i++) {
      graph.addNode(i);
      for (int j = 0; j < matrix[i].length; j++) {
        if (matrix[i][j] == 1) {
          graph.addEdge(i, j);
        }
      }
    }
    print('Created graph with ${graph.adjacencyList.length} nodes from matrix');
    return graph;
  }

  static Graphs fromLinkedList(Map<int, List<int>> linkedList) {
    print('Creating graph from linked list...');
    final graph = Graphs();

    linkedList.keys.forEach((node) {
      graph.addNode(node);
    });

    linkedList.forEach((node, neighbors) {
      final uniqueNeighbors =
          neighbors.where((neighbor) => neighbor != node).toSet();
      for (int neighbor in uniqueNeighbors) {
        if (linkedList.containsKey(neighbor)) {
          graph.addEdge(node, neighbor);
        } else {
          print(
            'Warning: Neighbor $neighbor not found in graph, skipping edge',
          );
        }
      }
    });

    print(
      'Created graph with ${graph.adjacencyList.length} nodes from linked list',
    );
    return graph;
  }

  String toJson() {
    print('Converting graph to JSON...');
    return jsonEncode({
      'adjacencyList': adjacencyList,
      'edgeWeights': edgeWeights,
    });
  }

  static Graphs fromJson(String json) {
    print('Creating graph from JSON...');
    try {
      Map<String, dynamic> data = jsonDecode(json);
      Map<int, List<int>> adjacencyList = {};
      Map<String, int> edgeWeights = {};

      data['adjacencyList'].forEach((key, value) {
        adjacencyList[int.parse(key)] = List<int>.from(value);
      });

      data['edgeWeights'].forEach((key, value) {
        edgeWeights[key] = value;
      });

      print('Created graph with ${adjacencyList.length} nodes from JSON');
      return Graphs()
        ..adjacencyList = adjacencyList
        ..edgeWeights = edgeWeights;
    } catch (e) {
      print('Error parsing JSON: $e');
      return Graphs();
    }
  }

  @override
  String toString() {
    return 'Adjacency List: $adjacencyList\nEdge Weights: $edgeWeights';
  }

  int getEdgeWeight(int u, int v) {
    return edgeWeights["$u-$v"] ?? edgeWeights["$v-$u"] ?? 1;
  }

  void addEdgeWithWeight(int u, int v, int weight) {
    // Önce bu kenar zaten var mı kontrol et
    if (!edges.any(
      (e) =>
          (e.source == u && e.destination == v) ||
          (e.source == v && e.destination == u),
    )) {
      // Kenarı ekle
      edges.add(Edge(source: u, destination: v, weight: weight));

      // Adjacency list'i güncelle
      adjacencyList.putIfAbsent(u, () => []).add(v);
      adjacencyList.putIfAbsent(v, () => []).add(u);

      // Ağırlıkları ekle
      edgeWeights["$u-$v"] = weight;
      edgeWeights["$v-$u"] = weight;

      // debugPrint('✅ Kenar eklendi: $u-$v (Ağırlık: $weight)');
    } else {
      // debugPrint('⏭️ Kenar zaten var: $u-$v');
    }
  }

  bool edgeExists(int u, int v) {
    return edges.any(
      (e) =>
          (e.source == u && e.destination == v) ||
          (e.source == v && e.destination == u),
    );
  }

  Edge? getEdge(int u, int v) {
    return edges.firstWhere(
      (edge) =>
          (edge.source == u && edge.destination == v) ||
          (edge.source == v && edge.destination == u),
      orElse: () => Edge(source: u, destination: v), // Fallback
    );
  }
}

// Edge model sınıfı
class Edge {
  final int source;
  final int destination;
  final int weight;
  Offset? sourcePosition = Offset.zero;
  Offset? destinationPosition = Offset.zero;

  Edge({required this.source, required this.destination, this.weight = 1});
  void updatePositions(Offset srcPos, Offset destPos) {
    sourcePosition = srcPos;
    destinationPosition = destPos;
  }

  @override
  String toString() {
    return '$source-$destination($weight)';
  }
}
