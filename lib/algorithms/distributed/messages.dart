class Message {
  final String id;
  final String sourceNodeId;
  final String destinationNodeId;
  final String content;
  final DateTime timestamp;
  final MessageType? type; // New field for message type
  final Map<String, dynamic>? payload; // Additional data
  int? get layer {
    if (isBfsLayerMessage || isBfsAckMessage || isBfsRejectMessage) {
      return payload?['layer'] as int?;
    }
    return null;
  }
   int get safeLayer {
    assert(layer != null, 'Layer bilgisi olmayan mesaj!');
    return layer!;
  }
  Message({
    required this.sourceNodeId,
    required this.destinationNodeId,
    required this.content,
    DateTime? timestamp,
    this.type,
    this.payload,
  }) : id = DateTime.now().microsecondsSinceEpoch.toString(),
       timestamp = timestamp ?? DateTime.now();

  // Named constructors for different message types
  factory Message.route({
    required String sourceNodeId,
    required String destinationNodeId,
    required String content,
    Map<String, dynamic>? routingData,
  }) {
    return Message(
      sourceNodeId: sourceNodeId,
      destinationNodeId: destinationNodeId,
      content: content,
      type: MessageType.route,
      payload: routingData,
    );
  }

  factory Message.bfsLayer({
    required String sourceNodeId,
    required String destinationNodeId,
    required int layer,
  }) {
    return Message(
      sourceNodeId: sourceNodeId,
      destinationNodeId: destinationNodeId,
      content: 'layer:$layer',
      type: MessageType.bfsLayer,
      payload: {'layer': layer},
    );
  }

  factory Message.bfsAck({
    required String sourceNodeId,
    required String destinationNodeId,
    required int layer,
  }) {
    return Message(
      sourceNodeId: sourceNodeId,
      destinationNodeId: destinationNodeId,
      content: 'ack:$layer',
      type: MessageType.bfsAck,
      payload: {'layer': layer},
    );
  }

  factory Message.bfsReject({
    required String sourceNodeId,
    required String destinationNodeId,
    required int layer,
  }) {
    return Message(
      sourceNodeId: sourceNodeId,
      destinationNodeId: destinationNodeId,
      content: 'reject:$layer',
      type: MessageType.bfsReject,
      payload: {'layer': layer},
    );
  }

  Message copyWith({
    String? sourceNodeId,
    String? destinationNodeId,
    String? content,
    DateTime? timestamp,
    MessageType? type,
    Map<String, dynamic>? payload,
  }) {
    return Message(
      sourceNodeId: sourceNodeId ?? this.sourceNodeId,
      destinationNodeId: destinationNodeId ?? this.destinationNodeId,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      type: type ?? this.type,
      payload: payload ?? (this.payload != null ? Map.of(this.payload!) : null),
    );
  }

  // Helper methods
  bool get isRoutingMessage => type == MessageType.route;
  bool get isBfsLayerMessage => type == MessageType.bfsLayer;
  bool get isBfsAckMessage => type == MessageType.bfsAck;
  bool get isBfsRejectMessage => type == MessageType.bfsReject;

  // Serialization
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sourceNodeId': sourceNodeId,
      'destinationNodeId': destinationNodeId,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'type': type?.toString(),
      'payload': payload,
    };
  }

  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      sourceNodeId: map['sourceNodeId'],
      destinationNodeId: map['destinationNodeId'],
      content: map['content'],
      timestamp: DateTime.parse(map['timestamp']),
      type: _parseMessageType(map['type']),
      payload: map['payload'] != null ? Map<String, dynamic>.from(map['payload']) : null,
    );
  }

  static MessageType? _parseMessageType(String? typeStr) {
    if (typeStr == null) return null;
    return MessageType.values.firstWhere(
      (e) => e.toString() == typeStr,
      orElse: () => MessageType.route,
    );
  }
}

enum MessageType {
  route,      // For standard routing messages
  bfsLayer,   // For BFS layer updates
  bfsAck,     // For BFS acknowledgments
  bfsReject,  // For BFS rejections
}