import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:http/http.dart' as http;

class ReadBookScreen extends StatefulWidget {
  final String pdfUrl;

  const ReadBookScreen({super.key, required this.pdfUrl});

  @override
  State<ReadBookScreen> createState() => _ReadBookScreenState();
}

class _ReadBookScreenState extends State<ReadBookScreen> {
  final PdfViewerController _controller = PdfViewerController();
  final TextEditingController _searchController = TextEditingController();

  PdfTextSearchResult _searchResult = PdfTextSearchResult();

  Uint8List? pdfBytes;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadPdf();
  }

  Future<void> loadPdf() async {
    try {
      final response = await http.get(Uri.parse(widget.pdfUrl));

      if (response.statusCode == 200) {
        setState(() {
          pdfBytes = response.bodyBytes;
          loading = false;
        });
      } else {
        throw Exception("Load failed");
      }
    } catch (e) {
      print("ERROR LOAD PDF: $e");
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Đọc sách"),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text("Tìm trong sách"),
                  content: TextField(
                    controller: _searchController,
                    decoration:
                    const InputDecoration(hintText: "Nhập từ khóa"),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        _searchResult =
                            _controller.searchText(_searchController.text);
                        Navigator.pop(context);
                      },
                      child: const Text("Tìm"),
                    )
                  ],
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.navigate_before),
            onPressed: () => _searchResult.previousInstance(),
          ),
          IconButton(
            icon: const Icon(Icons.navigate_next),
            onPressed: () => _searchResult.nextInstance(),
          ),
        ],
      ),

      body: loading
          ? const Center(child: CircularProgressIndicator())
          : pdfBytes != null
          ? SfPdfViewer.memory(
        pdfBytes!,
        controller: _controller,
      )
          : const Center(child: Text("Không mở được PDF")),
    );
  }
}