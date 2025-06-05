import 'package:graph_visualizer/algorithms/distributed/messages.dart';
import 'package:graph_visualizer/models/distrubuted_models.dart';

class SimpleRouting {
  static Future<void> floodMessage({
    required DistributedNode startNode,
    required String messageContent,
    required String destinationId,
    required List<DistributedNode> allNodes,
    required Function(Message, DistributedNode) onMessageProcessed,
    int delayMs = 300,
  }) async {
    // Create a map for quick node lookup
    final nodeMap = {for (var node in allNodes) node.id: node};

    // Create initial message
    final initialMessage = Message(
      sourceNodeId: startNode.id,
      destinationNodeId: destinationId,
      content: messageContent,
    );

    // Process the initial message
    await _processMessage(
      message: initialMessage,
      currentNode: startNode,
      senderNode: null, // No sender for initial message
      nodeMap: nodeMap,
      onMessageProcessed: onMessageProcessed,
      delayMs: delayMs,
      visitedNodes: {}, // Track visited nodes to prevent loops
    );
  }

  static Future<void> _processMessage({
    required Message message,
    required DistributedNode currentNode,
    required DistributedNode? senderNode,
    required Map<String, DistributedNode> nodeMap,
    required Function(Message, DistributedNode) onMessageProcessed,
    required int delayMs,
    required Set<String> visitedNodes,
  }) async {
    // Notify UI about this message processing
    onMessageProcessed(message, currentNode);

    // Mark this node as visited for this message
    final visitKey = '${message.sourceNodeId}-${message.destinationNodeId}-${currentNode.id}';
    if (visitedNodes.contains(visitKey)) {
      return; // Already visited this node for this message
    }
    visitedNodes.add(visitKey);

    // Wait to simulate network delay
    await Future.delayed(Duration(milliseconds: delayMs));

    // If this is the destination, stop
    if (message.destinationNodeId == currentNode.id) {
      return;
    }

    // Check routing table for destination
    if (currentNode.routingTable.containsKey(message.destinationNodeId)) {
      final nextHopId = currentNode.routingTable[message.destinationNodeId]!;
      if (nextHopId.isNotEmpty) {
        final nextHop = nodeMap[nextHopId]!;
        final newMessage = message.copyWith();
        
        await _processMessage(
          message: newMessage,
          currentNode: nextHop,
          senderNode: currentNode,
          nodeMap: nodeMap,
          onMessageProcessed: onMessageProcessed,
          delayMs: delayMs,
          visitedNodes: visitedNodes,
        );
      }
    } 
    // Flood to all neighbors except sender
    else {
      for (final neighborId in currentNode.neighbors) {
        if (senderNode == null || neighborId != senderNode.id) {
          final nextHop = nodeMap[neighborId]!;
          final newMessage = message.copyWith();
          
          await _processMessage(
            message: newMessage,
            currentNode: nextHop,
            senderNode: currentNode,
            nodeMap: nodeMap,
            onMessageProcessed: onMessageProcessed,
            delayMs: delayMs,
            visitedNodes: visitedNodes,
          );
        }
      }
    }
  }
}