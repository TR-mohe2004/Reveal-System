class Order {
  final int id;
  final String orderNumber;
  final double totalPrice;
  final String status;
  final String createdAt;
  final List<OrderItem> items;

  Order({
    required this.id,
    required this.orderNumber,
    required this.totalPrice,
    required this.status,
    required this.createdAt,
    required this.items,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'],
      orderNumber: json['order_number'] ?? '---',
      totalPrice: double.tryParse(json['total_price'].toString()) ?? 0.0,
      status: json['status'] ?? 'PENDING',
      createdAt: json['created_at'] ?? '',
      items: (json['items'] as List?)?.map((i) => OrderItem.fromJson(i)).toList() ?? [],
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

  OrderItem({
    required this.productId,
    required this.productName,
    required this.quantity,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      productId: json['product_id'],
      productName: json['product_name'] ?? 'منتج',
      quantity: json['quantity'] ?? 1,
    );
  }
}
