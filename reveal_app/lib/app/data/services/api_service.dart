import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:reveal_app/app/data/models/product_model.dart';
import 'package:reveal_app/app/data/models/wallet_model.dart'; 

class ApiService {
  // ✅✅✅ تم تحديث الـ IP للرقم الجديد الذي أرسلته ✅✅✅
  static const String _laptopIp = "192.168.122.98"; 

  // تحديد الرابط تلقائياً حسب الجهاز المستخدم
  static String get baseUrl {
    if (kIsWeb) {
      return "http://127.0.0.1:8000"; // للمتصفح
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      // للهاتف الحقيقي والمحاكي، نستخدم عنوان الشبكة الخاص باللابتوب
      return "http://$_laptopIp:8000"; 
    } else {
      return "http://127.0.0.1:8000"; // للآيفون والديسكتوب
    }
  }

  static const String _tokenKey = 'auth_token';

  // ---------------------------------------------------------------------------
  // 1. إدارة التوكن (Token Management)
  // ---------------------------------------------------------------------------

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  Future<void> removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  // دالة مساعدة لتجهيز الهيدر (Headers) مع التوكن
  Future<Map<String, String>> _getHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Token $token', 
    };
  }

  // ---------------------------------------------------------------------------
  // 2. المصادقة (Auth)
  // ---------------------------------------------------------------------------

  // تسجيل الدخول
  Future<Map<String, dynamic>> login(String email, String password) async {
    final url = Uri.parse('$baseUrl/api/auth/login/');
    print('🔵 [LOGIN] URL: $url'); // للتأكد من الرابط
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        if (data['token'] != null) {
          await saveToken(data['token']);
        }
        return data;
      } else {
        throw Exception('بيانات الدخول غير صحيحة');
      }
    } catch (e) {
      print('❌ [LOGIN ERROR]: $e');
      throw Exception('خطأ في الاتصال: $e');
    }
  }

  // إنشاء حساب جديد
  Future<Map<String, dynamic>> signup(String fullName, String email, String password) async {
    final url = Uri.parse('$baseUrl/api/auth/signup/');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email, 
          'password': password,
          'full_name': fullName,
          'phone_number': '0000000000', // رقم افتراضي
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
         final data = json.decode(utf8.decode(response.bodyBytes));
         if (data['token'] != null) {
           await saveToken(data['token']);
         }
        return data;
      } else {
        throw Exception('فشل التسجيل: ${response.body}');
      }
    } catch (e) {
      throw Exception('خطأ في الاتصال: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // 3. البيانات (Data)
  // ---------------------------------------------------------------------------

  // جلب المنتجات للصفحة الرئيسية
  Future<List<Product>> getProducts() async {
    final url = Uri.parse('$baseUrl/api/products/');
    try {
      final response = await http.get(url); 
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        return data.map((json) => Product.fromJson(json)).toList(); 
      } else {
        print("Server Error: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      print("Error fetching products: $e");
      return [];
    }
  }

  // دالة جلب المحفظة
  Future<Wallet?> getWallet() async {
    final url = Uri.parse('$baseUrl/api/wallet/');
    try {
      final headers = await _getHeaders();
      final response = await http.get(url, headers: headers);
      
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        return Wallet.fromJson(data); 
      }
      return null;
    } catch (e) {
      print("Error fetching wallet: $e");
      return null;
    }
  }

  // --- Actions ---
  Future<bool> createOrder(double totalPrice, List<Map<String, dynamic>> items) async {
    final url = Uri.parse('$baseUrl/api/orders/create/');
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        url,
        headers: headers,
        body: json.encode({
          'total_price': totalPrice,
          'items': items,
        }),
      );
      return response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }
}