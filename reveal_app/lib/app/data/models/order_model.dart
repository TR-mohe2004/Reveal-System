class Order {
  final int id;
  final String orderNumber;
  final double totalPrice;
  final String status;
  final String createdAt;
  final List<OrderItem> items;

  // --- الحقول الجديدة التي أضفناها لتصحيح الأخطاء ---
  final String? cafeName; // اسم الكافيتيريا
  final String? cafeLogo; // شعار الكافيتيريا

  Order({
    required this.id,
    required this.orderNumber,
    required this.totalPrice,
    required this.status,
    required this.createdAt,
    required this.items,
    this.cafeName, // اختياري
    this.cafeLogo, // اختياري
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'],
      orderNumber: json['order_number'] ?? '---',
      totalPrice: double.tryParse(json['total_price'].toString()) ?? 0.0,
      status: json['status'] ?? 'PENDING',
      createdAt: json['created_at'] ?? '',
      items: (json['items'] as List?)?.map((i) => OrderItem.fromJson(i)).toList() ?? [],
      
      // استقبال البيانات الجديدة من الباك اند (أو وضع قيم افتراضية)
      cafeName: json['cafe_name'] ?? 'اسم الكافيتيريا', 
      cafeLogo: json['cafe_logo'], 
    );
  }

  String get statusText {
    switch (status) {
      case 'PENDING':
        return 'قيد الانتظار';
      case 'PREPARING':
        return 'جاري التحضير';
      case 'READY':
        return 'جاهز للاستلام';
      case 'COMPLETED':
        return 'مكتمل';
      case 'CANCELLED':
        return 'ملغي';
      default:
        return status;
    }
  }
}

class OrderItem {
  final int productId;
  final String productName;
  final int quantity;
  
  // --- حقل صورة المنتج الجديد ---
  final String? productImage; 

  OrderItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    this.productImage, // اختياري
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      productId: json['product_id'],
      productName: json['product_name'] ?? 'منتج',
      quantity: json['quantity'] ?? 1,
      // استقبال صورة المنتج
      productImage: json['product_image'], 
    );
  }
}