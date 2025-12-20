import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import 'package:reveal_app/app/core/utils/smart_image_util.dart'; // استيراد الحيلة الذكية
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

  Future<void> fetchOrders() async {
    try {
      final apiService = ApiService();
      final orders = await apiService.getOrders();
      if (mounted) {
        setState(() {
          myOrders = orders;
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching orders: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  // تحديد ستايل الحالة وأيقونتها
  Map<String, dynamic> getStatusStyle(String status) {
    switch (status.toUpperCase()) {
      case 'SUCCESS':
      case 'COMPLETED':
      case 'READY':
        return {"color": tealColor, "text": "جاهز للاستلام ✅", "bg": tealColor.withOpacity(0.1)};
      case 'PREPARING':
        return {"color": Colors.orange, "text": "قيد التحضير 👨‍🍳", "bg": Colors.orange.withOpacity(0.1)};
      case 'CANCELLED':
        return {"color": Colors.red, "text": "ملغي ❌", "bg": Colors.red.withOpacity(0.1)};
      case 'PENDING':
      default:
        return {"color": Colors.grey, "text": "قيد الانتظار ⏳", "bg": Colors.grey.withOpacity(0.1)};
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. حذفنا Scaffold و AppBar لأن MainScreen تتحكم فيهم
    // نبدأ مباشرة بـ Column أو Container
    return Column(
      children: [
        // --- عنوان جميل بسيط ---
        Container(
          padding: const EdgeInsets.all(20),
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "طلباتي السابقة",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
              ),
              Text(
                "تابع حالة طلباتك أو اطلب مرة أخرى",
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),

        // --- قائمة الطلبات ---
        Expanded(
          child: isLoading
              ? Center(child: CircularProgressIndicator(color: tealColor))
              : myOrders.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      onRefresh: fetchOrders,
                      color: tealColor,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: myOrders.length,
                        itemBuilder: (context, index) {
                          return _buildOrderCard(myOrders[index]);
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  // تصميم الحالة الفارغة
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            "لا توجد طلبات حتى الآن",
            style: TextStyle(fontSize: 18, color: Colors.grey[600], fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text("اطلب أكلتك المفضلة الآن واستمتع!", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  // --- تصميم بطاقة الطلب (محسن جداً) ---
  Widget _buildOrderCard(OrderModel order) {
    final statusData = getStatusStyle(order.status);
    
    DateTime orderDate;
    try {
      orderDate = DateTime.parse(order.createdAt);
    } catch (_) {
      orderDate = DateTime.now();
    }
    // تنسيق الوقت ليكون مقروءاً (مثال: منذ 5 دقائق)
    final dateStr = intl.DateFormat('d MMM, hh:mm a', 'en').format(orderDate);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // 1. رأس البطاقة (اسم الكلية والحالة)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.store_rounded, color: tealColor),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.cafeName ?? "مقهى الكلية", // ✅ الاسم الحقيقي للمقهى
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          dateStr,
                          style: TextStyle(color: Colors.grey[500], fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusData['bg'],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusData['text'],
                    style: TextStyle(
                      color: statusData['color'],
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, thickness: 0.5),

          // 2. محتوى الطلب (صور المنتجات باستخدام الحيلة الذكية)
          if (order.items.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                height: 60,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: order.items.length,
                  separatorBuilder: (ctx, i) => const SizedBox(width: 10),
                  itemBuilder: (context, i) {
                    final item = order.items[i];
                    // ✅ استخدام الحيلة الذكية لجلب الصورة
                    // نفترض أن item يحتوي على productName، وإذا لم يوجد نستخدم اسم "منتج"
                    // ملاحظة: تأكد أن OrderItemModel يحتوي على حقل لاسم المنتج
                    // هنا سنفترض أن item.productImage يأتي من السيرفر، وإذا لا نستخدم الاسم
                    final imgPath = SmartImageUtil.getImagePath(
                      item.productName ?? "burger", // استخدم اسم المنتج هنا
                      item.productImage
                    );
                    final isNetwork = SmartImageUtil.isNetworkImage(imgPath);

                    return Stack(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: isNetwork
                                ? Image.network(imgPath, fit: BoxFit.cover)
                                : Image.asset(imgPath, fit: BoxFit.cover),
                          ),
                        ),
                        // دائرة الكمية
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.black87,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              "${item.quantity}x",
                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),

          // 3. الفوتر (السعر وزر إعادة الطلب)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("الإجمالي", style: TextStyle(color: Colors.grey, fontSize: 12)),
                    Text(
                      "${order.totalPrice.toStringAsFixed(2)} د.ل",
                      style: TextStyle(
                        color: tealColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    // ميزة مستقبلية: إعادة الطلب
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("سيتم تفعيل ميزة إعادة الطلب قريباً")),
                    );
                  },
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text("اطلب مرة أخرى"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    elevation: 0,
                    side: BorderSide(color: Colors.grey[300]!),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}