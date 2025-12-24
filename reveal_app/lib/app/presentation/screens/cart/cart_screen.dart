import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reveal_app/app/data/providers/cart_provider.dart';
import 'package:reveal_app/app/data/providers/navigation_provider.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  bool _isLoading = false;
  String _paymentMethod = 'WALLET';

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
                    final isNetworkImage = item.imageUrl.startsWith('http');
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
                            BoxShadow(color: Colors.grey.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 4)),
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
                                          image: isNetworkImage
                                              ? NetworkImage(item.imageUrl)
                                              : AssetImage(item.imageUrl) as ImageProvider,
                                          fit: BoxFit.cover,
                                        )
                                      : null,
                                ),
                                child: item.imageUrl.isEmpty ? const Icon(Icons.fastfood, color: Colors.grey) : null,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
                                    if (item.options.isNotEmpty)
                                      Text(item.options, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                                    if (item.options.isNotEmpty)
                                      const SizedBox(height: 4),
                                    const SizedBox(height: 4),
                                    Text('${(item.price * item.quantity).toStringAsFixed(2)} د.ل', style: const TextStyle(color: Color(0xFF2DBA9D), fontWeight: FontWeight.bold, fontSize: 14)),
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
                                      child: const Padding(padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4), child: Icon(Icons.remove, size: 18, color: Colors.grey)),
                                    ),
                                    Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                    InkWell(
                                      onTap: () => cart.incrementItem(item.id), // ✅ تم استدعاء الدالة بشكل صحيح
                                      child: const Padding(padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4), child: Icon(Icons.add, size: 18, color: Color(0xFF2DBA9D))),
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
                  boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.15), blurRadius: 20, offset: const Offset(0, -5))],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('الإجمالي الكلي:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                        Text('${cart.totalAmount.toStringAsFixed(2)} د.ل', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF2DBA9D))),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        'طريقة الدفع',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildPaymentOption(value: 'WALLET', label: 'المحفظة', icon: Icons.account_balance_wallet),
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
                        ),
                        child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('تأكيد الطلب', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
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

  Widget _buildPaymentOption({required String value, required String label, required IconData icon}) {
    final selected = _paymentMethod == value;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _paymentMethod = value),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF2DBA9D) : Colors.grey[100],
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: selected ? const Color(0xFF2DBA9D) : Colors.grey.shade200),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: selected ? Colors.white : Colors.grey, size: 20),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleCheckout(BuildContext context, CartProvider cart) async {
    setState(() => _isLoading = true);
    try {
      final success = await cart.checkout(paymentMethod: _paymentMethod);
      if (!context.mounted) return;
      if (success) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Icon(Icons.check_circle_rounded, color: Colors.green, size: 60),
            content: const Text('تم تأكيد الطلب!\nسنبدأ في تحضير طلبك الآن.', textAlign: TextAlign.center, style: TextStyle(fontSize: 16)),
            actions: [
              TextButton(onPressed: () {Navigator.pop(ctx); context.read<NavigationProvider>().setIndex(4);}, child: const Text('حسناً', style: TextStyle(color: Color(0xFF2DBA9D), fontWeight: FontWeight.bold))),
            ],
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      final message = _friendlyOrderError(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _friendlyOrderError(Object error) {
    final message = error.toString();
    if (message.contains('401') || message.contains('Not authenticated') || message.contains('Unauthorized')) {
      return 'انتهت الجلسة. يرجى تسجيل الدخول مرة أخرى.';
    }
    if (message.contains('balance') || message.contains('رصيد') || message.contains('wallet')) {
      return 'رصيد المحفظة غير كافٍ لإتمام الطلب.';
    }
    if (message.contains('مقهى') || message.contains('cafe') || message.contains('single')) {
      return 'الطلب يجب أن يكون من مقهى واحد.';
    }
    return 'تعذر إرسال الطلب. حاول مرة أخرى.';
  }

  void _showClearCartDialog(BuildContext context, CartProvider cart) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('مسح السلة'),
        content: const Text('هل تريد مسح جميع المنتجات من السلة؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء', style: TextStyle(color: Colors.grey))),
          TextButton(onPressed: () {cart.clear(); Navigator.pop(ctx);}, child: const Text('مسح الكل', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }
}
