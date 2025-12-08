import 'package:flutter/material.dart';
import '../models/cart_item_model.dart';
import '../models/product_model.dart';
import '../services/api_service.dart';

class CartProvider extends ChangeNotifier {
  final Map<String, CartItem> _items = {};
  Map<String, CartItem> get items => _items;
  
  double get totalAmount {
    var total = 0.0;
    _items.forEach((key, item) {
      total += item.price * item.quantity;
    });
    return total;
  }

  void addItem(Product product) {
    if (_items.containsKey(product.id)) {
      _items.update(product.id.toString(), (existing) => CartItem(
        id: existing.id,
        name: existing.name,
        price: existing.price,
        imageUrl: existing.imageUrl,
        quantity: existing.quantity + 1,
        collegeId: existing.collegeId,
        collegeName: existing.collegeName,
      ));
    } else {
      _items.putIfAbsent(product.id.toString(), () => CartItem(
        id: product.id.toString(),
        name: product.name,
        price: product.price,
        imageUrl: product.imageUrl,
        quantity: 1,
        collegeId: product.collegeId,
        collegeName: product.collegeName,
      ));
    }
    notifyListeners();
  }

  void removeItem(String id) {
    _items.remove(id);
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }

  Future<bool> checkout() async {
    final api = ApiService();
    List<Map<String, dynamic>> orderItems = [];
    _items.forEach((key, item) {
      orderItems.add({'product_id': item.id, 'quantity': item.quantity});
    });
    
    bool success = await api.createOrder(totalAmount, orderItems);
    if (success) clear();
    return success;
  }
}
