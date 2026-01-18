import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reveal_app/app/data/models/college_model.dart';
import 'package:reveal_app/app/data/models/product_model.dart';
import 'package:reveal_app/app/data/providers/cart_provider.dart';
import 'package:reveal_app/app/data/providers/college_provider.dart';
import 'package:reveal_app/app/data/services/api_service.dart';

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
  CollegeProvider? _collegeProvider;

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

  String userName = "جاري التحميل...";
  String location = "جاري تحديد المقهى...";

  final Color tealColor = const Color(0xFF009688);
  final Color orangeColor = const Color(0xFFFF5722);
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = "all";
  String _searchQuery = '';

  final ApiService _apiService = ApiService();

  String _normalizeCafeName(String name) {
    final trimmed = name.trim();
    if (trimmed.contains('تقنية')) {
      return 'مقهى تقنية المعلومات';
    }
    if (trimmed.contains('لغة') || trimmed.contains('العربية')) {
      return 'مقهى اللغة العربية';
    }
    if (trimmed.contains('اقتصاد') || trimmed.contains('الاقتصاد')) {
      return 'مقهى الاقتصاد';
    }
    return trimmed;
  }

  bool _isSupportedCafeName(String name) {
    final trimmed = name.trim();
    return trimmed.contains('تقنية') ||
        trimmed.contains('لغة') ||
        trimmed.contains('العربية') ||
        trimmed.contains('اقتصاد') ||
        trimmed.contains('الاقتصاد');
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _collegeProvider = context.read<CollegeProvider>();
      _collegeProvider?.addListener(_handleCollegeSelection);
    });
    _fetchRealData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _collegeProvider?.removeListener(_handleCollegeSelection);
    super.dispose();
  }

  Future<void> _fetchRealData() async {
    try {
      try {
        final userProfile = await _apiService.getUserProfile();
        setState(() {
          userName = userProfile.fullName;
        });
      } catch (_) {
        setState(() => userName = "مستخدم");
      }

      final cafesData = await _apiService.getCafes();
      final filtered = cafesData.where((cafe) => _isSupportedCafeName(cafe.name)).toList();
      if (mounted) {
        final provider = context.read<CollegeProvider>();
        setState(() {
          cafes = filtered.isNotEmpty ? filtered : cafesData;
          if (cafes.isNotEmpty) {
            final preferredCafe = provider.selectedCollege ?? cafes.first;
            selectedCafeId = preferredCafe.id;
            location = _normalizeCafeName(preferredCafe.name);
            if (provider.selectedCollege == null) {
              provider.selectCollege(preferredCafe);
            }
          }
        });
      }

      if (selectedCafeId != null) {
        await _fetchProductsForCafe(selectedCafeId);
      } else if (mounted) {
        setState(() => isLoading = false);
      }
    } catch (e) {
      debugPrint("Error: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _fetchProductsForCafe(String? cafeId) async {
    try {
      final productsData = await _apiService.getProducts(cafeId: cafeId);
      final normalizedCafeId = (cafeId ?? '').toString();
      final filtered = normalizedCafeId.isEmpty
          ? productsData
          : productsData.where((p) => p.cafeId == normalizedCafeId).toList();
      if (mounted) {
        setState(() {
          allProducts = filtered.isNotEmpty ? filtered : productsData;
          displayedProducts = _applyFilters();
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _handleCollegeSelection() {
    final selected = _collegeProvider?.selectedCollege;
    if (selected == null || selectedCafeId == selected.id) {
      return;
    }
    _selectCafe(selected);
  }

  void _selectCafe(CollegeModel cafe) {
    if (selectedCafeId == cafe.id) return;
    setState(() {
      selectedCafeId = cafe.id;
      location = _normalizeCafeName(cafe.name);
      _selectedCategory = 'all';
      _searchQuery = '';
      _searchController.clear();
      isLoading = true;
    });
    _fetchProductsForCafe(cafe.id);
  }

  String _categoryKeyFor(ProductModel product) {
    final text = "${product.category} ${product.name}".toLowerCase();
    if (text.contains('بيتزا') || text.contains('pizza')) {
      return 'pizza';
    }
    if (text.contains('برغر') || text.contains('برجر') || text.contains('burger')) {
      return 'burger';
    }
    if (text.contains('حلويات') || text.contains('حلوى') || text.contains('dessert') || text.contains('sweet')) {
      return 'dessert';
    }
    if (text.contains('مشروب') ||
        text.contains('مشروبات') ||
        text.contains('قهوة') ||
        text.contains('عصير') ||
        text.contains('ماء') ||
        text.contains('drink') ||
        text.contains('coffee') ||
        text.contains('juice')) {
      return 'drink';
    }
    return 'other';
  }

  bool _requiresOptions(ProductModel product) {
    final key = _categoryKeyFor(product);
    return key == 'pizza' || key == 'burger';
  }

  String _buildOptionsString({required bool cheese, required bool harissa}) {
    final cheeseText = cheese ? 'مع جبن' : 'بدون جبن';
    final harissaText = harissa ? 'مع هريسة' : 'بدون هريسة';
    return '$cheeseText، $harissaText';
  }

  List<ProductModel> _categoryProducts(String key) {
    return allProducts.where((p) => _categoryKeyFor(p) == key).take(5).toList();
  }

  List<ProductModel> _applyFilters() {
    Iterable<ProductModel> filtered = allProducts;
    if (_selectedCategory != "all") {
      filtered = filtered.where((p) => _categoryKeyFor(p) == _selectedCategory);
    }
    final query = _searchQuery.trim().toLowerCase();
    if (query.isNotEmpty) {
      filtered = filtered.where((p) =>
          p.name.toLowerCase().contains(query) ||
          p.category.toLowerCase().contains(query));
    }
    return filtered.toList();
  }

  void _runSearch(String keyword) {
    setState(() {
      _searchQuery = keyword.trim();
      displayedProducts = _applyFilters();
    });
  }

  void _filterByCategory(String key) {
    setState(() {
      _selectedCategory = key;
      displayedProducts = _applyFilters();
    });
  }

  void _showUnavailableMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("المنتج غير متوفر حالياً")),
    );
  }

  void _showAddToCartSheet(ProductModel product) {
    if (!product.isAvailable) {
      _showUnavailableMessage();
      return;
    }

    int quantity = 1;
    bool includeCheese = true;
    bool includeHarissa = false;
    final showOptions = _requiresOptions(product);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (ctx) {
        final bottomInset = MediaQuery.of(ctx).viewInsets.bottom;
        return SafeArea(
          top: false,
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomInset),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(product.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Text("${product.price} د.ل", style: TextStyle(color: tealColor, fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    if (showOptions) ...[
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text("خيارات الإضافة", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[700])),
                      ),
                      const SizedBox(height: 8),
                      SwitchListTile(
                        value: includeCheese,
                        activeColor: tealColor,
                        title: const Text("جبن"),
                        subtitle: Text(includeCheese ? "مع جبن" : "بدون جبن"),
                        onChanged: (value) => setModalState(() => includeCheese = value),
                      ),
                      SwitchListTile(
                        value: includeHarissa,
                        activeColor: orangeColor,
                        title: const Text("هريسة"),
                        subtitle: Text(includeHarissa ? "مع هريسة" : "بدون هريسة"),
                        onChanged: (value) => setModalState(() => includeHarissa = value),
                      ),
                    ],
                    const SizedBox(height: 8),
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
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: tealColor, padding: const EdgeInsets.symmetric(vertical: 12)),
                        onPressed: () {
                          try {
                            final options = showOptions
                                ? _buildOptionsString(cheese: includeCheese, harissa: includeHarissa)
                                : '';
                            context.read<CartProvider>().addItem(product, quantity: quantity, options: options);
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("تمت إضافة $quantity من ${product.name} إلى السلة")),
                            );
                          } on MismatchedCollegeException catch (e) {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(e.toString())),
                            );
                          } catch (e) {
                            debugPrint("Cart Error: $e");
                          }
                        },
                        child: const Text(
                          "إضافة إلى السلة",
                          style: TextStyle(fontSize: 16),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            },
          ),
        );
      },
    );
  }

  void _quickAdd(ProductModel product) {
    if (!product.isAvailable) {
      _showUnavailableMessage();
      return;
    }

    if (_requiresOptions(product)) {
      _showAddToCartSheet(product);
      return;
    }

    try {
      context.read<CartProvider>().addItem(product);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("تمت إضافة ${product.name} إلى السلة")),
      );
    } on MismatchedCollegeException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } catch (e) {
      debugPrint("Cart Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final favorites = allProducts.where((p) => p.isFavorite).toList();
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final showFilteredGrid = _searchQuery.isNotEmpty || _selectedCategory != "all";

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: isLoading
            ? Center(child: CircularProgressIndicator(color: tealColor))
            : SingleChildScrollView(
                padding: EdgeInsets.only(bottom: 140 + bottomInset),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("المقهى الحالي:", style: TextStyle(fontSize: 12, color: Colors.grey)),
                              Text(location, style: const TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text("مرحباً بك", style: TextStyle(fontSize: 12, color: Colors.grey)),
                              Text(userName, style: TextStyle(fontWeight: FontWeight.bold, color: tealColor, fontSize: 16)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 15),
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
                            hintText: "ابحث عن منتج...",
                            prefixIcon: Icon(Icons.search, color: tealColor),
                            contentPadding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildCategoryTiles(),
                    const SizedBox(height: 20),
                    if (favorites.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text("المفضلة", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
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
                    allProducts.isEmpty
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(40),
                              child: Text("لا توجد منتجات متاحة حالياً"),
                            ),
                          )
                        : showFilteredGrid
                            ? GridView.builder(
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
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildCategorySection('burger', 'برغر'),
                                  _buildCategorySection('pizza', 'بيتزا'),
                                  _buildCategorySection('dessert', 'حلويات'),
                                  _buildCategorySection('drink', 'مشروبات'),
                                ],
                              ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildCategoryTiles() {
    final tiles = [
      {'key': 'all', 'label': 'الكل', 'asset': 'assets/images/logo.png'},
      ..._categoryTiles,
    ];

    return SizedBox(
      height: 104,
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        width: 104,
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    tealColor.withOpacity(0.9),
                    const Color(0xFF4DD0E1).withOpacity(0.9),
                  ],
                )
              : LinearGradient(
                  colors: [
                    Colors.white,
                    Colors.grey.shade50,
                  ],
                ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: isSelected ? tealColor.withOpacity(0.2) : Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: isSelected ? tealColor.withOpacity(0.25) : Colors.black.withOpacity(0.05),
              blurRadius: isSelected ? 12 : 8,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 42,
              height: 42,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withOpacity(0.95) : Colors.grey.shade100,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Image.asset(asset, height: 26, width: 26, fit: BoxFit.contain),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? Colors.white : Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
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
    final text = '${product.category} ${product.name}'.toLowerCase();
    if (text.contains('قهوة') || text.contains('coffee')) {
      final coffeeAssets = [
        'assets/images/coffee_placeholder.png',
        'assets/images/coffee_placeholder2.png',
      ];
      final variantIndex = (product.imageVariant != null && product.imageVariant! >= 0)
          ? product.imageVariant!
          : index;
      final coffeeAsset = coffeeAssets[variantIndex % coffeeAssets.length];
      return Image.asset(coffeeAsset, width: double.infinity, fit: BoxFit.cover);
    }

    final assets = _categoryAssets[categoryKey];
    final variantIndex = (product.imageVariant != null && product.imageVariant! >= 0)
        ? product.imageVariant!
        : index;
    final fallbackAsset = (assets != null && assets.isNotEmpty)
        ? assets[variantIndex % assets.length]
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
            child: Text(
              product.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(ProductModel product, {String? categoryKey, int index = 0}) {
    final key = categoryKey ?? _categoryKeyFor(product);
    final available = product.isAvailable;

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
                  if (!available)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          "غير متوفر",
                          style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
                      Text("${product.price} د.ل", style: TextStyle(color: tealColor, fontWeight: FontWeight.bold, fontSize: 14)),
                      InkWell(
                        onTap: () => _quickAdd(product),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: available ? orangeColor : Colors.grey,
                            borderRadius: BorderRadius.circular(8),
                          ),
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
