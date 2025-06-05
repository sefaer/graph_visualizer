class Message {
  final String id;
  final String sourceNodeId;
  final String destinationNodeId;
  final String content;
  final DateTime timestamp;

  Message({
    required this.sourceNodeId,
    required this.destinationNodeId,
    required this.content,
    DateTime? timestamp,
  }) : id = DateTime.now().microsecondsSinceEpoch.toString(),
       timestamp = timestamp ?? DateTime.now();

  Message copyWith({
    String? sourceNodeId,
    String? destinationNodeId,
    String? content,
    DateTime? timestamp,
  }) {
    return Message(
      sourceNodeId: sourceNodeId ?? this.sourceNodeId,
      destinationNodeId: destinationNodeId ?? this.destinationNodeId,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}