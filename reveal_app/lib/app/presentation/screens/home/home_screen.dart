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

              // 4. التصنيفات (الأيقونات الدائرية) - ميني همبرغر وغيرها
              SizedBox(
                height: 90,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  reverse: true, // لتبدأ من اليمين
                  children: [
                    _buildCategoryItem("مشروبات", Icons.coffee),
                    _buildCategoryItem("سندويتش", Icons.lunch_dining),
                    _buildCategoryItem("أكل صحي", Icons.health_and_safety),
                    _buildCategoryItem("برجر", Icons.fastfood),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // 5. الفلاتر (الأسعار، التقييم...) - باللون التركوازي
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

              // 7. قائمة المنتجات (Restaurant Cards) الحية
              Consumer<ProductProvider>(
                builder: (context, provider, child) {
                  if (provider.products.isEmpty) {
                    return const Center(child: Text("لا توجد منتجات حالياً"));
                  }
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: provider.products.length,
                    itemBuilder: (context, index) {
                      return RestaurantCard(product: provider.products[index]);
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

  Widget _buildCategoryItem(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.grey[200],
            child: Icon(icon, color: Colors.black54),
          ),
          const SizedBox(height: 5),
          Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, {bool isSelected = false}) {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isSelected ? const Color(0xFF2DBA9D) : Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Text(label, style: TextStyle(color: isSelected ? const Color(0xFF2DBA9D) : Colors.black)),
          if (isSelected) ...[
            const SizedBox(width: 5),
            const Icon(Icons.keyboard_arrow_down, size: 16, color: Color(0xFF2DBA9D))
          ]
        ],
      ),
    );
  }
}

// ✨✨✨ Restaurant Card (التصميم الرمادي الأصلي) ✨✨✨
class RestaurantCard extends StatelessWidget {
  final Product product;
  const RestaurantCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 5, spreadRadius: 1),
        ],
      ),
      child: Column(
        children: [
          // الجزء الرمادي (الصورة)
          Stack(
            children: [
              Container(
                height: 140,
                decoration: const BoxDecoration(
                  color: Colors.grey, // لون رمادي كما في الصورة الأصلية
                  borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
                ),
                child: product.imageUrl.isNotEmpty
                    ? Image.network(
                        product.imageUrl,
                        width: double.infinity,
                        height: 140,
                        fit: BoxFit.cover,
                        errorBuilder: (c,o,s) => const Center(child: Icon(Icons.image, size: 50, color: Colors.white)),
                      )
                    : const Center(child: Icon(Icons.image, size: 50, color: Colors.white)),
              ),
              // أيقونة القلب
              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  child: const Icon(Icons.favorite_border, size: 18),
                ),
              ),
              // التقييم (الزاوية اليمنى السفلية)
              Positioned(
                bottom: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Text("0.0 (عدد المقيمين)", style: TextStyle(color: Colors.white, fontSize: 10)),
                      SizedBox(width: 4),
                      Icon(Icons.star, color: Colors.orange, size: 12),
                    ],
                  ),
                ),
              )
            ],
          ),
          
          // البيانات (الاسم والسعر)
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end, // محاذاة لليمين
              children: [
                Text(
                  product.name, // اسم المنتج أو الكافيتيريا
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  textDirection: TextDirection.rtl,
                ),
                const SizedBox(height: 5),
                Text(
                  "سعر المنتج: ${product.price} دينار | عدد الأصناف المتوفرة: 255",
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                  textDirection: TextDirection.rtl,
                ),
                Divider(color: Colors.grey[300]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}