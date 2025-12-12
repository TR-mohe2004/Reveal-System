import 'package:reveal_app/app/data/models/cart_item_model.dart'; // ✨ تم حذف استيراد cloud_firestore.dart ✨

class Product {
  final String id;
  final String name;
  final double price;
  final String imageUrl;
  final String description;
  final String category;
  final String collegeId;
  final String collegeName;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.imageUrl,
    required this.description,
    required this.category,
    required this.collegeId,
    required this.collegeName,
  });

  // --- دالة التحويل من JSON (Django API) ---
  factory Product.fromJson(Map<String, dynamic> json) {
    // ✨ تم نقل منطق معالجة رابط الصورة إلى ApiService ليبقى الموديل نظيفاً ✨
    return Product(
      id: json['id'].toString(),
      name: json['name'] ?? 'اسم غير متوفر',
      price: double.tryParse(json['price'].toString()) ?? 0.0,
      // يفترض أن رابط الصورة الآن كامل ويأتي من ApiService
      imageUrl: json['image'] ?? json['imageUrl'] ?? '',
      description: json['description'] ?? '',
      category: json['category_name'] ?? json['category']?.toString() ?? 'عام',
      collegeId: json['college']?.toString() ?? '',
      collegeName: json['college_name'] ?? '',
    );
  }

  // التحويل من CartItem (للسلة)
  factory Product.fromCartItem(CartItem cartItem) {
    return Product(
      id: cartItem.id,
      name: cartItem.name,
      price: cartItem.price,
      imageUrl: cartItem.imageUrl,
      collegeId: cartItem.collegeId,
      collegeName: cartItem.collegeName,
      category: '',
      description: '',
    );
  }
}