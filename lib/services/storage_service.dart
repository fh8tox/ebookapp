import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final _storage = FirebaseStorage.instance;

  Future<String?> uploadPdf(File file, String fileName) async {
    try {
      final ref = _storage.ref().child('books/$fileName.pdf');

      await ref.putFile(file);

      final url = await ref.getDownloadURL();
      return url;
    } catch (e) {
      print("Upload error: $e");
      return null;
    }
  }
}