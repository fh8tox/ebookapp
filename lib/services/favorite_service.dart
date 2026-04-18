import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/book.dart';

class FavoriteService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Lấy UID của user hiện tại
  String get uid => FirebaseAuth.instance.currentUser!.uid;

  // Đường dẫn đến collection favorites của từng user
  CollectionReference get _ref =>
      _db.collection('users').doc(uid).collection('favorites');

  // =========================
  // ADD FAVORITE (Dùng object Book)
  // =========================
  Future<void> addFavorite(Book book) async {
    // book.toMap() lúc này đã chứa 'epubUrl' theo Model mới
    await _ref.doc(book.id).set(book.toMap());
  }

  // =========================
  // ADD FAVORITE FROM LOCAL MAP
  // =========================
  Future<void> addFavoriteFromMap(Map<String, dynamic> bookData) async {
    await _ref.doc(bookData["id"]).set({
      "id": bookData["id"] ?? "",
      "title": bookData["title"] ?? "",
      "author": bookData["author"] ?? "",
      "imageUrl": bookData["imageUrl"] ?? "",
      "epubUrl": bookData["epubUrl"] ?? "", // 🔥 Sửa: pdfUrl -> epubUrl
    });
  }

  // =========================
  // REMOVE FAVORITE
  // =========================
  Future<void> removeFavorite(String bookId) async {
    await _ref.doc(bookId).delete();
  }

  // =========================
  // CHECK FAVORITE
  // =========================
  Future<bool> isFavorite(String bookId) async {
    final doc = await _ref.doc(bookId).get();
    return doc.exists;
  }

  // =========================
  // STREAM FAVORITES (Realtime)
  // =========================
  Stream<QuerySnapshot> getFavorites() {
    return _ref.snapshots();
  }

  // =========================
  // GET SINGLE FAVORITE DATA
  // =========================
  Future<Map<String, dynamic>?> getFavoriteData(String bookId) async {
    final doc = await _ref.doc(bookId).get();
    if (!doc.exists) return null;
    return doc.data() as Map<String, dynamic>;
  }

  // =========================
  // CLEAR ALL
  // =========================
  Future<void> clearAllFavorites() async {
    // Lấy snapshot hiện tại một lần duy nhất
    final snapshot = await _ref.get();
    final batch = _db.batch();

    for (var doc in snapshot.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }
}