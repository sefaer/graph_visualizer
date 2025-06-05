import 'package:graph_visualizer/algorithms/distributed/messages.dart';

class DistributedNode {
  final String id;
  final List<String> neighbors;
  final Map<String, String> _routingTable;
  final List<Message> receivedMessages = [];

  DistributedNode(this.id, this.neighbors) : _routingTable = {};

  // Getter for read-only access
  Map<String, String> get routingTable => Map.unmodifiable(_routingTable);

  // Method to update routing table
  void updateRoutingTable(Map<String, String> newTable) {
    _routingTable.clear();
    _routingTable.addAll(newTable);
  }

  Future<void> receiveMessage(
    Message message, 
    DistributedNode? sender,
    Function(Message, String) onForward,  // Changed to accept node ID string
  ) async {
    receivedMessages.add(message);
    
    if (message.destinationNodeId == id) {
      return; // Message arrived at destination
    }

    if (_routingTable.containsKey(message.destinationNodeId)) {
      final nextHopId = _routingTable[message.destinationNodeId]!;
      if (nextHopId.isNotEmpty) {
        final newMessage = message.copyWith();
        onForward(newMessage, nextHopId);
      }
    } else {
      for (final neighborId in neighbors) {
        if (sender == null || neighborId != sender.id) {
          final newMessage = message.copyWith();
          onForward(newMessage, neighborId);
        }
      }
    }
  }
}