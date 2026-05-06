import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/book.dart';
import '../../services/download_service.dart';
import '../../services/favorite_service.dart';
import 'read_local_book_screen.dart'; // 👈 thêm import

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final downloader = DownloadService();
  final favoriteService = FavoriteService();

  Directory? _appDir;
  String keyword = "";

  final Map<String, bool> downloadCache = {};

  @override
  void initState() {
    super.initState();
    _initAppDir();
  }

  Future<void> _initAppDir() async {
    _appDir = await downloader.getDir();
    setState(() {});
  }

  String _epubPath(Book book) => '${_appDir?.path}/${book.id}.epub';
  String _imgPath(Book book) => '${_appDir?.path}/${book.id}.jpg';

  Future<void> _preloadDownloads(List<Book> books) async {
    for (var b in books) {
      if (!downloadCache.containsKey(b.id)) {
        final exists = await File(_epubPath(b)).exists();
        downloadCache[b.id] = exists;
      }
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  ColorScheme get cs => Theme.of(context).colorScheme;

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
          _buildSearchBar(),
          Expanded(child: _buildBookList()),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(12),
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
      ),
    );
  }

  Widget _buildBookList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('books')
          .orderBy('title')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final books = snapshot.data!.docs
            .map((e) => Book.fromMap(e.data() as Map<String, dynamic>, e.id))
            .where((b) =>
        b.title.toLowerCase().contains(keyword) ||
            b.author.toLowerCase().contains(keyword))
            .toList();

        _preloadDownloads(books);

        if (books.isEmpty) {
          return Center(
            child: Text(
              keyword.isEmpty
                  ? "Bắt đầu khám phá sách hay"
                  : "Không tìm thấy kết quả",
              style: TextStyle(color: cs.onSurfaceVariant),
            ),
          );
        }

        return ListView.builder(
          itemCount: books.length,
          itemBuilder: (_, i) => BookItem(
            book: books[i],
            downloader: downloader,
            favoriteService: favoriteService,
            downloaded: downloadCache[books[i].id] ?? false,
            epubPath: _epubPath(books[i]),
            imgPath: _imgPath(books[i]),
            onDownloaded: () {
              setState(() => downloadCache[books[i].id] = true);
            },
            onDeleted: () {
              setState(() => downloadCache[books[i].id] = false);
            },
          ),
        );
      },
    );
  }
}

class BookItem extends StatefulWidget {
  final Book book;
  final DownloadService downloader;
  final FavoriteService favoriteService;
  final bool downloaded;
  final String epubPath;
  final String imgPath;
  final VoidCallback onDownloaded;
  final VoidCallback onDeleted;

  const BookItem({
    super.key,
    required this.book,
    required this.downloader,
    required this.favoriteService,
    required this.downloaded,
    required this.epubPath,
    required this.imgPath,
    required this.onDownloaded,
    required this.onDeleted,
  });

  @override
  State<BookItem> createState() => _BookItemState();
}

class _BookItemState extends State<BookItem> {
  double progress = 0;
  bool isDownloading = false;
  bool isFav = false;

  @override
  void initState() {
    super.initState();
    _initFav();
  }

  Future<void> _initFav() async {
    isFav = await widget.favoriteService.isFavorite(widget.book.id);
    if (mounted) setState(() {});
  }

  Future<void> toggleFavorite() async {
    if (isFav) {
      await widget.favoriteService.removeFavorite(widget.book.id);
    } else {
      await widget.favoriteService.addFavorite(widget.book);
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
      sub.cancel();
      widget.onDownloaded();
      setState(() => isDownloading = false);
    } catch (e) {
      sub.cancel();
      setState(() => isDownloading = false);
    }
  }

  Future<void> delete() async {
    await File(widget.epubPath).delete().catchError((_) {});
    await File(widget.imgPath).delete().catchError((_) {});
    widget.onDeleted();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.all(8),
      child: ListTile(
        // 👇 FIX DUY NHẤT Ở ĐÂY
        onTap: widget.downloaded
            ? () async {
          final file = File(widget.epubPath);

          if (await file.exists()) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    ReadLocalBookScreen(path: widget.epubPath),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("File không tồn tại")),
            );
          }
        }
            : null,

        leading: _cover(),
        title: Text(widget.book.title,
            maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(widget.book.author),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(isFav ? Icons.favorite : Icons.favorite_border),
              onPressed: toggleFavorite,
            ),
            if (widget.downloaded)
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: delete,
              )
            else if (isDownloading)
              SizedBox(
                width: 40,
                height: 40,
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
    final file = File(widget.imgPath);
    if (file.existsSync()) {
      return Image.file(file, width: 50, fit: BoxFit.cover);
    }
    return Image.network(widget.book.imageUrl, width: 50);
  }
}