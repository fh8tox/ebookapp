import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthProvider {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Hàm hỗ trợ dịch lỗi (Bổ sung thêm các mã lỗi của Email Link)
  String _getFriendlyErrorMessage(String code) {
    switch (code) {
      case 'invalid-email': return "Email không hợp lệ.";
      case 'user-disabled': return "Tài khoản này đã bị khóa.";
      case 'user-not-found': return "Email này chưa được đăng ký.";
      case 'wrong-password': return "Sai mật khẩu, vui lòng thử lại.";
      case 'email-already-in-use': return "Email này đã được sử dụng.";
      case 'weak-password': return "Mật khẩu quá yếu.";
      case 'network-request-failed': return "Lỗi kết nối mạng.";
      case 'expired-action-code': return "Mã xác thực đã hết hạn.";
      case 'invalid-action-code': return "Mã xác thực không hợp lệ hoặc đã được sử dụng.";
      case 'unknown': return "Lỗi bảo mật (App Check) hoặc hệ thống.";
      default: return "Lỗi: $code";
    }
  }

  // ================= ĐĂNG NHẬP (TRUYỀN THỐNG) =================
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = result.user;
      if (user != null) {
        String role = await _getUserRole(user.uid);
        return {'success': true, 'user': user, 'role': role};
      }
      return {'success': false, 'error': 'Đăng nhập thất bại'};
    } on FirebaseAuthException catch (e) {
      return {'success': false, 'error': _getFriendlyErrorMessage(e.code)};
    } catch (e) {
      return {'success': false, 'error': 'Lỗi hệ thống: $e'};
    }
  }

  // ================= ĐĂNG KÝ (TRUYỀN THỐNG) =================
  Future<Map<String, dynamic>> register(String email, String password, {String role = 'user'}) async {
    try {
      final result = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      final user = result.user;

      if (user != null) {
        await _saveUserToFirestore(user.uid, email, role);
        return {'success': true, 'user': user};
      }
      return {'success': false};
    } on FirebaseAuthException catch (e) {
      return {'success': false, 'error': _getFriendlyErrorMessage(e.code)};
    } catch (e) {
      return {'success': false, 'error': 'Không thể tạo tài khoản'};
    }
  }

  // ================= GỬI LINK XÁC THỰC EMAIL (EMAIL LINK AUTH) =================
  Future<Map<String, dynamic>> sendSignInLink(String email) async {
    try {
      var acs = ActionCodeSettings(
        // URL này PHẢI được thêm vào Authorized Domains trong Firebase Console
        url: "https://your-project-id.firebaseapp.com",
        handleCodeInApp: true,
        androidPackageName: "com.example.yourapp", // Thay bằng package của bạn
        androidInstallApp: true,
        androidMinimumVersion: "12",
        iOSBundleId: "com.example.yourapp",
      );

      await _auth.sendSignInLinkToEmail(email: email, actionCodeSettings: acs);
      return {'success': true};
    } on FirebaseAuthException catch (e) {
      return {'success': false, 'error': _getFriendlyErrorMessage(e.code)};
    }
  }

  // ================= QUÊN MẬT KHẨU (RESET PASSWORD) =================
  Future<Map<String, dynamic>> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      print("✅ Đã gửi mail reset tới: $email");
      return {'success': true};
    } on FirebaseAuthException catch (e) {
      print("❌ Firebase error: ${e.code}");
      return {'success': false, 'error': _getFriendlyErrorMessage(e.code)};
    } catch (e) {
      print("❌ Unknown error: $e");
      return {'success': false, 'error': 'Không thể gửi yêu cầu đặt lại mật khẩu'};
    }
  }

  Future<Map<String, dynamic>> changePassword(
      String currentPassword, String newPassword) async {
    try {
      final user = _auth.currentUser;

      if (user == null || user.email == null) {
        return {'success': false, 'error': 'Chưa đăng nhập'};
      }

      // 🔑 Re-authenticate
      final cred = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(cred);

      // 🔁 Đổi mật khẩu
      await user.updatePassword(newPassword);

      return {'success': true};
    } on FirebaseAuthException catch (e) {
      return {'success': false, 'error': _getFriendlyErrorMessage(e.code)};
    } catch (e) {
      return {'success': false, 'error': 'Đổi mật khẩu thất bại'};
    }
  }

  // ================= CÁC HÀM HỖ TRỢ (PRIVATE) =================

  // Lấy Role từ Firestore
  Future<String> _getUserRole(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get().timeout(const Duration(seconds: 5));
      if (doc.exists) {
        return (doc.data() as Map<String, dynamic>)['role'] ?? 'user';
      }
    } catch (e) {
      print("Lỗi lấy role: $e");
    }
    return 'user';
  }

  // Lưu thông tin User mới vào Firestore
  Future<void> _saveUserToFirestore(String uid, String email, String role) async {
    await _db.collection('users').doc(uid).set({
      'email': email,
      'role': role,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> logout() async => await _auth.signOut();
  User? get currentUser => _auth.currentUser;
}