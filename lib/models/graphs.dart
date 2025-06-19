import 'dart:ui';
import 'dart:collection';
import 'dart:convert';

class Graphs {
  Map<int, List<int>> adjacencyList = {};
  Map<String, int> edgeWeights = {};
  List<Edge> edges = [];

  // Düğüm ekle (eğer yoksa)
  void addNode(int node) {
    if (!adjacencyList.containsKey(node)) {
      adjacencyList[node] = [];
      print('Added node: $node');
    }
  }

  // Yönsüz ve ağırlıksız kenar ekleme
  void addEdge(int node1, int node2) {
    if (!adjacencyList.containsKey(node1)) addNode(node1);
    if (!adjacencyList.containsKey(node2)) addNode(node2);

    if (!adjacencyList[node1]!.contains(node2))
      adjacencyList[node1]!.add(node2);
    if (!adjacencyList[node2]!.contains(node1))
      adjacencyList[node2]!.add(node1);
  }

  // Ağırlıklı kenar ekleme (adjacencyList ve edges listesine ekler)
  void addEdgeWithWeight(int u, int v, int weight) {
    // Aynı kenarın çift yönlü tekrarını önlemek için kontrol
    if (!edges.any(
      (e) =>
          (e.source == u && e.destination == v) ||
          (e.source == v && e.destination == u),
    )) {
      edges.add(Edge(source: u, destination: v, weight: weight));

      adjacencyList.putIfAbsent(u, () => []).add(v);
      adjacencyList.putIfAbsent(v, () => []).add(u);

      edgeWeights["$u-$v"] = weight;
      edgeWeights["$v-$u"] = weight;
    }
  }

  // WeightedEdges'den Graph oluşturur
  static Graphs fromWeightedEdges(Map<int, List<Edge>> weightedEdges) {
    print('\n=== GRAFİK AĞIRLIKLI KENARLARDAN OLUŞTURULUYOR ===');
    final graph = Graphs();

    // Tüm düğümleri topla (kaynak ve hedef)
    final allNodeIds = <int>{};
    for (var entry in weightedEdges.entries) {
      allNodeIds.add(entry.key);
      for (var edge in entry.value) {
        allNodeIds.add(edge.destination);
      }
    }

    print('Toplam düğüm sayısı: ${allNodeIds.length}');
    print('Düğümler: ${allNodeIds.toList()}');

    // Düğümleri ekle
    print('\nDÜĞÜMLER EKLENİYOR:');
    for (var node in allNodeIds) {
      graph.addNode(node);
      print(' - Düğüm eklendi: $node');
    }

    // Kenarları ve ağırlıkları ekle
    print('\nKENARLAR VE AĞIRLIKLAR EKLENİYOR:');
    final addedEdges = <String>{};
    for (var entry in weightedEdges.entries) {
      final source = entry.key;
      final edges = entry.value;

      print('\nKaynak düğüm $source için kenarlar:');

      if (edges.isEmpty) {
        print('  ! Bu düğümün çıkan kenarı yok (yalıtılmış düğüm)');
      }

      for (var edge in edges) {
        final dest = edge.destination;
        final weight = edge.weight;

        if (weight == null) {
          print('  ! UYARI: Kenar $source -> $dest ağırlıksız, çizilmiyor');
          continue;
        }

        final edgeKey1 = '$source->$dest';
        final edgeKey2 = '$dest->$source';

        if (!addedEdges.contains(edgeKey1) && !addedEdges.contains(edgeKey2)) {
          graph.addEdgeWithWeight(source, dest, weight);
          addedEdges.add(edgeKey1);
          print('  - Kenar eklendi: $source <-> $dest (ağırlık: $weight)');
        } else {
          print('  ! Atlandı (tekrar kenar): $source <-> $dest');
        }
      }
    }

    // Oluşan grafik yapısını göster
    print('\nOLUŞAN GRAFİK YAPISI:');
    graph.adjacencyList.forEach((node, neighbors) {
      print(' - Düğüm $node komşuları: $neighbors');
    });

    return graph;
  }

  // Bağlılık kontrolü (connected graph kontrolü)
  bool isConnected() {
    if (adjacencyList.isEmpty) return false;

    final visited = <int>{};
    final queue = Queue<int>();
    final firstNode = adjacencyList.keys.first;

    queue.add(firstNode);
    visited.add(firstNode);

    while (queue.isNotEmpty) {
      final currentNode = queue.removeFirst();
      for (var neighbor in adjacencyList[currentNode] ?? []) {
        if (!visited.contains(neighbor)) {
          visited.add(neighbor);
          queue.add(neighbor);
        }
      }
    }

    return visited.length == adjacencyList.length;
  }

  // Adjacency matrix'den Graph oluşturma
  static Graphs fromAdjacencyMatrix(List<List<int>> matrix) {
    final graph = Graphs();
    for (int i = 0; i < matrix.length; i++) {
      graph.addNode(i);
      for (int j = 0; j < matrix[i].length; j++) {
        if (matrix[i][j] == 1) {
          graph.addEdge(i, j);
        }
      }
    }
    return graph;
  }

  // Linked list (komşuluk listesi) ile Graph oluşturma
  static Graphs fromLinkedList(Map<int, List<int>> linkedList) {
    final graph = Graphs();

    for (var node in linkedList.keys) {
      graph.addNode(node);
    }

    linkedList.forEach((node, neighbors) {
      final uniqueNeighbors = neighbors.where((n) => n != node).toSet();
      for (var neighbor in uniqueNeighbors) {
        if (linkedList.containsKey(neighbor)) {
          graph.addEdge(node, neighbor);
        } else {
          print('Warning: Neighbor $neighbor not found, skipping edge');
        }
      }
    });

    return graph;
  }

  // JSON formatına dönüştürme
  String toJson() {
    return jsonEncode({
      'adjacencyList': adjacencyList,
      'edgeWeights': edgeWeights,
    });
  }

  // JSON'dan Graph oluşturma
  static Graphs fromJson(String json) {
    try {
      final data = jsonDecode(json);
      final adjacencyList = <int, List<int>>{};
      final edgeWeights = <String, int>{};

      (data['adjacencyList'] as Map).forEach((key, value) {
        adjacencyList[int.parse(key)] = List<int>.from(value);
      });

      (data['edgeWeights'] as Map).forEach((key, value) {
        edgeWeights[key] = value;
      });

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

  bool edgeExists(int u, int v) {
    return edges.any(
      (e) =>
          (e.source == u && e.destination == v) ||
          (e.source == v && e.destination == u),
    );
  }

  Edge? getEdge(int u, int v) {
    return edges.firstWhere(
      (e) =>
          (e.source == u && e.destination == v) ||
          (e.source == v && e.destination == u),
      orElse: () => Edge(source: u, destination: v),
    );
  }
}

class Edge {
  final int source;
  final int destination;
  final int weight;

  // Pozisyonlar (nullable)
  Offset? sourcePosition;
  Offset? destinationPosition;

  Edge({required this.source, required this.destination, this.weight = 1});

  void updatePositions(Offset srcPos, Offset destPos) {
    sourcePosition = srcPos;
    destinationPosition = destPos;
  }

  @override
  String toString() => '$source-$destination($weight)';
}

// Extension ile tüm düğümleri almak için kolay erişim
extension GraphExtensions on Graphs {
  Set<int> get allNodes {
    final nodes = <int>{};
    adjacencyList.forEach((key, neighbors) {
      nodes.add(key);
      nodes.addAll(neighbors);
    });
    return nodes;
  }
}
