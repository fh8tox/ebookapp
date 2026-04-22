import 'package:flutter/material.dart';
import '../services/auth_provider.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final emailController = TextEditingController();
  final authProvider = AuthProvider();
  bool isLoading = false;

  void handleResetPassword() async {
    final email = emailController.text.trim();
    if (email.isEmpty) {
      _showMsg("Vui lòng nhập email");
      return;
    }

    setState(() => isLoading = true);
    final result = await authProvider.resetPassword(email);
    setState(() => isLoading = false);

    if (result['success']) {
      _showMsg("Nếu email tồn tại, link đã được gửi.");
      if (mounted) Navigator.pop(context);
    } else {
      _showMsg(result['error'] ?? "Lỗi gửi email");
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
              colors: [Colors.blue.shade900, Colors.blue.shade500],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 80),

              /// Title
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 30),
                child: Text(
                  "Quên mật khẩu",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 10),

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 30),
                child: Text(
                  "Nhập email để nhận link đặt lại mật khẩu",
                  style: TextStyle(color: Colors.white70),
                ),
              ),

              const SizedBox(height: 40),

              /// Card trắng
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(30),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                    BorderRadius.only(topLeft: Radius.circular(60)),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 30),

                      /// Input Email
                      TextField(
                        controller: emailController,
                        decoration: InputDecoration(
                          labelText: "Email",
                          prefixIcon: const Icon(Icons.email_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                      ),

                      const SizedBox(height: 40),

                      /// Button
                      isLoading
                          ? const CircularProgressIndicator()
                          : SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade800,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          onPressed: handleResetPassword,
                          child: const Text(
                            "GỬI YÊU CẦU",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                      const Spacer(),

                      /// Back to login
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Quay lại đăng nhập"),
                      ),
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
}