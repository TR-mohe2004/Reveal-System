import 'package:flutter/material.dart';
// ✅ تم تعديل المسارات لتكون دقيقة (Absolute Imports)
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
      final userData = await _apiService.getUserProfile();
      _currentUser = User.fromJson(userData);
      _status = AuthStatus.authenticated;
      notifyListeners();
    } catch (e) {
      await logout();
      _errorMessage = 'انتهت صلاحية الجلسة';
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    _status = AuthStatus.authenticating;
    _errorMessage = null;
    notifyListeners();

    try {
      await _apiService.login(email, password);
      await fetchUserProfile();
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

  // ✅ الدالة الآن تستقبل الإيميل وتمرره بشكل صحيح (4 متغيرات)
  Future<bool> signup(String fullName, String email, String phone, String password) async {
    _status = AuthStatus.authenticating;
    _errorMessage = null;
    notifyListeners();

    try {
      await _apiService.signup(fullName, email, phone, password);
      await fetchUserProfile();
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

  Future<void> logout() async {
    await _apiService.removeToken();
    _currentUser = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }
}