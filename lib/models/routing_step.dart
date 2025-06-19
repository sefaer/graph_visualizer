import 'package:graph_visualizer/algorithms/distributed/messages.dart';

class RoutingStep {
  final int currentStep;
  final int totalSteps;
  final String description;
  final List<Message> messages;
  final Map<String, String> routingTables;
  final int? activeMessageIndex;
  final Map<String, dynamic> messageQueues; // Changed to dynamic
  final String? processingNode; // Changed to String
  final double messageProgress;
final Map<String, dynamic>? nodeStates;
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
     this.nodeStates, //
  });

  // Helper method to convert message queues to List<String>
  Map<String, List<String>> get messageQueuesAsStrings {
    return Map.fromEntries(
      messageQueues.entries.map((e) {
        if (e.value is List<Message>) {
          return MapEntry(
            e.key,
            (e.value as List<Message>).map((m) => m.content).toList(),
          );
        }
        return MapEntry(e.key, e.value as List<String>);
      }),
    );
  }

  // Helper method to convert message queues to List<Message>
  Map<String, List<Message>> get messageQueuesAsMessages {
    return Map.fromEntries(
      messageQueues.entries.map((e) {
        if (e.value is List<Message>) {
          return MapEntry(e.key, e.value as List<Message>);
        } else {
          return MapEntry(
            e.key,
            (e.value as List<String>)
                .map(
                  (s) => Message(
                    sourceNodeId: '',
                    destinationNodeId: '',
                    content: s,
                  ),
                )
                .toList(),
          );
        }
      }),
    );
  }
}
