import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:graph_visualizer/algorithms/distributed/messages.dart';
import 'package:graph_visualizer/algorithms/distributed/simple_routing.dart';
import 'package:graph_visualizer/models/distrubuted_models.dart';
import 'package:graph_visualizer/models/graphs.dart';
import 'package:graph_visualizer/widgets/graph_painter.dart';

class RoutingScreen extends StatefulWidget {
  final Graphs graph;
  const RoutingScreen({Key? key, required this.graph}) : super(key: key);

  @override
  _RoutingScreenState createState() => _RoutingScreenState();
}

class _RoutingScreenState extends State<RoutingScreen>
    with TickerProviderStateMixin {
  List<DistributedNode> nodes = [];
  List<Message> messages = [];
  int activeMessageIndex = -1;
  bool isSimulating = false;
  Timer? _simulationTimer;
  int currentStep = 0;
  int totalSteps = 10;
  String? selectedStartNodeId;
  String? selectedTargetNodeId;
  final TextEditingController _messageController = TextEditingController();
  bool _showRoutingTables = true;
  Map<int, Offset>? _nodePositions;
  @override
  void initState() {
    super.initState();
    _initializeNodes();
    _messageController.text = 'Hello'; // Default message
  }

  void didChangeDependencies() {
    super.didChangeDependencies();
    _nodePositions = _calculateForceDirectedPositions();
  }

  @override
  void dispose() {
    _simulationTimer?.cancel();
    _messageController.dispose();
    super.dispose();
  }

  void _initializeNodes() {
    nodes =
        widget.graph.adjacencyList.keys.map((id) {
          final node = DistributedNode(
            id.toString(),
            widget.graph.adjacencyList[id]?.map((n) => n.toString()).toList() ??
                [],
          );
          node.updateRoutingTable(_generateRoutingTable(id));
          return node;
        }).toList();
  }

  Map<String, String> _generateRoutingTable(int nodeId) {
    final table = <String, String>{};
    final neighbors =
        widget.graph.adjacencyList[nodeId]?.map((n) => n.toString()).toList() ??
        [];

    // For each node in the graph
    for (final target in widget.graph.adjacencyList.keys) {
      final targetId = target.toString();

      // Skip self
      if (target == nodeId) continue;

      // If target is a direct neighbor
      if (neighbors.contains(targetId)) {
        table[targetId] = targetId; // Route directly
      }
      // Else use first neighbor as next hop
      else {
        table[targetId] = neighbors.isNotEmpty ? neighbors.first : '';
      }
    }

    return table;
  }

Future<void> _startFlooding() async {
  if (nodes.isEmpty || selectedStartNodeId == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Please select a start node!'))
    );
    return;
  }

  setState(() {
    isSimulating = true;
    messages.clear();
    activeMessageIndex = -1;
    currentStep = 0;
  });

  final startNode = nodes.firstWhere((n) => n.id == selectedStartNodeId);
  final destinationId = selectedTargetNodeId ?? nodes.last.id;

  // Create a queue for message processing
  final queue = Queue<Message>();
  queue.add(Message(
    sourceNodeId: startNode.id,
    destinationNodeId: destinationId,
    content: _messageController.text.isNotEmpty 
        ? _messageController.text 
        : 'Hello',
  ));

  while (queue.isNotEmpty && isSimulating) {
    final message = queue.removeFirst();
    
    // Show the current message
    setState(() {
      messages.add(message);
      activeMessageIndex = messages.length - 1;
      currentStep = 0;
    });

    // Animate the message movement
    await _animateMessage(message);

    // Process routing
    final currentNode = nodes.firstWhere((n) => n.id == message.sourceNodeId);
    if (message.destinationNodeId == currentNode.id) {
      continue; // Reached destination
    }

    // Get next hops according to routing table
    final nextHops = currentNode.routingTable[message.destinationNodeId] != null
        ? [currentNode.routingTable[message.destinationNodeId]!]
        : currentNode.neighbors;

    for (final nextHopId in nextHops) {
      if (nextHopId.isNotEmpty) {
        queue.add(Message(
          sourceNodeId: nextHopId,
          destinationNodeId: message.destinationNodeId,
          content: message.content,
        ));
      }
    }
  }

  setState(() => isSimulating = false);
}

Future<void> _animateMessage(Message message) async {
  final controller = AnimationController(
    duration: Duration(milliseconds: 500),
    vsync: this,
  );
  
  await controller.forward();
  controller.dispose();
}

  void _processMessage(Message message) {
    final sourceNode = nodes.firstWhere((n) => n.id == message.sourceNodeId);
    sourceNode.receivedMessages.add(message);

    setState(() {
      messages.add(message);
      activeMessageIndex = messages.length - 1;
      currentStep = 0;
    });

    _simulationTimer?.cancel();
    _simulationTimer = Timer.periodic(Duration(milliseconds: 300), (timer) {
      setState(() {
        currentStep++;
        if (currentStep >= totalSteps) {
          timer.cancel();
          _propagateMessage(message);
        }
      });
    });
  }

  void _propagateMessage(Message message) {
    final sourceNode = nodes.firstWhere((n) => n.id == message.sourceNodeId);
    final nextHopId = sourceNode.routingTable[message.destinationNodeId];

    if (nextHopId == null || nextHopId.isEmpty) {
      setState(() => isSimulating = false);
      return;
    }

    final nextHop = nodes.firstWhere((n) => n.id == nextHopId);
    _processMessage(message.copyWith(sourceNodeId: nextHop.id));
  }

  void _stopSimulation() {
    _simulationTimer?.cancel();
    setState(() => isSimulating = false);
  }

  void _resetSimulation() {
    _simulationTimer?.cancel();
    setState(() {
      isSimulating = false;
      messages.clear();
      activeMessageIndex = -1;
      currentStep = 0;
      for (var node in nodes) {
        node.receivedMessages.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Yönlendirme Simülasyonu'),
        actions: [
          IconButton(
            icon: Icon(Icons.help_outline),
            onPressed: () => _showHelpDialog(),
            tooltip: 'Yardım',
          ),
          IconButton(
            icon: Icon(
              _showRoutingTables
                  ? Icons.table_chart
                  : Icons.table_chart_outlined,
            ),
            onPressed:
                () => setState(() => _showRoutingTables = !_showRoutingTables),
            tooltip: 'Yönlendirme Tablolarını Göster/Gizle',
          ),
        ],
      ),
      body:Column(
  children: [
    // Control panel at the top
    _buildControlPanel(Theme.of(context).colorScheme),
    
    // Main graph visualization area
    Expanded(
      child: Stack(
        children: [
          // Interactive graph viewer as the base layer
          InteractiveViewer(
            boundaryMargin: EdgeInsets.all(100),
            minScale: 0.5,
            maxScale: 3.0,
            child: CustomPaint(
              size: Size.infinite,
              painter: GraphPainter(
                traversalOrder: [],
                graph: widget.graph,
                nodePositions: _nodePositions ?? {}, // Handle null case
                messages: messages,
                activeMessageIndex: activeMessageIndex,
                routingTables: _showRoutingTables
                    ? {for (var node in nodes) node.id: jsonEncode(node.routingTable)}
                    : null,
                currentStep: currentStep,
                totalSteps: totalSteps,
                showWeights: false,
              ),
            ),
          ),
          
          // Message animations overlay
          if (messages.isNotEmpty && activeMessageIndex >= 0 && _nodePositions != null)
            Positioned.fill(
              child: _buildMessageAnimations(),
            ),
        ],
      ),
    ),
    
    // Simulation controls at the bottom
    _buildSimulationControls(Theme.of(context).colorScheme),
  ],
),
    );
  }

Widget _buildMessageAnimations() {
  if (_nodePositions == null) return SizedBox.shrink();

  return IgnorePointer(
    child: Stack(
      clipBehavior: Clip.none,
      children: [
        // Draw all message paths
        for (final message in messages)
          if (_isValidMessage(message))
            CustomPaint(
              painter: _MessagePathPainter(
                from: _nodePositions![int.parse(message.sourceNodeId)]!,
                to: _nodePositions![int.parse(message.destinationNodeId)]!,
                isActive: messages.indexOf(message) == activeMessageIndex,
              ),
            ),
        
        // Draw message bubbles
        for (final entry in messages.asMap().entries)
          if (_isValidMessage(entry.value))
            _buildMessageBubble(entry.key, entry.value),
      ],
    ),
  );
}

bool _isValidMessage(Message message) {
  try {
    final sourceId = int.parse(message.sourceNodeId);
    final destId = int.parse(message.destinationNodeId);
    return _nodePositions!.containsKey(sourceId) && 
           _nodePositions!.containsKey(destId);
  } catch (e) {
    return false;
  }
}

Widget _buildMessageBubble(int index, Message message) {
  final sourceId = int.parse(message.sourceNodeId);
  final destId = int.parse(message.destinationNodeId);
    if (!_nodePositions!.containsKey(sourceId) || 
        !_nodePositions!.containsKey(destId)) {
      return SizedBox.shrink();
    }
  final from = _nodePositions![sourceId]!;
  final to = _nodePositions![destId]!;
  final progress = (index == activeMessageIndex) 
      ? currentStep / totalSteps 
      : 1.0;

  return Positioned(
    left: from.dx + (to.dx - from.dx) * progress - 20,
    top: from.dy + (to.dy - from.dy) * progress - 20,
    child: Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: (index == activeMessageIndex)
            ? Colors.orange
            : Colors.orange.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: Offset(0, 2),)
        ]
      ),
      child: Text(
        message.content.length > 3
            ? '${message.content.substring(0, 3)}..'
            : message.content,
        style: TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
  );
}


  Widget _buildControlPanel(ColorScheme colorScheme) {
    return Card(
      margin: EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            // Node selection
            Row(
              children: [
                Expanded(
                  child: _buildNodeSelector(
                    label: 'Başlangıç Düğümü',
                    selectedId: selectedStartNodeId,
                    onSelected:
                        (id) => setState(() => selectedStartNodeId = id),
                    color: Colors.green,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildNodeSelector(
                    label: 'Hedef Düğüm (Opsiyonel)',
                    selectedId: selectedTargetNodeId,
                    onSelected:
                        (id) => setState(() => selectedTargetNodeId = id),
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),

            // Message input
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      labelText: 'Mesaj İçeriği',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _resetSimulation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.error,
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                  child: Icon(Icons.refresh),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNodeSelector({
    required String label,
    required String? selectedId,
    required Function(String) onSelected,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
        SizedBox(height: 4),
        Container(
          height: 50,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: nodes.length,
            itemBuilder: (context, index) {
              final node = nodes[index];
              final isSelected = node.id == selectedId;
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ChoiceChip(
                  label: Text('Düğüm ${node.id}'),
                  selected: isSelected,
                  onSelected:
                      isSimulating ? null : (selected) => onSelected(node.id),
                  selectedColor: color.withOpacity(0.2),
                  labelStyle: TextStyle(
                    color: isSelected ? color : null,
                    fontWeight: isSelected ? FontWeight.bold : null,
                  ),
                  avatar:
                      isSelected
                          ? CircleAvatar(
                            backgroundColor: color,
                            radius: 10,
                            child: Icon(
                              Icons.check,
                              size: 12,
                              color: Colors.white,
                            ),
                          )
                          : null,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSimulationControls(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Message counter
          Chip(
            avatar: CircleAvatar(
              backgroundColor: colorScheme.primary.withOpacity(0.2),
              child: Icon(Icons.message, size: 16, color: colorScheme.primary),
            ),
            label: Text('Mesajlar: ${messages.length}'),
          ),

          // Simulation controls
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: isSimulating ? _stopSimulation : _startFlooding,
                icon: Icon(isSimulating ? Icons.stop : Icons.play_arrow),
                label: Text(isSimulating ? 'Durdur' : 'Başlat'),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isSimulating ? Colors.red : colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Map<int, Offset> _calculateForceDirectedPositions() {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    final area = width * height;
    final k = sqrt(area / widget.graph.adjacencyList.length);
    final iterations = 100;
    final positions = <int, Offset>{};
    final displacements = <int, Offset>{};

    final random = Random();
    final nodeIds = widget.graph.adjacencyList.keys.toList();

    // Başlangıç pozisyonlarını rastgele ata
    for (var id in nodeIds) {
      positions[id] = Offset(
        random.nextDouble() * width,
        random.nextDouble() * height * 0.6,
      );
    }

    for (int iter = 0; iter < iterations; iter++) {
      // Yer değiştirmeleri sıfırla
      for (var id in nodeIds) {
        displacements[id] = Offset.zero;
      }

      // Repulsive forces (itme kuvveti)
      for (int i = 0; i < nodeIds.length; i++) {
        for (int j = i + 1; j < nodeIds.length; j++) {
          final u = nodeIds[i];
          final v = nodeIds[j];
          final delta = positions[u]! - positions[v]!;
          final distance = delta.distance + 0.01;
          final force = k * k / distance;

          final direction = delta / distance;

          displacements[u] = displacements[u]! + direction * force;
          displacements[v] = displacements[v]! - direction * force;
        }
      }

      // Attractive forces (çekme kuvveti)
      widget.graph.adjacencyList.forEach((u, neighbors) {
        for (var v in neighbors) {
          final delta = positions[u]! - positions[v]!;
          final distance = delta.distance + 0.01;
          final force = distance * distance / k;

          final direction = delta / distance;

          displacements[u] = displacements[u]! - direction * force;
          displacements[v] = displacements[v]! + direction * force;
        }
      });

      // Pozisyonları güncelle
      for (var id in nodeIds) {
        var disp = displacements[id]!;
        var pos = positions[id]! + disp * 0.05;

        // Kenarlara taşmasını önle
        pos = Offset(pos.dx.clamp(0.0, width), pos.dy.clamp(0.0, height * 0.6));

        positions[id] = pos;
      }
    }

    return positions;
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Yönlendirme Simülasyonu Yardım'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Bu simülasyon basit bir flooding algoritmasını göstermektedir.',
                  ),
                  SizedBox(height: 12),
                  Text('Nasıl Kullanılır:'),
                  SizedBox(height: 8),
                  _buildHelpItem('1. Başlangıç ve hedef düğümleri seçin'),
                  _buildHelpItem('2. İsteğe bağlı mesaj içeriğini düzenleyin'),
                  _buildHelpItem(
                    '3. "Başlat" butonuna basarak simülasyonu başlatın',
                  ),
                  _buildHelpItem(
                    '4. Mesajların ağ üzerinde nasıl yayıldığını gözlemleyin',
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Yönlendirme tabloları her düğümün hangi komşuya yönlendirme yapacağını gösterir.',
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Tamam'),
              ),
            ],
          ),
    );
  }

  Widget _buildHelpItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [Text('• '), Expanded(child: Text(text))],
      ),
    );
  }
}
extension OffsetExtensions on Offset {
  Offset normalized() {
    final length = distance;
    return length > 0 ? this / length : this;
  }

  double directionAngle() {
    return atan2(dy, dx);
  }
}
class _MessagePathPainter extends CustomPainter {
  final Offset from;
  final Offset to;
  final bool isActive;

  _MessagePathPainter({required this.from, required this.to, required this.isActive});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isActive ? Colors.orange : Colors.orange.withOpacity(0.2)
      ..strokeWidth = isActive ? 3 : 2
      ..style = PaintingStyle.stroke;

    canvas.drawLine(from, to, paint);
    
    if (isActive) {
      _drawArrow(canvas, from, to);
    }
  }

  void _drawArrow(Canvas canvas, Offset start, Offset end) {
    final direction = (end - start).normalized();
    const arrowSize = 12.0;
    const arrowAngle = 0.5;
    
    final arrowPaint = Paint()
      ..color = Colors.orange
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(end.dx, end.dy)
      ..lineTo(end.dx - arrowSize * cos(atan2(direction.dy, direction.dx) - arrowAngle),
               end.dy - arrowSize * sin(atan2(direction.dy, direction.dx) - arrowAngle))
      ..lineTo(end.dx - arrowSize * cos(atan2(direction.dy, direction.dx) + arrowAngle),
               end.dy - arrowSize * sin(atan2(direction.dy, direction.dx) + arrowAngle))
      ..close();

    canvas.drawPath(path, arrowPaint);
  }

  @override
  bool shouldRepaint(covariant _MessagePathPainter oldDelegate) {
    return from != oldDelegate.from || 
           to != oldDelegate.to ||
           isActive != oldDelegate.isActive;
  }
}