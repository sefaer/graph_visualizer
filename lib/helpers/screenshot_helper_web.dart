import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'dart:typed_data';

Future<void> saveImageWeb(BuildContext context, Uint8List bytes) async {
  try {
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..target = 'blank'
      ..download = 'graph_screenshot_${DateTime.now().millisecondsSinceEpoch}.png'
      ..click();
    
    html.Url.revokeObjectUrl(url);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Grafik indiriliyor...'),
        duration: Duration(seconds: 2),
      ),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Web indirme hatası: ${e.toString()}'),
        backgroundColor: Colors.red,
      ),
    );
  }
}