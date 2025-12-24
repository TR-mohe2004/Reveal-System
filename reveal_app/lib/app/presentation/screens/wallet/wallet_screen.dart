import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reveal_app/app/core/enums/view_state.dart';
import 'package:reveal_app/app/data/providers/wallet_provider.dart';
import 'wallet_history_screen.dart';
import 'wallet_transfer_screen.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  @override
  void initState() {
    super.initState();
    // جلب البيانات فور فتح الشاشة
    // نستخدم addPostFrameCallback لضمان عدم حدوث خطأ أثناء بناء الواجهة
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WalletProvider>().fetchWalletData();
    });
  }

  Future<void> _handleTransferToCafe(BuildContext context, double currentBalance) async {
    final TextEditingController amountController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("دفع لمقهى الكلية", textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("أدخل القيمة المراد دفعها:"),
            const SizedBox(height: 10),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "القيمة (د.ل)",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("إلغاء", style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (amountController.text.isNotEmpty) {
                final amount = double.tryParse(amountController.text.trim().replaceAll(',', '.')) ?? 0.0;
                if (amount > 0 && amount <= currentBalance) {
                  final success = await context.read<WalletProvider>().withdrawFromWallet(amount: amount);
                  if (!context.mounted) {
                    return;
                  }
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success ? "تم خصم $amount د.ل بنجاح" : "تعذر خصم المبلغ",
                      ),
                      backgroundColor: success ? null : Colors.red,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("رصيد غير كافٍ أو قيمة غير صحيحة"), backgroundColor: Colors.red),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF009688)),
            child: const Text("تأكيد"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Consumer للاستماع للتغييرات في البروفايدر
    return Consumer<WalletProvider>(
      builder: (context, provider, child) {
        
        // 1. حالة التحميل (لأول مرة)
        if (provider.state == ViewState.busy && provider.wallet == null) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF009688)));
        }

        // 2. حالة الخطأ
        if (provider.state == ViewState.error && provider.wallet == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 60, color: Colors.red[300]),
                const SizedBox(height: 10),
                Text(provider.errorMessage ?? "حدث خطأ غير متوقع"),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => provider.fetchWalletData(),
                  child: const Text("إعادة المحاولة"),
                )
              ],
            ),
          );
        }

        // 3. حالة عرض البيانات (Retrieved)
        final wallet = provider.wallet;
        
        // إذا لم تكن هناك محفظة (null)، نعرض واجهة فارغة أو زر لإنشاء محفظة
        if (wallet == null) {
           return const Center(child: Text("لا توجد بيانات محفظة متاحة"));
        }

        return RefreshIndicator(
          onRefresh: () => provider.fetchWalletData(),
          color: const Color(0xFF009688),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 10),
                
                // --- بطاقة المحفظة ---
                Container(
                  constraints: const BoxConstraints(minHeight: 220),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF009688), Color(0xFF4DB6AC)],
                    ),
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        top: -50,
                        left: -50,
                        child: Container(
                          width: 150,
                          height: 150,
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), shape: BoxShape.circle),
                        ),
                      ),
                      
                      Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // الصف العلوي: الاسم والكلية
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        wallet.userFullName, // الاسم من السيرفر
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        wallet.college, // الكلية من السيرفر
                                        style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.nfc, color: Colors.white70, size: 30),
                              ],
                            ),

                            // الوسط: الرصيد
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "الرصيد المتاح",
                                  style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Text(
                                      wallet.balance.toStringAsFixed(2), // الرصيد من السيرفر
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 36,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      wallet.currency, // العملة من السيرفر
                                      style: const TextStyle(color: Colors.white70, fontSize: 20),
                                    ),
                                  ],
                                ),
                              ],
                            ),

                            // الأسفل: كود المحفظة
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "كود الربط (للشحن)",
                                      style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12),
                                    ),
                                    SelectableText( // جعل النص قابل للنسخ
                                      wallet.linkCode.isEmpty ? "---" : wallet.linkCode,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        letterSpacing: 2,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // --- الأزرار ---
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 16,
                  runSpacing: 12,
                  children: [
                    _buildActionButton(
                      icon: Icons.payment,
                      label: "دفع",
                      onTap: () => _handleTransferToCafe(context, wallet.balance),
                    ),
                    _buildActionButton(
                      icon: Icons.swap_horiz,
                      label: "تحويل",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const WalletTransferScreen()),
                        );
                      },
                    ),
                    _buildActionButton(
                      icon: Icons.history,
                      label: "السجل",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const WalletHistoryScreen()),
                        );
                      },
                    ),
                    _buildActionButton(
                      icon: Icons.refresh, // زر تحديث يدوي إضافي
                      label: "تحديث",
                      onTap: () => provider.fetchWalletData(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButton({required IconData icon, required String label, required VoidCallback onTap}) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, spreadRadius: 2),
              ],
            ),
            child: Icon(icon, color: const Color(0xFF009688), size: 32),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}
