import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactScreen extends StatelessWidget {
  const ContactScreen({super.key});

  ColorScheme cs(BuildContext context) =>
      Theme.of(context).colorScheme;

  Future<void> openLink(String url) async {
    final uri = Uri.parse(url);

    if (await canLaunchUrl(uri)) {
      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = cs(context);

    return Scaffold(
      backgroundColor: color.surface,

      appBar: AppBar(
        title: const Text("Liên hệ"),
        backgroundColor: color.surface,
        elevation: 0,
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            const SizedBox(height: 20),

            Icon(
              Icons.support_agent,
              size: 80,
              color: color.primary,
            ),

            const SizedBox(height: 10),

            Text(
              "Hỗ trợ & Liên hệ",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color.onSurface,
              ),
            ),

            const SizedBox(height: 30),

            _buildButton(
              context,
              icon: Icons.email,
              title: "Gửi Email",
              subtitle: "phuochuunguyen2004@gmail.com",
              color: color.primary,
              onTap: () {
                openLink(
                  "mailto:phuochuunguyen2004@gmail.com?subject=Hỗ trợ ứng dụng",
                );
              },
            ),

            const SizedBox(height: 12),

            _buildButton(
              context,
              icon: Icons.facebook,
              title: "Facebook",
              subtitle: "Nguyễn Hữu Phước",
              color: color.primary,
              onTap: () {
                openLink("https://www.facebook.com/fuoc190604");
              },
            ),

            const SizedBox(height: 12),

            _buildButton(
              context,
              icon: Icons.language,
              title: "Website",
              subtitle: "Nguyễn Duy Nam",
              color: color.primary,
              onTap: () {
                openLink("https://www.facebook.com/ciute.duy.37");
              },
            ),

            const SizedBox(height: 12),

            _buildButton(
              context,
              icon: Icons.chat,
              title: "Zalo",
              subtitle: "Chat hỗ trợ nhanh",
              color: color.primary,
              onTap: () {
                openLink("https://zalo.me/0365592081");
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButton(
      BuildContext context, {
        required IconData icon,
        required String title,
        required String subtitle,
        required Color color,
        required VoidCallback onTap,
      }) {
    final cs = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: cs.outlineVariant.withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: cs.primaryContainer,
              child: Icon(icon, color: cs.onPrimaryContainer),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: cs.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}