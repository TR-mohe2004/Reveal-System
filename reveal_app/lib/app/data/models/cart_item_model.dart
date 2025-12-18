class CartItem {
  final String id;          // معرف المنتج
  final String name;        // اسم المنتج
  final int quantity;       // الكمية
  final double price;       // السعر الفردي
  final String imageUrl;    // الصورة
  final String collegeId;   // معرف الكلية
  final String collegeName; // اسم الكلية

  CartItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.price,
    required this.imageUrl,
    required this.collegeId,
    required this.collegeName,
  });

  // دالة لحساب السعر الإجمالي لهذا العنصر (السعر * الكمية)
  double get totalItemPrice => price * quantity;

  // تحويل من JSON (عند استرجاع السلة المحفوظة)
  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['product_id']?.toString() ?? json['id'].toString(),
      name: json['product_name'] ?? json['name'] ?? '',
      quantity: int.tryParse(json['quantity'].toString()) ?? 1,
      price: double.tryParse(json['price'].toString()) ?? 0.0,
      imageUrl: json['image_url'] ?? json['image'] ?? '',
      collegeId: json['college_id']?.toString() ?? '',
      collegeName: json['college_name'] ?? '',
    );
  }

  // تحويل إلى JSON (لإرسال الطلب للباك إند)
  Map<String, dynamic> toJson() {
    return {
      'product_id': id,
      'qty': quantity, // الباك إند عادة يتوقع qty أو quantity
      'quantity': quantity,
      'price': price,
      'college_id': collegeId,
    };
  }
}