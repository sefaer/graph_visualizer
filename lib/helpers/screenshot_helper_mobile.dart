import 'package:flutter/material.dart';
import 'dart:typed_data';

Future<void> saveImageWeb(BuildContext context, Uint8List bytes) async {
  // Bu fonksiyon sadece web'de çalışır, diğer platformlarda boş bırakıyoruz
  debugPrint('Web kaydetme fonksiyonu bu platformda çalıştırılmadı');
  return;
}