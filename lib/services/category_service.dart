import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/category.dart';

class CategoryService {
  final _db = FirebaseFirestore.instance.collection('categories');

  Future<void> addCategory(String name) async {
    await _db.add({
      'name': name,
    });
  }

  Future<void> updateCategory(String id, String name) async {
    await _db.doc(id).update({
      'name': name,
    });
  }

  Future<void> deleteCategory(String id) async {
    await _db.doc(id).delete();
  }

  Stream<List<Category>> getCategories() {
    return _db.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Category.fromMap(doc.id, doc.data());
      }).toList();
    });
  }
}