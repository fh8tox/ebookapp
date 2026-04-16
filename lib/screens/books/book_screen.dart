import 'package:flutter/material.dart';
import '../../models/book.dart';
import '../../services/book_service.dart';
import 'add_book_screen.dart';
import 'edit_book_screen.dart';

class BookScreen extends StatefulWidget {
  const BookScreen({super.key});

  @override
  State<BookScreen> createState() => _BookScreenState();
}

class _BookScreenState extends State<BookScreen> {
  final service = BookService();

  final ScrollController _scrollController = ScrollController();

  List<Book> books = [];
  bool isLoadingMore = false;
  bool hasMore = true;

  int limit = 10;

  @override
  void initState() {
    super.initState();
    loadBooks();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent) {
        loadMore();
      }
    });
  }

  Future<void> loadBooks() async {
    final data = await service.getBooksOnce(limit);
    setState(() {
      books = data;
      hasMore = data.length == limit;
    });
  }

  Future<void> loadMore() async {
    if (isLoadingMore || !hasMore) return;

    setState(() => isLoadingMore = true);

    final data = await service.getBooksOnce(books.length + limit);

    setState(() {
      books = data;
      hasMore = data.length >= books.length + limit;
      isLoadingMore = false;
    });
  }

  void confirmDelete(String id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Xóa sách"),
        content: const Text("Bạn có chắc muốn xóa?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Hủy"),
          ),
          ElevatedButton(
            onPressed: () async {
              await service.deleteBook(id);
              Navigator.pop(context);
              loadBooks();
            },
            child: const Text("Xóa"),
          ),
        ],
      ),
    );
  }

  void goToAddScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddBookScreen()),
    ).then((_) => loadBooks());
  }

  void goToEditScreen(Book book) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditBookScreen(book: book),
      ),
    ).then((_) => loadBooks());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Quản lý sách")),

      floatingActionButton: FloatingActionButton(
        onPressed: goToAddScreen,
        child: const Icon(Icons.add),
      ),

      body: GridView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(8),
        gridDelegate:
        const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.65,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: books.length + (isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == books.length) {
            return const Center(child: CircularProgressIndicator());
          }

          final book = books[index];

          return Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // 📷 ẢNH (KHÔNG CLICK ĐỌC NỮA)
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                    child: book.imageUrl.isNotEmpty
                        ? Image.network(
                      book.imageUrl,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                      const Icon(Icons.broken_image),
                    )
                        : const Icon(Icons.book, size: 50),
                  ),
                ),

                // 📄 INFO
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        book.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold),
                      ),
                      Text(
                        book.author,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        "Thể loại: ${book.categoryId}",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),

                // ⚙️ ACTION (CHỈ EDIT + DELETE)
                Row(
                  mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => goToEditScreen(book),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () =>
                          confirmDelete(book.id),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}