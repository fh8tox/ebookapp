import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  ColorScheme cs(BuildContext context) =>
      Theme.of(context).colorScheme;

  @override
  Widget build(BuildContext context) {
    final color = cs(context);

    return Scaffold(
      backgroundColor: color.surface,

      appBar: AppBar(
        title: const Text("Chính sách bảo mật"),
        backgroundColor: color.surface,
        elevation: 0,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            const SizedBox(height: 10),

            Center(
              child: Icon(
                Icons.privacy_tip,
                size: 70,
                color: color.primary,
              ),
            ),

            const SizedBox(height: 10),

            Center(
              child: Text(
                "Chính sách bảo mật",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color.onSurface,
                ),
              ),
            ),

            const SizedBox(height: 20),

            _box(context,
              "Giới thiệu",
              "Ứng dụng đọc sách này được phát triển phục vụ mục đích học tập "
                  "và không nhằm mục đích thương mại.",
            ),

            _box(context,
              "Thông tin thu thập",
              "Ứng dụng có thể sử dụng email đăng nhập từ Firebase. "
                  "Ngoài ra không thu thập thông tin cá nhân nhạy cảm khác.",
            ),

            _box(context,
              "Sử dụng dữ liệu",
              "Dữ liệu chỉ được dùng để lưu sách đã tải, sách yêu thích "
                  "và đồng bộ trải nghiệm người dùng.",
            ),

            _box(context,
              "Lưu trữ",
              "Một số dữ liệu được lưu trên thiết bị người dùng hoặc Firebase "
                  "để hỗ trợ tính năng ứng dụng.",
            ),

            _box(context,
              "Chia sẻ thông tin",
              "Chúng tôi không chia sẻ hoặc bán dữ liệu người dùng cho bên thứ ba.",
            ),

            _box(context,
              "Liên hệ",
              "Nếu bạn có thắc mắc, vui lòng liên hệ: "
                  "phuochuunguyen2004@gmail.com",
            ),

            const SizedBox(height: 20),

            Center(
              child: Text(
                "© Nhóm phát triển - 2026",
                style: TextStyle(color: color.onSurfaceVariant),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _box(
      BuildContext context,
      String title,
      String content,
      ) {
    final color = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
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
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: color.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              color: color.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}