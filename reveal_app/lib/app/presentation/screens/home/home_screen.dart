import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reveal_app/app/data/models/college_model.dart';
import 'package:reveal_app/app/data/models/product_model.dart'; // ضروري للسلة
import 'package:reveal_app/app/data/services/api_service.dart';
import 'package:reveal_app/app/data/providers/cart_provider.dart'; // تأكد من وجود هذا الملف

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
  List<CollegeModel> cafes = [];
  String? selectedCafeId;

  final List<Map<String, String>> _categoryTiles = [
    {'key': 'burger', 'label': 'برغر', 'asset': 'assets/images/burger.png'},
    {'key': 'pizza', 'label': 'بيتزا', 'asset': 'assets/images/pizza.png'},
    {'key': 'dessert', 'label': 'حلويات', 'asset': 'assets/images/dessert.png'},
    {'key': 'drink', 'label': 'مشروبات', 'asset': 'assets/images/drinks.png'},
  ];

  final Map<String, List<String>> _categoryAssets = {
    'burger': [
      'assets/images/burger1.png',
      'assets/images/burger2.png',
      'assets/images/burger3.png',
      'assets/images/burger4.png',
      'assets/images/burger5.png',
      'assets/images/burger.png',
    ],
    'pizza': [
      'assets/images/pizza1.png',
      'assets/images/pizza2.png',
      'assets/images/pizza3.png',
      'assets/images/pizza4.png',
      'assets/images/pizza5.png',
      'assets/images/pizza.png',
    ],
    'dessert': [
      'assets/images/dessert1.png',
      'assets/images/dessert2.png',
      'assets/images/dessert3.png',
      'assets/images/dessert4.png',
      'assets/images/dessert5.png',
      'assets/images/dessert.png',
    ],
    'drink': [
      'assets/images/drink1.png',
      'assets/images/drink2.png',
      'assets/images/drink3.png',
      'assets/images/drink4.png',
      'assets/images/drink5.png',
      'assets/images/drinks.png',
    ],
  };

  
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
      try {
        final userProfile = await _apiService.getUserProfile();
        setState(() {
          userName = userProfile.fullName;
        });
      } catch (e) {
        setState(() => userName = "??????");
      }

      final cafesData = await _apiService.getCafes();
      if (mounted) {
        setState(() {
          cafes = cafesData;
          if (selectedCafeId == null && cafes.isNotEmpty) {
            selectedCafeId = cafes.first.id;
            location = cafes.first.name;
          }
        });
      }

      await _fetchProductsForCafe(selectedCafeId);
    } catch (e) {
      debugPrint("Error: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _fetchProductsForCafe(String? cafeId) async {
    try {
      final productsData = await _apiService.getProducts(cafeId: cafeId);
      if (mounted) {
        setState(() {
          allProducts = productsData;
          displayedProducts = List.from(allProducts);
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

    void _selectCafe(CollegeModel cafe) {
    if (selectedCafeId == cafe.id) return;
    setState(() {
      selectedCafeId = cafe.id;
      location = cafe.name;
      _selectedCategory = 'all';
      isLoading = true;
    });
    _fetchProductsForCafe(cafe.id);
  }

  String _categoryKeyFor(ProductModel product) {
    final text = "${product.category} ${product.name}".toLowerCase();
    if (text.contains('pizza') || text.contains('بيتزا')) {
      return 'pizza';
    }
    if (text.contains('burger') || text.contains('burg') || text.contains('برغر') || text.contains('برجر')) {
      return 'burger';
    }
    if (text.contains('dessert') || text.contains('sweet') || text.contains('حلويات') || text.contains('حلوى') || text.contains('حلى')) {
      return 'dessert';
    }
    if (text.contains('drink') || text.contains('coffee') || text.contains('juice') || text.contains('مشروب') || text.contains('مشروبات') || text.contains('قهوة') || text.contains('عصير')) {
      return 'drink';
    }
    return 'other';
  }

  List<ProductModel> _categoryProducts(String key) {
    return allProducts.where((p) => _categoryKeyFor(p) == key).take(6).toList();
  }

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
        displayedProducts = allProducts.where((p) => _categoryKeyFor(p) == key).toList();
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
                          context.read<CartProvider>().addItem(product, quantity: quantity);
                          
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("تمت إضافة $quantity من ${product.name} للسلة ✅")),
                          );
                        } on MismatchedCollegeException catch (e) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(e.toString())),
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

                  if (cafes.isNotEmpty) ...[
                    _buildCafeSelector(),
                    const SizedBox(height: 16),
                  ],

                  _buildCategoryTiles(),
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


                  // 5. شبكة المنتجات (قابلة للضغط)
                  allProducts.isEmpty
                      ? const Center(child: Padding(padding: EdgeInsets.all(40), child: Text("?? ???? ?????? ??????")))
                      : _selectedCategory == "all"
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildCategorySection('burger', 'برغر'),
                                _buildCategorySection('pizza', 'بيتزا'),
                                _buildCategorySection('dessert', 'حلويات'),
                                _buildCategorySection('drink', 'مشروبات'),
                              ],
                            )
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
                              itemBuilder: (context, index) => _buildProductCard(
                                displayedProducts[index],
                                categoryKey: _categoryKeyFor(displayedProducts[index]),
                                index: index,
                              ),
                            ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  // --- Widgets ---

  Widget _buildCafeSelector() {
    return SizedBox(
      height: 46,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: cafes.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cafe = cafes[index];
          final isSelected = cafe.id == selectedCafeId;
          return ChoiceChip(
            label: Text(cafe.name),
            selected: isSelected,
            selectedColor: tealColor,
            labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
            onSelected: (_) => _selectCafe(cafe),
          );
        },
      ),
    );
  }

  Widget _buildCategoryTiles() {
    final tiles = [
      {'key': 'all', 'label': 'الكل', 'asset': 'assets/images/logo.png'},
      ..._categoryTiles,
    ];

    return SizedBox(
      height: 90,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: tiles.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) => _buildCategoryTile(tiles[index]),
      ),
    );
  }

  Widget _buildCategoryTile(Map<String, String> tile) {
    final key = tile['key'] ?? 'all';
    final label = tile['label'] ?? '';
    final asset = tile['asset'] ?? 'assets/images/logo.png';
    final isSelected = _selectedCategory == key;

    return InkWell(
      onTap: () => _filterByCategory(key),
      child: Container(
        width: 90,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? tealColor.withOpacity(0.15) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isSelected ? tealColor : Colors.grey.shade200),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 3))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(asset, height: 36, width: 36, fit: BoxFit.contain),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(fontSize: 12), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySection(String key, String label) {
    final items = _categoryProducts(key);
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.75,
            crossAxisSpacing: 15,
            mainAxisSpacing: 15,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) => _buildProductCard(
            items[index],
            categoryKey: key,
            index: index,
          ),
        ),
      ],
    );
  }

  Widget _buildProductImage(ProductModel product, String categoryKey, int index) {
    final assets = _categoryAssets[categoryKey];
    final fallbackAsset = (assets != null && assets.isNotEmpty)
        ? assets[index % assets.length]
        : 'assets/images/logo.png';

    if (product.imageUrl.isNotEmpty && product.imageUrl.startsWith('http')) {
      return Image.network(
        product.imageUrl,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Image.asset(
          fallbackAsset,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
      );
    }

    return Image.asset(fallbackAsset, width: double.infinity, fit: BoxFit.cover);
  }

  Widget _buildFavoriteCard(ProductModel product) {
    final key = _categoryKeyFor(product);
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
              child: _buildProductImage(product, key, 0),
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

  Widget _buildProductCard(ProductModel product, {String? categoryKey, int index = 0}) {
    final key = categoryKey ?? _categoryKeyFor(product);
    return GestureDetector(
      onTap: () => _showAddToCartSheet(product),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                    child: _buildProductImage(product, key, index),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: InkWell(
                      onTap: () {
                        setState(() => product.isFavorite = !product.isFavorite);
                      },
                      child: CircleAvatar(
                        backgroundColor: Colors.white,
                        radius: 14,
                        child: Icon(
                          product.isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: Colors.red,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
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
                      Text("${product.price} ?.?", style: TextStyle(color: tealColor, fontWeight: FontWeight.bold, fontSize: 14)),
                      InkWell(
                        onTap: () {
                          try {
                            context.read<CartProvider>().addItem(product);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("??? ????? ${product.name} ?????")),
                            );
                          } on MismatchedCollegeException catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(e.toString())),
                            );
                          } catch (e) {
                            print("Cart Error: $e");
                          }
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
