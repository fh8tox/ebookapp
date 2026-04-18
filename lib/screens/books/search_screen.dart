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
  // PATH (Chuyển sang EPUB)
  // =========================
  String _epubPath(Book book) => '${_appDir?.path ?? ''}/${book.id}.epub';
  String _imgPath(Book book) => '${_appDir?.path ?? ''}/${book.id}.jpg';

  Future<bool> isDownloaded(Book book) async {
    if (downloadCache.containsKey(book.id)) {
      return downloadCache[book.id]!;
    }

    if (_appDir == null) return false;

    // Kiểm tra file .epub tồn tại
    final exists = await File(_epubPath(book)).exists();
    downloadCache[book.id] = exists;
    return exists;
  }

  // =========================
  // FAVORITE
  // =========================
  Future<void> toggleFavorite(Book book) async {
    final isFav = await favoriteService.isFavorite(book.id);

    if (isFav) {
      await serviceRemove(book.id);
    } else {
      await favoriteService.addFavorite(book);
    }
    if (mounted) setState(() {});
  }

  Future<void> serviceRemove(String id) async {
    await favoriteService.removeFavorite(id);
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

    // Lắng nghe tiến trình từ stream của DownloadService
    final subscription = downloader.progressStream(book.id).listen((p) {
      if (mounted) setState(() => progressMap[book.id] = p);
    });

    try {
      await downloader.downloadBook(book);

      subscription.cancel();
      setState(() {
        downloadingMap[book.id] = false;
        progressMap.remove(book.id);
        downloadCache[book.id] = true;
      });

      _snack("Tải file EPUB thành công!");
    } catch (e) {
      subscription.cancel();
      setState(() {
        downloadingMap[book.id] = false;
        progressMap.remove(book.id);
      });
      _snack("Tải thất bại!");
    }
  }

  Future<void> deleteDownload(Book book) async {
    await File(_epubPath(book)).delete().catchError((_) {});
    await File(_imgPath(book)).delete().catchError((_) {});
    // Xóa cả file json meta nếu có
    await File('${_appDir?.path ?? ''}/${book.id}.json').delete().catchError((_) {});

    setState(() {
      downloadCache[book.id] = false;
      progressMap.remove(book.id);
      downloadingMap.remove(book.id);
    });

    _snack("Đã xóa file EPUB!");
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  ColorScheme get cs => Theme.of(context).colorScheme;

  // =========================
  // COVER
  // =========================
  Widget buildBookCover(Book book) {
    return FutureBuilder<bool>(
      future: isDownloaded(book),
      builder: (context, snap) {
        if (snap.data == true) {
          final localImage = File(_imgPath(book));
          if (localImage.existsSync()) {
            return Image.file(
              localImage,
              width: 60,
              height: 80,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _coverNet(book),
            );
          }
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
        child: Icon(Icons.book, color: cs.primary),
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
            // Favorite Button
            StreamBuilder<QuerySnapshot>(
              stream: favoriteService.getFavorites(),
              builder: (context, favSnap) {
                final isFav = favSnap.hasData &&
                    favSnap.data!.docs.any((d) => d.id == book.id);

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
                icon: Icon(Icons.delete_sweep_outlined, color: cs.error),
                onPressed: () => deleteDownload(book),
              )
            else if (isDownloading)
              SizedBox(
                width: 40,
                height: 40,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(value: progress, strokeWidth: 3),
                    Text("${(progress * 100).toInt()}%",
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: cs.onSurface)),
                  ],
                ),
              )
            else
              IconButton(
                icon: Icon(Icons.cloud_download_outlined, color: cs.primary),
                onPressed: () => downloadBook(book),
              ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: const Text("Tìm kiếm sách"),
        backgroundColor: cs.surface,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // SEARCH BAR
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SearchBar(
              controller: _searchController,
              hintText: "Tên sách hoặc tác giả...",
              leading: const Icon(Icons.search),
              trailing: [
                if (_searchController.text.isNotEmpty)
                  IconButton(
                    onPressed: () {
                      _searchController.clear();
                      setState(() => keyword = "");
                    },
                    icon: const Icon(Icons.close),
                  )
              ],
              onChanged: (v) => setState(() => keyword = v.toLowerCase()),
              elevation: WidgetStateProperty.all(0),
              backgroundColor: WidgetStateProperty.all(cs.surfaceContainerHighest),
            ),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('books')
                  .orderBy('title')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("Không có dữ liệu sách"));
                }

                final books = snapshot.data!.docs
                    .map((e) => Book.fromMap(e.data() as Map<String, dynamic>, e.id))
                    .where((b) =>
                b.title.toLowerCase().contains(keyword) ||
                    b.author.toLowerCase().contains(keyword))
                    .toList();

                if (books.isEmpty) {
                  return Center(
                    child: Text(
                      keyword.isEmpty ? "Bắt đầu khám phá sách hay" : "Không tìm thấy kết quả",
                      style: TextStyle(color: cs.onSurfaceVariant),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: books.length,
                  itemBuilder: (_, i) => _bookCard(books[i]),
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
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: buildBookCover(book),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.title,
                    style: TextStyle(fontWeight: FontWeight.bold, color: cs.onSurface),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    book.author,
                    style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
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