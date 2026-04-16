import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';

class BookProvider {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // 📥 Upload PDF
  Future<String?> uploadPDF() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result == null) return null;

    File file = File(result.files.single.path!);

    String fileName = DateTime.now().millisecondsSinceEpoch.toString();

    final ref = _storage.ref().child('books/$fileName.pdf');

    await ref.putFile(file);

    return await ref.getDownloadURL();
  }

  // ➕ Thêm sách
  Future<void> addBook({
    required String title,
    required String author,
    required String categoryId,
    required String pdfUrl,
  }) async {
    await _db.collection('books').add({
      'title': title,
      'author': author,
      'categoryId': categoryId,
      'pdfUrl': pdfUrl,
      'createdAt': Timestamp.now(),
    });
  }

  // ❌ Xoá sách
  Future<void> deleteBook(String id) async {
    await _db.collection('books').doc(id).delete();
  }

  // 📚 Lấy danh sách
  Stream<QuerySnapshot> getBooks() {
    return _db.collection('books').snapshots();
  }
}