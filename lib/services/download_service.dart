import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../models/book.dart';

class DownloadService {
  final Map<String, StreamController<double>> _progressControllers = {};

  Future<Directory> getDir() async {
    return await getApplicationDocumentsDirectory();
  }


  // ✅ SỬA: Không thay đổi ID, dùng nguyên book.id làm filename
  String _fileName(String id) {
    return id; // Giữ nguyên ID gốc
  }

  // =========================
  // PROGRESS STREAM
  // =========================
  Stream<double> progressStream(String bookId) {
    if (!_progressControllers.containsKey(bookId)) {
      _progressControllers[bookId] = StreamController<double>.broadcast();
    }
    return _progressControllers[bookId]!.stream;
  }

  // =========================
  // CLEANUP
  // =========================
  void _cleanup(String bookId) {
    final controller = _progressControllers[bookId];
    controller?.close();
    _progressControllers.remove(bookId);
  }

  Future<Map<String, String>> downloadBook(
      Book book, {
        Function(double progress)? onProgress,
      }) async {
    final bookId = book.id;
    final controller = _progressControllers[bookId];

    final dir = await getDir();
    final fileName = _fileName(bookId); // ✅ Giờ fileName = book.id chính xác

    final pdfPath = '${dir.path}/$fileName.pdf';
    final imagePath = '${dir.path}/$fileName.jpg';
    final metaPath = '${dir.path}/$fileName.json';

    final pdfFile = File(pdfPath);
    final imageFile = File(imagePath);
    final metaFile = File(metaPath);

    try {
      // ================= PDF DOWNLOAD WITH PROGRESS =================
      if (!await pdfFile.exists()) {
        final request = await http.Client().send(
          http.Request('GET', Uri.parse(book.pdfUrl)),
        );

        final totalBytes = request.contentLength ?? 0;
        int received = 0;
        final bytes = <int>[];

        await for (var chunk in request.stream) {
          bytes.addAll(chunk);
          received += chunk.length;

          final progress = totalBytes > 0 ? received / totalBytes : 0.0;

          // Update stream
          controller?.add(progress);
          // Update callback
          onProgress?.call(progress);
        }

        await pdfFile.writeAsBytes(bytes);
        controller?.add(1.0);
        onProgress?.call(1.0);
      } else {
        controller?.add(1.0);
        onProgress?.call(1.0);
      }

      // ================= IMAGE =================
      if (!await imageFile.exists() && book.imageUrl.isNotEmpty) {
        try {
          final res = await http.get(Uri.parse(book.imageUrl));
          if (res.statusCode == 200) {
            await imageFile.writeAsBytes(res.bodyBytes);
          }
        } catch (_) {}
      }

      // ================= META =================
      if (!await metaFile.exists()) {
        final data = {
          "id": book.id,        // ✅ Lưu đúng book.id gốc
          "title": book.title,
          "author": book.author,
          "imageUrl": book.imageUrl,
          "pdfUrl": book.pdfUrl,
        };

        await metaFile.writeAsString(jsonEncode(data));
      }

      return {
        "pdfPath": pdfPath,
        "imagePath": imagePath,
        "metaPath": metaPath,
      };
    } finally {
      Future.delayed(const Duration(seconds: 2), () {
        _cleanup(bookId);
      });
    }
  }

  void dispose() {
    for (var controller in _progressControllers.values) {
      controller.close();
    }
    _progressControllers.clear();
  }
}