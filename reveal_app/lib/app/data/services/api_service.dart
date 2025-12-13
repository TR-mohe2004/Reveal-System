import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:reveal_app/app/data/models/college_model.dart';
import 'package:reveal_app/app/data/models/product_model.dart';
import 'package:reveal_app/app/data/models/wallet_model.dart';
import 'package:reveal_app/app/data/models/order_model.dart';

class ApiService {
  // ✅ تم تحديث الرابط ليشير إلى استضافة PythonAnywhere
  // هذا الرابط يعمل للويب وللأندرويد ولكل المنصات
  static String get baseUrl {
    return "https://RevealSystem.pythonanywhere.com";
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
  Future<Map<String, dynamic>> login(String phone, String password) async {
    final url = Uri.parse('$baseUrl/api/auth/login/');
    debugPrint('🔵 [LOGIN] URL: $url');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        // إرسال phone_number بدلاً من email ليتوافق مع التعديلات
        body: json.encode({'phone_number': phone, 'password': password}),
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
      debugPrint('❌ [LOGIN ERROR]: $e');
      throw Exception('خطأ في الاتصال: $e');
    }
  }

  // إنشاء حساب جديد
  Future<Map<String, dynamic>> signup(String fullName, String phone, String password) async {
    final url = Uri.parse('$baseUrl/api/auth/signup/');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'full_name': fullName,
          'phone_number': phone,
          'password': password,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        if (data['token'] != null) {
          await saveToken(data['token']);
        }
        return data;
      } else {
        final errorBody = json.decode(utf8.decode(response.bodyBytes));
        String message = 'فشل إنشاء الحساب.';
        if (errorBody is Map) {
          if (errorBody.containsKey('username')) {
             message = 'رقم الهاتف مستخدم بالفعل.';
          } else if (errorBody.containsKey('phone_number')) {
            message = 'رقم الهاتف: ${errorBody['phone_number'][0]}';
          }
        }
        throw Exception(message);
      }
    } catch (e) {
      throw Exception('خطأ في الاتصال: $e');
    }
  }

  Future<Map<String, dynamic>> getUserProfile() async {
    final url = Uri.parse('$baseUrl/api/auth/user/');
    debugPrint('👤 [GET USER PROFILE] URL: $url');
    try {
      final headers = await _getHeaders();
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        return json.decode(utf8.decode(response.bodyBytes));
      } else {
        throw Exception('فشل في جلب بيانات المستخدم: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('خطأ في الاتصال أثناء جلب بيانات المستخدم: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // 3. البيانات (Data)
  // ---------------------------------------------------------------------------
  
  Future<List<College>> getCafes() async {
    final url = Uri.parse('$baseUrl/api/cafes/');
    debugPrint('🏫 [GET CAFES] URL: $url');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final cafeData = json.decode(utf8.decode(response.bodyBytes)) as List<dynamic>;
        return cafeData.map((json) => College.fromJson(json)).toList();
      } else {
        debugPrint('Server Error fetching cafes: ${response.statusCode}');
        throw Exception('فشل تحميل الكافيتيريات من الخادم');
      }
    } catch (e) {
      debugPrint('Error fetching cafes: $e');
      throw Exception('حدث خطأ في الشبكة أثناء جلب الكافيتيريات.');
    }
  }

  Future<List<Product>> getProducts({String? collegeId}) async {
    var urlString = '$baseUrl/api/products/';
    if (collegeId != null && collegeId.isNotEmpty) {
      urlString += '?college_id=$collegeId';
    }
    final url = Uri.parse(urlString);
    debugPrint('📦 [GET PRODUCTS] URL: $url');
    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final productData = json.decode(utf8.decode(response.bodyBytes)) as List<dynamic>;
        return productData.map((json) {
          String imagePath = json['image'] ?? '';
          // إصلاح مسار الصورة في حال كان نسبياً
          if (imagePath.isNotEmpty && !imagePath.startsWith('http')) {
             // إزالة السلاش المكرر إن وجد
            if (imagePath.startsWith('/')) {
              imagePath = imagePath.substring(1);
            }
            json['image'] = '$baseUrl/$imagePath';
          }
          return Product.fromJson(json);
        }).toList();
      } else {
        debugPrint('Server Error: ${response.statusCode}');
        throw Exception('فشل في جلب المنتجات من الخادم');
      }
    } catch (e) {
      debugPrint('Error fetching products: $e');
      throw Exception('خطأ في الاتصال بالشبكة أثناء جلب المنتجات.');
    }
  }

  Future<Wallet> getWallet() async {
    final url = Uri.parse('$baseUrl/api/wallet/');
    debugPrint('💰 [GET WALLET] URL: $url');
    try {
      final headers = await _getHeaders();
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        return Wallet.fromJson(data);
      } else {
        debugPrint('Server Error fetching wallet: ${response.statusCode}');
        throw Exception('فشل تحميل بيانات المحفظة.');
      }
    } catch (e) {
      debugPrint('Error fetching wallet: $e');
      throw Exception('حدث خطأ في الشبكة أثناء جلب محفظتك.');
    }
  }

  Future<bool> createOrder(double totalPrice, List<Map<String, dynamic>> items, String collegeId) async {
    final url = Uri.parse('$baseUrl/api/orders/create/');
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        url,
        headers: headers,
        body: json.encode({
          'total_price': totalPrice,
          'items': items,
          'college': int.tryParse(collegeId),
        }),
      );

      if (response.statusCode == 201) {
        return true;
      } else {
        final errorBody = json.decode(utf8.decode(response.bodyBytes));
        final errorMessage = errorBody['error'] ?? 'فشل في إنشاء الطلب. حاول مرة أخرى.';
        throw Exception(errorMessage);
      }
    } catch (e) {
      throw Exception('خطأ في الاتصال أثناء إنشاء الطلب: $e');
    }
  }

  Future<List<Order>> getOrders() async {
    final url = Uri.parse('$baseUrl/api/orders/list/');
    debugPrint('🥡 [GET ORDERS] URL: $url');
    try {
      final headers = await _getHeaders();
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final orderData = json.decode(utf8.decode(response.bodyBytes)) as List<dynamic>;
        return orderData.map((json) => Order.fromJson(json)).toList();
      } else {
        debugPrint('Server Error fetching orders: ${response.statusCode}');
        throw Exception('فشل تحميل الطلبات من الخادم');
      }
    } catch (e) {
      debugPrint('Error fetching orders: $e');
      throw Exception('خطأ في الشبكة أثناء جلب الطلبات.');
    }
  }

  Future<bool> linkWalletWithCode(String linkCode) async {
    final url = Uri.parse('$baseUrl/api/wallet/link/');
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        url,
        headers: headers,
        body: json.encode({'link_code': linkCode}),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception('الكود غير صحيح أو تم استخدامه من قبل.');
      }
    } catch (e) {
      throw Exception('فشل ربط المحفظة: ${e.toString()}');
    }
  }
}