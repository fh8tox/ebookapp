import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  ColorScheme cs(BuildContext context) =>
      Theme.of(context).colorScheme;

  @override
  Widget build(BuildContext context) {
    final color = cs(context);

    return Scaffold(
      backgroundColor: color.surface,

      appBar: AppBar(
        title: const Text("Giới thiệu ứng dụng"),
        backgroundColor: color.surface,
        elevation: 0,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [

            const SizedBox(height: 20),

            // ICON APP
            Icon(
              Icons.menu_book,
              size: 80,
              color: color.primary,
            ),

            const SizedBox(height: 10),

            Text(
              "EBook App",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color.onSurface,
              ),
            ),

            const SizedBox(height: 5),

            Text(
              "Phiên bản 1.0.0",
              style: TextStyle(color: color.onSurfaceVariant),
            ),

            const SizedBox(height: 30),

            _buildSection(
              context,
              title: "Giới thiệu",
              content:
              "Book Reader App là ứng dụng đọc sách online và offline, "
                  "giúp người dùng tìm kiếm, tải xuống và đọc sách PDF dễ dàng "
                  "mọi lúc mọi nơi.",
            ),

            _buildSection(
              context,
              title: "Tính năng chính",
              content:
              "• Tìm kiếm sách theo tên và tác giả\n"
                  "• Tải sách về đọc offline\n"
                  "• Lưu sách yêu thích\n"
                  "• Quản lý thư viện cá nhân",
            ),

            _buildSection(
              context,
              title: "Dành cho ai?",
              content:
              "Ứng dụng phù hợp cho học sinh, sinh viên, "
                  "người yêu thích đọc sách và tài liệu PDF.",
            ),

            _buildSection(
              context,
              title: "Liên hệ",
              content:
              "Email: phuochuunguyen2004@gmail.com\n"
                  "Facebook: https://www.facebook.com/fuoc190604\n"
                  "Facebook: https://www.facebook.com/ciute.duy.37",
            ),

            const SizedBox(height: 20),

            Text(
              "© 2026 Book Reader App. All rights reserved.",
              style: TextStyle(color: color.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
      BuildContext context, {
        required String title,
        required String content,
      }) {
    final color = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.outlineVariant.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              height: 1.4,
              color: color.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}