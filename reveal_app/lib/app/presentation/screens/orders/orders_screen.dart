import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart' as intl;
import 'package:provider/provider.dart';
import 'package:reveal_app/app/core/utils/smart_image_util.dart';
import 'package:reveal_app/app/data/models/order_model.dart';
import 'package:reveal_app/app/data/providers/cart_provider.dart';
import 'package:reveal_app/app/data/providers/navigation_provider.dart';
import 'package:reveal_app/app/data/providers/notification_provider.dart';
import 'package:reveal_app/app/data/services/api_service.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  bool isLoading = true;
  List<OrderModel> myOrders = [];

  final Color tealColor = const Color(0xFF009688);
  final Color orangeColor = const Color(0xFFFF5722);

  @override
  void initState() {
    super.initState();
    _initLocale();
    fetchOrders();
  }

  Future<void> _initLocale() async {
    try {
      await initializeDateFormatting('ar');
    } catch (_) {
      // ignore locale init errors
    }
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
        await context.read<NotificationProvider>().refreshFromOrders(orders);
      }
    } catch (e) {
      debugPrint("Error fetching orders: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  Map<String, dynamic> getStatusStyle(String status) {
    switch (status.toUpperCase()) {
      case 'SUCCESS':
      case 'COMPLETED':
      case 'READY':
        return {"color": tealColor, "text": "طلبك جاهز للاستلام", "bg": tealColor.withOpacity(0.1)};
      case 'PREPARING':
        return {"color": Colors.orange, "text": "طلبك قيد التحضير", "bg": Colors.orange.withOpacity(0.1)};
      case 'CANCELLED':
        return {"color": Colors.red, "text": "تم إلغاء الطلب", "bg": Colors.red.withOpacity(0.1)};
      case 'PENDING':
        return {"color": Colors.grey, "text": "بانتظار الموافقة", "bg": Colors.grey.withOpacity(0.1)};
      case 'ACCEPTED':
        return {"color": Colors.blue, "text": "تم قبول طلبك", "bg": Colors.blue.withOpacity(0.1)};
      default:
        return {"color": Colors.grey, "text": "قيد المعالجة", "bg": Colors.grey.withOpacity(0.1)};
    }
  }

  Future<void> _handleReorder(OrderModel order) async {
    if (order.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("لا توجد عناصر لإعادة الطلب.")),
      );
      return;
    }

    final cart = context.read<CartProvider>();
    final orderCafeId = order.cafeId ?? '';
    if (orderCafeId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("تعذر تحديد المقهى لهذا الطلب.")),
      );
      return;
    }

    if (cart.items.isNotEmpty) {
      final existingCafeId = cart.items.values.first.collegeId;
      if (existingCafeId.isNotEmpty && existingCafeId != orderCafeId) {
        final shouldClear = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text("تبديل السلة؟"),
            content: const Text("السلة تحتوي على عناصر من مقهى آخر. هل تريد مسحها وإعادة الطلب؟"),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("إلغاء")),
              ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("نعم")),
            ],
          ),
        );
        if (shouldClear != true) {
          return;
        }
        cart.clear();
      }
    }

    cart.replaceWithOrder(order);
    if (!mounted) return;
    context.read<NavigationProvider>().setIndex(1);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("تمت إضافة الطلب إلى السلة.")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
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
          const Text("ابدأ بطلب منتجاتك المفضلة!", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildOrderCard(OrderModel order) {
    final statusData = getStatusStyle(order.status);

    DateTime orderDate;
    try {
      orderDate = DateTime.parse(order.createdAt);
    } catch (_) {
      orderDate = DateTime.now();
    }
    String dateStr;
    try {
      dateStr = intl.DateFormat('d MMM, hh:mm a', 'ar').format(orderDate);
    } catch (_) {
      dateStr = intl.DateFormat('d MMM, hh:mm a').format(orderDate);
    }

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
                          order.displayCafeName.isNotEmpty ? order.displayCafeName : "مقهى غير محدد",
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
                    final imgPath = SmartImageUtil.getImagePath(
                      item.productName,
                      item.productImage,
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
          if (order.items.any((item) => item.options.isNotEmpty))
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: order.items
                    .where((item) => item.options.isNotEmpty)
                    .map((item) => Text(
                          '${item.productName}: ${item.options}',
                          style: TextStyle(color: Colors.grey[700], fontSize: 12),
                        ))
                    .toList(),
              ),
            ),
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
                  onPressed: () => _handleReorder(order),
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
