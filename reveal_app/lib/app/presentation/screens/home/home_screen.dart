import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reveal_app/app/data/providers/product_provider.dart';
import 'package:reveal_app/app/data/models/product_model.dart';
import 'package:reveal_app/app/data/providers/auth_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // متغير لتغيير العنوان حسب الكلية المختارة
  String pageTitle = "المطاعم";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProductProvider>(context, listen: false).fetchAllProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).currentUser;
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // 1. الهيدر (الاسم والموقع)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(icon: const Icon(Icons.favorite_border), onPressed: () {}),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'أهلاً، ${user?.fullName ?? "الطالب"}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const Text(
                          'موقعك: جامعة طرابلس',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                    IconButton(icon: const Icon(Icons.menu), onPressed: () {}),
                  ],
                ),
              ),

              // 2. العنوان (المطاعم أو اسم الكلية)
              Text(
                pageTitle, 
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),

              // 3. شريط البحث
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: const TextField(
                    textAlign: TextAlign.right,
                    decoration: InputDecoration(
                      hintText: 'هل تبحث عن حاجة معينة؟',
                      border: InputBorder.none,
                      suffixIcon: Icon(Icons.search),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 4. التصنيفات (صور حقيقية بدلاً من الأيقونات)
              SizedBox(
                height: 110, // زيادة الارتفاع قليلاً لاستيعاب الصور والنص
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  reverse: true, // لتبدأ من اليمين
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  children: [
                    _buildCategoryItem("مشروبات", "assets/images/drinks.png"),
                    _buildCategoryItem("حلى", "assets/images/dessert.png"), // استبدال أكل صحي بـ حلى
                    _buildCategoryItem("بيتزا", "assets/images/pizza.png"), // استبدال سندويتش بـ بيتزا
                    _buildCategoryItem("برجر", "assets/images/burger.png"),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // 5. الفلاتر
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                reverse: true,
                child: Row(
                  children: [
                    const SizedBox(width: 16),
                    _buildFilterChip("فلترة", isSelected: true),
                    _buildFilterChip("الموقع"),
                    _buildFilterChip("التقييم"),
                    _buildFilterChip("الأسعار"),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 6. عنوان "أفضل العروض"
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text("أفضل العروض >", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // 7. قائمة المنتجات
              Consumer<ProductProvider>(
                builder: (context, provider, child) {
                  // استخدام بيانات وهمية للعرض إذا كانت القائمة فارغة (مؤقتاً للتحقق من التصميم)
                  final displayProducts = provider.products.isNotEmpty 
                      ? provider.products 
                      : [
                          Product(
                            id: "1", 
                            name: "اسم الكافيتيريا - المنطقة والعنوان", 
                            price: 0.0, 
                            imageUrl: "", // سيتم استخدام الأيقونة الافتراضية
                            description: "عدد الأصناف المتوفرة: 255 صنف",
                            category: "مطعم",
                            collegeId: "1",
                            collegeName: "جامعة طرابلس",
                          ),
                          Product(
                            id: "2", 
                            name: "مطعم الجامعة الرئيسي", 
                            price: 0.0, 
                            imageUrl: "", 
                            description: "شاورما، برجر، ومشروبات",
                            category: "مطعم",
                            collegeId: "1",
                            collegeName: "جامعة طرابلس",
                          ),
                          Product(
                            id: "3", 
                            name: "كافيتيريا العلوم", 
                            price: 0.0, 
                            imageUrl: "", 
                            description: "سندويتشات وقهوة",
                            category: "كافيتيريا",
                            collegeId: "2",
                            collegeName: "كلية العلوم",
                          ),
                        ];

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: displayProducts.length,
                    itemBuilder: (context, index) {
                      return RestaurantCard(product: displayProducts[index]);
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // تعديل لبناء العنصر باستخدام صورة بدلاً من أيقونة
  Widget _buildCategoryItem(String title, String imagePath) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: const Color(0xFFFCE4EC), // خلفية فاتحة مشابهة للصورة
              borderRadius: BorderRadius.circular(20), // تدوير الحواف ليصبح مربع بحواف دائرية كما في الصورة
              image: DecorationImage(
                image: AssetImage(imagePath),
                fit: BoxFit.cover,
              ),
               boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  blurRadius: 5,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title, 
            style: const TextStyle(
              fontSize: 14, 
              fontWeight: FontWeight.bold,
              color: Colors.black87
            )
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, {bool isSelected = false}) {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF2DBA9D) : Colors.white, // تلوين الخلفية عند التحديد
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isSelected ? const Color(0xFF2DBA9D) : Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.black)), // النص أبيض عند التحديد
          if (isSelected) ...[
            const SizedBox(width: 5),
            const Icon(Icons.keyboard_arrow_down, size: 16, color: Colors.white)
          ]
        ],
      ),
    );
  }
}

// ✨✨✨ Restaurant Card ✨✨✨
class RestaurantCard extends StatelessWidget {
  final Product product;
  const RestaurantCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.15), blurRadius: 10, offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        children: [
          // الجزء الرمادي (الصورة)
          Stack(
            children: [
              Container(
                height: 160,
                decoration: const BoxDecoration(
                  color: Colors.grey, 
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: product.imageUrl.isNotEmpty
                    ? ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                        child: Image.network(
                          product.imageUrl,
                          width: double.infinity,
                          height: 160,
                          fit: BoxFit.cover,
                          errorBuilder: (c,o,s) => const Center(child: Icon(Icons.image, size: 50, color: Colors.white)),
                        ),
                      )
                    : const Center(child: Icon(Icons.image, size: 50, color: Colors.white)),
              ),
              // أيقونة القلب
              Positioned(
                top: 15,
                left: 15,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  child: const Icon(Icons.favorite_border, size: 20, color: Colors.black54),
                ),
              ),
              // التقييم (الزاوية اليمنى السفلية)
              Positioned(
                bottom: 15,
                right: 15,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    children: [
                      Text("0.0 (عدد المقيمين)", style: TextStyle(color: Colors.white, fontSize: 11)),
                      SizedBox(width: 4),
                      Icon(Icons.star, color: Colors.orange, size: 14),
                    ],
                  ),
                ),
              )
            ],
          ),
          
          // البيانات (الاسم والسعر)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end, // محاذاة لليمين
              children: [
                Text(
                  product.name, 
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  textDirection: TextDirection.rtl,
                ),
                const SizedBox(height: 8),
                Text(
                  product.price > 0 ? "سعر المنتج: ${product.price} دينار" : "سعر التوصيل: 00 دينار | ${product.description}",
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                  textDirection: TextDirection.rtl,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
