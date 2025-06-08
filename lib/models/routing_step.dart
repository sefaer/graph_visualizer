import 'package:graph_visualizer/algorithms/distributed/messages.dart';

class RoutingStep {
  final int currentStep;
  final int totalSteps;
  final String description;
  final List<Message> messages;
  final Map<String, String> routingTables;
  final int? activeMessageIndex;
  final Map<String, List<String>> messageQueues;
  final int? processingNode;
  final double messageProgress;

  RoutingStep({
    required this.currentStep,
    required this.totalSteps,
    required this.description,
    required this.messages,
    required this.routingTables,
    this.activeMessageIndex,
    required this.messageQueues,
    this.processingNode,
    this.messageProgress = 0.0,
  });
}