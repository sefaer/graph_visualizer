import 'package:graph_visualizer/models/graphs.dart';

abstract class BaseMSTStep {
  final Set<String> includedEdges; // MST'de yer alan kenarlar
  final String description; // Adım açıklaması
  final Map<int, int> parentMap; // Union-Find için parent bilgisi
  final int currentStep; // Mevcut adım numarası
  final int totalSteps; // Toplam adım sayısı

  BaseMSTStep({
    required this.includedEdges,
    required this.description,
    required this.parentMap,
    required this.currentStep,
    required this.totalSteps,
  });
}

class PrimStep extends BaseMSTStep {
  final Set<int> selectedNodes; // Seçilen düğümler
  final Map<int, int> keyValues; // Düğümlerin key değerleri
  final int? currentNode; // Şu an işlenen düğüm
  final Set<String> potentialEdges; // Potansiyel kenarlar

  PrimStep({
    required this.selectedNodes,
    required this.keyValues,
    required this.currentNode,
    required this.potentialEdges,
    required super.includedEdges,
    required super.description,
    required super.parentMap,
    required super.currentStep,
    required super.totalSteps,
  });
}

class KruskalStep extends BaseMSTStep {
  final Set<String> rejectedEdges; // Reddedilen kenarlar
  final List<Edge> sortedEdges; // Sıralanmış kenar listesi
  final int currentEdgeIndex; // Şu anki kenar indeksi

  KruskalStep({
    required this.rejectedEdges,
    required this.sortedEdges,
    required this.currentEdgeIndex,
    required super.includedEdges,
    required super.description,
    required super.parentMap,
    required super.currentStep,
    required super.totalSteps,
  });
}

class ReverseDeleteStep extends BaseMSTStep {
  final Set<String> rejectedEdges; // Silinen kenarlar
  final List<Edge> sortedEdges; // Sıralanmış kenar listesi
  final int currentEdgeIndex; // Şu anki kenar indeksi
  final String processingEdge; // İşlenmekte olan kenar

  ReverseDeleteStep({
    required this.rejectedEdges,
    required this.sortedEdges,
    required this.currentEdgeIndex,
    required this.processingEdge,
    required super.includedEdges,
    required super.description,
    required super.parentMap,
    required super.currentStep,
    required super.totalSteps,
  });
}
 /*import 'package:graph_visualizer
/models/base_models.dart';

class BaseMSTStep extends BaseVisualizationStep {
  final Set<String> includedEdges;
  final Map<int, int> parentMap;

  BaseMSTStep({
    required this.includedEdges,
    required this.parentMap,
    required super.description,
    required super.currentStep,
    required super.totalSteps,
  });
}

class DijkstraStep extends BaseVisualizationStep {
  final Map<int, int> distances;
  final Set<int> visited;
  final int currentNode;

  DijkstraStep({
    required this.distances,
    required this.visited,
    required this.currentNode,
    required super.description,
    required super.currentStep,
    required super.totalSteps,
  });
} */