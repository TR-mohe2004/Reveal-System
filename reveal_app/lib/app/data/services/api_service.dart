import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ✅ استيراد المودلز الجديدة الصحيحة
import 'package:reveal_app/app/data/models/college_model.dart';
import 'package:reveal_app/app/data/models/order_model.dart';
import 'package:reveal_app/app/data/models/product_model.dart';
import 'package:reveal_app/app/data/models/wallet_model.dart';
import 'package:reveal_app/app/data/models/user_model.dart' as app_user; // تفادي التعارض مع Firebase User

class ApiService {
  // الرابط الحقيقي للسيرفر
  static String get baseUrl => "https://RevealSystem.pythonanywhere.com";
  static const String _tokenKey = 'auth_token';

  // ---------------------------------------------------------------------------
  // 🔐 إدارة التوكن (Token Helpers)
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

  // بناء الهيدرز (Headers) تلقائياً مع التوكن
  Future<Map<String, String>> _getHeaders({bool authRequired = false, bool useFirebaseToken = false}) async {
    String? token;
    if (useFirebaseToken) {
      final user = FirebaseAuth.instance.currentUser;
      token = await user?.getIdToken();
    } else {
      token = await getToken();
    }

    if (authRequired && token == null) {
      throw Exception('جلسة العمل انتهت، يرجى تسجيل الدخول مجدداً.');
    }

    return {
      'Content-Type': 'application/json; charset=UTF-8',
      if (token != null) 'Authorization': useFirebaseToken ? 'Bearer $token' : 'Token $token',
    };
  }

  // ---------------------------------------------------------------------------
  // 👤 المصادقة (Auth)
  // ---------------------------------------------------------------------------
  Future<Map<String, dynamic>> login(String emailOrPhone, String password) async {
    final url = Uri.parse('$baseUrl/api/login/'); // تأكد من الـ Slash في النهاية إذا كان Django
    debugPrint('[LOGIN] URL: $url');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: json.encode({
          'username': emailOrPhone, // الباك إند عادة يتوقع username
          'password': password,
        }),
      );

      debugPrint('[LOGIN] Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        if (data['token'] != null) {
          await saveToken(data['token']);
        }
        return data;
      } else {
        throw Exception('بيانات الدخول غير صحيحة.');
      }
    } catch (e) {
      throw Exception('فشل تسجيل الدخول: $e');
    }
  }

  Future<Map<String, dynamic>> signup(String fullName, String email, String phone, String password) async {
    final url = Uri.parse('$baseUrl/api/signup/');
    
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: json.encode({
          'full_name': fullName,
          'email': email,
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
        throw Exception(errorBody['error'] ?? 'فشل إنشاء الحساب.');
      }
    } catch (e) {
      throw Exception('حدث خطأ أثناء التسجيل: $e');
    }
  }

  // ✅ جلب بروفايل المستخدم كـ UserModel
  Future<app_user.User> getUserProfile() async {
    final url = Uri.parse('$baseUrl/api/user/'); // أو /profile/

    try {
      final headers = await _getHeaders(authRequired: true);
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        return app_user.User.fromJson(data);
      } else {
        throw Exception('فشل تحميل بيانات المستخدم.');
      }
    } catch (e) {
      throw Exception('خطأ في جلب البروفايل: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // 📦 البيانات الأساسية (Data)
  // ---------------------------------------------------------------------------
  
  // ✅ جلب الكليات (CollegeModel)
  Future<List<CollegeModel>> getCafes() async {
    final url = Uri.parse('$baseUrl/api/colleges/'); // تأكد من الرابط الصحيح (cafes أو colleges)
    debugPrint('[GET CAFES] URL: $url');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> cafeData = json.decode(utf8.decode(response.bodyBytes));
        
        return cafeData.map((json) {
           // معالجة الصور إذا كانت ناقصة
           if (json['image'] != null && !json['image'].toString().startsWith('http')) {
             json['image'] = '$baseUrl${json['image']}';
           }
           return CollegeModel.fromJson(json);
        }).toList();

      } else {
        throw Exception('فشل جلب قائمة الكليات: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('خطأ في الاتصال: $e');
    }
  }

  // ✅ جلب المنتجات (ProductModel)
  Future<List<ProductModel>> getProducts({String? collegeId}) async {
    final query = <String, String>{};
    if (collegeId != null && collegeId.isNotEmpty) {
      query['college_id'] = collegeId;
    }

    final url = Uri.parse('$baseUrl/api/products/').replace(
      queryParameters: query.isEmpty ? null : query,
    );
    
    debugPrint('[GET PRODUCTS] URL: $url');

    try {
      final headers = await _getHeaders(); // نرسل التوكن إن وجد لتخصيص النتائج (مثل المفضلة)
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final List<dynamic> productData = json.decode(utf8.decode(response.bodyBytes));
        
        return productData.map((raw) {
          final map = Map<String, dynamic>.from(raw as Map);
          
          // 🔥 إصلاح روابط الصور القادمة من دجانغو
          final imagePath = (map['image_url'] ?? map['image'] ?? '').toString();
          if (imagePath.isNotEmpty && !imagePath.startsWith('http')) {
            final normalized = imagePath.startsWith('/') ? imagePath : '/$imagePath';
            map['image_url'] = '$baseUrl$normalized';
          }
          
          return ProductModel.fromJson(map);
        }).toList();
      } else {
        throw Exception('فشل تحميل المنتجات: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('خطأ أثناء جلب المنتجات: $e');
    }
  }

  // ✅ جلب المحفظة (WalletModel)
  Future<WalletModel> getWallet() async {
    final url = Uri.parse('$baseUrl/api/wallet/');
    debugPrint('[GET WALLET] URL: $url');

    try {
      final headers = await _getHeaders(authRequired: true, useFirebaseToken: true);
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        return WalletModel.fromJson(data);
      } else {
        throw Exception('فشل جلب المحفظة: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('خطأ في المحفظة: $e');
    }
  }

  // ✅ ربط المحفظة بالكود
  Future<bool> linkWalletWithCode(String linkCode) async {
    final url = Uri.parse('$baseUrl/api/wallet/link/');
    try {
      final headers = await _getHeaders(authRequired: true, useFirebaseToken: true);
      
      final response = await http.post(
        url,
        headers: headers,
        body: json.encode({'link_code': linkCode}),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        final body = json.decode(utf8.decode(response.bodyBytes));
        throw Exception(body['error'] ?? 'الكود غير صحيح أو مستخدم مسبقاً.');
      }
    } catch (e) {
      throw Exception('خطأ أثناء الربط: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // 🛒 الطلبات (Orders)
  // ---------------------------------------------------------------------------
  
  Future<bool> createOrder(double totalPrice, List<Map<String, dynamic>> items, String collegeId) async {
    final url = Uri.parse('$baseUrl/api/purchase/'); // أو /orders/create/
    try {
      final headers = await _getHeaders(authRequired: true, useFirebaseToken: true);
      
      final body = json.encode({
        'total_price': totalPrice,
        'items': items,
        'college_id': collegeId, // نرسل الـ ID كنص أو رقم حسب الباك إند
      });

      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 201 || response.statusCode == 200) {
        return true;
      } else {
        final errorBody = json.decode(utf8.decode(response.bodyBytes));
        throw Exception(errorBody['error'] ?? 'فشل إنشاء الطلب.');
      }
    } catch (e) {
      throw Exception('خطأ أثناء الطلب: $e');
    }
  }

  // ✅ جلب سجل الطلبات (OrderModel)
  Future<List<OrderModel>> getOrders() async {
    final url = Uri.parse('$baseUrl/api/orders/');
    
    try {
      final headers = await _getHeaders(authRequired: true);
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final List<dynamic> orderData = json.decode(utf8.decode(response.bodyBytes));
        return orderData.map((json) => OrderModel.fromJson(json)).toList();
      } else {
        throw Exception('فشل جلب الطلبات: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('خطأ في سجل الطلبات: $e');
    }
  }
}
