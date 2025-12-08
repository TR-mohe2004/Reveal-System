import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/user_model.dart'; // تأكد أن ملف user_model.dart موجود

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

  // Getters
  AuthStatus get status => _status;
  User? get currentUser => _currentUser;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _status == AuthStatus.authenticated;

  AuthProvider() {
    _checkLoginStatus();
  }

  // التحقق من حالة الدخول عند فتح التطبيق
  Future<void> _checkLoginStatus() async {
    final token = await _apiService.getToken();
    if (token != null) {
      _status = AuthStatus.authenticated;
      // ملاحظة: هنا يمكن مستقبلاً إضافة دالة لجلب بيانات المستخدم (Profile)
    } else {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  // دالة تسجيل الدخول
  Future<bool> login(String email, String password) async {
    _status = AuthStatus.authenticating;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = await _apiService.login(email, password);
      
      // حفظ بيانات المستخدم القادمة من الباك اند
      if (data['user'] != null) {
        _currentUser = User.fromJson(data['user']);
      }
      
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      // تنظيف رسالة الخطأ
      _errorMessage = e.toString().replaceAll('Exception:', '').trim();
      notifyListeners();
      return false;
    }
  }

  // دالة إنشاء الحساب (تم التعديل لتستقبل 3 متغيرات وتطابق ApiService)
  Future<bool> signup(String fullName, String email, String password) async {
    _status = AuthStatus.authenticating;
    _errorMessage = null;
    notifyListeners();

    try {
      // إرسال البيانات للـ API (تم تصحيح الاستدعاء)
      final data = await _apiService.signup(fullName, email, password);
      
      if (data['user'] != null) {
        _currentUser = User.fromJson(data['user']);
      }

      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      _errorMessage = e.toString().replaceAll('Exception:', '').trim();
      notifyListeners();
      return false;
    }
  }

  // تسجيل الخروج
  Future<void> logout() async {
    await _apiService.removeToken();
    _currentUser = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }
}