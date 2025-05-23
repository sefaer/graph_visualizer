import 'package:flutter/material.dart';
import 'package:graph_visualizer/models/graphs.dart' as my_models;

class CustomEdgeWidget extends StatelessWidget {
  final my_models.Edge edge;
  final String? label;
  final Color color;
  final double width;

  const CustomEdgeWidget({
    Key? key,
    required this.edge,
    this.label,
    required this.color,
    required this.width,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _EdgePainter(
        edge: edge,
        color: color,
        strokeWidth: width,
        label: label,
      ),
    );
  }
}

class _EdgePainter extends CustomPainter {
  final my_models.Edge edge;
  final Color color;
  final double strokeWidth;
  final String? label;

  _EdgePainter({
    required this.edge,
    required this.color,
    required this.strokeWidth,
    this.label,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (edge.sourcePosition == null || edge.destinationPosition == null) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    // Kenar çizgisi
    canvas.drawLine(
      edge.sourcePosition!,
      edge.destinationPosition!,
      paint,
    );

    // Eğer label varsa, kenarın ortasına yaz
    if (label != null) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
            color: color.computeLuminance() > 0.5 ? Colors.black : Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final centerX = (edge.sourcePosition!.dx + edge.destinationPosition!.dx) / 2;
      final centerY = (edge.sourcePosition!.dy + edge.destinationPosition!.dy) / 2;

      textPainter.paint(
        canvas,
        Offset(centerX - textPainter.width / 2, centerY - textPainter.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}