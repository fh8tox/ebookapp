import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/book.dart';

class BookService {
  final db = FirebaseFirestore.instance;

  Future<void> addBook(Book book) async {
    final doc = db.collection('books').doc();

    await doc.set({
      'id': doc.id,
      'title': book.title,
      'author': book.author,
      'categoryId': book.categoryId,
      'pdfUrl': book.pdfUrl,
      'imageUrl': book.imageUrl, // ✅ thêm
    });
  }

  Future<void> deleteBook(String id) async {
    await db.collection('books').doc(id).delete();
  }

  Future<List<Book>> getBooksOnce(int limit) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('books')
        .limit(limit)
        .get();

    return snapshot.docs
        .map((doc) => Book.fromMap(doc.data(), doc.id))
        .toList();
  }
}