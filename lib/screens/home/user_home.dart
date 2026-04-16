import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../login_screen.dart';
import '../books/search_screen.dart';
import '../books/downloaded_books_screen.dart';
import '../settings_screen.dart';
import '../books/favorite_books_screen.dart';
import '../about_screen.dart';
import '../contact_screen.dart';
import '../privacy_policy_screen.dart';

class UserHome extends StatelessWidget {
  const UserHome({super.key});

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
        title: const Text("Trang người dùng"),
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            const DrawerHeader(child: Text("Menu")),

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
              title: const Text("Sách đã tải"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const DownloadedBooksScreen(),
                  ),
                );
              },
            ),

            ListTile(
              title: const Text("Sách yêu thích"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const FavoriteBooksScreen(),
                  ),
                );
              },
            ),

            ListTile(
              title: const Text("Giới thiệu"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AboutScreen(),
                  ),
                );
              },
            ),

            ListTile(
              title: const Text("Liên hệ"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ContactScreen(),
                  ),
                );
              },
            ),

            ListTile(
              title: const Text("Chính sách"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PrivacyPolicyScreen(),
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
      body: const Center(child: Text("User Home")),
    );
  }
}