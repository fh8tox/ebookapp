import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/book.dart';
import '../../services/download_service.dart';
import '../../services/favorite_service.dart';
import 'read_local_book_screen.dart'; // Đảm bảo screen này hỗ trợ đọc EPUB

class FavoriteBooksScreen extends StatefulWidget {
  const FavoriteBooksScreen({super.key});

  @override
  State<FavoriteBooksScreen> createState() => _FavoriteBooksScreenState();
}

class _FavoriteBooksScreenState extends State<FavoriteBooksScreen> {
  final service = FavoriteService();
  final downloader = DownloadService();

  Directory? _appDir;

  final Map<String, Map<String, dynamic>> localMap = {};
  final Set<String> downloadedIds = {};

  final Map<String, double> progressMap = {};
  final Set<String> downloading = {};

  Map<String, Book> firebaseCache = {};

  bool _loadingLocal = true;

  @override
  void initState() {
    super.initState();
    init();
  }

  Future<void> init() async {
    await _initAppDir();
    await loadLocalBooks();
  }

  Future<void> _initAppDir() async {
    _appDir = await downloader.getDir();
  }

  // =========================
  // LOAD LOCAL BOOKS (EPUB)
  // =========================
  Future<void> loadLocalBooks() async {
    if (_appDir == null) return;

    setState(() => _loadingLocal = true);

    // Tìm các file .json (metadata) để lấy thông tin sách
    final files = _appDir!
        .listSync()
        .where((f) => f.path.endsWith('.json'))
        .toList();

    localMap.clear();
    downloadedIds.clear();

    for (var file in files) {
      try {
        final data = jsonDecode(await File(file.path).readAsString())
        as Map<String, dynamic>;

        final id = data['id'];
        // 🔥 KIỂM TRA FILE .epub thay vì .pdf
        final epubPath = '${_appDir!.path}/$id.epub';

        if (await File(epubPath).exists()) {
          localMap[id] = data;
          downloadedIds.add(id);
        }
      } catch (_) {}
    }

    if (mounted) setState(() => _loadingLocal = false);
  }

  // =========================
  // DOWNLOAD
  // =========================
  Future<void> download(Book book) async {
    try {
      if (_appDir == null) {
        _appDir = await downloader.getDir();
      }

      setState(() {
        downloading.add(book.id);
        progressMap[book.id] = 0.0;
      });

      final stream = downloader.progressStream(book.id);

      final sub = stream.listen((p) {
        if (!mounted) return;
        setState(() => progressMap[book.id] = p);
      });

      await downloader.downloadBook(book);

      await sub.cancel();

      setState(() {
        downloading.remove(book.id);
        progressMap.remove(book.id);
      });

      await loadLocalBooks(); // Refresh lại danh sách đã tải

      _snack("Tải sách thành công!");
    } catch (e) {
      setState(() {
        downloading.remove(book.id);
        progressMap.remove(book.id);
      });
      _snack("Tải thất bại: $e");
    }
  }

  // =========================
  // FAVORITE
  // =========================
  Future<void> toggleFavorite(Book book) async {
    final isFav = await service.isFavorite(book.id);

    if (isFav) {
      await service.removeFavorite(book.id);
    } else {
      await service.addFavorite(book);
    }
    // Không cần setState ở đây nếu dùng StreamBuilder bên dưới
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  // =========================
  // OPEN LOCAL BOOK (EPUB)
  // =========================
  Future<void> openBook(String id) async {
    final path = '${_appDir!.path}/$id.epub'; // Đổi đuôi file

    if (await File(path).exists()) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ReadLocalBookScreen(path: path), // Truyền path .epub
        ),
      );
    } else {
      _snack("File không tồn tại, vui lòng tải lại.");
    }
  }

  // =========================
  // MERGE LOCAL + FIREBASE
  // =========================
  Book merge(Book book) {
    final local = localMap[book.id];
    if (local == null) return book;

    return Book(
      id: book.id,
      title: local['title'] ?? book.title,
      author: local['author'] ?? book.author,
      imageUrl: local['imageUrl'] ?? book.imageUrl,
      epubUrl: book.epubUrl, // Đồng nhất với epubUrl
      categoryId: book.categoryId,
    );
  }

  // ... (Các hàm _cover và _placeholder giữ nguyên) ...
  Widget _cover(Book book) {
    if (book.imageUrl.isNotEmpty) {
      return Image.network(
        book.imageUrl,
        width: 70,
        height: 100,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(),
      );
    }
    return _placeholder();
  }

  Widget _placeholder() {
    return Container(
      width: 70,
      height: 100,
      color: Colors.grey[200],
      child: const Icon(Icons.book_online, color: Colors.blue),
    );
  }

  // =========================
  // CARD
  // =========================
  Widget buildBookCard(Book book) {
    final b = merge(book);

    final isDownloaded = downloadedIds.contains(b.id);
    final isDownloading = downloading.contains(b.id);
    final progress = progressMap[b.id] ?? 0.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: isDownloaded ? () => openBook(b.id) : null,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _cover(b),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      b.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(b.author, style: TextStyle(color: Colors.grey[700])),
                    const SizedBox(height: 8),
                    Text(
                      isDownloaded
                          ? "Đã lưu máy (EPUB)"
                          : (isDownloading ? "Đang tải EPUB..." : "Chưa tải về"),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isDownloaded ? Colors.green : (isDownloading ? Colors.orange : Colors.grey),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  isDownloaded
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : isDownloading
                      ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(value: progress, strokeWidth: 3),
                  )
                      : IconButton(
                    icon: const Icon(Icons.cloud_download_outlined, color: Colors.blue),
                    onPressed: () => download(b),
                  ),
                  StreamBuilder<QuerySnapshot>(
                    stream: service.getFavorites(),
                    builder: (context, snapshot) {
                      final isFav = snapshot.hasData &&
                          snapshot.data!.docs.any((d) => d.id == b.id);

                      return IconButton(
                        icon: Icon(
                          isFav ? Icons.favorite : Icons.favorite_border,
                          color: isFav ? Colors.red : null,
                        ),
                        onPressed: () => toggleFavorite(b),
                      );
                    },
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("❤️ Yêu thích (${firebaseCache.length})"),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: service.getFavorites(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting || _loadingLocal) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text("Danh sách yêu thích trống"),
            );
          }

          final books = snapshot.data!.docs.map((d) {
            return Book.fromMap(
              d.data() as Map<String, dynamic>,
              d.id,
            );
          }).toList();

          // Cập nhật cache để đếm số lượng trên AppBar
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (firebaseCache.length != books.length) {
              setState(() {
                firebaseCache = {for (var b in books) b.id: b};
              });
            }
          });

          return RefreshIndicator(
            onRefresh: loadLocalBooks,
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: books.length,
              itemBuilder: (_, i) => buildBookCard(books[i]),
            ),
          );
        },
      ),
    );
  }
}