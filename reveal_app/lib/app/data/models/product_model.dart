// تأكد أن مسار CartItemModel صحيح لديك، وإذا لم يكن موجوداً احذفه مؤقتاً
// import 'package:reveal_app/app/data/models/cart_item_model.dart'; 

class ProductModel {
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
  
  // المفضلة والتقييم
  bool isFavorite; 
  final double rating; 

  ProductModel({
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
    this.isFavorite = false,
    this.rating = 0.0,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    // التعامل المرن مع الصور والأسماء المتغيرة من الباك إند
    final image = (json['image_url'] ?? json['image'] ?? json['imageUrl'] ?? '').toString();
    final collegeIdentifier = json['college']?.toString() ?? json['cafe']?.toString() ?? '';
    final cafeNameValue = (json['cafe_name'] ?? json['college_name'] ?? '').toString();

    return ProductModel(
      id: json['id'].toString(),
      name: (json['name'] ?? '').toString(),
      price: double.tryParse(json['price'].toString()) ?? 0.0,
      imageUrl: image,
      description: (json['description'] ?? '').toString(),
      
      category: (json['category_name'] ?? json['category'] ?? '').toString(),
      categoryId: json['category_id']?.toString() ?? '',
      
      cafeId: json['cafe_id']?.toString() ?? '',
      cafeName: cafeNameValue,
      collegeId: collegeIdentifier,
      collegeName: (json['college_name'] ?? json['cafe_name'] ?? '').toString(),
      
      isAvailable: json['is_available'] == null
          ? true
          : json['is_available'] == true || json['is_available'].toString().toLowerCase() == 'true',
      
      isFavorite: json['is_favorite'] == true || json['is_favorite'].toString().toLowerCase() == 'true',
      rating: double.tryParse(json['rating'].toString()) ?? 0.0,
    );
  }
}