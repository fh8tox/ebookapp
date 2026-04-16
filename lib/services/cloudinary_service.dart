import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';

class CloudinaryService {
  final String cloudName = "ds5xbbjm3";
  final String uploadPreset = "ebookapp";

  // ================= UPLOAD PDF =================
  Future<String?> uploadPdf(dynamic file) async {
    final url = Uri.parse(
        "https://api.cloudinary.com/v1_1/$cloudName/raw/upload"); // 🔥 QUAN TRỌNG

    final request = http.MultipartRequest("POST", url);
    request.fields['upload_preset'] = uploadPreset;

    if (kIsWeb) {
      if (file is PlatformFile) {
        request.files.add(http.MultipartFile.fromBytes(
          'file',
          file.bytes!,
          filename: file.name,
        ));
      }
    } else {
      if (file is File) {
        request.files.add(await http.MultipartFile.fromPath(
          'file',
          file.path,
        ));
      } else if (file is PlatformFile && file.bytes != null) {
        request.files.add(http.MultipartFile.fromBytes(
          'file',
          file.bytes!,
          filename: file.name,
        ));
      }
    }

    final response = await request.send();

    if (response.statusCode == 200) {
      final res = await http.Response.fromStream(response);
      final data = json.decode(res.body);

      print("PDF URL: ${data['secure_url']}"); // debug

      return data['secure_url']; // ✅ sẽ là raw/upload
    } else {
      print("Upload PDF failed: ${response.statusCode}");
      return null;
    }
  }

  // ================= UPLOAD IMAGE =================
  Future<String?> uploadImage(dynamic file) async {
    final url = Uri.parse(
        "https://api.cloudinary.com/v1_1/$cloudName/image/upload");

    final request = http.MultipartRequest("POST", url);
    request.fields['upload_preset'] = uploadPreset;

    if (kIsWeb) {
      if (file is PlatformFile) {
        request.files.add(http.MultipartFile.fromBytes(
          'file',
          file.bytes!,
          filename: file.name,
        ));
      }
    } else {
      if (file is File) {
        request.files.add(await http.MultipartFile.fromPath(
          'file',
          file.path,
        ));
      } else if (file is PlatformFile && file.bytes != null) {
        request.files.add(http.MultipartFile.fromBytes(
          'file',
          file.bytes!,
          filename: file.name,
        ));
      }
    }

    final response = await request.send();

    if (response.statusCode == 200) {
      final res = await http.Response.fromStream(response);
      final data = json.decode(res.body);

      print("Image URL: ${data['secure_url']}");

      return data['secure_url'];
    } else {
      print("Upload image failed: ${response.statusCode}");
      return null;
    }
  }
}