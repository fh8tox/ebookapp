import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthProvider {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Hàm hỗ trợ dịch lỗi
  String _getFriendlyErrorMessage(String code) {
    switch (code) {
      case 'invalid-email': return "Email không hợp lệ.";
      case 'user-disabled': return "Tài khoản này đã bị khóa.";
      case 'user-not-found': return "Email này chưa được đăng ký.";
      case 'wrong-password': return "Sai mật khẩu, vui lòng thử lại.";
      case 'email-already-in-use': return "Email này đã được sử dụng.";
      case 'weak-password': return "Mật khẩu quá yếu.";
      case 'network-request-failed': return "Lỗi kết nối mạng.";
      case 'unknown': return "Lỗi bảo mật (App Check) hoặc hệ thống.";
      default: return "Lỗi không xác định: $code";
    }
  }

  // ================= ĐĂNG NHẬP =================
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = result.user;
      if (user != null) {
        String role = 'user';
        try {
          // Thêm timeout cho Firestore đề phòng App Check chặn
          final doc = await _db.collection('users').doc(user.uid).get().timeout(const Duration(seconds: 5));
          if (doc.exists) {
            role = (doc.data() as Map<String, dynamic>)['role'] ?? 'user';
          }
        } catch (e) {
          print("Lỗi lấy role Firestore: $e");
          // Vẫn cho đăng nhập nếu lấy role thất bại (mặc định user)
        }

        return {'success': true, 'user': user, 'role': role};
      }
      return {'success': false, 'error': 'Đăng nhập thất bại'};
    } on FirebaseAuthException catch (e) {
      return {'success': false, 'error': _getFriendlyErrorMessage(e.code)};
    } catch (e) {
      return {'success': false, 'error': 'Lỗi hệ thống: $e'};
    }
  }

  // ================= ĐĂNG KÝ =================
  Future<Map<String, dynamic>> register(String email, String password, {String role = 'user'}) async {
    try {
      final result = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      final user = result.user;

      if (user != null) {
        await _db.collection('users').doc(user.uid).set({
          'email': email,
          'role': role,
          'createdAt': FieldValue.serverTimestamp(),
        });
        return {'success': true, 'user': user};
      }
      return {'success': false};
    } on FirebaseAuthException catch (e) {
      return {'success': false, 'error': _getFriendlyErrorMessage(e.code)};
    } catch (e) {
      return {'success': false, 'error': 'Không thể tạo tài khoản'};
    }
  }

  Future<void> logout() async => await _auth.signOut();
  User? get currentUser => _auth.currentUser;
}