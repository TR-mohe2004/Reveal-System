import 'package:flutter/material.dart';
import '../models/cart_item_model.dart';
import '../models/product_model.dart';
import '../services/api_service.dart';

/// Exception thrown when attempting to mix products from different colleges.
class MismatchedCollegeException implements Exception {
  final String message;
  MismatchedCollegeException(this.message);

  @override
  String toString() => message;
}

class CartProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  // Keyed by product ID (String)
  final Map<String, CartItem> _items = {};

  Map<String, CartItem> get items => _items;

  double get totalAmount {
    var total = 0.0;
    _items.forEach((key, item) {
      total += item.price * item.quantity;
    });
    return total;
  }

  int get itemCount {
    var count = 0;
    _items.forEach((key, item) {
      count += item.quantity;
    });
    return count;
  }

  void addItem(Product product) {
    // Prevent mixing items from different colleges
    if (_items.isNotEmpty && _items.values.first.collegeId != product.collegeId) {
      throw MismatchedCollegeException(
        'لا يمكنك إضافة منتجات من كليات مختلفة في نفس السلة. يرجى إكمال الطلب الحالي أو إفراغ السلة أولاً.',
      );
    }

    if (_items.containsKey(product.id.toString())) {
      _items.update(
        product.id.toString(),
        (existing) => CartItem(
          id: existing.id,
          name: existing.name,
          price: existing.price,
          imageUrl: existing.imageUrl,
          quantity: existing.quantity + 1,
          collegeId: existing.collegeId,
          collegeName: existing.collegeName,
        ),
      );
    } else {
      _items.putIfAbsent(
        product.id.toString(),
        () => CartItem(
          id: product.id.toString(),
          name: product.name,
          price: product.price,
          imageUrl: product.imageUrl,
          quantity: 1,
          collegeId: product.collegeId,
          collegeName: product.collegeName,
        ),
      );
    }
    notifyListeners();
  }

  void removeSingleItem(String productId) {
    if (!_items.containsKey(productId)) {
      return;
    }
    if (_items[productId]!.quantity > 1) {
      _items.update(
        productId,
        (existing) => CartItem(
          id: existing.id,
          name: existing.name,
          price: existing.price,
          imageUrl: existing.imageUrl,
          quantity: existing.quantity - 1,
          collegeId: existing.collegeId,
          collegeName: existing.collegeName,
        ),
      );
    } else {
      _items.remove(productId);
    }
    notifyListeners();
  }

  void removeItem(String productId) {
    _items.remove(productId);
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }

  Future<bool> checkout() async {
    if (_items.isEmpty) {
      return false;
    }

    final List<Map<String, dynamic>> orderItems = [];
    final collegeId = _items.values.first.collegeId;

    _items.forEach((key, item) {
      final productId = int.tryParse(item.id);
      if (productId == null) {
        throw FormatException('معرّف المنتج غير صالح: ${item.id}');
      }
      orderItems.add({
        'product_id': productId,
        'qty': item.quantity,
      });
    });

    try {
      await _apiService.createOrder(totalAmount, orderItems, collegeId);
      clear();
      return true;
    } catch (e) {
      rethrow;
    }
  }
}

