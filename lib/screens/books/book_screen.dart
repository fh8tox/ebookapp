import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Thêm firestore để lấy category
import '../../models/book.dart';
import '../../services/book_service.dart';
import 'add_book_screen.dart';
import 'edit_book_screen.dart';

class BookScreen extends StatefulWidget {
  const BookScreen({super.key});

  @override
  State<BookScreen> createState() => _BookScreenState();
}

class _ScrollControllerState extends State<BookScreen> {
  final service = BookService();
  final ScrollController _scrollController = ScrollController();

  List<Book> books = [];
  Map<String, String> categoryNames = {}; // Lưu trữ: { "id": "Tên thể loại" }

  bool isLoadingMore = false;
  bool hasMore = true;
  int limit = 10;

  @override
  void initState() {
    super.initState();
    initData();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent) {
        loadMore();
      }
    });
  }

  // Khởi tạo cả category và danh sách sách
  Future<void> initData() async {
    await loadCategories();
    await loadBooks();
  }

  // Lấy toàn bộ danh sách thể loại để map ID sang Name
  Future<void> loadCategories() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('categories').get();
      final Map<String, String> tempMap = {};
      for (var doc in snapshot.docs) {
        tempMap[doc.id] = doc['name'] ?? 'Không xác định';
      }
      setState(() {
        categoryNames = tempMap;
      });
    } catch (e) {
      print("Lỗi tải thể loại: $e");
    }
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Xóa", style: TextStyle(color: Colors.white)),
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
      appBar: AppBar(
        title: const Text("Quản lý sách"),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: goToAddScreen,
        child: const Icon(Icons.add),
      ),
      body: books.isEmpty && !isLoadingMore
          ? const Center(child: Text("Đang tải dữ liệu..."))
          : GridView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(10),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.62, // Tăng nhẹ để không bị tràn UI
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: books.length + (isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == books.length) {
            return const Center(child: CircularProgressIndicator());
          }

          final book = books[index];
          // Lấy tên thể loại từ map, nếu không có thì hiện ID hoặc thông báo
          final categoryName = categoryNames[book.categoryId] ?? "Đang tải...";

          return Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 📷 ẢNH
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
                      const Center(child: Icon(Icons.broken_image)),
                    )
                        : Container(
                      color: Colors.grey[200],
                      child: const Icon(Icons.book, size: 50),
                    ),
                  ),
                ),

                // 📄 THÔNG TIN
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        book.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        book.author,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      // HIỂN THỊ TÊN THỂ LOẠI
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          categoryName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.blue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ⚙️ HÀNH ĐỘNG
                const Divider(height: 1),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.orange),
                      onPressed: () => goToEditScreen(book),
                    ),
                    const SizedBox(height: 20, child: VerticalDivider()),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => confirmDelete(book.id),
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

// Giữ lại tên Class ban đầu để tránh lỗi compiler
class _BookScreenState extends _ScrollControllerState {}