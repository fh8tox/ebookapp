import 'package:flutter/material.dart';
import '../services/auth_provider.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final currentPassController = TextEditingController();
  final newPassController = TextEditingController();
  final confirmPassController = TextEditingController();

  final authProvider = AuthProvider();

  bool isLoading = false;

  bool obscureCurrent = true;
  bool obscureNew = true;
  bool obscureConfirm = true;

  void handleChangePassword() async {
    final currentPass = currentPassController.text.trim();
    final newPass = newPassController.text.trim();
    final confirmPass = confirmPassController.text.trim();

    if (currentPass.isEmpty || newPass.isEmpty || confirmPass.isEmpty) {
      _showMsg("Vui lòng nhập đầy đủ thông tin");
      return;
    }

    if (newPass != confirmPass) {
      _showMsg("Mật khẩu xác nhận không khớp");
      return;
    }

    if (newPass.length < 6) {
      _showMsg("Mật khẩu mới phải từ 6 ký tự");
      return;
    }

    setState(() => isLoading = true);

    final result = await authProvider.changePassword(currentPass, newPass);

    setState(() => isLoading = false);

    if (result['success']) {
      _showMsg("Đổi mật khẩu thành công");
      Navigator.pop(context);
    } else {
      _showMsg(result['error'] ?? "Có lỗi xảy ra");
    }
  }

  void _showMsg(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  Widget buildInput({
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback toggle,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        suffixIcon: IconButton(
          icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
          onPressed: toggle,
        ),
      ),
    );
  }

  @override
  void dispose() {
    currentPassController.dispose();
    newPassController.dispose();
    confirmPassController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Đổi mật khẩu")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            buildInput(
              controller: currentPassController,
              label: "Mật khẩu hiện tại",
              obscure: obscureCurrent,
              toggle: () =>
                  setState(() => obscureCurrent = !obscureCurrent),
            ),
            const SizedBox(height: 15),

            buildInput(
              controller: newPassController,
              label: "Mật khẩu mới",
              obscure: obscureNew,
              toggle: () => setState(() => obscureNew = !obscureNew),
            ),
            const SizedBox(height: 15),

            buildInput(
              controller: confirmPassController,
              label: "Xác nhận mật khẩu",
              obscure: obscureConfirm,
              toggle: () =>
                  setState(() => obscureConfirm = !obscureConfirm),
            ),
            const SizedBox(height: 30),

            isLoading
                ? const CircularProgressIndicator()
                : Column(
              children: [
                /// 🔵 BUTTON ĐỔI MẬT KHẨU
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(15),
                    onTap: handleChangePassword,
                    child: Ink(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.blue.shade800,
                            Colors.blue.shade500
                          ],
                        ),
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: const Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.lock_reset,
                                color: Colors.white),
                            SizedBox(width: 10),
                            Text(
                              "ĐỔI MẬT KHẨU",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 15),

                /// ⚪ BUTTON HỦY
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey.shade400),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: const Text(
                      "HỦY",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}