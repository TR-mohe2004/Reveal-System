import 'package:flutter/material.dart';
import 'package:reveal_app/app/data/models/cart_item_model.dart';
import 'package:reveal_app/app/data/models/product_model.dart';
import 'package:reveal_app/app/data/services/api_service.dart';

// استثناء مخصص لمنع خلط الطلبات من كليات مختلفة
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

  // حساب السعر الإجمالي الحقيقي
  double get totalAmount {
    var total = 0.0;
    _items.forEach((key, item) {
      total += item.price * item.quantity;
    });
    return total;
  }

  // عدد العناصر في السلة
  int get itemCount {
    var count = 0;
    _items.forEach((key, item) {
      count += item.quantity;
    });
    return count;
  }

  // إضافة منتج للسلة (منطق حقيقي)
  void addItem(ProductModel product) {
    // 1. التحقق من عدم الخلط بين الكليات
    if (_items.isNotEmpty && _items.values.first.collegeId != product.collegeId) {
      throw MismatchedCollegeException(
        'عذراً، لا يمكن طلب منتجات من كليات مختلفة في نفس الطلب.',
      );
    }

    // 2. إذا كان المنتج موجوداً، زد الكمية
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
      // 3. إذا كان جديداً، أضفه
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

  // إنقاص الكمية أو الحذف
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

  // حذف منتج بالكامل
  void removeItem(String productId) {
    _items.remove(productId);
    notifyListeners();
  }

  // تفريغ السلة
  void clear() {
    _items.clear();
    notifyListeners();
  }

  // إرسال الطلب للسيرفر (Checkout الحقيقي)
  Future<bool> checkout() async {
    if (_items.isEmpty) return false;
    
    // بيانات الطلب للإرسال
    final collegeId = _items.values.first.collegeId;
    final List<Map<String, dynamic>> orderItems = [];
    
    _items.forEach((key, item) {
      orderItems.add(item.toJson());
    });

    try {
      // استدعاء الـ API الحقيقي
      await _apiService.createOrder(totalAmount, orderItems, collegeId);
      clear(); // تفريغ السلة بعد النجاح
      return true;
    } catch (e) {
      rethrow; // تمرير الخطأ ليظهر للمستخدم
    }
  }
}