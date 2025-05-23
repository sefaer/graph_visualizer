import 'package:graph_visualizer/screens/main_screen.dart';
import 'package:flutter/material.dart';
import 'screens/bfs-dfs/input_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Algoritma Görselleştirme',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MainScreen(),
      routes: {
        '/input': (context) => InputScreen(),
        // '/mst': (context) => MinimumSpanningTreeScreen(),
      },
    );
  }
}
