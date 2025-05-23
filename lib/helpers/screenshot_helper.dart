import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class ScreenshotHelper {
  static final GlobalKey screenshotKey = GlobalKey();

  static Future<void> captureAndSaveGraph(BuildContext context) async {
    try {
      final boundary =
          screenshotKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;

      if (boundary == null) {
        throw Exception("Render sınırı bulunamadı");
      }

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        throw Exception("Resim byte'a dönüştürülemedi");
      }

      final pngBytes = byteData.buffer.asUint8List();

      if (kIsWeb) {
        await _saveImageWeb(context, pngBytes);
      } else {
        await _saveImageDesktop(context, pngBytes);
      }
    } catch (e) {
      debugPrint('Ekran görüntüsü hatası: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hata: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  static Future<void> _saveImageWeb(
    BuildContext context,
    Uint8List bytes,
  ) async {
    // Web implementasyonu ayrı bir dosyada olacak
    throw UnsupportedError('Web implementasyonu bu dosyada bulunmuyor');
  }

  static Future<void> _saveImageDesktop(
    BuildContext context,
    Uint8List bytes,
  ) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = '${directory.path}/graph_screenshot_$timestamp.png';

      await File(filePath).writeAsBytes(bytes);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Grafik kaydedildi: $filePath'),
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Kaydetme hatası: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
