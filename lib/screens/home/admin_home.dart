import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../login_screen.dart';
import '../category/category_screen.dart';
import '../books/book_screen.dart';
import '../books/search_screen.dart';
import '../settings_screen.dart';

class AdminHome extends StatelessWidget {
  const AdminHome({super.key});

  Future<void> logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Trang Admin"),
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            const DrawerHeader(child: Text("Admin Menu")),

            ListTile(
              title: const Text("Tìm đọc sách"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SearchScreen(),
                  ),
                );
              },
            ),

            ListTile(
              title: const Text("Quản lý sách"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const BookScreen(),
                  ),
                );
              },
            ),

            ListTile(
              title: const Text("Quản lý thể loại"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CategoryScreen(),
                  ),
                );
              },
            ),

            ListTile(
              title: const Text("Cài đặt"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SettingsScreen(),
                  ),
                );
              },
            ),

            const Divider(),

            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text("Đăng xuất"),
              onTap: () => logout(context),
            ),
          ],
        ),
      ),
      body: const Center(
        child: Text("Admin Dashboard"),
      ),
    );
  }
}