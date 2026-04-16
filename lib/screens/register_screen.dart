import 'package:flutter/material.dart';
import '../services/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController(); // Thêm ô nhập lại mật khẩu

  final authProvider = AuthProvider();

  bool isLoading = false;
  bool isObscure = true;

  void register() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final confirmPass = confirmPasswordController.text.trim();

    // Kiểm tra các trường dữ liệu
    if (email.isEmpty || password.isEmpty) {
      _showMsg("Vui lòng nhập đầy đủ thông tin");
      return;
    }

    if (password != confirmPass) {
      _showMsg("Mật khẩu nhập lại không khớp");
      return;
    }

    if (password.length < 6) {
      _showMsg("Mật khẩu phải từ 6 ký tự trở lên");
      return;
    }

    setState(() => isLoading = true);

    final result = await authProvider.register(
      email,
      password,
      role: 'user',
    );

    if (mounted) setState(() => isLoading = false);

    if (result['success']) {
      _showMsg("Đăng ký thành công! Hãy đăng nhập.");
      Navigator.pop(context); // Quay lại màn hình Login
    } else {
      _showMsg(result['error'] ?? 'Đăng ký thất bại');
    }
  }

  void _showMsg(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          height: MediaQuery.of(context).size.height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              colors: [Colors.blue.shade900, Colors.blue.shade600],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 60),
              // Nút quay lại
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
              // Header
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Tạo Tài Khoản",
                        style: TextStyle(color: Colors.white, fontSize: 35, fontWeight: FontWeight.bold)),
                    SizedBox(height: 5),
                    Text("Bắt đầu hành trình đọc sách của bạn ngay hôm nay",
                        style: TextStyle(color: Colors.white70, fontSize: 16)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Form trắng
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(50),
                        topRight: Radius.circular(50)
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(30),
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        // Email
                        _buildInputBox(
                          controller: emailController,
                          hint: "Email",
                          icon: Icons.email_outlined,
                        ),
                        const SizedBox(height: 20),
                        // Password
                        _buildInputBox(
                          controller: passwordController,
                          hint: "Mật khẩu",
                          icon: Icons.lock_outline,
                          isPassword: true,
                        ),
                        const SizedBox(height: 20),
                        // Confirm Password
                        _buildInputBox(
                          controller: confirmPasswordController,
                          hint: "Nhập lại mật khẩu",
                          icon: Icons.lock_reset_outlined,
                          isPassword: true,
                        ),
                        const SizedBox(height: 40),
                        // Button
                        isLoading
                            ? const CircularProgressIndicator()
                            : SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton(
                            onPressed: register,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade800,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                              elevation: 5,
                            ),
                            child: const Text("ĐĂNG KÝ NGAY",
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text("Đã có tài khoản?"),
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text("Đăng nhập",
                                  style: TextStyle(color: Colors.blue.shade800, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  // Widget dùng chung cho Input
  Widget _buildInputBox({required TextEditingController controller, required String hint, required IconData icon, bool isPassword = false}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5)),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword ? isObscure : false,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, color: Colors.blue.shade800),
          suffixIcon: isPassword
              ? IconButton(
            icon: Icon(isObscure ? Icons.visibility_off : Icons.visibility),
            onPressed: () => setState(() => isObscure = !isObscure),
          )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(18),
        ),
      ),
    );
  }
}