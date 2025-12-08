import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:reveal_app/app/data/models/cart_item_model.dart';

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

  // --- دالة التحويل من Firestore (المترجم) ---
  factory Product.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Product(
      id: doc.id,
      name: data['name'] ?? 'اسم غير متوفر',
      price: (data['price'] is String) 
          ? double.tryParse(data['price']) ?? 0.0 
          : (data['price'] ?? 0.0).toDouble(),
      imageUrl: data['imageUrl'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? 'عام',
      collegeId: data['collegeId'] ?? '',
      collegeName: data['collegeName'] ?? '',
    );
  }

  // --- دالة التحويل من JSON (Django API) ---
  factory Product.fromJson(Map<String, dynamic> json) {
    String imagePath = json['image'] ?? json['imageUrl'] ?? '';
    // إصلاح رابط الصورة إذا كان نسبياً (يبدأ بـ /media)
    if (imagePath.isNotEmpty && !imagePath.startsWith('http')) {
      // نفترض أن ApiService.baseUrl هو العنوان الرئيسي
      // ملاحظة: هذا يتطلب أن يكون baseUrl عاماً أو مكرراً هنا، أو نستخدم منطقاً بسيطاً
      // سنستخدم قيمة ثابتة هنا مؤقتاً أو يمكن تمرير baseUrl للدالة
      // الخيار الأفضل: التعامل معه في الـ UI أو Service، ولكن للتسهيل سنضيفه هنا
      // سنفترض 10.0.2.2 للأندرويد، ولكن الأفضل أن تأتي من السيرفر كاملة
      if (imagePath.startsWith('/')) {
         imagePath = 'http://10.0.2.2:8000$imagePath'; 
      }
    }

    return Product(
      id: json['id'].toString(),
      name: json['name'] ?? 'اسم غير متوفر',
      price: double.tryParse(json['price'].toString()) ?? 0.0,
      imageUrl: imagePath,
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