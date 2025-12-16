import 'package:flutter/material.dart';
import 'package:reveal_app/app/data/models/cart_item_model.dart';
import 'package:reveal_app/app/data/models/product_model.dart';
import 'package:reveal_app/app/data/services/api_service.dart';

class MismatchedCollegeException implements Exception {
  final String message;
  MismatchedCollegeException(this.message);
  @override
  String toString() => message;
}

class CartProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
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
    if (_items.isNotEmpty &&
        _items.values.first.collegeId != product.collegeId) {
      throw MismatchedCollegeException(
        'Cannot mix items from different colleges.',
      );
    }
    if (_items.containsKey(product.id)) {
      _items.update(
        product.id,
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
        product.id,
        () => CartItem(
          id: product.id,
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
    if (!_items.containsKey(productId)) return;
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
    if (_items.isEmpty) return false;
    final collegeId = _items.values.first.collegeId;
    final List<Map<String, dynamic>> orderItems = [];
    _items.forEach((key, item) {
      if (int.tryParse(item.id) != null) {
        orderItems.add({
          'product_id': int.parse(item.id),
          'quantity': item.quantity,
        });
      }
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
