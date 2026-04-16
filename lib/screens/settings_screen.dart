import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/theme_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Cài đặt")),

      body: ListView(
        children: [

          // 🌙 DARK MODE
          SwitchListTile(
            title: const Text("Dark Mode"),
            subtitle: const Text("Bật / tắt giao diện tối"),
            value: themeProvider.isDark,
            onChanged: (value) {
              themeProvider.toggleTheme(value);
            },
          ),

        ],
      ),
    );
  }
}