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

class OrderModel {
  final int id;
  final String orderNumber;
  final double totalPrice;
  final String status;
  final String createdAt;
  final List<OrderItem> items;
  final String? cafeId;
  final String? cafeName;
  final String? cafeLogo;

  OrderModel({
    required this.id,
    required this.orderNumber,
    required this.totalPrice,
    required this.status,
    required this.createdAt,
    required this.items,
    this.cafeId,
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
      cafeId: json['cafe_id']?.toString() ?? json['college_id']?.toString(),
      cafeName: json['cafe_name'] ?? json['college_name'] ?? 'مقهى غير محدد',
      cafeLogo: json['cafe_logo'] ?? json['image_url'],
    );
  }

  DateTime get dateObject {
    try {
      return DateTime.parse(createdAt);
    } catch (e) {
      return DateTime.now();
    }
  }

  String get displayCafeName {
    return _normalizeCafeName(cafeName ?? '');
  }

  String get statusText {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return 'بانتظار الموافقة';
      case 'ACCEPTED':
        return 'تم قبول طلبك';
      case 'PREPARING':
        return 'طلبك قيد التحضير';
      case 'READY':
        return 'طلبك جاهز للاستلام';
      case 'COMPLETED':
        return 'تم استلام الطلب';
      case 'CANCELLED':
        return 'تم إلغاء الطلب';
      default:
        return status;
    }
  }
}

class OrderItem {
  final int productId;
  final String productName;
  final int quantity;
  final double price;
  final String? productImage;
  final String options;

  OrderItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    this.price = 0.0,
    this.productImage,
    this.options = '',
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      productId: json['product_id'] ?? 0,
      productName: json['product_name'] ?? 'منتج',
      quantity: json['quantity'] ?? 1,
      price: double.tryParse((json['price'] ?? json['product_price'] ?? 0).toString()) ?? 0.0,
      productImage: json['product_image'] ?? json['image_url'] ?? json['image'],
      options: json['options']?.toString() ?? '',
    );
  }
}
