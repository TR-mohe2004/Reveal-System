import 'package:flutter/material.dart';
import 'package:reveal_app/app/data/models/cart_item_model.dart';
import 'package:reveal_app/app/data/models/order_model.dart';
import 'package:reveal_app/app/data/models/product_model.dart';
import 'package:reveal_app/app/data/services/api_service.dart';
import 'package:reveal_app/app/core/utils/smart_image_util.dart';

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

  // إضافة منتج جديد
  void addItem(ProductModel product, {int quantity = 1, String? options}) {
    final String currentCollegeId = product.collegeId.isNotEmpty ? product.collegeId : "1";
    final String sanitizedOptions = (options ?? '').trim();
    final String itemKey = sanitizedOptions.isEmpty ? product.id : '${product.id}::$sanitizedOptions';
    
    // التحقق من الكلية
    if (_items.isNotEmpty) {
      final firstItemCollegeId = _items.values.first.collegeId;
      if (firstItemCollegeId != currentCollegeId) {
        throw MismatchedCollegeException('عذراً، لا يمكن الشراء من كليتين مختلفتين في نفس الطلب.');
      }
    }

    if (_items.containsKey(itemKey)) {
      _items.update(
        itemKey,
        (existing) => CartItem(
          id: existing.id,
          productId: existing.productId,
          name: existing.name,
          price: existing.price,
          imageUrl: existing.imageUrl,
          quantity: existing.quantity + quantity,
          collegeId: existing.collegeId,
          collegeName: existing.collegeName,
          options: existing.options,
        ),
      );
    } else {
      _items.putIfAbsent(
        itemKey,
        () => CartItem(
          id: itemKey,
          productId: product.id,
          name: product.name,
          price: product.price,
          imageUrl: product.getImageUrl(),
          quantity: quantity,
          collegeId: currentCollegeId,
          collegeName: product.cafeteriaName,
          options: sanitizedOptions,
        ),
      );
    }
    notifyListeners();
  }

  // ✅ الدالة المفقودة التي تسبب الخطأ
  void incrementItem(String productId) {
    if (_items.containsKey(productId)) {
      _items.update(
        productId,
        (existing) => CartItem(
          id: existing.id,
          productId: existing.productId,
          name: existing.name,
          price: existing.price,
          imageUrl: existing.imageUrl,
          quantity: existing.quantity + 1,
          collegeId: existing.collegeId,
          collegeName: existing.collegeName,
          options: existing.options,
        ),
      );
      notifyListeners();
    }
  }

  // إنقاص الكمية
  void removeSingleItem(String productId) {
    if (!_items.containsKey(productId)) return;
    if (_items[productId]!.quantity > 1) {
      _items.update(
        productId,
        (existing) => CartItem(
          id: existing.id,
          productId: existing.productId,
          name: existing.name,
          price: existing.price,
          imageUrl: existing.imageUrl,
          quantity: existing.quantity - 1,
          collegeId: existing.collegeId,
          collegeName: existing.collegeName,
          options: existing.options,
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

  void replaceWithOrder(OrderModel order) {
    _items.clear();
    final cafeId = order.cafeId ?? '';
    final cafeName = order.displayCafeName;

    for (final item in order.items) {
      final productId = item.productId.toString();
      final options = item.options.trim();
      final itemKey = options.isEmpty ? productId : '$productId::$options';
      final imagePath = SmartImageUtil.getImagePath(item.productName, item.productImage);

      _items[itemKey] = CartItem(
        id: itemKey,
        productId: productId,
        name: item.productName,
        price: item.price,
        imageUrl: imagePath,
        quantity: item.quantity,
        collegeId: cafeId,
        collegeName: cafeName,
        options: options,
      );
    }

    notifyListeners();
  }

  Future<bool> checkout({String paymentMethod = 'WALLET'}) async {
    if (_items.isEmpty) return false;
    
    final List<Map<String, dynamic>> orderItems = [];
    _items.forEach((key, item) {
      orderItems.add({
        'product_id': item.productId,
        'quantity': item.quantity,
        'options': item.options,
      });
    });

    final collegeId = _items.values.first.collegeId;

    try {
      await _apiService.createOrder(totalAmount, orderItems, collegeId, paymentMethod: paymentMethod);
      clear();
      return true;
    } catch (e) {
      rethrow;
    }
  }
}
