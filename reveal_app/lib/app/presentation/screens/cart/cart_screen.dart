import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reveal_app/app/data/providers/cart_provider.dart';
import 'package:reveal_app/app/data/services/api_service.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        title: const Text('سلة المشتريات', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Consumer<CartProvider>(
        builder: (context, cart, child) {
          if (cart.items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text('سلة المشتريات فارغة', style: TextStyle(fontSize: 18, color: Colors.grey[500])),
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
                  padding: const EdgeInsets.all(16),
                  itemCount: cartItems.length,
                  separatorBuilder: (c, i) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = cartItems[index];
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2)),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(10),
                        leading: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: Colors.grey[200],
                            image: item.imageUrl.isNotEmpty
                                ? DecorationImage(image: NetworkImage(item.imageUrl), fit: BoxFit.cover)
                                : null,
                          ),
                          child: item.imageUrl.isEmpty ? const Icon(Icons.fastfood, color: Colors.grey) : null,
                        ),
                        title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${item.price} د.ل', style: const TextStyle(color: Color(0xFF2DBA9D), fontWeight: FontWeight.bold)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                              onPressed: () {
                                if (item.quantity > 1) {
                                  // تقليل الكمية (يحتاج دالة في Provider)
                                  // حالياً سنحذف العنصر إذا أردت التبسيط
                                  cart.removeItem(item.id); 
                                } else {
                                  cart.removeItem(item.id);
                                }
                              },
                            ),
                            Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            // زر زيادة الكمية يمكن إضافته هنا إذا كان الـ Provider يدعمه
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              
              // ملخص الطلب وزر الدفع
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                  boxShadow: [
                    BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, -5)),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('المجموع الكلي:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Text(
                          '${cart.totalAmount.toStringAsFixed(2)} د.ل',
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2DBA9D)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // زر تأكيد الطلب
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: () async {
                          // 1. إظهار دائرة التحميل
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (_) => const Center(child: CircularProgressIndicator(color: Colors.white)),
                          );

                          // 2. تحضير البيانات
                          final apiService = ApiService();
                          final List<Map<String, dynamic>> orderItems = cartItems.map((item) {
                            return {
                              'product_id': item.id, // تأكد أن الـ ID هو رقم المنتج في قاعدة البيانات
                              'quantity': item.quantity,
                            };
                          }).toList();

                          // 3. إرسال الطلب
                          final success = await apiService.createOrder(cart.totalAmount, orderItems);

                          // 4. إغلاق دائرة التحميل
                          if (context.mounted) Navigator.pop(context);

                          // 5. التعامل مع النتيجة
                          if (success) {
                            cart.clear(); // تفريغ السلة
                            if (context.mounted) {
                              // إظهار رسالة نجاح
                              showDialog(
                                context: context,
                                builder: (c) => AlertDialog(
                                  title: const Icon(Icons.check_circle, color: Colors.green, size: 60),
                                  content: const Text('تم إرسال طلبك بنجاح! سيتم تجهيزه قريباً.', textAlign: TextAlign.center),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pop(c);
                                        // يمكن التوجيه لصفحة "طلباتي" هنا
                                      },
                                      child: const Text('حسناً'),
                                    )
                                  ],
                                ),
                              );
                            }
                          } else {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('فشل الطلب. تأكد من أن رصيدك كافٍ!'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2DBA9D),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          elevation: 0,
                        ),
                        child: const Text(
                          'تأكيد الطلب والدفع',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
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
}