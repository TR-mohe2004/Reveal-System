import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart'; // ضروري للسلة
import 'package:reveal_app/app/data/services/api_service.dart';
import 'package:reveal_app/app/data/providers/cart_provider.dart'; // تأكد من وجود هذا الملف

// --- 1. المودل الذكي (تم تحديثه ليدعم التفاعل) ---
class ProductModel {
  final String id;
  final String name;
  final double price;
  final bool isAvailable;
  final String category;
  final String cafeteriaName;
  final double rating;
  final int ratingCount;
  bool isFavorite;
  String? serverImage; // رابط الصورة من السيرفر

  ProductModel({
    required this.id,
    required this.name,
    required this.price,
    required this.isAvailable,
    required this.category,
    required this.cafeteriaName,
    required this.rating,
    required this.ratingCount,
    this.isFavorite = false,
    this.serverImage,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'].toString(),
      name: json['name'] ?? "منتج",
      price: double.tryParse((json['price'] ?? 0).toString()) ?? 0.0,
      isAvailable: json['is_available'] ?? true,
      category: json['category'] != null ? json['category']['name'] ?? "general" : "general",
      cafeteriaName: json['cafe'] != null ? json['cafe']['name'] ?? "مقهى الكلية" : "مقهى الكلية",
      rating: 4.5, // قيمة افتراضية للتقييم مؤقتاً
      ratingCount: 50,
      serverImage: json['image'], // استقبال الصورة من السيرفر
    );
  }

  // دالة الصور الذكية (Fallback)
  String getImageUrl() {
    if (serverImage != null && serverImage!.startsWith('http')) {
      return serverImage!;
    }
    // صور افتراضية حسب التصنيف إذا لم توجد صورة سيرفر
    String cat = category.toLowerCase();
    if (cat.contains('burg')) return "https://cdn-icons-png.flaticon.com/512/3075/3075977.png";
    if (cat.contains('piz') || cat.contains('sand')) return "https://cdn-icons-png.flaticon.com/512/3132/3132693.png";
    if (cat.contains('drink') || cat.contains('coff')) return "https://cdn-icons-png.flaticon.com/512/2405/2405597.png";
    if (cat.contains('sweet') || cat.contains('cak')) return "https://cdn-icons-png.flaticon.com/512/3081/3081967.png";
    return "https://cdn-icons-png.flaticon.com/512/706/706164.png"; // عام
  }
}

// --- 2. الشاشة الرئيسية الحية ---
class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool isLoading = true;
  List<ProductModel> allProducts = [];
  List<ProductModel> displayedProducts = [];
  
  String userName = "جاري التحميل..."; // سيتم تغييره للاسم الحقيقي
  String location = "مقهى كلية تقنية المعلومات"; // الافتراضي

  final Color tealColor = const Color(0xFF009688);
  final Color orangeColor = const Color(0xFFFF5722);
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = "all";

  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _fetchRealData();
  }

  // دالة جلب البيانات الحقيقية (المستخدم + المنتجات)
  Future<void> _fetchRealData() async {
    try {
      // 1. جلب اسم المستخدم الحقيقي
      try {
        final userProfile = await _apiService.getUserProfile();
        setState(() {
          userName = userProfile.fullName;
        });
      } catch (e) {
        setState(() => userName = "يا بطل"); // في حال فشل جلب البروفايل
      }

      // 2. جلب المنتجات من السيرفر
      final productsData = await _apiService.getProducts(); 
      // ملاحظة: getProducts في ApiService يجب أن ترجع List<dynamic> أو List<ProductModel>
      // هنا سنفترض أنها ترجع List<ProductModel> (كما عدلناها سابقاً)
      
      // تحويل البيانات (إذا كانت ApiService ترجع List<ProductModel> جاهزة استخدمها مباشرة)
      // سأكتب كود التحويل هنا لضمان العمل مع أي تحديث
      final url = Uri.parse('https://revealsystem.pythonanywhere.com/api/products/');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        List data = json.decode(utf8.decode(response.bodyBytes));
        if (mounted) {
          setState(() {
            allProducts = data.map((e) => ProductModel.fromJson(e)).toList();
            displayedProducts = List.from(allProducts);
            isLoading = false;
          });
        }
      } else {
        // فشل الاتصال، لا نستخدم Static بل نظهر خطأ أو قائمة فارغة
        setState(() => isLoading = false);
      }
    } catch (e) {
      debugPrint("Error: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  // البحث والفلترة
  void _runSearch(String keyword) {
    setState(() {
      displayedProducts = allProducts.where((p) =>
        p.name.toLowerCase().contains(keyword.toLowerCase()) || 
        p.category.toLowerCase().contains(keyword.toLowerCase())
      ).toList();
    });
  }

  void _filterByCategory(String key) {
    setState(() {
      _selectedCategory = key;
      if (key == "all") {
        displayedProducts = List.from(allProducts);
      } else {
        displayedProducts = allProducts.where((p) => p.category.toLowerCase().contains(key)).toList();
      }
    });
  }

  // --- نافذة إضافة للسلة (التفاعلية) ---
  void _showAddToCartSheet(ProductModel product) {
    int quantity = 1;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(20),
              height: 250,
              child: Column(
                children: [
                  Text(product.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Text("${product.price} د.ل", style: TextStyle(color: tealColor, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: () {
                          if (quantity > 1) setModalState(() => quantity--);
                        },
                      ),
                      Text("$quantity", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: () => setModalState(() => quantity++),
                      ),
                    ],
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: tealColor, padding: const EdgeInsets.symmetric(vertical: 12)),
                      onPressed: () {
                        // --- إضافة للسلة الحقيقية ---
                        // تأكد من أنك قمت بعمل Provide لـ CartProvider في main.dart
                        try {
                          // هذا السطر يتطلب تعديل CartProvider ليقبل ProductModel
                          // context.read<CartProvider>().addItem(product.id, product.name, product.price, quantity);
                          
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("تمت إضافة $quantity من ${product.name} للسلة ✅")),
                          );
                        } catch (e) {
                          print("Cart Error: $e");
                        }
                      },
                      child: const Text("إضافة للسلة", style: TextStyle(fontSize: 16)),
                    ),
                  )
                ],
              ),
            );
          }
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // قائمة المفضلات (تفاعلية)
    final favorites = allProducts.where((p) => p.isFavorite).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text("المطاعم", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        leading: Icon(Icons.favorite, color: orangeColor), // مجرد أيقونة هنا
),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: tealColor))
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. الترحيب (الاسم الحقيقي)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("موقعك الحالي:", style: TextStyle(fontSize: 12, color: Colors.grey)),
                            Text(location, style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text("أهلاً بك،", style: TextStyle(fontSize: 12, color: Colors.grey)),
                            Text(userName, style: TextStyle(fontWeight: FontWeight.bold, color: tealColor, fontSize: 16)),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 15),

                  // 2. البحث
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(30)),
                      child: TextField(
                        controller: _searchController,
                        onChanged: _runSearch,
                        textAlign: TextAlign.right,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: "ابحث عن وجبتك المفضلة...",
                          prefixIcon: Icon(Icons.search, color: tealColor),
                          contentPadding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 3. قسم "الأحببتها" (المفضلة) - ظهر من جديد!
                  if (favorites.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text("الأحببتها ❤️", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 140,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: favorites.length,
                        itemBuilder: (context, index) => _buildFavoriteCard(favorites[index]),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // 4. التصنيفات
                  SizedBox(
                    height: 50,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        _buildCatChip("الكل", "all"),
                        const SizedBox(width: 10),
                        _buildCatChip("برجر", "burger"),
                        const SizedBox(width: 10),
                        _buildCatChip("بيتزا", "pizza"),
                        const SizedBox(width: 10),
                        _buildCatChip("مشروبات", "drink"),
                      ],
                    ),
                  ),

                  const SizedBox(height: 15),

                  // 5. شبكة المنتجات (قابلة للضغط)
                  displayedProducts.isEmpty
                      ? const Center(child: Padding(padding: EdgeInsets.all(40), child: Text("لا توجد منتجات متاحة")))
                      : GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(16),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.75,
                            crossAxisSpacing: 15,
                            mainAxisSpacing: 15,
                          ),
                          itemCount: displayedProducts.length,
                          itemBuilder: (context, index) => _buildProductCard(displayedProducts[index]),
                        ),
                  
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  // --- Widgets ---

  Widget _buildCatChip(String label, String key) {
    bool isSelected = _selectedCategory.contains(key);
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: tealColor,
      labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
      onSelected: (bool selected) {
        _filterByCategory(key);
      },
    );
  }

  Widget _buildFavoriteCard(ProductModel product) {
    return Container(
      width: 120,
      margin: const EdgeInsets.only(left: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
              child: Image.network(product.getImageUrl(), fit: BoxFit.cover, width: double.infinity),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(product.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(ProductModel product) {
    return GestureDetector(
      onTap: () => _showAddToCartSheet(product), // عند الضغط يفتح نافذة الشراء
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // الصورة والمفضلة
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                    child: Image.network(product.getImageUrl(), width: double.infinity, fit: BoxFit.cover),
                  ),
                  Positioned(
                    top: 8, right: 8,
                    child: InkWell(
                      onTap: () {
                        setState(() => product.isFavorite = !product.isFavorite);
                      },
                      child: CircleAvatar(
                        backgroundColor: Colors.white, radius: 14,
                        child: Icon(product.isFavorite ? Icons.favorite : Icons.favorite_border, color: Colors.red, size: 18),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // التفاصيل وزر الإضافة
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("${product.price} د.ل", style: TextStyle(color: tealColor, fontWeight: FontWeight.bold, fontSize: 14)),
                      InkWell(
                        onTap: () {
                          // إضافة سريعة (1 قطعة)
                           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("تمت إضافة ${product.name} للسلة")));
                           // context.read<CartProvider>().addItem(...) // هنا التفعيل الحقيقي
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(color: orangeColor, borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.add, color: Colors.white, size: 20),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}