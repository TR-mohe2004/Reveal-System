import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import 'package:reveal_app/app/data/models/order_model.dart';
import 'package:reveal_app/app/data/services/api_service.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  bool isLoading = true;
  List<OrderModel> myOrders = [];
  
  // الألوان الرسمية
  final Color tealColor = const Color(0xFF009688);
  final Color orangeColor = const Color(0xFFFF5722);

  @override
  void initState() {
    super.initState();
    fetchOrders();
  }

  // دالة جلب الطلبات الحقيقية
  Future<void> fetchOrders() async {
    try {
      final apiService = ApiService();
      // جلب الطلبات من السيرفر
      final orders = await apiService.getOrders();
      
      if (mounted) {
        setState(() {
          myOrders = orders;
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching orders: $e");
      // في حال الخطأ نوقف التحميل (يمكنك إضافة بيانات وهمية هنا للتجربة إذا أردت)
      if (mounted) setState(() => isLoading = false);
    }
  }

  // تحديد ستايل الحالة (اللون والنص)
  Map<String, dynamic> getStatusStyle(String status) {
    switch (status.toUpperCase()) {
      case 'SUCCESS':
      case 'COMPLETED':
        return {"color": tealColor, "text": "مكتمل ✅", "bg": tealColor};
      case 'PREPARING':
        return {"color": Colors.orange, "text": "قيد التحضير 👨‍🍳", "bg": Colors.orange};
      case 'CANCELLED':
        return {"color": Colors.red, "text": "ملغي ❌", "bg": Colors.red};
      case 'PENDING':
      default:
        return {"color": Colors.grey, "text": "قيد الانتظار...", "bg": Colors.grey};
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5), // خلفية رمادية فاتحة
      
      // --- 1. الشريط العلوي (AppBar) ---
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "طلباتي",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        leading: Builder(builder: (context) {
          return IconButton(
            icon: const Icon(Icons.menu, color: Colors.black, size: 28),
            onPressed: () => Scaffold.of(context).openDrawer(),
          );
        }),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: const [
                Text("الموقع الحالي", style: TextStyle(color: Colors.grey, fontSize: 10)),
                Text("طرابلس الجامعية", style: TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
          )
        ],
      ),

      // القائمة الجانبية
      drawer: const Drawer(child: Center(child: Text("القائمة الجانبية"))),

      // --- 2. جسم الصفحة (قائمة الطلبات) ---
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: tealColor))
          : myOrders.isEmpty
              ? const Center(child: Text("لا توجد طلبات سابقة", style: TextStyle(fontSize: 16, color: Colors.grey)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: myOrders.length,
                  itemBuilder: (context, index) {
                    return _buildOrderCard(myOrders[index]);
                  },
                ),

      // --- 3. الشريط السفلي (مطابق للتصميم) ---
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: tealColor, // الخلفية خضراء (Teal)
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white70,
          currentIndex: 3, // نحدد أننا في صفحة "طلباتي"
          showSelectedLabels: true,
          showUnselectedLabels: true,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              label: "الرئيسية",
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.shopping_cart_outlined),
              label: "السلة",
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              label: "الحساب",
            ),
            BottomNavigationBarItem(
              // تصميم الأيقونة النشطة (دائرة برتقالية)
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: orangeColor, // البرتقالي
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.receipt_long, color: Colors.white, size: 20),
              ),
              label: "طلباتي",
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.account_balance_wallet_outlined),
              label: "المحفظة",
            ),
          ],
          onTap: (index) {
             // منطق التنقل يتم عبر MainScreen عادةً، 
             // أو يمكنك استخدام Navigator هنا للانتقال للصفحات الأخرى
             if (index == 4) Navigator.pushNamed(context, '/wallet');
             if (index == 0) Navigator.pushNamed(context, '/main');
          },
        ),
      ),
    );
  }

  // --- 4. تصميم بطاقة الطلب ---
  Widget _buildOrderCard(OrderModel order) {
    final statusStyle = getStatusStyle(order.status);
    
    // تحويل التاريخ (معالجة الخطأ المحتمل في التنسيق)
    DateTime orderDate;
    try {
      orderDate = DateTime.parse(order.createdAt);
    } catch (_) {
      orderDate = DateTime.now();
    }
    final dateStr = intl.DateFormat('yyyy-MM-dd • hh:mm a').format(orderDate);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            // الرأس: اللوجو واسم الكلية
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: Colors.grey[100],
                  // محاولة عرض لوغو الكلية إذا وجد
                  backgroundImage: (order.cafeLogo != null && order.cafeLogo!.isNotEmpty) 
                      ? NetworkImage(order.cafeLogo!) 
                      : null,
                  child: (order.cafeLogo == null || order.cafeLogo!.isEmpty) 
                      ? Icon(Icons.store_mall_directory, color: tealColor) 
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        // ✅ التعديل: استخدام cafeName بدلاً من collegeName
                        order.cafeName ?? "الكافيتيريا", 
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dateStr,
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                // حالة الطلب (نص صغير في الأعلى)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: (statusStyle['bg'] as Color).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    statusStyle['text'],
                    style: TextStyle(
                      color: statusStyle['color'],
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            
            const Divider(height: 24),

            // صور المنتجات (Horizontal List)
            if (order.items.isNotEmpty)
              SizedBox(
                height: 60,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: order.items.length,
                  itemBuilder: (context, i) {
                    // ✅ التعديل: الوصول للصورة عبر items[i].productImage
                    final imgUrl = order.items[i].productImage;
                    return Container(
                      width: 60,
                      margin: const EdgeInsets.only(left: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(10),
                        image: DecorationImage(
                          image: NetworkImage(
                            (imgUrl != null && imgUrl.isNotEmpty) 
                                ? imgUrl 
                                : "https://cdn-icons-png.flaticon.com/512/3075/3075977.png" // صورة افتراضية
                          ),
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  },
                ),
              ),

            const SizedBox(height: 16),

            // الزر السفلي (الحالة والسعر)
            Container(
              height: 48,
              decoration: BoxDecoration(
                color: statusStyle['bg'], // لون الخلفية يتغير حسب الحالة
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      statusStyle['text'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      // ✅ التعديل: استخدام totalPrice بدلاً من amount
                      "${order.totalPrice.toStringAsFixed(1)} د.ل",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}