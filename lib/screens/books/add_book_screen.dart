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

  PlatformFile? epubFile; // Đã đổi từ pdfFile -> epubFile
  PlatformFile? imageFile;

  String? selectedCategory;
  bool loading = false;

  // ================= PICK EPUB =================
  Future<void> pickEpub() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['epub'], // Chỉ lọc file epub
      withData: true,
    );

    if (result != null) {
      setState(() {
        epubFile = result.files.first;
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
        epubFile == null ||
        imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng nhập đầy đủ và chọn file EPUB")),
      );
      return;
    }

    setState(() => loading = true);

    try {
      // Gọi hàm upload Epub
      final epubUrl = await cloudinary.uploadEpub(epubFile!);
      final imageUrl = await cloudinary.uploadImage(imageFile!);

      if (epubUrl == null || imageUrl == null) {
        throw Exception("Upload file lên Cloudinary thất bại");
      }

      final book = Book(
        id: '',
        title: titleController.text,
        author: authorController.text,
        categoryId: selectedCategory!,
        epubUrl: epubUrl, // Gán URL EPUB
        imageUrl: imageUrl,
      );

      await service.addBook(book);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Thêm sách EPUB thành công")),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi: ${e.toString()}")),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Thêm sách mới (EPUB)")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: "Tên sách", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: authorController,
              decoration: const InputDecoration(labelText: "Tác giả", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 15),

            // ===== CATEGORY DROPDOWN =====
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('categories').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const LinearProgressIndicator();

                final categories = snapshot.data!.docs;
                return DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: const InputDecoration(labelText: "Thể loại", border: OutlineInputBorder()),
                  hint: const Text("Chọn thể loại"),
                  items: categories.map((doc) {
                    return DropdownMenuItem(
                      value: doc.id,
                      child: Text(doc['name']),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => selectedCategory = value),
                );
              },
            ),
            const SizedBox(height: 20),

            // ===== IMAGE PICKER =====
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: pickImage,
                  icon: const Icon(Icons.image),
                  label: const Text("Chọn ảnh bìa"),
                ),
                const SizedBox(width: 10),
                if (imageFile != null) const Icon(Icons.check_circle, color: Colors.green),
              ],
            ),
            if (imageFile != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Image.memory(imageFile!.bytes!, height: 150),
              ),

            const SizedBox(height: 20),

            // ===== EPUB PICKER =====
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(10)
              ),
              child: Column(
                children: [
                  ElevatedButton.icon(
                    onPressed: pickEpub,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                    icon: const Icon(Icons.book, color: Colors.white),
                    label: const Text("Chọn file EPUB", style: TextStyle(color: Colors.white)),
                  ),
                  if (epubFile != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text("Đã chọn: ${epubFile!.name}",
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // ===== SUBMIT BUTTON =====
            loading
                ? const CircularProgressIndicator()
                : SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: upload,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                child: const Text("LƯU SÁCH", style: TextStyle(fontSize: 18, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}