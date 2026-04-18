import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Import Model đúng theo cấu trúc: lùi 2 cấp
import '../../models/book.dart';

import '../login_screen.dart';
import '../category/category_screen.dart';
import '../books/book_screen.dart';
import '../books/search_screen.dart';
import '../settings_screen.dart';

class AdminHome extends StatelessWidget {
  const AdminHome({super.key});

  Future<void> logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Quản trị Mind Book"),
        centerTitle: true,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.admin_panel_settings, size: 40, color: Colors.orange),
              ),
              accountName: const Text("Quản trị viên"),
              accountEmail: Text(FirebaseAuth.instance.currentUser?.email ?? "admin@mindbook.com"),
              decoration: const BoxDecoration(color: Colors.orange),
            ),
            ListTile(
              leading: const Icon(Icons.search),
              title: const Text("Tìm đọc sách"),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchScreen())),
            ),
            ListTile(
              leading: const Icon(Icons.book),
              title: const Text("Quản lý sách"),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BookScreen())),
            ),
            ListTile(
              leading: const Icon(Icons.category),
              title: const Text("Quản lý thể loại"),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CategoryScreen())),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text("Cài đặt"),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text("Đăng xuất"),
              onTap: () => logout(context),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Phần Thống kê nhanh
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                "Tổng quan hệ thống",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            _buildQuickStats(),

            // Phần danh sách sách mới cập nhật (để admin kiểm tra)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                "Sách vừa thêm gần đây",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),

            // Dùng StreamBuilder để hiển thị danh sách sách mới nhất
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('books')
                  .orderBy('createAt', descending: true) // ✅ Đã sửa từ 'timestamp' thành 'createAt'
                  .limit(5)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  // Thêm thông báo lỗi để dễ dàng debug nếu sai tên trường
                  return Center(child: Text("Lỗi: ${snapshot.error}"));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                    child: Text("Chưa có dữ liệu sách mới."),
                  );
                }

                final docs = snapshot.data!.docs;

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    // Đảm bảo hàm Book.fromMap của bạn không bị crash khi createAt là Timestamp
                    final book = Book.fromMap(data, docs[index].id);

                    return ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: (book.imageUrl != null && book.imageUrl.isNotEmpty)
                            ? Image.network(
                          book.imageUrl,
                          width: 40,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(width: 40, color: Colors.grey[300], child: const Icon(Icons.broken_image)),
                        )
                            : Container(width: 40, color: Colors.grey[300], child: const Icon(Icons.book)),
                      ),
                      title: Text(
                        book.title,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text("Tác giả: ${book.author}"),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        // Navigator sang trang chi tiết hoặc sửa sách
                      },
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // Widget hiển thị các ô thống kê (giả lập hoặc dùng Stream để đếm)
  Widget _buildQuickStats() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          // Thống kê Sách
          _buildCounterStat("books", "Sách", Colors.blue),
          const SizedBox(width: 10),

          // Thống kê Thể loại
          _buildCounterStat("categories", "Thể loại", Colors.green),
          const SizedBox(width: 10),

          // Thống kê Người dùng (Giả sử collection tên là 'users')
          _buildCounterStat("users", "Users", Colors.purple),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.5)),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildCounterStat(String collectionPath, String label, Color color) {
    return Expanded(
      child: FutureBuilder<AggregateQuerySnapshot>(
        future: FirebaseFirestore.instance.collection(collectionPath).count().get(),
        builder: (context, snapshot) {
          // Giá trị mặc định khi đang load hoặc lỗi
          String value = "...";

          if (snapshot.hasData) {
            value = snapshot.data!.count.toString();
          } else if (snapshot.hasError) {
            value = "!";
          }

          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(0.5)),
            ),
            child: Column(
              children: [
                Text(
                  value,
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: color
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

}