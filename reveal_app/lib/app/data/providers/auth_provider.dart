import 'package:flutter/material.dart';
// ✅ المسارات الصحيحة
import 'package:reveal_app/app/data/models/user_model.dart';
import 'package:reveal_app/app/data/services/api_service.dart';

enum AuthStatus {
  uninitialized,
  unauthenticated,
  authenticating,
  authenticated,
}

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  AuthStatus _status = AuthStatus.uninitialized;
  User? _currentUser;
  String? _errorMessage;

  AuthStatus get status => _status;
  User? get currentUser => _currentUser;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _status == AuthStatus.authenticated;

  AuthProvider() {
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final token = await _apiService.getToken();
    if (token != null) {
      await fetchUserProfile();
    } else {
      _status = AuthStatus.unauthenticated;
      notifyListeners();
    }
  }

  Future<void> fetchUserProfile() async {
    _status = AuthStatus.authenticating;
    notifyListeners();
    try {
      // ✅ تصحيح هام: ApiService الآن ترجع كائن User جاهزاً
      // لا نحتاج لاستدعاء User.fromJson هنا
      _currentUser = await _apiService.getUserProfile();
      
      _status = AuthStatus.authenticated;
      notifyListeners();
    } catch (e) {
      // إذا فشل جلب البروفايل (مثلاً التوكن منتهي)، نسجل الخروج
      await logout();
      _errorMessage = 'انتهت صلاحية الجلسة، يرجى تسجيل الدخول مجدداً';
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    _status = AuthStatus.authenticating;
    _errorMessage = null;
    notifyListeners();

    try {
      await _apiService.login(email, password);
      // بعد تسجيل الدخول بنجاح، نجلب بيانات المستخدم
      await fetchUserProfile();
      return true;
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      // تنظيف رسالة الخطأ لتظهر بشكل جميل للمستخدم
      _errorMessage = e.toString().replaceAll('Exception:', '').trim();
      notifyListeners();
      return false;
    }
  }

  Future<bool> signup(String fullName, String email, String phone, String password) async {
    _status = AuthStatus.authenticating;
    _errorMessage = null;
    notifyListeners();

    try {
      await _apiService.signup(fullName, email, phone, password);
      // بعد التسجيل بنجاح، نجلب بيانات المستخدم
      await fetchUserProfile();
      return true;
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      _errorMessage = e.toString().replaceAll('Exception:', '').trim();
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _apiService.removeToken();
    _currentUser = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }
}