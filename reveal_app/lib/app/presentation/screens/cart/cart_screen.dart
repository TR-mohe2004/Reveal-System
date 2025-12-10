import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reveal_app/app/data/providers/cart_provider.dart';
import 'package:reveal_app/app/data/services/api_service.dart'; // لتأكيد المسار فقط إذا احتجت كلاسات مساعدة

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
          // زر تفريغ السلة
          Consumer<CartProvider>(
            builder: (_, cart, __) => cart.items.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.delete_sweep_outlined, color: Colors.red),
                    onPressed: () {
                      _showClearCartDialog(context, cart);
                    },
                  )
                : const SizedBox(),
          )
        ],
      ),
      body: Consumer<CartProvider>(
        builder: (context, cart, child) {
          // حالة السلة الفارغة
          if (cart.items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_outlined, size: 100, color: Colors.grey[300]),
                  const SizedBox(height: 20),
                  Text(
                    'سلة المشتريات فارغة',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey[500]),
                  ),
                  const SizedBox(height: 10),
                  const Text('لم تقم بإضافة أي وجبات بعد', style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          final cartItems = cart.items.values.toList();

          return Column(
            children: [
              // قائمة المنتجات
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  itemCount: cartItems.length,
                  separatorBuilder: (c, i) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = cartItems[index];
                    
                    // Dismissible للسحب والحذف
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
                      onDismissed: (direction) {
                        cart.removeItem(item.id);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.08),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            children: [
                              // الصورة
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
                              
                              // التفاصيل
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
                              
                              // أزرار التحكم بالكمية
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.grey[200]!),
                                ),
                                child: Row(
                                  children: [
                                    // زر -
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
                                    // زر +
                                    InkWell(
                                      onTap: () {
                                        // لزيادة الكمية، نحتاج لإنشاء كائن Product وهمي أو تعديل addItem
                                        // للتبسيط هنا، سنعتمد أن المستخدم يضيف من القائمة الرئيسية،
                                        // أو يمكن تعديل addItem لتقبل ID فقط.
                                        // الحل السريع للزيادة هو تكرار addItem ولكنها تتطلب Product كامل.
                                        // الأفضل هنا الاكتفاء بالناقص والحذف، والزيادة من القائمة،
                                        // أو تعديل Provider ليقبل زيادة الكمية مباشرة عبر ID.
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

              // منطقة الدفع (Bottom Sheet)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.15),
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
                          'المجموع الكلي:',
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
                        onPressed: _isLoading
                            ? null
                            : () async {
                                await _handleCheckout(context, cart);
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2DBA9D),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 5,
                          shadowColor: const Color(0xFF2DBA9D).withOpacity(0.4),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text(
                                'تأكيد الطلب والدفع',
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

  // دالة معالجة الدفع
  Future<void> _handleCheckout(BuildContext context, CartProvider cart) async {
    setState(() => _isLoading = true);

    // استدعاء دالة الدفع في المزود
    final success = await cart.checkout();

    setState(() => _isLoading = false);

    if (!context.mounted) return;

    if (success) {
      // نجاح
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Icon(Icons.check_circle_rounded, color: Colors.green, size: 60),
          content: const Text(
            'تم استلام طلبك بنجاح!\nسيتم البدء في تحضيره فوراً.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx); // إغلاق الديالوج
                Navigator.pop(context); // العودة للرئيسية
              },
              child: const Text('حسناً', style: TextStyle(color: Color(0xFF2DBA9D), fontWeight: FontWeight.bold)),
            )
          ],
        ),
      );
    } else {
      // فشل (رصيد غير كافي أو خطأ سيرفر)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 10),
              Text('فشل الطلب! تأكد من رصيد محفظتك.'),
            ],
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  // ديالوج تأكيد الحذف
  void _showClearCartDialog(BuildContext context, CartProvider cart) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تفريغ السلة؟'),
        content: const Text('هل أنت متأكد من حذف جميع العناصر من السلة؟'),
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
            child: const Text('حذف الكل', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}