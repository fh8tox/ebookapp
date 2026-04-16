import 'dart:async'; // Cần để bắt lỗi TimeoutException
import 'package:flutter/material.dart';
import '../services/auth_provider.dart';
import '../screens/home/user_home.dart';
import '../screens/home/admin_home.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final authProvider = AuthProvider();

  bool isLoading = false;
  bool isObscure = true;

  Future<void> login() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showMsg("Vui lòng nhập đầy đủ email và mật khẩu");
      return;
    }

    setState(() => isLoading = true);

    try {
      // Gọi hàm login với Timeout 10 giây
      final result = await authProvider.login(email, password)
          .timeout(const Duration(seconds: 10));

      if (!mounted) return;

      if (result['success']) {
        final String role = result['role'];
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => role == 'admin' ? const AdminHome() : const UserHome()),
        );
      } else {
        _showMsg(result['error']);
      }
    } on TimeoutException {
      _showMsg("Mạng quá yếu hoặc bị chặn bởi App Check");
    } catch (e) {
      _showMsg("Đã xảy ra lỗi không mong muốn");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _showMsg(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Giữ nguyên phần build UI đẹp mắt mà tôi đã gửi ở lần trước của bạn
    // ... (Code UI giữ nguyên)
    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          height: MediaQuery.of(context).size.height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              colors: [Colors.blue.shade900, Colors.blue.shade500],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 80),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 30),
                child: Text("Đăng Nhập",
                    style: TextStyle(color: Colors.white, fontSize: 35, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 40),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(30),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(topLeft: Radius.circular(60)),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 30),
                      _buildInput(emailController, "Email", Icons.email_outlined, false),
                      const SizedBox(height: 20),
                      _buildInput(passwordController, "Mật khẩu", Icons.lock_outline, true),
                      const SizedBox(height: 50),
                      isLoading
                          ? const CircularProgressIndicator()
                          : SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade800,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
                          ),
                          onPressed: login,
                          child: const Text("XÁC NHẬN", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () => Navigator.pushNamed(context, '/register'),
                        child: const Text("Chưa có tài khoản? Đăng ký ngay"),
                      )
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInput(TextEditingController ctrl, String hint, IconData icon, bool isPass) {
    return TextField(
      controller: ctrl,
      obscureText: isPass ? isObscure : false,
      decoration: InputDecoration(
        labelText: hint,
        prefixIcon: Icon(icon),
        suffixIcon: isPass ? IconButton(
          icon: Icon(isObscure ? Icons.visibility_off : Icons.visibility),
          onPressed: () => setState(() => isObscure = !isObscure),
        ) : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
      ),
    );
  }
}