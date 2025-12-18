class OrderModel {
  final int id;
  final String orderNumber;
  final double totalPrice;
  final String status;
  final String createdAt;
  final List<OrderItem> items;

  // الحقول الإضافية للعرض
  final String? cafeName;
  final String? cafeLogo;

  OrderModel({
    required this.id,
    required this.orderNumber,
    required this.totalPrice,
    required this.status,
    required this.createdAt,
    required this.items,
    this.cafeName,
    this.cafeLogo,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      orderNumber: json['order_number']?.toString() ?? '---',
      totalPrice: double.tryParse(json['total_price'].toString()) ?? 0.0,
      status: json['status'] ?? 'PENDING',
      createdAt: json['created_at'] ?? DateTime.now().toString(),
      items: (json['items'] as List?)?.map((i) => OrderItem.fromJson(i)).toList() ?? [],
      
      // استقبال البيانات
      cafeName: json['cafe_name'] ?? json['college_name'] ?? 'الكافيتيريا',
      cafeLogo: json['cafe_logo'] ?? json['image_url'],
    );
  }

  // تحويل التاريخ من نص إلى كائن DateTime لسهولة التنسيق
  DateTime get dateObject {
    try {
      return DateTime.parse(createdAt);
    } catch (e) {
      return DateTime.now();
    }
  }

  String get statusText {
    switch (status.toUpperCase()) {
      case 'PENDING': return 'قيد الانتظار';
      case 'PREPARING': return 'جاري التحضير';
      case 'READY': return 'جاهز للاستلام';
      case 'COMPLETED': return 'مكتمل';
      case 'CANCELLED': return 'ملغي';
      default: return status;
    }
  }
}

class OrderItem {
  final int productId;
  final String productName;
  final int quantity;
  final double price; // مفيدة لو احتجت تعرض سعر القطعة
  final String? productImage;

  OrderItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    this.price = 0.0,
    this.productImage,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      productId: json['product_id'] ?? 0,
      productName: json['product_name'] ?? 'منتج',
      quantity: json['quantity'] ?? 1,
      price: double.tryParse(json['price'].toString()) ?? 0.0,
      productImage: json['product_image'] ?? json['image_url'],
    );
  }
}