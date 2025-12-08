// lib/app/data/models/cart_item_model.dart

/// CartItem: يمثل نموذج البيانات للمنتج عندما يكون داخل سلة المشتريات.
/// يختلف عن Product بأنه يحتوي على حقل 'quantity' (الكمية).
class CartItem {
  final String id;          // معرف المنتج
  final String name;        // اسم المنتج
  final int quantity;       // كمية هذا المنتج في السلة
  final double price;       // سعر القطعة الواحدة
  final String imageUrl;    // رابط صورة المنتج
  final String collegeId;   // معرف الكلية
  final String collegeName; // اسم الكلية

  CartItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.price,
    required this.imageUrl,
    required this.collegeId,
    required this.collegeName,
  });
}
