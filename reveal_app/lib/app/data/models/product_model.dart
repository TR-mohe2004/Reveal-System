import 'package:reveal_app/app/data/models/cart_item_model.dart';

class Product {
  final String id;
  final String name;
  final double price;
  final String imageUrl;
  final String description;
  
  // Category Info
  final String category;
  final String categoryId;
  
  // College/Cafe Info
  final String cafeId;
  final String cafeName;
  final String collegeId;
  final String collegeName;
  
  final bool isAvailable;

  // --- 🔥 حقل جديد للمفضلة (قابل للتغيير) ---
  bool isFavorite; 

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.imageUrl,
    required this.description,
    required this.category,
    required this.collegeId,
    required this.collegeName,
    this.categoryId = '',
    this.cafeId = '',
    this.cafeName = '',
    this.isAvailable = true,
    this.isFavorite = false, // القيمة الافتراضية
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    final image = (json['image_url'] ?? json['image'] ?? json['imageUrl'] ?? '').toString();
    final collegeIdentifier = json['college']?.toString() ?? json['cafe']?.toString() ?? '';
    final cafeNameValue = (json['cafe_name'] ?? json['college_name'] ?? '').toString();

    return Product(
      id: json['id'].toString(),
      name: (json['name'] ?? '').toString(),
      price: double.tryParse(json['price'].toString()) ?? 0.0,
      imageUrl: image,
      description: (json['description'] ?? '').toString(),
      category: (json['category_name'] ?? json['category'] ?? '').toString(),
      categoryId: json['category']?.toString() ?? '',
      cafeId: json['cafe']?.toString() ?? '',
      cafeName: cafeNameValue,
      collegeId: collegeIdentifier,
      collegeName: (json['college_name'] ?? json['cafe_name'] ?? '').toString(),
      
      // استقبال حالة التوفر
      isAvailable: json['is_available'] == null
          ? true
          : json['is_available'] == true || json['is_available'].toString().toLowerCase() == 'true',
      
      // استقبال حالة المفضلة من السيرفر (إن وجدت)
      isFavorite: json['is_favorite'] == true || json['is_favorite'].toString().toLowerCase() == 'true',
    );
  }

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
      cafeId: cartItem.collegeId,
      cafeName: cartItem.collegeName,
      isFavorite: false, // قيمة افتراضية عند التحويل من السلة
    );
  }
}