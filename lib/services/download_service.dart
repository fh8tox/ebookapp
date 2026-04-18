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

  // File name dùng ID gốc của sách
  String _fileName(String id) {
    return id;
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

    // Đảm bảo controller tồn tại để báo progress
    if (!_progressControllers.containsKey(bookId)) {
      _progressControllers[bookId] = StreamController<double>.broadcast();
    }
    final controller = _progressControllers[bookId];

    final dir = await getDir();
    final fileName = _fileName(bookId);

    // Đổi đuôi file sang .epub
    final epubPath = '${dir.path}/$fileName.epub';
    final imagePath = '${dir.path}/$fileName.jpg';
    final metaPath = '${dir.path}/$fileName.json';

    final epubFile = File(epubPath);
    final imageFile = File(imagePath);
    final metaFile = File(metaPath);

    try {
      // ================= EPUB DOWNLOAD WITH PROGRESS =================
      if (!await epubFile.exists()) {
        final client = http.Client();
        final request = http.Request('GET', Uri.parse(book.epubUrl)); // Dùng epubUrl
        final response = await client.send(request);

        final totalBytes = response.contentLength ?? 0;
        int received = 0;

        // Sử dụng IOSink để ghi file trực tiếp, tiết kiệm RAM
        final sink = epubFile.openWrite();

        await for (var chunk in response.stream) {
          sink.add(chunk);
          received += chunk.length;

          final progress = totalBytes > 0 ? received / totalBytes : 0.0;

          // Update stream và callback
          controller?.add(progress);
          onProgress?.call(progress);
        }

        await sink.close();
        client.close();

        controller?.add(1.0);
        onProgress?.call(1.0);
      } else {
        // Nếu file đã tồn tại, báo progress hoàn tất ngay
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
        } catch (e) {
          print("Download image error: $e");
        }
      }

      // ================= META (Lưu thông tin sách để dùng offline) =================
      if (!await metaFile.exists()) {
        final data = {
          "id": book.id,
          "title": book.title,
          "author": book.author,
          "imageUrl": book.imageUrl,
          "epubUrl": book.epubUrl, // Lưu epubUrl thay vì pdfUrl
        };

        await metaFile.writeAsString(jsonEncode(data));
      }

      return {
        "epubPath": epubPath,
        "imagePath": imagePath,
        "metaPath": metaPath,
      };
    } catch (e) {
      print("Download error: $e");
      rethrow;
    } finally {
      // Đợi một chút rồi mới đóng stream để UI kịp cập nhật trạng thái hoàn tất
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