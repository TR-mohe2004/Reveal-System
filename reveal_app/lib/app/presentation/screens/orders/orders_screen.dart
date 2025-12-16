import 'package:flutter/material.dart';
import 'package:reveal_app/app/core/enums/view_state.dart';
import 'package:reveal_app/app/data/models/order_model.dart';
import 'package:reveal_app/app/data/services/api_service.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final ApiService _apiService = ApiService();
  List<Order> _orders = [];
  ViewState _state = ViewState.idle;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    setState(() {
      _state = ViewState.busy;
      _errorMessage = null;
    });

    try {
      final orders = await _apiService.getOrders();
      setState(() {
        _orders = orders;
        _state = ViewState.idle;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _state = ViewState.error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'طلباتي',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_state == ViewState.busy) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF2DBA9D)));
    }

    if (_state == ViewState.error) {
      return Center(child: Text(_errorMessage ?? 'حدث خطأ ما'));
    }

    if (_orders.isEmpty) {
      return const Center(child: Text('لا توجد طلبات سابقة'));
    }

    return RefreshIndicator(
      onRefresh: _fetchOrders,
      color: const Color(0xFF2DBA9D),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _orders.length,
        itemBuilder: (context, index) {
          final order = _orders[index];
          return _buildDynamicOrderCard(order);
        },
      ),
    );
  }

  // --- الكرت المحدث حسب التصميم ---
  Widget _buildDynamicOrderCard(Order order) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // 1. الرأس: اسم الكلية والشعار والتاريخ
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // النصوص (الاسم والتاريخ والسعر والحالة)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // اسم الكلية (داينمك)
                    Text(
                      order.cafeName ?? "اسم الكافيتيريا", // تأكد أن المودل يحتوي على هذا الحقل
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    
                    // التاريخ
                    Text(
                      order.createdAt.split('T')[0],
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    
                    const SizedBox(height: 4),
                    
                    // السعر + الحالة
                    Row(
                      children: [
                        Text(
                          getStatusText(order.status), // دالة تحويل الحالة لنص عربي
                          style: TextStyle(
                            color: getStatusColor(order.status),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${order.totalPrice.toStringAsFixed(0)} د.ل',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(width: 10),
              
              // شعار الكلية (داينمك)
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.orange, width: 2),
                  image: DecorationImage(
                    fit: BoxFit.cover,
                    // نستخدم صورة الشعار القادمة من الطلب، أو صورة افتراضية
                    image: (order.cafeLogo != null && order.cafeLogo!.isNotEmpty)
                        ? NetworkImage(order.cafeLogo!)
                        : const AssetImage('assets/images/logo.png') as ImageProvider,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 15),

          // 2. صور المنتجات (داينمك)
          SizedBox(
            height: 70, // ارتفاع شريط الصور
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: order.items.length,
              separatorBuilder: (c, i) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final item = order.items[index];
                return Container(
                  width: 70,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                    image: (item.productImage != null && item.productImage!.isNotEmpty)
                        ? DecorationImage(
                            image: NetworkImage(item.productImage!), // صورة المنتج (بيتزا مثلا)
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: Stack(
                    children: [
                      // إذا لم تكن هناك صورة، نعرض أيقونة
                      if (item.productImage == null || item.productImage!.isEmpty)
                        const Center(child: Icon(Icons.fastfood, color: Colors.grey)),
                      
                      // الكمية (x2)
                      Positioned(
                        bottom: 4,
                        left: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            "x${item.quantity}",
                            style: const TextStyle(color: Colors.white, fontSize: 10),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 15),

          // 3. زر إعادة الطلب
          SizedBox(
            width: double.infinity,
            height: 45,
            child: ElevatedButton(
              onPressed: () {
                // كود إعادة الطلب هنا
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2DBA9D), // اللون التركواز/الأخضر
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.refresh, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text(
                    "أعد الطلب",
                    style: TextStyle(
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
    );
  }

  // دوال مساعدة للحالة والألوان
  String getStatusText(String status) {
    switch (status) {
      case 'PENDING': return 'قيد الانتظار';
      case 'PREPARING': return 'جاري التحضير';
      case 'READY': return 'طلبك جاهز للاستلام'; // النص الذي طلبته
      case 'COMPLETED': return 'مكتمل';
      case 'CANCELLED': return 'ملغي';
      default: return status;
    }
  }

  Color getStatusColor(String status) {
    switch (status) {
      case 'READY': return const Color(0xFF2DBA9D); // أخضر
      case 'CANCELLED': return Colors.red;
      case 'PENDING': return Colors.orange;
      default: return Colors.grey;
    }
  }
}

/* ملاحظة للتعديل في OrderModel:
تأكد من إضافة الحقول التالية في كلاس Order وكلاس OrderItem:

class Order {
  // ... الحقول القديمة
  final String? cafeName; // اسم الكلية
  final String? cafeLogo; // رابط شعار الكلية
  
  // ...
}

class OrderItem {
  // ... الحقول القديمة
  final String? productImage; // رابط صورة الوجبة
  
  // ...
}
*/