import 'dart:io';
import 'package:flutter/material.dart';
import 'package:epub_view/epub_view.dart';

class ReadLocalBookScreen extends StatefulWidget {
  final String path;

  const ReadLocalBookScreen({super.key, required this.path});

  @override
  State<ReadLocalBookScreen> createState() => _ReadLocalBookScreenState();
}

class _ReadLocalBookScreenState extends State<ReadLocalBookScreen> {
  late EpubController _epubController;

  @override
  void initState() {
    super.initState();
    _epubController = EpubController(
      document: EpubDocument.openFile(File(widget.path)),
    );
  }

  @override
  void dispose() {
    _epubController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: EpubViewActualChapter(
          controller: _epubController,
          builder: (chapterValue) => Text(
            chapterValue?.chapter?.Title?.trim() ?? "Đang tải...",
            style: const TextStyle(fontSize: 15),
          ),
        ),
        // 🔙 Nút back
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      drawer: Drawer(child: EpubViewTableOfContents(controller: _epubController)),
      body: EpubView(
        controller: _epubController,
        builders: EpubViewBuilders<DefaultBuilderOptions>(
          options: const DefaultBuilderOptions(),
          loaderBuilder: (_) => const Center(child: CircularProgressIndicator()),
          errorBuilder: (_, error) => Center(child: Text("Lỗi: $error")),
        ),
      ),
    );
  }
}