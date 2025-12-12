import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

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
    debugPrint('Checking login status. Token: $token');
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
      debugPrint('Error fetching user profile: $e');
      await logout();
      _errorMessage = 'انتهت صلاحية الجلسة، يرجى تسجيل الدخول من جديد.';
      notifyListeners();
    }
  }

  Future<bool> login(String phone, String password) async {
    _status = AuthStatus.authenticating;
    _errorMessage = null;
    notifyListeners();

    try {
      await _apiService.login(phone, password);
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

  Future<bool> signup(String fullName, String phone, String password) async {
    _status = AuthStatus.authenticating;
    _errorMessage = null;
    notifyListeners();

    try {
      await _apiService.signup(fullName, phone, password);
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

