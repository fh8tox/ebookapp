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

  bool _loadingLocal = true;

  @override
  void initState() {
    super.initState();
    init();
  }

  Future<void> init() async {
    _appDir = await downloader.getDir();
    await loadLocalBooks();
  }

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
        final data = jsonDecode(await File(file.path).readAsString());
        final id = data['id'];
        final epubPath = '${_appDir!.path}/$id.epub';

        if (await File(epubPath).exists()) {
          localMap[id] = data;
          downloadedIds.add(id);
        }
      } catch (_) {}
    }

    if (mounted) setState(() => _loadingLocal = false);
  }

  Book merge(Book book) {
    final local = localMap[book.id];
    if (local == null) return book;

    return Book(
      id: book.id,
      title: local['title'] ?? book.title,
      author: local['author'] ?? book.author,
      imageUrl: local['imageUrl'] ?? book.imageUrl,
      epubUrl: book.epubUrl,
      categoryId: book.categoryId,
    );
  }

  Future<void> openBook(String id) async {
    final path = '${_appDir!.path}/$id.epub';

    if (await File(path).exists()) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ReadLocalBookScreen(path: path),
        ),
      );
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("File không tồn tại")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(centerTitle: true, title: const Text("❤️ Yêu thích")),
      body: StreamBuilder<QuerySnapshot>(
        stream: service.getFavorites(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || _loadingLocal) {
            return const Center(child: CircularProgressIndicator());
          }

          final books = snapshot.data!.docs
              .map((d) => Book.fromMap(
            d.data() as Map<String, dynamic>,
            d.id,
          ))
              .toList();

          if (books.isEmpty) {
            return const Center(child: Text("Danh sách yêu thích trống"));
          }

          return RefreshIndicator(
            onRefresh: loadLocalBooks,
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: books.length,
              itemBuilder: (_, i) => BookItem(
                book: merge(books[i]),
                isDownloaded: downloadedIds.contains(books[i].id),
                downloader: downloader,
                service: service,
                appDir: _appDir!,
                onReload: loadLocalBooks,
                onOpen: openBook,
              ),
            ),
          );
        },
      ),
    );
  }
}

class BookItem extends StatefulWidget {
  final Book book;
  final bool isDownloaded;
  final DownloadService downloader;
  final FavoriteService service;
  final Directory appDir;
  final VoidCallback onReload;
  final Function(String) onOpen;

  const BookItem({
    super.key,
    required this.book,
    required this.isDownloaded,
    required this.downloader,
    required this.service,
    required this.appDir,
    required this.onReload,
    required this.onOpen,
  });

  @override
  State<BookItem> createState() => _BookItemState();
}

class _BookItemState extends State<BookItem> {
  bool isDownloading = false;
  double progress = 0;
  bool isFav = true;

  @override
  void initState() {
    super.initState();
    _initFav();
  }

  Future<void> _initFav() async {
    isFav = await widget.service.isFavorite(widget.book.id);
    if (mounted) setState(() {});
  }

  Future<void> toggleFav() async {
    if (isFav) {
      await widget.service.removeFavorite(widget.book.id);
    } else {
      await widget.service.addFavorite(widget.book);
    }
    setState(() => isFav = !isFav);
  }

  Future<void> download() async {
    if (isDownloading) return;

    setState(() {
      isDownloading = true;
      progress = 0;
    });

    final sub = widget.downloader
        .progressStream(widget.book.id)
        .listen((p) {
      if ((p - progress).abs() > 0.05) {
        setState(() => progress = p);
      }
    });

    try {
      await widget.downloader.downloadBook(widget.book);
      await sub.cancel();
      widget.onReload();
      setState(() => isDownloading = false);
    } catch (_) {
      await sub.cancel();
      setState(() => isDownloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: widget.isDownloaded ? () => widget.onOpen(widget.book.id) : null,
        leading: _cover(),
        title: Text(widget.book.title,
            maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(widget.book.author),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(isFav ? Icons.favorite : Icons.favorite_border,
                  color: isFav ? Colors.red : null),
              onPressed: toggleFav,
            ),
            if (widget.isDownloaded)
              const Icon(Icons.check_circle, color: Colors.green)
            else if (isDownloading)
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(value: progress),
              )
            else
              IconButton(
                icon: const Icon(Icons.download),
                onPressed: download,
              ),
          ],
        ),
      ),
    );
  }

  Widget _cover() {
    final file = File('${widget.appDir.path}/${widget.book.id}.jpg');
    if (file.existsSync()) {
      return Image.file(file, width: 50, fit: BoxFit.cover);
    }
    return Image.network(widget.book.imageUrl, width: 50);
  }
}
