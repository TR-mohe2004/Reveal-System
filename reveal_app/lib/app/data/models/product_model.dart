class ProductModel {
  final String id;
  final String name;
  final double price;
  final String imageUrl;
  final String description;

  final String category;
  final String categoryId;

  final String cafeId;
  final String cafeName;
  final String collegeId;
  final String collegeName;
  final int? imageVariant;

  final bool isAvailable;
  bool isFavorite;
  final double rating;
  final int ratingCount;

  String get cafeteriaName => cafeName.isNotEmpty ? cafeName : collegeName;

  ProductModel({
    required this.id,
    required this.name,
    required this.price,
    required this.imageUrl,
    required this.description,
    required this.category,
    required this.categoryId,
    required this.collegeId,
    required this.collegeName,
    this.imageVariant,
    this.cafeId = '',
    this.cafeName = '',
    this.isAvailable = true,
    this.isFavorite = false,
    this.rating = 0.0,
    this.ratingCount = 0,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    final image = (json['image_url'] ?? json['image'] ?? json['imageUrl'] ?? '').toString();

    String catName = 'غير مصنف';
    String catId = '';
    if (json['category'] is Map) {
      catName = json['category']['name']?.toString() ?? 'غير مصنف';
      catId = json['category']['id']?.toString() ?? '';
    } else {
      catName = (json['category_name'] ?? json['category'] ?? 'غير مصنف').toString();
      catId = json['category_id']?.toString() ?? '';
    }

    String cfName = (json['cafe_name'] ?? '').toString();
    String clgName = (json['college_name'] ?? '').toString();
    String cfId = (json['cafe_id'] ?? '').toString();
    String clgId = (json['college_id'] ?? json['college'] ?? cfId ?? '1').toString();

    if (json['cafe'] is Map) {
      cfName = json['cafe']['name']?.toString() ?? cfName;
      cfId = json['cafe']['id']?.toString() ?? cfId;
    }

    return ProductModel(
      id: json['id'].toString(),
      name: (json['name'] ?? 'منتج').toString(),
      price: double.tryParse(json['price'].toString()) ?? 0.0,
      imageUrl: image,
      description: (json['description'] ?? '').toString(),
      category: catName,
      categoryId: catId,
      cafeId: cfId,
      cafeName: cfName.isNotEmpty ? cfName : 'مقهى المستخدم',
      collegeId: clgId,
      collegeName: clgName.isNotEmpty ? clgName : cfName,
      imageVariant: json['image_variant'] is int
          ? json['image_variant']
          : int.tryParse((json['image_variant'] ?? '').toString()),
      isAvailable: json['is_available'] == null
          ? true
          : json['is_available'] == true ||
              json['is_available'].toString().toLowerCase() == 'true',
      isFavorite: json['is_favorite'] == true ||
          json['is_favorite'].toString().toLowerCase() == 'true',
      rating: double.tryParse(json['rating'].toString()) ?? 4.5,
      ratingCount: int.tryParse(json['rating_count'].toString()) ?? 50,
    );
  }

  String getImageUrl() {
    if (imageUrl.isNotEmpty && imageUrl.startsWith('http')) {
      return imageUrl;
    }

    final text = '$category $name'.toLowerCase();
    if (text.contains('قهوة') || text.contains('coffee')) {
      return _pickVariant([
        'assets/images/coffee_placeholder.png',
        'assets/images/coffee_placeholder2.png',
      ]);
    }
    if (text.contains('بيتزا') || text.contains('pizza')) {
      return _pickVariant(_assetPool('assets/images/pizza', 5));
    }
    if (text.contains('برغر') || text.contains('برجر') || text.contains('burger') || text.contains('burg')) {
      return _pickVariant(_assetPool('assets/images/burger', 5));
    }
    if (text.contains('حلويات') || text.contains('حلوى') || text.contains('حلى') || text.contains('dessert') || text.contains('sweet')) {
      return _pickVariant(_assetPool('assets/images/dessert', 5));
    }
    if (text.contains('مشروب') ||
        text.contains('مشروبات') ||
        text.contains('عصير') ||
        text.contains('ماء') ||
        text.contains('مياه') ||
        text.contains('drink') ||
        text.contains('juice')) {
      return _pickVariant(_assetPool('assets/images/drink', 5));
    }

    return 'assets/images/logo.png';
  }

  List<String> _assetPool(String baseName, int count) {
    return List.generate(count, (i) => '$baseName${i + 1}.png');
  }

  String _pickVariant(List<String> items) {
    if (items.isEmpty) {
      return 'assets/images/logo.png';
    }
    final variant = imageVariant;
    if (variant != null && variant >= 0) {
      return items[variant % items.length];
    }
    return items.first;
  }
}
