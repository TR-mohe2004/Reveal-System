import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

// --- 1. المودل الذكي (Hybrid Model) ---
class ProductModel {
  final String id;
  final String name;
  final double price;
  final bool isAvailable;
  final String category; // burger, pizza, sweet, drink
  final String cafeteriaName; // اسم الكافيتيريا
  final double rating;
  final int ratingCount;

  ProductModel({
    required this.id,
    required this.name,
    required this.price,
    required this.isAvailable,
    required this.category,
    required this.cafeteriaName,
    required this.rating,
    required this.ratingCount,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] ?? "0",
      name: json['name'] ?? "منتج",
      price: double.parse((json['price'] ?? 0).toString()),
      isAvailable: json['is_available'] ?? true,
      category: json['category'] ?? "burger",
      cafeteriaName: json['college_name'] ?? "الكافيتيريا المركزية",
      rating: double.parse((json['rating'] ?? 0.0).toString()),
      ratingCount: json['rating_count'] ?? 0,
    );
  }

  // --- دالة تحديد الصورة الثابتة (Assets Logic) ---
  // هذه الدالة تضمن أن كل منتج يحصل على صورة ثابتة من الـ 20 صورة
  String getStaticAssetImage() {
    // نستخدم آخر رقم في الـ ID أو الهاش كود لتحديد رقم الصورة من 1 إلى 5
    // مثال: لو الـ ID ينتهي بـ 3، نأخذ الصورة رقم 3
    int imageIndex = (id.hashCode % 5) + 1; 

    // هنا نضع روابط صور حقيقية (مؤقتة) لتظهر لك النتيجة فوراً
    // عند تجهيز الصور في ملف Assets، استبدل الروابط بـ: "assets/images/${category}_$imageIndex.png"
    
    switch (category.toLowerCase()) {
      case 'pizza':
      case 'sandwish': // في حال كانت التسمية في الباك اند هكذا
        // صور البيتزا/السندوتشات
        List<String> pizzas = [
          "https://cdn-icons-png.flaticon.com/512/3132/3132693.png", // 1
          "https://cdn-icons-png.flaticon.com/512/1404/1404945.png", // 2
          "https://cdn-icons-png.flaticon.com/512/3595/3595458.png", // 3
          "https://cdn-icons-png.flaticon.com/512/6978/6978255.png", // 4
          "https://cdn-icons-png.flaticon.com/512/4039/4039232.png", // 5
        ];
        return pizzas[imageIndex - 1];

      case 'sweet':
      case 'healthy':
        // صور الحلى/الصحي
        List<String> sweets = [
          "https://cdn-icons-png.flaticon.com/512/3081/3081967.png",
          "https://cdn-icons-png.flaticon.com/512/2515/2515127.png", 
          "https://cdn-icons-png.flaticon.com/512/2936/2936894.png",
          "https://cdn-icons-png.flaticon.com/512/869/869687.png",
          "https://cdn-icons-png.flaticon.com/512/3142/3142787.png",
        ];
        return sweets[imageIndex - 1];

      case 'drink':
        // صور المشروبات
        List<String> drinks = [
          "https://cdn-icons-png.flaticon.com/512/2405/2405597.png",
          "https://cdn-icons-png.flaticon.com/512/3050/3050130.png",
          "https://cdn-icons-png.flaticon.com/512/920/920580.png",
          "https://cdn-icons-png.flaticon.com/512/1149/1149810.png",
          "https://cdn-icons-png.flaticon.com/512/3081/3081162.png",
        ];
        return drinks[imageIndex - 1];

      case 'burger':
      default:
        // صور البرجر
        List<String> burgers = [
          "https://cdn-icons-png.flaticon.com/512/3075/3075977.png",
          "https://cdn-icons-png.flaticon.com/512/2921/2921822.png",
          "https://cdn-icons-png.flaticon.com/512/877/877951.png",
          "https://cdn-icons-png.flaticon.com/512/5787/5787016.png",
          "https://cdn-icons-png.flaticon.com/512/1147/1147832.png",
        ];
        return burgers[imageIndex - 1];
    }
  }
}

// --- 2. الشاشة الرئيسية ---
class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool isLoading = true;
  List<ProductModel> products = [];
  String userName = "زائر";
  String location = "طرابلس الجامعية";

  // الألوان من الصور المرفقة
  final Color tealColor = const Color(0xFF009688); 
  final Color orangeColor = const Color(0xFFFF5722); 

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    // 1. جلب بيانات المستخدم
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        userName = user.displayName ?? "يا بطل";
      });
    }

    // 2. جلب المنتجات (محاولة من السيرفر، وإذا فشل نستخدم الـ 20 صندوق)
    try {
      final url = Uri.parse('https://RevealSystem.pythonanywhere.com/api/products/');
      final response = await http.get(url).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        List data = json.decode(response.body);
        if (mounted) {
          setState(() {
            products = data.map((e) => ProductModel.fromJson(e)).toList();
            isLoading = false;
          });
        }
      } else {
        _generateStaticBoxes(); // السيرفر رد بخطأ
      }
    } catch (e) {
      debugPrint("Server Error: $e");
      _generateStaticBoxes(); // خطأ في الاتصال
    }
  }

  // دالة توليد الـ 20 صندوق (5 من كل نوع)
  void _generateStaticBoxes() {
    if (!mounted) return;
    List<ProductModel> staticList = [];

    // 5 برجر
    for(int i=1; i<=5; i++) {
      staticList.add(ProductModel(
        id: "bur_$i", name: "برجر كلاسيك $i", price: 15.0 + i, isAvailable: true, 
        category: "burger", cafeteriaName: "كافيتيريا الهندسة", rating: 4.5, ratingCount: 120 + i
      ));
    }
    // 5 بيتزا/سندوتش
    for(int i=1; i<=5; i++) {
      staticList.add(ProductModel(
        id: "piz_$i", name: "سندوتش دجاج $i", price: 12.0 + i, isAvailable: i % 2 == 0, // بعضها غير متوفر
        category: "sandwish", cafeteriaName: "كافيتيريا الاقتصاد", rating: 4.2, ratingCount: 80 + i
      ));
    }
    // 5 صحي
    for(int i=1; i<=5; i++) {
      staticList.add(ProductModel(
        id: "hel_$i", name: "سلطة فواكه $i", price: 10.0 + i, isAvailable: true, 
        category: "healthy", cafeteriaName: "كافيتيريا العلوم", rating: 4.8, ratingCount: 50 + i
      ));
    }
    // 5 مشروبات
    for(int i=1; i<=5; i++) {
      staticList.add(ProductModel(
        id: "drk_$i", name: "عصير طبيعي $i", price: 5.0 + i, isAvailable: true, 
        category: "drink", cafeteriaName: "كافيتيريا الآداب", rating: 4.0, ratingCount: 200 + i
      ));
    }

    setState(() {
      products = staticList;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      
      // الشريط العلوي المخصص (القلب والقائمة)
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "المطاعم",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        leading: IconButton(
          icon: const Icon(Icons.favorite_border, color: Colors.black, size: 28),
          onPressed: () {},
        ),
        actions: [
          Builder(builder: (context) {
            return IconButton(
              icon: const Icon(Icons.menu, color: Colors.black, size: 30),
              onPressed: () => Scaffold.of(context).openDrawer(),
            );
          }),
        ],
      ),

      drawer: const Drawer(child: Center(child: Text("القائمة الجانبية"))),

      body: isLoading 
        ? Center(child: CircularProgressIndicator(color: tealColor))
        : SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. الهيدر (الموقع والترحيب)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text("موقعك: ", style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                              Text(location, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            ],
                          ),
                        ],
                      ),
                      RichText(
                        text: TextSpan(
                          style: const TextStyle(color: Colors.black, fontSize: 14, fontFamily: 'Cairo'),
                          children: [
                            const TextSpan(text: "أهلاً وسهلاً، ", style: TextStyle(color: Colors.grey)),
                            TextSpan(text: userName, style: TextStyle(fontWeight: FontWeight.bold, color: tealColor)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 15),

                // 2. شريط البحث
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: TextField(
                      textAlign: TextAlign.right, // النص عربي يبدأ من اليمين
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: "هل تبحث عن حاجة معينة؟",
                        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                        prefixIcon: Icon(Icons.search, color: tealColor), // العدسة
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // 3. التصنيفات (الدوائر الملونة)
                SizedBox(
                  height: 90,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    children: [
                      _buildCategory("مشروبات", "https://cdn-icons-png.flaticon.com/512/2405/2405597.png", const Color(0xFFEFEBE9)), // بني فاتح
                      _buildCategory("سندوتش", "https://cdn-icons-png.flaticon.com/512/2276/2276931.png", const Color(0xFFE0F2F1)), // تركواز فاتح
                      _buildCategory("أكل صحي", "https://cdn-icons-png.flaticon.com/512/2515/2515127.png", const Color(0xFFFFF9C4)), // أصفر فاتح
                      _buildCategory("برجر", "https://cdn-icons-png.flaticon.com/512/3075/3075977.png", const Color(0xFFFFCCBC)), // برتقالي فاتح
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // 4. أزرار الفلترة
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      _buildFilterChip("فلترة", icon: Icons.keyboard_arrow_down),
                      const SizedBox(width: 8),
                      _buildFilterChip("الموقع"),
                      const SizedBox(width: 8),
                      _buildFilterChip("التقييم"),
                      const SizedBox(width: 8),
                      _buildFilterChip("الأسعار"),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // 5. عنوان القسم: المطاعم القريبة
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(" | المطاعم القريبة >", 
                        style: TextStyle(color: tealColor, fontSize: 16, fontWeight: FontWeight.bold)
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // 6. قائمة المنتجات (الكروت)
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(), // لأن الصفحة كلها تسكرول
                  itemCount: products.length,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemBuilder: (context, index) {
                    return _buildProductCard(products[index]);
                  },
                ),
                
                const SizedBox(height: 20),
              ],
            ),
          ),
    );
  }

  // --- Widgets مساعدة ---

  // عنصر التصنيف
  Widget _buildCategory(String title, String imgUrl, Color bgColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.rectangle,
              borderRadius: BorderRadius.circular(15), // مربع بحواف دائرية كما في الصورة
            ),
            child: Image.network(imgUrl, width: 40, height: 40),
          ),
          const SizedBox(height: 5),
          Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // زر الفلترة
  Widget _buildFilterChip(String label, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: tealColor),
      ),
      child: Row(
        children: [
          if (icon != null) Icon(icon, size: 18, color: Colors.black),
          if (icon != null) const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // كرت المنتج (المطعم)
  Widget _buildProductCard(ProductModel product) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5, offset: Offset(0, 3))],
      ),
      child: Column(
        children: [
          // القسم العلوي: الصورة + القلب + التقييم
          Stack(
            children: [
              // الصورة الرمادية الكبيرة
              Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                  image: DecorationImage(
                    image: NetworkImage(product.getStaticAssetImage()), // الصورة الثابتة حسب النوع
                    fit: BoxFit.cover, // لتملأ المكان
                  ),
                ),
              ),
              // أيقونة القلب
              const Positioned(
                top: 10, left: 10,
                child: CircleAvatar(
                  backgroundColor: Colors.white, radius: 14,
                  child: Icon(Icons.favorite_border, size: 18, color: Colors.black54),
                ),
              ),
              // شارة التقييم السوداء
              Positioned(
                bottom: 10, right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Text("تقييم: ${product.rating} (${product.ratingCount} مقيم)", 
                        style: const TextStyle(color: Colors.white, fontSize: 10)
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.star, color: Colors.amber, size: 10),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // القسم السفلي: النصوص والتفاصيل
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // اسم الكافيتيريا والمنطقة
                Text("${product.cafeteriaName} - المنطقة الجامعية", 
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)
                ),
                
                const SizedBox(height: 6),
                
                // السعر والتوفر
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("سعر المنتج: ${product.price} د.ل", 
                      style: const TextStyle(color: Colors.grey, fontSize: 12)
                    ),
                    // حالة التوفر (نص ملون)
                    Text(
                      product.isAvailable ? "متوفر: ${product.name}" : "غير متوفر حالياً",
                      style: TextStyle(
                        color: product.isAvailable ? Colors.black : Colors.red, 
                        fontWeight: FontWeight.bold, fontSize: 11
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}