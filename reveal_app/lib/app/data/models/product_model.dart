class ProductModel {
  final String id;
  final String name;
  final double price;
  final String imageUrl; // رابط الصورة الخام من السيرفر
  final String description;
  
  // معلومات التصنيف
  final String category;
  final String categoryId;
  
  // معلومات المقهى والكلية
  final String cafeId;
  final String cafeName;    // اسم المقهى
  final String collegeId;   // معرف الكلية (مهم للسلة)
  final String collegeName; // اسم الكلية (للعرض)
  
  // الحالة والتقييم
  final bool isAvailable;
  bool isFavorite; 
  final double rating; 
  final int ratingCount;    // عدد المقيمين (إضافة جمالية)

  // خاصية مساعدة لتوحيد اسم المكان (تستخدم في الواجهة)
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
    this.cafeId = '',
    this.cafeName = '',
    this.isAvailable = true,
    this.isFavorite = false,
    this.rating = 0.0,
    this.ratingCount = 0,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    // 1. استخراج الصورة (معالجة احتمالات الأسماء المختلفة)
    final image = (json['image_url'] ?? json['image'] ?? json['imageUrl'] ?? '').toString();

    // 2. معالجة التصنيف (قد يأتي كنص أو كائن متداخل من الباك اند)
    String catName = 'عام';
    String catId = '';
    if (json['category'] is Map) {
      catName = json['category']['name']?.toString() ?? 'عام';
      catId = json['category']['id']?.toString() ?? '';
    } else {
      catName = (json['category_name'] ?? json['category'] ?? 'عام').toString();
      catId = json['category_id']?.toString() ?? '';
    }

    // 3. معالجة المقهى والكلية
    String cfName = (json['cafe_name'] ?? '').toString();
    String clgName = (json['college_name'] ?? '').toString();
    String cfId = (json['cafe_id'] ?? '').toString();
    String clgId = (json['college_id'] ?? json['college'] ?? cfId ?? '1').toString();
    
    // إذا كان المقهى يأتي ككائن متداخل
    if (json['cafe'] is Map) {
      cfName = json['cafe']['name']?.toString() ?? cfName;
      cfId = json['cafe']['id']?.toString() ?? cfId;
      // محاولة استخراج الكلية من داخل المقهى إذا وجدت
      if (json['cafe']['college'] != null) {
         // منطق إضافي حسب شكل الباك اند الخاص بك
      }
    }

    return ProductModel(
      id: json['id'].toString(),
      name: (json['name'] ?? 'منتج بدون اسم').toString(),
      price: double.tryParse(json['price'].toString()) ?? 0.0,
      imageUrl: image,
      description: (json['description'] ?? '').toString(),
      
      category: catName,
      categoryId: catId,
      
      cafeId: cfId,
      cafeName: cfName.isNotEmpty ? cfName : "مقهى الكلية",
      
      collegeId: clgId,
      collegeName: clgName.isNotEmpty ? clgName : cfName, // احتياطياً نستخدم اسم المقهى
      
      isAvailable: json['is_available'] == null
          ? true
          : json['is_available'] == true || json['is_available'].toString().toLowerCase() == 'true',
      
      isFavorite: json['is_favorite'] == true || json['is_favorite'].toString().toLowerCase() == 'true',
      rating: double.tryParse(json['rating'].toString()) ?? 4.5, // قيمة افتراضية جيدة
      ratingCount: int.tryParse(json['rating_count'].toString()) ?? 50,
    );
  }

  // ✅ الدالة الضرورية جداً لعمل الصور (تستخدم في CartProvider و HomeScreen)
  String getImageUrl() {
    // 1. إذا كانت هناك صورة حقيقية من السيرفر، نستخدمها
    if (imageUrl.isNotEmpty && imageUrl.startsWith('http')) {
      return imageUrl;
    }

    // 2. إذا لم توجد، نستخدم صورة افتراضية بناءً على التصنيف (Smart Fallback)
    String cat = category.toLowerCase();
    if (cat.contains('burg') || cat.contains('برجر')) {
      return "https://cdn-icons-png.flaticon.com/512/3075/3075977.png";
    }
    if (cat.contains('piz') || cat.contains('sand') || cat.contains('سندوتش') || cat.contains('بيتزا')) {
      return "https://cdn-icons-png.flaticon.com/512/3132/3132693.png";
    }
    if (cat.contains('drink') || cat.contains('coff') || cat.contains('مشروب') || cat.contains('قهوة')) {
      return "https://cdn-icons-png.flaticon.com/512/2405/2405597.png";
    }
    if (cat.contains('sweet') || cat.contains('cak') || cat.contains('حلى') || cat.contains('كيك')) {
      return "https://cdn-icons-png.flaticon.com/512/3081/3081967.png";
    }
    if (cat.contains('health') || cat.contains('صحي')) {
      return "https://cdn-icons-png.flaticon.com/512/2515/2515127.png";
    }

    // صورة افتراضية عامة
    return "https://cdn-icons-png.flaticon.com/512/706/706164.png";
  }
}
