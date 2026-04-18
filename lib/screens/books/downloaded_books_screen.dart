import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';

import '../../models/book.dart';
import '../../services/download_service.dart';
import '../../services/favorite_service.dart';
import 'read_local_book_screen.dart';

class DownloadedBooksScreen extends StatefulWidget {
  const DownloadedBooksScreen({super.key});

  @override
  State<DownloadedBooksScreen> createState() =>
      _DownloadedBooksScreenState();
}

class _DownloadedBooksScreenState extends State<DownloadedBooksScreen> {
  final downloader = DownloadService();
  final favoriteService = FavoriteService();

  List<Map<String, dynamic>> downloadedBooks = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadDownloadedBooks();
  }

  ColorScheme get cs => Theme.of(context).colorScheme;

  // =========================
  // LOAD LOCAL BOOKS (EPUB)
  // =========================
  Future<void> loadDownloadedBooks() async {
    setState(() => isLoading = true);

    try {
      final dir = await downloader.getDir();

      final jsonFiles = dir
          .listSync()
          .where((f) => f.path.endsWith('.json'))
          .toList();

      List<Map<String, dynamic>> books = [];

      for (var file in jsonFiles) {
        try {
          final jsonContent = await File(file.path).readAsString();
          final data = jsonDecode(jsonContent);

          final bookId = data['id'];
          // 🔥 ĐỔI: Kiểm tra file .epub thay vì .pdf
          final epubPath = '${dir.path}/$bookId.epub';

          if (!await File(epubPath).exists()) continue;

          final isFavorite = await favoriteService.isFavorite(bookId);

          books.add({
            'id': bookId,
            'data': data,
            'path': epubPath, // Đường dẫn đến file epub
            'isFavorite': isFavorite,
          });
        } catch (_) {}
      }

      if (mounted) {
        setState(() {
          downloadedBooks = books;
          isLoading = false;
        });
      }
    } catch (_) {
      setState(() {
        downloadedBooks = [];
        isLoading = false;
      });
    }
  }

  // =========================
  // DELETE (EPUB)
  // =========================
  Future<void> deleteBook(Map<String, dynamic> bookInfo) async {
    final id = bookInfo['id'];
    final epubPath = bookInfo['path']; // Đã là .epub từ loadDownloadedBooks
    final dir = await downloader.getDir();

    // Xóa file sách, ảnh cover và file meta json
    await File(epubPath).delete().catchError((_) {});
    await File('${dir.path}/$id.jpg').delete().catchError((_) {});
    await File('${dir.path}/$id.json').delete().catchError((_) {});

    await loadDownloadedBooks();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Đã xóa sách khỏi thiết bị"),
          backgroundColor: cs.primary,
        ),
      );
    }
  }

  // =========================
  // FAVORITE
  // =========================
  Future<void> toggleFavorite(Map<String, dynamic> bookInfo) async {
    final id = bookInfo['id'];
    final data = bookInfo['data'];
    final current = bookInfo['isFavorite'];

    // Chú ý: Book.fromMap cần xử lý key 'epubUrl' thay vì 'pdfUrl'
    final book = Book.fromMap(data, id);

    if (current) {
      await favoriteService.removeFavorite(id);
    } else {
      await favoriteService.addFavorite(book);
    }

    setState(() {
      bookInfo['isFavorite'] = !current;
    });
  }

  // =========================
  // COVER & UI HELPERS
  // =========================
  Widget buildCover(Map<String, dynamic> bookInfo) {
    final data = bookInfo['data'];
    final imageUrl = data['imageUrl'];

    if (imageUrl != null && imageUrl.isNotEmpty) {
      return Image.network(
        imageUrl,
        width: 60,
        height: 80,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(),
      );
    }
    return _placeholder();
  }

  Widget _placeholder() {
    return Container(
      width: 60,
      height: 80,
      color: cs.surfaceContainerHighest,
      child: Icon(Icons.book, color: cs.primary), // Đổi icon sang book
    );
  }

  void showDeleteDialog(Map<String, dynamic> bookInfo) {
    final title = bookInfo['data']['title'];

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: cs.surface,
        title: const Text("Xóa sách?"),
        content: Text("Bạn có chắc muốn xóa vĩnh viễn file EPUB của \"$title\"?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Hủy"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              deleteBook(bookInfo);
            },
            style: TextButton.styleFrom(foregroundColor: cs.error),
            child: const Text("Xóa"),
          ),
        ],
      ),
    );
  }

  // =========================
  // UI
  // =========================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: Text("Thư viện Offline (${downloadedBooks.length})"),
        backgroundColor: cs.surface,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: loadDownloadedBooks,
            icon: const Icon(Icons.refresh),
          )
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : downloadedBooks.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off, size: 80, color: cs.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(
              "Không tìm thấy sách offline",
              style: TextStyle(color: cs.onSurface, fontSize: 16),
            ),
            Text(
              "Sách bạn tải về sẽ xuất hiện ở đây",
              style: TextStyle(color: cs.onSurfaceVariant),
            ),
          ],
        ),
      )
          : RefreshIndicator(
        onRefresh: loadDownloadedBooks,
        child: ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: downloadedBooks.length,
          itemBuilder: (_, i) {
            final bookInfo = downloadedBooks[i];
            final data = bookInfo['data'];
            final isFav = bookInfo['isFavorite'];

            return Card(
              color: cs.surfaceContainerHighest,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ReadLocalBookScreen(
                        path: bookInfo['path'], // Path đến file .epub
                      ),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: buildCover(bookInfo),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data['title'] ?? 'Không rõ tiêu đề',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: cs.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              data['author'] ?? 'Không rõ tác giả',
                              style: TextStyle(color: cs.onSurfaceVariant),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: cs.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                "EPUB",
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: cs.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        children: [
                          IconButton(
                            icon: Icon(
                              isFav ? Icons.favorite : Icons.favorite_border,
                              color: isFav ? cs.error : cs.onSurfaceVariant,
                            ),
                            onPressed: () => toggleFavorite(bookInfo),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete_outline, color: cs.error),
                            onPressed: () => showDeleteDialog(bookInfo),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}