import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/book.dart';
import '../../services/book_service.dart';

class EditBookScreen extends StatefulWidget {
  final Book book;

  const EditBookScreen({super.key, required this.book});

  @override
  State<EditBookScreen> createState() => _EditBookScreenState();
}

class _EditBookScreenState extends State<EditBookScreen> {
  final service = BookService();

  final titleController = TextEditingController();
  final authorController = TextEditingController();

  String? selectedCategoryId;

  @override
  void initState() {
    super.initState();

    titleController.text = widget.book.title;
    authorController.text = widget.book.author;

    // ✅ tránh null + tránh value không hợp lệ
    selectedCategoryId = widget.book.categoryId.isNotEmpty
        ? widget.book.categoryId
        : null;
  }

  Future<void> updateBook() async {
    if (titleController.text.isEmpty || authorController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Nhập đầy đủ thông tin")),
      );
      return;
    }

    await service.db.collection('books').doc(widget.book.id).update({
      'title': titleController.text,
      'author': authorController.text,
      'categoryId': selectedCategoryId ?? '',
    });

    Navigator.pop(context);
  }

  @override
  void dispose() {
    titleController.dispose();
    authorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Sửa sách")),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            // ===== TÊN SÁCH =====
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: "Tên sách"),
            ),

            const SizedBox(height: 10),

            // ===== TÁC GIẢ =====
            TextField(
              controller: authorController,
              decoration: const InputDecoration(labelText: "Tác giả"),
            ),

            const SizedBox(height: 10),

            // ===== CHỌN THỂ LOẠI =====
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('categories')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const CircularProgressIndicator();
                }

                final categories = snapshot.data!.docs;

                // ✅ đảm bảo value hợp lệ
                final validIds = categories.map((e) => e.id).toList();

                if (selectedCategoryId != null &&
                    !validIds.contains(selectedCategoryId)) {
                  selectedCategoryId = null;
                }

                return DropdownButtonFormField<String>(
                  value: selectedCategoryId,

                  hint: const Text("Chọn thể loại"),

                  items: categories.map((doc) {
                    return DropdownMenuItem<String>(
                      value: doc.id,
                      child: Text(doc['name']),
                    );
                  }).toList(),

                  onChanged: (value) {
                    setState(() {
                      selectedCategoryId = value;
                    });
                  },
                );
              },
            ),

            const SizedBox(height: 20),

            // ===== NÚT LƯU =====
            ElevatedButton(
              onPressed: updateBook,
              child: const Text("Lưu thay đổi"),
            ),
          ],
        ),
      ),
    );
  }
}