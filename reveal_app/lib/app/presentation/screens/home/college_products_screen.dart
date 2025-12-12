// lib/app/presentation/screens/home/college_products_screen.dart (النسخة النهائية)

import 'package:flutter/material.dart';

class CollegeProductsScreen extends StatefulWidget {
  const CollegeProductsScreen({super.key});

  @override
  State<CollegeProductsScreen> createState() => _CollegeProductsScreenState();
}

class _CollegeProductsScreenState extends State<CollegeProductsScreen> {
  bool isFavorited = false;
  int selectedCategoryIndex = 0; // لتتبع الفئة المختارة

  final List<String> categories = [
    'العصائر',
    'السموثيز',
    'المشروبات',
    'الوجبات الصحية',
    'الحلويات'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: CustomScrollView(
          slivers: [
            // 1. الـ AppBar المخصص الذي يحتوي على صورة الغلاف والشعار
            SliverAppBar(
              expandedHeight: 220.0,
              backgroundColor: Colors.white,
              elevation: 0,
              pinned: true, // يبقى الـ AppBar ظاهرًا عند التمرير
              leading: Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.only(top: 16.0, right: 16.0),
                  child: IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        shape: BoxShape.rectangle,
                        border: Border.all(color: Colors.grey.shade400, width: 1.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.black),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    // صورة الغلاف
                    const Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 150,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(30),
                            bottomRight: Radius.circular(30),
                          ),
                        ),
                        child: const Center(child: Icon(Icons.image, color: Colors.white, size: 80)),
                      ),
                    ),
                    // الشعار الدائري المتداخل
                    Positioned(
                      top: 150 - 60, // 150 (ارتفاع الغلاف) - 60 (نصف ارتفاع الشعار)
                      child: const CircleAvatar(
                        radius: 64,
                        backgroundColor: Color(0xFFF27E49),
                        child: CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.white,
                          child: CircleAvatar(
                            radius: 56,
                            backgroundColor: Colors.grey,
                            child: Icon(Icons.storefront, size: 60, color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 2. المحتوى الرئيسي الذي يظهر تحت الـ AppBar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE6F8F5),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFF2DBA9D)),
                          ),
                          child: const Row(
                            children: [
                              Text('مفتوح', style: TextStyle(color: Color(0xFF2DBA9D), fontWeight: FontWeight.bold)),
                              SizedBox(width: 4),
                              Icon(Icons.check_circle, color: Color(0xFF2DBA9D), size: 16),
                            ],
                          ),
                        ),
                        const Text(
                          'اسم الكافتيريا - المنطقة والعنوان',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: Icon(
                            isFavorited ? Icons.favorite : Icons.favorite_border,
                            color: isFavorited ? Colors.red : Colors.black,
                            size: 30,
                          ),
                          onPressed: () {
                            setState(() {
                              isFavorited = !isFavorited;
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'الملخص العام عن المطعم سيوضع هنا، سيكون ملخص عام، نبذة بسيطة، وبحد قصير.',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    const InfoRow(), // بطاقة المعلومات (التجهيز، البعد، الخ)
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            
            // 3. شريط البحث والفلاتر الذي يثبت في الأعلى عند التمرير
            SliverPersistentHeader(
              delegate: _SliverHeaderDelegate(
                child: const Container(
                  color: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: const Column(
                    children: [
                      SearchBarWidget(),
                      SizedBox(height: 8),
                      FilterChipsRow(),
                    ],
                  ),
                ),
                minHeight: 120.0,
                maxHeight: 120.0,
              ),
              pinned: true,
            ),

            // 4. قائمة الأصناف
            SliverPadding(
              padding: const EdgeInsets.all(16.0),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, // عمودان
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.75, // نسبة العرض إلى الارتفاع للبطاقة
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) => const ProductCard(),
                  childCount: 10, // عدد وهمي للمنتجات
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- ويدجتس مساعدة ومنظمة ---

// بطاقة المعلومات (سرعة التجهيز، البعد، التوصيل، التقييم)
class InfoRow extends StatelessWidget {
  const InfoRow({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(15),
      ),
      // ✨✨✨ هذا هو الجزء الذي تم إصلاحه ✨✨✨
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          InfoItem(title: 'التقييم', value: '0.0 (0)', icon: Icons.star_border),
          InfoItem(title: 'التوصيل', value: '00 دينار'),
          InfoItem(title: 'البعد', value: '00 كيلومتر'),
          InfoItem(title: 'سرعة التجهيز', value: '00 دقيقة'),
        ],
      ),
    );
  }
}

class InfoItem extends StatelessWidget {
  final String title;
  final String value;
  final IconData? icon;
  const InfoItem({super.key, required this.title, required this.value, this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        const SizedBox(height: 4),
        Row(
          children: [
            if (icon != null) Icon(icon, color: Colors.orange, size: 16),
            if (icon != null) const SizedBox(width: 4),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          ],
        ),
      ],
    );
  }
}

// شريط البحث
class SearchBarWidget extends StatelessWidget {
  const SearchBarWidget({super.key});
  @override
  Widget build(BuildContext context) {
    return TextField(
      textAlign: TextAlign.right,
      decoration: InputDecoration(
        hintText: 'هل تبحث عن حاجة معينة؟',
        prefixIcon: const Icon(Icons.search, color: Color(0xFF2DBA9D)),
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        contentPadding: EdgeInsets.zero,
      ),
    );
  }
}

// فلاتر الأصناف
class FilterChipsRow extends StatelessWidget {
  const FilterChipsRow({super.key});
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      reverse: true,
      child: Row(
        children: [
          FilterChip(label: const Text('فلترة'), onSelected: (b) {}, avatar: const Icon(Icons.keyboard_arrow_down)),
          const SizedBox(width: 8),
          FilterChip(label: const Text('التقييم'), onSelected: (b) {}, selected: true, selectedColor: Colors.grey[300]),
          const SizedBox(width: 8),
          FilterChip(label: const Text('الطلب'), onSelected: (b) {}),
          const SizedBox(width: 8),
          FilterChip(label: const Text('الأسعار'), onSelected: (b) {}),
        ],
      ),
    );
  }
}

// بطاقة الصنف الواحد
class ProductCard extends StatefulWidget {
  const ProductCard({super.key});
  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  bool isProductFavorited = false;
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      color: Colors.grey[100],
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Center(child: Icon(Icons.image, color: Colors.white, size: 40)),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.white,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: Icon(
                        isProductFavorited ? Icons.favorite : Icons.favorite_border,
                        color: isProductFavorited ? Colors.red : Colors.black,
                        size: 18,
                      ),
                      onPressed: () => setState(() => isProductFavorited = !isProductFavorited),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: const Color(0xFF2DBA9D),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.add, color: Colors.white, size: 20),
                      onPressed: () { /* TODO: Add to cart */ },
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Padding(
            padding: const EdgeInsets.all(8.0),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text('اسم الصنف', style: TextStyle(fontWeight: FontWeight.bold)),
                const Text('00 دينار', style: TextStyle(color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// هذا الكلاس ضروري لعمل الـ SliverPersistentHeader
class _SliverHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double minHeight;
  final double maxHeight;

  _SliverHeaderDelegate({
    required this.child,
    required this.minHeight,
    required this.maxHeight,
  });

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(_SliverHeaderDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxHeight ||
        minHeight != oldDelegate.minHeight ||
        child != oldDelegate.child;
  }
}
