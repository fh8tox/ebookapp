import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/book.dart';
import '../../services/download_service.dart';
import '../../services/favorite_service.dart';
import 'read_local_book_screen.dart';

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
  // LOAD LOCAL BOOKS
  // =========================
  Future<void> loadLocalBooks() async {
    if (_appDir == null) return;

    setState(() => _loadingLocal = true);

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
        final pdfPath = '${_appDir!.path}/$id.pdf';

        if (await File(pdfPath).exists()) {
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

      downloading.add(book.id);
      progressMap[book.id] = 0.0;
      setState(() {});

      final stream = downloader.progressStream(book.id);

      final sub = stream.listen((p) {
        if (!mounted) return;
        setState(() => progressMap[book.id] = p);
      });

      await downloader.downloadBook(book);

      await sub.cancel();

      downloading.remove(book.id);
      progressMap.remove(book.id);

      await loadLocalBooks();

      _snack("Tải thành công!");
    } catch (e) {
      downloading.remove(book.id);
      progressMap.remove(book.id);

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

    setState(() {});
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  // =========================
  // OPEN LOCAL BOOK
  // =========================
  Future<void> openBook(String id) async {
    final path = '${_appDir!.path}/$id.pdf';

    if (await File(path).exists()) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ReadLocalBookScreen(path: path),
        ),
      );
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
      pdfUrl: book.pdfUrl,
      categoryId: book.categoryId,
    );
  }

  // =========================
  // COVER
  // =========================
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
      child: const Icon(Icons.menu_book, color: Colors.blue),
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
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(b.author),

                    const SizedBox(height: 8),

                    Text(
                      isDownloaded
                          ? "Đã tải"
                          : (isDownloading ? "Đang tải..." : "Chưa tải"),
                      style: TextStyle(
                        color: isDownloaded ? Colors.green : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),

              Column(
                children: [
                  isDownloaded
                      ? const Icon(Icons.download_done, color: Colors.green)
                      : isDownloading
                      ? SizedBox(
                    width: 30,
                    height: 30,
                    child: CircularProgressIndicator(value: progress),
                  )
                      : IconButton(
                    icon: const Icon(Icons.download),
                    onPressed: () => download(b),
                  ),

                  StreamBuilder(
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

  // =========================
  // UI
  // =========================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("❤️ Favorite (${firebaseCache.length})"),
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: service.getFavorites(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || _loadingLocal) {
            return const Center(child: CircularProgressIndicator());
          }

          final books = snapshot.data!.docs.map((d) {
            return Book.fromMap(
              d.data() as Map<String, dynamic>,
              d.id,
            );
          }).toList();

          firebaseCache = {
            for (var b in books) b.id: b
          };

          if (books.isEmpty) {
            return const Center(
              child: Text("Chưa có sách yêu thích"),
            );
          }

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