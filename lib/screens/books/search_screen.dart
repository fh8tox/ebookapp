import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/book.dart';
import '../../services/download_service.dart';
import '../../services/favorite_service.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final downloader = DownloadService();
  final favoriteService = FavoriteService();

  final Map<String, double> progressMap = {};
  final Map<String, bool> downloadingMap = {};
  final Map<String, bool> downloadCache = {};

  Directory? _appDir;

  String keyword = "";

  @override
  void initState() {
    super.initState();
    _initAppDir();
  }

  Future<void> _initAppDir() async {
    _appDir = await downloader.getDir();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // =========================
  // PATH
  // =========================
  String _pdfPath(Book book) => '${_appDir?.path ?? ''}/${book.id}.pdf';
  String _imgPath(Book book) => '${_appDir?.path ?? ''}/${book.id}.jpg';

  Future<bool> isDownloaded(Book book) async {
    if (downloadCache.containsKey(book.id)) {
      return downloadCache[book.id]!;
    }

    if (_appDir == null) return false;

    final exists = await File(_pdfPath(book)).exists();
    downloadCache[book.id] = exists;
    return exists;
  }

  // =========================
  // FAVORITE
  // =========================
  Future<void> toggleFavorite(Book book) async {
    final isFav = await favoriteService.isFavorite(book.id);

    if (isFav) {
      await favoriteService.removeFavorite(book.id);
    } else {
      await favoriteService.addFavorite(book);
    }

    setState(() {});
  }

  // =========================
  // DOWNLOAD
  // =========================
  Future<void> downloadBook(Book book) async {
    if (downloadingMap[book.id] == true) return;

    setState(() {
      downloadingMap[book.id] = true;
      progressMap[book.id] = 0.0;
    });

    downloader.progressStream(book.id).listen((p) {
      if (mounted) setState(() => progressMap[book.id] = p);
    });

    try {
      await downloader.downloadBook(book);

      setState(() {
        downloadingMap[book.id] = false;
        progressMap.remove(book.id);
        downloadCache[book.id] = true;
      });

      _snack("Tải thành công!");
    } catch (_) {
      setState(() {
        downloadingMap[book.id] = false;
        progressMap.remove(book.id);
      });

      _snack("Tải thất bại!");
    }
  }

  Future<void> deleteDownload(Book book) async {
    await File(_pdfPath(book)).delete().catchError((_) {});
    await File(_imgPath(book)).delete().catchError((_) {});

    setState(() {
      downloadCache[book.id] = false;
      progressMap.remove(book.id);
      downloadingMap.remove(book.id);
    });

    _snack("Đã xóa file!");
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  // =========================
  // THEME HELPERS
  // =========================
  ColorScheme get cs => Theme.of(context).colorScheme;

  // =========================
  // COVER
  // =========================
  Widget buildBookCover(Book book) {
    return FutureBuilder<bool>(
      future: isDownloaded(book),
      builder: (context, snap) {
        if (snap.data == true) {
          return Image.file(
            File(_imgPath(book)),
            width: 60,
            height: 80,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _coverNet(book),
          );
        }
        return _coverNet(book);
      },
    );
  }

  Widget _coverNet(Book book) {
    return Image.network(
      book.imageUrl,
      width: 60,
      height: 80,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        width: 60,
        height: 80,
        color: cs.surfaceContainerHighest,
        child: Icon(Icons.menu_book, color: cs.primary),
      ),
    );
  }

  // =========================
  // ACTIONS
  // =========================
  Widget buildActions(Book book) {
    final isDownloading = downloadingMap[book.id] ?? false;
    final progress = progressMap[book.id] ?? 0.0;

    return FutureBuilder<bool>(
      future: isDownloaded(book),
      builder: (context, snap) {
        final downloaded = snap.data ?? false;

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FutureBuilder<bool>(
              future: favoriteService.isFavorite(book.id),
              builder: (context, fav) {
                final isFav = fav.data ?? false;

                return IconButton(
                  icon: Icon(
                    isFav ? Icons.favorite : Icons.favorite_border,
                    color: isFav ? cs.error : cs.onSurfaceVariant,
                  ),
                  onPressed: () => toggleFavorite(book),
                );
              },
            ),

            if (downloaded)
              IconButton(
                icon: Icon(Icons.delete_outline, color: cs.error),
                onPressed: () => deleteDownload(book),
              )
            else if (isDownloading)
              SizedBox(
                width: 40,
                height: 40,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(value: progress),
                    Text("${(progress * 100).toInt()}%",
                        style: TextStyle(fontSize: 10, color: cs.onSurface)),
                  ],
                ),
              )
            else
              IconButton(
                icon: Icon(Icons.download, color: cs.primary),
                onPressed: () => downloadBook(book),
              ),
          ],
        );
      },
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
        title: const Text("Tìm sách"),
        backgroundColor: cs.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _searchController.clear();
              setState(() => keyword = "");
            },
          )
        ],
      ),

      body: Column(
        children: [
          // SEARCH BAR
          Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(20),
            ),
            child: TextField(
              controller: _searchController,
              style: TextStyle(color: cs.onSurface),
              decoration: InputDecoration(
                hintText: "Tìm sách...",
                prefixIcon: Icon(Icons.search, color: cs.onSurfaceVariant),
                border: InputBorder.none,
              ),
              onChanged: (v) => setState(() => keyword = v.toLowerCase()),
            ),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('books')
                  .orderBy('title')
                  .snapshots(),

              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final books = snapshot.data!.docs
                    .map((e) => Book.fromMap(
                  e.data() as Map<String, dynamic>,
                  e.id,
                ))
                    .where((b) =>
                b.title.toLowerCase().contains(keyword) ||
                    b.author.toLowerCase().contains(keyword))
                    .toList();

                if (books.isEmpty) {
                  return Center(
                    child: Text(
                      keyword.isEmpty
                          ? "Khám phá sách"
                          : "Không tìm thấy",
                      style: TextStyle(color: cs.onSurfaceVariant),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: books.length,
                  itemBuilder: (_, i) {
                    final book = books[i];
                    return _bookCard(book);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _bookCard(Book book) {
    return Card(
      color: cs.surfaceContainerHighest,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: buildBookCover(book),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: cs.onSurface,
                    ),
                  ),
                  Text(
                    book.author,
                    style: TextStyle(color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),

            buildActions(book),
          ],
        ),
      ),
    );
  }
}