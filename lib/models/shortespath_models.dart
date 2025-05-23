import 'package:graph_visualizer/models/graphs.dart';

abstract class BaseShortestPathStep {
  final Map<int, double> distances;
  final Set<int> visited;
  final String description;
  final int currentStep;
  final int totalSteps;
  final Map<int, int?> previousNodes;
  final String? processingEdge;
  BaseShortestPathStep({
    required this.distances,
    required this.visited,
    required this.description,
    required this.currentStep,
    required this.totalSteps,
    required this.previousNodes,
    this.processingEdge,
  });
}

class DijkstraStep extends BaseShortestPathStep {
  final int currentNode;
  final Set<int> frontier;

  DijkstraStep({
    required this.currentNode,
    required this.frontier,
    required super.distances,
    required super.visited,
    required super.description,
    required super.currentStep,
    required super.totalSteps,
    required super.previousNodes,
  });
}

class BellmanFordStep extends BaseShortestPathStep {
  final int iteration;
  final bool hasNegativeCycle;
  final String? processingEdge;

  BellmanFordStep({
    required this.iteration,
    required this.hasNegativeCycle,
    this.processingEdge,
    required super.distances,
    required super.visited,
    required super.description,
    required super.currentStep,
    required super.totalSteps,
    required super.previousNodes,
  });
}
