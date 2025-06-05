// widgets/message_widget.dart
import 'package:flutter/material.dart';

class MessageAnimation extends StatelessWidget {
  final String content;
  final Offset from;
  final Offset to;
  final bool isActive;

  const MessageAnimation({
    required this.content,
    required this.from,
    required this.to,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(seconds: 1),
      builder: (_, double progress, __) {
        final currentPosition = Offset(
          from.dx + (to.dx - from.dx) * progress,
          from.dy + (to.dy - from.dy) * progress,
        );

        return Positioned(
          left: currentPosition.dx - 20,
          top: currentPosition.dy - 20,
          child: Opacity(
            opacity: isActive ? 1.0 : 0.6,
            child: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isActive ? Colors.orange : Colors.orange.withOpacity(0.6),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  )],
              ),
              child: Text(
                content,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}