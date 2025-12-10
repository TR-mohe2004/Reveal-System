import 'package:flutter/material.dart';
import '../models/cart_item_model.dart';
import '../models/product_model.dart';
import '../services/api_service.dart';

class CartProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  // تخزين العناصر: المفتاح هو ID المنتج كـ String
  final Map<String, CartItem> _items = {};

  Map<String, CartItem> get items => _items;

  // حساب الإجمالي الكلي
  double get totalAmount {
    var total = 0.0;
    _items.forEach((key, item) {
      total += item.price * item.quantity;
    });
    return total;
  }

  // عدد العناصر في السلة (مجموع الكميات)
  int get itemCount {
    var count = 0;
    _items.forEach((key, item) {
      count += item.quantity;
    });
    return count;
  }

  // إضافة منتج للسلة
  void addItem(Product product) {
    if (_items.containsKey(product.id.toString())) {
      // إذا كان المنتج موجوداً، نزيد الكمية
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
      // إذا كان جديداً، نضيفه
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

  // تقليل كمية منتج واحد (أو حذفه إذا وصل للصفر)
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

  // حذف منتج بالكامل من السلة
  void removeItem(String productId) {
    _items.remove(productId);
    notifyListeners();
  }

  // تفريغ السلة
  void clear() {
    _items.clear();
    notifyListeners();
  }

  // إرسال الطلب للسيرفر (Checkout)
  Future<bool> checkout() async {
    if (_items.isEmpty) return false;

    // تجهيز قائمة المنتجات للباك اند
    // Django يتوقع: [{'product_id': 1, 'qty': 2}, ...]
    List<Map<String, dynamic>> orderItems = [];
    
    _items.forEach((key, item) {
      orderItems.add({
        'product_id': int.parse(item.id), // تحويل الـ ID لرقم لأن الباك اند يتوقع int
        'qty': item.quantity,             // لاحظ: استخدمنا 'qty' لتطابق serializer المنظومة
      });
    });

    try {
      // إرسال السعر الإجمالي وقائمة العناصر
      bool success = await _apiService.createOrder(totalAmount, orderItems);
      
      if (success) {
        clear(); // تفريغ السلة عند النجاح
        return true;
      }
      return false;
    } catch (e) {
      print("Error during checkout: $e");
      return false;
    }
  }
}