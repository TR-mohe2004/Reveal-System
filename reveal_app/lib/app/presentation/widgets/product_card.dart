import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reveal_app/app/data/models/product_model.dart';
import 'package:reveal_app/app/data/providers/cart_provider.dart';
import 'package:reveal_app/app/data/providers/product_provider.dart';

class ProductCard extends StatelessWidget {
  final ProductModel product;
  const ProductCard({super.key, required this.product});

  static final Random _random = Random();
  static const String _defaultAsset = 'assets/images/burger.png';

  bool get _hasRemoteImage {
    final url = product.imageUrl.trim().toLowerCase();
    return url.isNotEmpty && url != 'null';
  }

  // --- دالة اختيار صورة عشوائية ---
  String _chooseFallbackAsset() {
    final normalized = product.category.toLowerCase();
    final pools = <String, List<String>>{
      'pizza': _assetPool('assets/images/pizza', 5),
      'بيتزا': _assetPool('assets/images/pizza', 5),
      'burger': _assetPool('assets/images/burger', 5),
      'برجر': _assetPool('assets/images/burger', 5),
      'dessert': _assetPool('assets/images/dessert', 4),
      'حلو': _assetPool('assets/images/dessert', 4),
      'drink': _assetPool('assets/images/drinks', 4),
      'مشروب': _assetPool('assets/images/drinks', 4),
    };

    for (final entry in pools.entries) {
      if (normalized.contains(entry.key)) {
        return _pickRandom(entry.value);
      }
    }

    return _pickRandom([
      _defaultAsset,
      'assets/images/pizza.png',
      'assets/images/dessert.png',
      'assets/images/drinks.png',
    ]);
  }

  List<String> _assetPool(String baseName, int count) {
    return [ '$baseName.png' ]; 
  }

  String _pickRandom(List<String> items) => items[_random.nextInt(items.length)];

  Widget _buildAssetImage(String assetPath) {
    return Image.asset(
      assetPath,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Image.asset(_defaultAsset, fit: BoxFit.cover),
    );
  }

  // --- دالة إضافة للسلة ---
  void _addToCart(BuildContext context) {
    final cart = context.read<CartProvider>();
    try {
      cart.addItem(product);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم إضافة ${product.name} إلى السلة 🛒'),
          backgroundColor: const Color(0xFF2DBA9D),
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isFavorite = product.isFavorite;
    final priceText = product.price.toStringAsFixed(2);
    final cafeName = product.cafeName.isNotEmpty ? product.cafeName : product.collegeName;
    final fallbackAsset = _chooseFallbackAsset();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // --- صورة المنتج وزر المفضلة ---
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: SizedBox(
                  height: 170,
                  child: _hasRemoteImage
                      ? Image.network(
                          product.imageUrl,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          errorBuilder: (_, __, ___) => _buildAssetImage(fallbackAsset),
                        )
                      : _buildAssetImage(fallbackAsset),
                ),
              ),
              
              // زر المفضلة (القلب)
              Positioned(
                top: 10,
                left: 10,
                child: Material(
                  color: Colors.white,
                  shape: const CircleBorder(),
                  elevation: 2,
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () {
                      // تم التصحيح: إرسال ID كنص مباشرة بدون int.parse
                      context.read<ProductProvider>().toggleFavorite(product.id);
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        size: 22,
                        color: isFavorite ? Colors.red : Colors.grey,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // --- تفاصيل المنتج ---
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  textDirection: TextDirection.rtl,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (cafeName.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        cafeName,
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                        textDirection: TextDirection.rtl,
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.store, size: 14, color: Colors.grey),
                    ],
                  ),
                ],
                
                const SizedBox(height: 12),
                
                // السعر وزر الإضافة
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // السعر
                    Text(
                      '$priceText د.ل',
                      style: const TextStyle(
                        color: Color(0xFF2DBA9D), 
                        fontWeight: FontWeight.bold, 
                        fontSize: 18
                      ),
                      textDirection: TextDirection.rtl,
                    ),

                    // زر الإضافة للسلة
                    ElevatedButton(
                      onPressed: () => _addToCart(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2DBA9D),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.add, size: 18),
                          SizedBox(width: 4),
                          Text('إضافة', style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
                
                // الوصف
                if (product.description.isNotEmpty && product.description != 'null') ...[
                  const SizedBox(height: 8),
                  Text(
                    product.description,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    textDirection: TextDirection.rtl,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
