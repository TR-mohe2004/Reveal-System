import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:reveal_app/app/data/models/college_model.dart';
import 'package:reveal_app/app/data/models/order_model.dart';
import 'package:reveal_app/app/data/models/product_model.dart';
import 'package:reveal_app/app/data/models/wallet_model.dart';

class ApiService {
  static String get baseUrl => "https://RevealSystem.pythonanywhere.com";
  static const String _tokenKey = 'auth_token';

  // ---------------------------------------------------------------------------
  // Token helpers
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

  Future<Map<String, String>> _getHeaders({bool authRequired = false}) async {
    final token = await getToken();

    if (authRequired && token == null) {
      throw Exception('Authentication token is missing. Please login again.');
    }

    return {
      'Content-Type': 'application/json; charset=UTF-8',
      if (token != null) 'Authorization': 'Token $token',
    };
  }

  // ---------------------------------------------------------------------------
  // Auth
  // ---------------------------------------------------------------------------
  Future<Map<String, dynamic>> login(String emailOrPhone, String password) async {
    final url = Uri.parse('$baseUrl/api/login');
    debugPrint('[LOGIN] URL: $url');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: json.encode({
          'email': emailOrPhone,
          'phone_number': emailOrPhone,
          'password': password,
        }),
      );

      debugPrint('[LOGIN] Status: ${response.statusCode}');
      debugPrint('[LOGIN] Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        if (data['token'] != null) {
          await saveToken(data['token']);
        }
        return data;
      } else {
        throw Exception('Invalid credentials or server error.');
      }
    } catch (e) {
      throw Exception('Unable to login: $e');
    }
  }

  Future<Map<String, dynamic>> signup(String fullName, String email, String phone, String password) async {
    final url = Uri.parse('$baseUrl/api/signup');
    debugPrint('[SIGNUP] URL: $url');

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
        throw Exception(errorBody['error'] ?? 'Could not create account.');
      }
    } catch (e) {
      throw Exception('Unable to signup: $e');
    }
  }

  Future<Map<String, dynamic>> getUserProfile() async {
    final url = Uri.parse('$baseUrl/api/user');

    try {
      final headers = await _getHeaders(authRequired: true);
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        return json.decode(utf8.decode(response.bodyBytes));
      } else {
        throw Exception('Failed to load user profile.');
      }
    } catch (e) {
      throw Exception('Error while fetching profile: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Data
  // ---------------------------------------------------------------------------
  Future<List<College>> getCafes() async {
    final url = Uri.parse('$baseUrl/api/cafes');
    debugPrint('[GET CAFES] URL: $url');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final cafeData = json.decode(utf8.decode(response.bodyBytes)) as List<dynamic>;
        return cafeData.map((json) => College.fromJson(json)).toList();
      } else {
        throw Exception('Failed to fetch cafes: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error while fetching cafes: $e');
    }
  }

  Future<List<Product>> getProducts({String? collegeId}) async {
    final query = <String, String>{};
    if (collegeId != null && collegeId.isNotEmpty) {
      query['college_id'] = collegeId;
    }

    final url = Uri.parse('$baseUrl/api/products/').replace(
      queryParameters: query.isEmpty ? null : query,
    );
    debugPrint('[GET PRODUCTS] URL: $url');

    try {
      // Send the token if it exists so the backend can personalize results.
      final headers = await _getHeaders();
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final productData = json.decode(utf8.decode(response.bodyBytes)) as List<dynamic>;
        return productData.map((raw) {
          final map = Map<String, dynamic>.from(raw as Map);
          final imagePath = (map['image_url'] ?? map['image'] ?? '').toString();

          if (imagePath.isNotEmpty && !imagePath.startsWith('http')) {
            final normalized = imagePath.startsWith('/') ? imagePath.substring(1) : imagePath;
            map['image_url'] = '$baseUrl/$normalized';
          }
          return Product.fromJson(map);
        }).toList();
      } else {
        throw Exception('Failed to fetch products: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error while fetching products: $e');
    }
  }

  Future<Wallet> getWallet() async {
    final url = Uri.parse('$baseUrl/api/wallet/');
    debugPrint('[GET WALLET] URL: $url');

    try {
      final headers = await _getHeaders(authRequired: true);
      final response = await http.get(url, headers: headers);

      debugPrint('[WALLET RESPONSE ${response.statusCode}]: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        return Wallet.fromJson(data);
      } else {
        throw Exception('Failed to fetch wallet: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error while fetching wallet: $e');
    }
  }

  Future<bool> createOrder(double totalPrice, List<Map<String, dynamic>> items, String collegeId) async {
    final url = Uri.parse('$baseUrl/api/orders/create');
    try {
      final headers = await _getHeaders(authRequired: true);
      final body = json.encode({
        'total_price': totalPrice,
        'items': items,
        'cafe_id': int.tryParse(collegeId) ?? 1,
      });

      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 201 || response.statusCode == 200) {
        return true;
      } else {
        final errorBody = json.decode(utf8.decode(response.bodyBytes));
        throw Exception(errorBody['error'] ?? 'Failed to create order.');
      }
    } catch (e) {
      throw Exception('Error while creating order: $e');
    }
  }

  Future<List<Order>> getOrders() async {
    final url = Uri.parse('$baseUrl/api/orders');
    debugPrint('[GET ORDERS] URL: $url');
    try {
      final headers = await _getHeaders(authRequired: true);
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final orderData = json.decode(utf8.decode(response.bodyBytes)) as List<dynamic>;
        return orderData.map((json) => Order.fromJson(json)).toList();
      } else {
        throw Exception('Failed to fetch orders: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error while fetching orders: $e');
    }
  }

  Future<bool> linkWalletWithCode(String linkCode) async {
    final url = Uri.parse('$baseUrl/api/wallet/link');
    try {
      final headers = await _getHeaders(authRequired: true);
      final response = await http.post(
        url,
        headers: headers,
        body: json.encode({'link_code': linkCode}),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception('Unable to link wallet with the provided code.');
      }
    } catch (e) {
      throw Exception('Error while linking wallet: $e');
    }
  }
}
