import 'dart:io';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class ReadLocalBookScreen extends StatelessWidget {
  final String path;

  const ReadLocalBookScreen({super.key, required this.path});

  @override
  Widget build(BuildContext context) {
    final file = File(path);

    return Scaffold(
      appBar: AppBar(title: const Text("Đọc sách")),
      body: file.existsSync()
          ? SfPdfViewer.file(file)
          : const Center(child: Text("Không tìm thấy file")),
    );
  }
}