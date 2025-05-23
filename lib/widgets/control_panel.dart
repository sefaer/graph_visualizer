import 'package:flutter/material.dart';

class ControlPanel extends StatelessWidget {
  final VoidCallback onBfsPressed;
  final VoidCallback onDfsPressed;
  final VoidCallback onNewGraphPressed;
  final VoidCallback onScreenShot;

  ControlPanel({
    required this.onBfsPressed,
    required this.onDfsPressed,
    required this.onNewGraphPressed,
    required this.onScreenShot
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(onPressed: onBfsPressed, child: Text("BFS")),
            SizedBox(width: 20),
            ElevatedButton(onPressed: onDfsPressed, child: Text("DFS")),
          ],
        ),
        SizedBox(height: 20),
        ElevatedButton(onPressed: onNewGraphPressed, child: Text("New Graph")),
           SizedBox(height: 20),
        ElevatedButton(onPressed: onNewGraphPressed, child: Text("Export")),
      ],
    );
  }
}
