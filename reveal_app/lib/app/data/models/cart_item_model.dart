class CartItem {
  final String id;
  final String productId;
  final String name;
  final int quantity;
  final double price;
  final String imageUrl;
  final String collegeId;
  final String collegeName;
  final String options;

  CartItem({
    required this.id,
    required this.productId,
    required this.name,
    required this.quantity,
    required this.price,
    required this.imageUrl,
    required this.collegeId,
    required this.collegeName,
    this.options = '',
  });

  double get totalItemPrice => price * quantity;

  factory CartItem.fromJson(Map<String, dynamic> json) {
    final productId = json['product_id']?.toString() ?? json['id']?.toString() ?? '';
    return CartItem(
      id: json['cart_id']?.toString() ?? productId,
      productId: productId,
      name: json['product_name'] ?? json['name'] ?? '',
      quantity: int.tryParse(json['quantity'].toString()) ?? 1,
      price: double.tryParse(json['price'].toString()) ?? 0.0,
      imageUrl: json['image_url'] ?? json['image'] ?? '',
      collegeId: json['college_id']?.toString() ?? '',
      collegeName: json['college_name'] ?? '',
      options: json['options']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'qty': quantity,
      'quantity': quantity,
      'price': price,
      'college_id': collegeId,
      'options': options,
    };
  }
}
