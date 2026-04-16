import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/book.dart';

class FavoriteService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String get uid => FirebaseAuth.instance.currentUser!.uid;

  CollectionReference get _ref =>
      _db.collection('users').doc(uid).collection('favorites');

  // =========================
  // ADD FAVORITE (FIREBASE BOOK)
  // =========================
  Future<void> addFavorite(Book book) async {
    await _ref.doc(book.id).set(book.toMap());
  }

  // =========================
  // ⭐ ADD FAVORITE FROM LOCAL JSON
  // =========================
  Future<void> addFavoriteFromMap(Map<String, dynamic> book) async {
    await _ref.doc(book["id"]).set({
      "id": book["id"] ?? "",
      "title": book["title"] ?? "",
      "author": book["author"] ?? "",
      "imageUrl": book["imageUrl"] ?? "",
      "pdfUrl": book["pdfUrl"] ?? "",
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
  // STREAM FAVORITES
  // =========================
  Stream<QuerySnapshot> getFavorites() {
    return _ref.snapshots();
  }

  // =========================
  // ⭐ GET SINGLE FAVORITE DATA
  // =========================
  Future<Map<String, dynamic>?> getFavoriteData(String bookId) async {
    final doc = await _ref.doc(bookId).get();
    if (!doc.exists) return null;
    return doc.data() as Map<String, dynamic>;
  }

  Future<void> clearAllFavorites() async {
    final snapshot = await getFavorites().first;
    final batch = FirebaseFirestore.instance.batch();

    for (var doc in snapshot.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }
}