import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reveal_app/app/core/enums/view_state.dart';
import 'package:reveal_app/app/data/models/product_model.dart';
import 'package:reveal_app/app/data/providers/auth_provider.dart';
import 'package:reveal_app/app/data/providers/product_provider.dart';
import 'package:reveal_app/app/data/providers/wallet_provider.dart'; // تأكد أن هذا المسار صحيح
import 'package:reveal_app/app/presentation/widgets/product_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const String _allCategoryLabel = ProductProvider.allCategoryLabel;
  final TextEditingController _searchController = TextEditingController();
  
  // عناوين متغيرة حسب الوقت
  String get greetingMessage {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'صباح الخير ☀️';
    if (hour < 18) return 'مساء الخير 🌤️';
    return 'سهرة سعيدة 🌙';
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  // دالة لجلب كل البيانات مرة واحدة
  Future<void> _loadData() async {
    final productProvider = context.read<ProductProvider>();
    final walletProvider = context.read<WalletProvider>(); // لجلب الرصيد
    
    // نشغل الاثنين مع بعض لتقليل وقت الانتظار
    await Future.wait([
      productProvider.fetchAllProducts(),
      walletProvider.fetchWalletData(),
    ]);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // نستدعي البروفايدرز
    final user = context.watch<AuthProvider>().currentUser;
    final productProvider = context.watch<ProductProvider>();
    final walletProvider = context.watch<WalletProvider>();

    final categories = <String>{_allCategoryLabel, ...productProvider.availableCategories}.toList();
    final displayProducts = productProvider.products;

    return Scaffold(
      backgroundColor: Colors.grey[50], // خلفية أهدأ للعين
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData, // تحديث البيانات عند السحب
          color: const Color(0xFF2DBA9D),
          child: CustomScrollView(
            slivers: [
              // 1. الرأس (Header) والمحفظة
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // الشريط العلوي (الاسم والقائمة)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // زر القائمة الجانبية
                          Builder(
                            builder: (ctx) => Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10)],
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.menu, color: Colors.black87),
                                onPressed: () => Scaffold.of(context).openEndDrawer(),
                              ),
                            ),
                          ),
                          
                          // نصوص الترحيب
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '$greetingMessage، ${user?.fullName?.split(' ')[0] ?? "ضيف"}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              const Text(
                                'اطلب وجبتك واستمتع',
                                style: TextStyle(color: Colors.grey, fontSize: 12),
                              ),
                            ],
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 20),

                      // 2. بطاقة المحفظة (جديد 🔥)
                      _buildWalletCard(walletProvider),
                      
                      const SizedBox(height: 20),

                      // 3. مربع البحث
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10)],
                        ),
                        child: TextField(
                          controller: _searchController,
                          textAlign: TextAlign.right,
                          textInputAction: TextInputAction.search,
                          onChanged: (value) {
                            productProvider.updateSearchQuery(value);
                            setState(() {});
                          },
                          decoration: InputDecoration(
                            hintText: 'ابحث عن وجبتك المفضلة...',
                            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                            border: InputBorder.none,
                            prefixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.close, color: Colors.grey),
                                    onPressed: () {
                                      _searchController.clear();
                                      productProvider.updateSearchQuery('');
                                      setState(() {});
                                    },
                                  )
                                : null,
                            suffixIcon: const Icon(Icons.search, color: Color(0xFF2DBA9D)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 4. التصنيفات بالصور (Visual Categories)
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 100,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    reverse: true, // لتبدأ من اليمين
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    children: [
                      _buildCategoryItem("مشروبات", "assets/images/drinks.png"),
                      _buildCategoryItem("حلويات", "assets/images/dessert.png"),
                      _buildCategoryItem("بيتزا", "assets/images/pizza.png"),
                      _buildCategoryItem("برجر", "assets/images/burger.png"),
                    ],
                  ),
                ),
              ),

              // 5. فلاتر التصنيفات (Chips)
              SliverToBoxAdapter(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  reverse: true,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: [
                      const SizedBox(width: 16),
                      ...categories.map((category) {
                        final isSelected = productProvider.selectedCategory == category ||
                            (productProvider.selectedCategory == null && category == _allCategoryLabel);
                        return Padding(
                          padding: const EdgeInsets.only(left: 10),
                          child: GestureDetector(
                            onTap: () => productProvider.filterByCategory(
                              category == _allCategoryLabel ? null : category,
                            ),
                            child: _buildFilterChip(category, isSelected: isSelected),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),

              // 6. قائمة المنتجات
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: _buildProductsList(productProvider, displayProducts),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ودجت بطاقة المحفظة
  Widget _buildWalletCard(WalletProvider provider) {
    final balance = provider.wallet?.balance ?? 0.0;
    final isCharged = balance > 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isCharged 
              ? [const Color(0xFF2DBA9D), const Color(0xFF1A9F84)] // أخضر إذا مشحونة
              : [const Color(0xFF607D8B), const Color(0xFF455A64)], // رمادي إذا فارغة
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (isCharged ? const Color(0xFF2DBA9D) : Colors.grey).withOpacity(0.4),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // الرصيد
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'رصيد المحفظة',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 5),
              Text(
                '${balance.toStringAsFixed(2)} د.ل',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          // الأيقونة
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCharged ? Icons.account_balance_wallet : Icons.money_off,
              color: Colors.white,
              size: 30,
            ),
          ),
        ],
      ),
    );
  }

  // ودجت بناء قائمة المنتجات (Sliver)
  Widget _buildProductsList(ProductProvider provider, List<Product> displayProducts) {
    if (provider.state == ViewState.busy) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(50),
          child: Center(child: CircularProgressIndicator(color: Color(0xFF2DBA9D))),
        ),
      );
    }

    if (provider.state == ViewState.error) {
      return SliverToBoxAdapter(
        child: Center(
          child: Column(
            children: [
              const Icon(Icons.error_outline, size: 50, color: Colors.red),
              const SizedBox(height: 10),
              Text(provider.errorMessage ?? 'فشل تحميل المنتجات'),
              TextButton(
                onPressed: provider.fetchAllProducts,
                child: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      );
    }

    if (displayProducts.isEmpty) {
      return const SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: EdgeInsets.only(top: 50),
            child: Text(
              'لا توجد منتجات مطابقة للبحث.',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: ProductCard(product: displayProducts[index]),
          );
        },
        childCount: displayProducts.length,
      ),
    );
  }

  // ودجت التصنيف الصوري (Visual Category)
  Widget _buildCategoryItem(String title, String imagePath) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          Container(
            width: 65,
            height: 65,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              image: DecorationImage(
                image: AssetImage(imagePath),
                fit: BoxFit.cover,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
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
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  // ودجت الفلتر (Chip)
  Widget _buildFilterChip(String label, {bool isSelected = false}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF2DBA9D) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isSelected ? const Color(0xFF2DBA9D) : Colors.grey[300]!),
        boxShadow: isSelected 
            ? [BoxShadow(color: const Color(0xFF2DBA9D).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))] 
            : [],
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.black54,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}