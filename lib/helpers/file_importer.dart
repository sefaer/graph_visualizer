import 'dart:io';
import 'package:file_picker/file_picker.dart';

class FileImporter {
  static Future<FileImportResult?> importGraphFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt', 'csv', 'doc', 'docx'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        final content = await File(file.path!).readAsString();
        
        return FileImportResult(
          fileName: file.name,
          content: content,
          filePath: file.path!,
          fileSize: file.size,
        );
      }
      return null;
    } catch (e) {
      throw FileImportException(e.toString());
    }
  }

}

class FileImportResult {
  final String fileName;
  final String content;
  final String filePath;
  final int fileSize;

  FileImportResult({
    required this.fileName,
    required this.content,
    required this.filePath,
    required this.fileSize,
  });
}

class FileImportException implements Exception {
  final String message;
  
  FileImportException(this.message);
  
  @override
  String toString() => 'FileImportException: $message';
}