import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/book.dart';
import '../../services/book_service.dart';
import '../../services/cloudinary_service.dart';

class AddBookScreen extends StatefulWidget {
  const AddBookScreen({super.key});

  @override
  State<AddBookScreen> createState() => _AddBookScreenState();
}

class _AddBookScreenState extends State<AddBookScreen> {
  final titleController = TextEditingController();
  final authorController = TextEditingController();

  final service = BookService();
  final cloudinary = CloudinaryService();

  PlatformFile? pdfFile;
  PlatformFile? imageFile;

  String? selectedCategory;

  bool loading = false;

  // ================= PICK PDF =================
  Future<void> pickPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );

    if (result != null) {
      setState(() {
        pdfFile = result.files.first;
      });
    }
  }

  // ================= PICK IMAGE =================
  Future<void> pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );

    if (result != null) {
      setState(() {
        imageFile = result.files.first;
      });
    }
  }

  // ================= UPLOAD =================
  Future<void> upload() async {
    if (titleController.text.isEmpty ||
        authorController.text.isEmpty ||
        selectedCategory == null ||
        pdfFile == null ||
        imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Nhập đầy đủ thông tin")),
      );
      return;
    }

    setState(() => loading = true);

    try {
      // 🔥 Upload riêng từng loại
      final pdfUrl = await cloudinary.uploadPdf(pdfFile!);
      final imageUrl = await cloudinary.uploadImage(imageFile!);

      if (pdfUrl == null || imageUrl == null) {
        throw Exception("Upload thất bại");
      }

      // 🔍 Debug cực quan trọng
      print("PDF URL: $pdfUrl");
      print("IMAGE URL: $imageUrl");

      final book = Book(
        id: '',
        title: titleController.text,
        author: authorController.text,
        categoryId: selectedCategory!,
        pdfUrl: pdfUrl,
        imageUrl: imageUrl,
      );

      await service.addBook(book);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Thêm sách thành công")),
      );

      Navigator.pop(context);
    } catch (e) {
      print("FULL ERROR: $e"); // Log này sẽ cho bạn biết chính xác lỗi ở đâu
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi: ${e.toString()}")), // Hiện lỗi lên màn hình
      );
    }

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Thêm sách")),
      body: SingleChildScrollView( // 🔥 tránh tràn UI
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            // ===== TITLE =====
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: "Tên sách"),
            ),

            // ===== AUTHOR =====
            TextField(
              controller: authorController,
              decoration: const InputDecoration(labelText: "Tác giả"),
            ),

            const SizedBox(height: 10),

            // ===== CATEGORY =====
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('categories')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const CircularProgressIndicator();
                }

                final categories = snapshot.data!.docs;

                return DropdownButtonFormField<String>(
                  value: selectedCategory,
                  hint: const Text("Chọn thể loại"),
                  items: categories.map((doc) {
                    return DropdownMenuItem(
                      value: doc.id,
                      child: Text(doc['name']),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedCategory = value;
                    });
                  },
                );
              },
            ),

            const SizedBox(height: 10),

            // ===== IMAGE =====
            ElevatedButton(
              onPressed: pickImage,
              child: const Text("Chọn ảnh bìa"),
            ),

            if (imageFile != null)
              Image.memory(
                imageFile!.bytes!,
                height: 120,
              ),

            const SizedBox(height: 10),

            // ===== PDF =====
            ElevatedButton(
              onPressed: pickPdf,
              child: const Text("Chọn file PDF"),
            ),

            if (pdfFile != null)
              Text("Đã chọn: ${pdfFile!.name}"),

            const SizedBox(height: 20),

            // ===== UPLOAD =====
            loading
                ? const CircularProgressIndicator()
                : ElevatedButton(
              onPressed: upload,
              child: const Text("Thêm sách"),
            ),
          ],
        ),
      ),
    );
  }
}