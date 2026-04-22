import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/theme_provider.dart';
import '../screens/change_password_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Widget buildCard(BuildContext context, {required Widget child}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
          )
        ],
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Cài đặt")),

      body: ListView(
        children: [

          const SizedBox(height: 10),

          /// 🌙 DARK MODE
          buildCard(
            context,
            child: SwitchListTile(
              title: const Text("Dark Mode"),
              subtitle: const Text("Bật / tắt giao diện tối"),
              value: themeProvider.isDark,
              onChanged: (value) {
                themeProvider.toggleTheme(value);
              },
            ),
          ),

          /// 🔒 ĐỔI MẬT KHẨU
          buildCard(
            context,
            child: ListTile(
              leading: const Icon(Icons.lock_reset),
              title: const Text("Đổi mật khẩu"),
              subtitle: const Text("Cập nhật mật khẩu tài khoản"),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ChangePasswordScreen(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}