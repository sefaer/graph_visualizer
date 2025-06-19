import 'package:graph_visualizer/algorithms/distributed/messages.dart';

class DistributedNode {
  final String id;
  final List<String> neighbors;

  // Routing properties
  final Map<String, String> _routingTable;
  final List<Message> receivedMessages = [];

  // BFS properties
  int parent = -1;
  int myLayer = -1;
  final Set<String> children = {};
  final Set<String> others = {};
  bool isRoot = false;

  DistributedNode(this.id, this.neighbors) : _routingTable = {};

  // Getter for read-only access to routing table
  Map<String, String> get routingTable => Map.unmodifiable(_routingTable);

  // Method to update routing table
  void updateRoutingTable(Map<String, String> newTable) {
    _routingTable.clear();
    _routingTable.addAll(newTable);
  }

  // Initialize as root node for BFS
  void initializeAsRoot() {
    isRoot = true;
    myLayer = 0;
    parent = -1;
  }

  // Combined message handling for both routing and BFS
  Future<void> receiveMessage(
    Message message,
    DistributedNode? sender,
    Function(Message, String) onForward,
  ) async {
    receivedMessages.add(message);

    // Handle BFS layer messages first
    if (message.content.startsWith('layer:')) {
      _handleBfsLayerMessage(message, sender, onForward);
      return;
    } else if (message.content.startsWith('ack:')) {
      children.add(message.sourceNodeId);
      return;
    } else if (message.content.startsWith('reject:')) {
      others.add(message.sourceNodeId);
      return;
    }

    // Original routing logic
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

  void _handleBfsLayerMessage(
    Message message,
    DistributedNode? sender,
    Function(Message, String) onForward,
  ) {
    final layerValue = int.parse(message.content.split(':')[1]);

    if (myLayer == -1 || layerValue < myLayer) {
      // Update distance
      parent = int.parse(message.sourceNodeId);
      myLayer = layerValue;

      // Inform parent
      onForward(
        Message(
          sourceNodeId: id,
          destinationNodeId: message.sourceNodeId,
          content: 'ack:$myLayer',
        ),
        message.sourceNodeId,
      );

      // Update neighbors (except sender)
      for (final neighbor in neighbors) {
        if (neighbor != message.sourceNodeId) {
          onForward(
            Message(
              sourceNodeId: id,
              destinationNodeId: neighbor,
              content: 'layer:${myLayer + 1}',
            ),
            neighbor,
          );
        }
      }
    } else {
      onForward(
        Message(
          sourceNodeId: id,
          destinationNodeId: message.sourceNodeId,
          content: 'reject:$myLayer',
        ),
        message.sourceNodeId,
      );
    }
  }

  // Get node state for visualization
  Map<String, dynamic> get state {
    return {
      'id': id,
      'parent': parent,
      'layer': myLayer,
      'children': children.toList(),
      'others': others.toList(),
      'isRoot': isRoot,
      'routingTable': Map.of(_routingTable),
      'receivedMessages': receivedMessages.map((m) => m.toMap()).toList(),
    };
  }
}
