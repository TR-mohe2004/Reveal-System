import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reveal_app/app/data/providers/cart_provider.dart';
import 'package:reveal_app/app/data/models/product_model.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        title: const Text(
          'سلة المشتريات',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          Consumer<CartProvider>(
            builder: (_, cart, __) => cart.items.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.delete_sweep_outlined, color: Colors.red),
                    onPressed: () => _showClearCartDialog(context, cart),
                  )
                : const SizedBox.shrink(),
          )
        ],
      ),
      body: Consumer<CartProvider>(
        builder: (context, cart, child) {
          if (cart.items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_outlined, size: 100, color: Colors.grey.shade300),
                  const SizedBox(height: 20),
                  Text(
                    'السلة فارغة',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey.shade500),
                  ),
                  const SizedBox(height: 10),
                  const Text('أضف منتجاتك المفضلة من القائمة', style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          final cartItems = cart.items.values.toList();

          return Column(
            children: [
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  itemCount: cartItems.length,
                  separatorBuilder: (c, i) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = cartItems[index];

                    return Dismissible(
                      key: ValueKey(item.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        padding: const EdgeInsets.only(left: 20),
                        alignment: Alignment.centerLeft,
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: const Icon(Icons.delete, color: Colors.white, size: 30),
                      ),
                      onDismissed: (direction) => cart.removeItem(item.id),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withValues(alpha: 0.08),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color: Colors.grey[100],
                                  image: item.imageUrl.isNotEmpty
                                      ? DecorationImage(
                                          image: NetworkImage(item.imageUrl),
                                          fit: BoxFit.cover,
                                        )
                                      : null,
                                ),
                                child: item.imageUrl.isEmpty
                                    ? const Icon(Icons.fastfood, color: Colors.grey)
                                    : null,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${(item.price * item.quantity).toStringAsFixed(2)} د.ل',
                                      style: const TextStyle(
                                        color: Color(0xFF2DBA9D),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.grey.shade200),
                                ),
                                child: Row(
                                  children: [
                                    InkWell(
                                      onTap: () => cart.removeSingleItem(item.id),
                                      child: const Padding(
                                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        child: Icon(Icons.remove, size: 18, color: Colors.grey),
                                      ),
                                    ),
                                    Text(
                                      '${item.quantity}',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    InkWell(
                                      onTap: () {
                                        final product = ProductModel(
                                          id: item.id,
                                          name: item.name,
                                          price: item.price,
                                          imageUrl: item.imageUrl,
                                          description: '',
                                          category: '',
                                          collegeId: item.collegeId,
                                          collegeName: item.collegeName,
                                        );
                                        cart.addItem(product);
                                      },
                                      child: const Padding(
                                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        child: Icon(Icons.add, size: 18, color: Color(0xFF2DBA9D)),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.15),
                      blurRadius: 20,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'الإجمالي الكلي:',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                        Text(
                          '${cart.totalAmount.toStringAsFixed(2)} د.ل',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2DBA9D),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : () => _handleCheckout(context, cart),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2DBA9D),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 5,
                          shadowColor: const Color(0xFF2DBA9D).withValues(alpha: 0.4),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text(
                                'تأكيد الطلب',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _handleCheckout(BuildContext context, CartProvider cart) async {
    setState(() => _isLoading = true);

    try {
      final success = await cart.checkout();

      if (!context.mounted) return;

      if (success) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Icon(Icons.check_circle_rounded, color: Colors.green, size: 60),
            content: const Text(
              'تم تأكيد الطلب!\nسنبدأ في تحضير طلبك الآن.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pop(context);
                },
                child: const Text('حسناً', style: TextStyle(color: Color(0xFF2DBA9D), fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(child: Text('حدث خطأ: ${e.toString()}')),
            ],
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showClearCartDialog(BuildContext context, CartProvider cart) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('مسح السلة'),
        content: const Text('هل تريد مسح جميع المنتجات من السلة؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              cart.clear();
              Navigator.pop(ctx);
            },
            child: const Text('مسح الكل', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
