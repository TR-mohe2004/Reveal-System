import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:reveal_app/app/data/models/college_model.dart';
import 'package:reveal_app/app/data/models/order_model.dart';
import 'package:reveal_app/app/data/models/product_model.dart';
import 'package:reveal_app/app/data/models/user_model.dart' as app_user;
import 'package:reveal_app/app/data/models/wallet_model.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class ApiService {
  static const String baseUrl = 'https://revealsystem.pythonanywhere.com';
  static const String _tokenKey = 'auth_token';

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

  Future<Map<String, String>> _headers({bool authRequired = false}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
      'Accept': 'application/json',
    };

    if (authRequired) {
      final token = await getToken();
      if (token == null || token.isEmpty) {
        throw ApiException('Not authenticated.', statusCode: 401);
      }
      headers['Authorization'] = 'Token $token';
    }

    return headers;
  }

  dynamic _decodeBody(http.Response response) {
    if (response.bodyBytes.isEmpty) {
      return null;
    }
    final bodyText = utf8.decode(response.bodyBytes);
    if (bodyText.isEmpty) {
      return null;
    }
    try {
      return json.decode(bodyText);
    } catch (_) {
      return bodyText;
    }
  }

  String _extractMessage(dynamic body, {String fallback = 'Request failed.'}) {
    if (body is Map) {
      for (final key in ['detail', 'error', 'message']) {
        final value = body[key];
        if (value != null && value.toString().trim().isNotEmpty) {
          return value.toString();
        }
      }
    }
    if (body is String && body.trim().isNotEmpty) {
      return body;
    }
    return fallback;
  }

  ApiException _buildException(http.Response response, dynamic body) {
    return ApiException(
      _extractMessage(body, fallback: 'Request failed (${response.statusCode}).'),
      statusCode: response.statusCode,
    );
  }

  Future<Map<String, dynamic>> login(String phoneNumber, String password) async {
    final url = Uri.parse('$baseUrl/api/login/');
    final payload = <String, dynamic>{
      'phone_number': phoneNumber.trim(),
      'password': password,
    };

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Accept': 'application/json',
        },
        body: json.encode(payload),
      );
      final data = _decodeBody(response);

      if (response.statusCode == 200) {
        if (data is Map && data['token'] != null) {
          await saveToken(data['token'].toString());
        }
        return data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{};
      }

      throw _buildException(response, data);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Network error: $e');
    }
  }

  Future<Map<String, dynamic>> signup(
    String fullName,
    String email,
    String phone,
    String password,
  ) async {
    final url = Uri.parse('$baseUrl/api/signup/');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Accept': 'application/json',
        },
        body: json.encode({
          'full_name': fullName,
          'email': email,
          'phone_number': phone,
          'password': password,
        }),
      );
      final data = _decodeBody(response);

      if (response.statusCode == 201 || response.statusCode == 200) {
        if (data is Map && data['token'] != null) {
          await saveToken(data['token'].toString());
        }
        return data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{};
      }

      throw _buildException(response, data);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Network error: $e');
    }
  }

  Future<app_user.User> getUserProfile() async {
    final url = Uri.parse('$baseUrl/api/user/');

    try {
      final response = await http.get(url, headers: await _headers(authRequired: true));
      final data = _decodeBody(response);

      if (response.statusCode == 200 && data is Map<String, dynamic>) {
        return app_user.User.fromJson(data);
      }

      throw _buildException(response, data);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Network error: $e');
    }
  }

  Future<List<CollegeModel>> getCafes() async {
    final url = Uri.parse('$baseUrl/api/cafes/');

    try {
      final response = await http.get(url, headers: await _headers());
      final data = _decodeBody(response);

      if (response.statusCode == 200 && data is List) {
        return data.map((raw) {
          final map = Map<String, dynamic>.from(raw as Map);
          final imagePath = (map['image'] ?? '').toString();
          if (imagePath.isNotEmpty && !imagePath.startsWith('http')) {
            final normalized = imagePath.startsWith('/') ? imagePath : '/$imagePath';
            map['image'] = '$baseUrl$normalized';
          }
          return CollegeModel.fromJson(map);
        }).toList();
      }

      throw _buildException(response, data);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Network error: $e');
    }
  }

  Future<List<ProductModel>> getProducts({String? cafeId}) async {
    final resolvedCafeId = (cafeId == null || cafeId.trim().isEmpty) ? '1' : cafeId;
    final url = Uri.parse('$baseUrl/api/products/').replace(
      queryParameters: {'cafe_id': resolvedCafeId},
    );

    try {
      final response = await http.get(url, headers: await _headers());
      final data = _decodeBody(response);

      if (response.statusCode == 200 && data is List) {
        return data.map((raw) {
          final map = Map<String, dynamic>.from(raw as Map);
          final imagePath = (map['image_url'] ?? map['image'] ?? '').toString();
          if (imagePath.isNotEmpty && !imagePath.startsWith('http')) {
            final normalized = imagePath.startsWith('/') ? imagePath : '/$imagePath';
            map['image_url'] = '$baseUrl$normalized';
          }
          return ProductModel.fromJson(map);
        }).toList();
      }

      throw _buildException(response, data);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Network error: $e');
    }
  }

  Future<WalletModel> getWallet() async {
    final url = Uri.parse('$baseUrl/api/wallet/');

    try {
      final response = await http.get(url, headers: await _headers(authRequired: true));
      final data = _decodeBody(response);

      if (response.statusCode == 200 && data is Map<String, dynamic>) {
        return WalletModel.fromJson(data);
      }

      throw _buildException(response, data);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Network error: $e');
    }
  }

  Future<bool> linkWalletWithCode(String linkCode) async {
    final url = Uri.parse('$baseUrl/api/wallet/link/');

    try {
      final response = await http.post(
        url,
        headers: await _headers(authRequired: true),
        body: json.encode({'link_code': linkCode}),
      );
      final data = _decodeBody(response);

      if (response.statusCode == 200) {
        return true;
      }

      throw _buildException(response, data);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Network error: $e');
    }
  }

  Future<bool> transferWallet({
    required String walletCode,
    required double amount,
    String? note,
  }) async {
    final url = Uri.parse('$baseUrl/api/wallet/transfer/');

    try {
      final response = await http.post(
        url,
        headers: await _headers(authRequired: true),
        body: json.encode({
          'wallet_code': walletCode,
          'amount': amount,
          if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
        }),
      );
      final data = _decodeBody(response);

      if (response.statusCode == 200 && data is Map && data['success'] == true) {
        return true;
      }

      throw _buildException(response, data);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Network error: $e');
    }
  }

  Future<bool> withdrawWallet({
    required double amount,
    String? note,
  }) async {
    final url = Uri.parse('$baseUrl/api/wallet/withdraw/');

    try {
      final response = await http.post(
        url,
        headers: await _headers(authRequired: true),
        body: json.encode({
          'amount': amount,
          if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
        }),
      );
      final data = _decodeBody(response);

      if (response.statusCode == 200 && data is Map && data['success'] == true) {
        return true;
      }

      throw _buildException(response, data);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Network error: $e');
    }
  }

  Future<bool> createOrder(double totalPrice, List<Map<String, dynamic>> items, String _collegeId, {String paymentMethod = 'WALLET'}) async {
    final url = Uri.parse('$baseUrl/api/orders/');

    try {
      final response = await http.post(
        url,
        headers: await _headers(authRequired: true),
        body: json.encode({
          'total_price': totalPrice,
          'items': items,
          'payment_method': paymentMethod,
        }),
      );
      final data = _decodeBody(response);

      if (response.statusCode == 201 || response.statusCode == 200) {
        return true;
      }

      throw _buildException(response, data);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Network error: $e');
    }
  }

  Future<List<OrderModel>> getOrders() async {
    final url = Uri.parse('$baseUrl/api/orders/');

    try {
      final response = await http.get(url, headers: await _headers(authRequired: true));
      final data = _decodeBody(response);

      if (response.statusCode == 200 && data is List) {
        return data.map((item) => OrderModel.fromJson(item)).toList();
      }

      throw _buildException(response, data);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Network error: $e');
    }
  }

  Future<bool> updateSecondaryPhone(String phone) async {
    final url = Uri.parse('$baseUrl/api/user/secondary-phone/');

    try {
      final response = await http.post(
        url,
        headers: await _headers(authRequired: true),
        body: json.encode({'secondary_phone': phone}),
      );
      final data = _decodeBody(response);

      if (response.statusCode == 200) {
        return true;
      }

      throw _buildException(response, data);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Network error: $e');
    }
  }

}
