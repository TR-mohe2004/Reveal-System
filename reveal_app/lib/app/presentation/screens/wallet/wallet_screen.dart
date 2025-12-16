// lib/app/presentation/screens/wallet/wallet_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reveal_app/app/core/enums/view_state.dart';
import 'package:reveal_app/app/data/providers/wallet_provider.dart';
import 'package:reveal_app/app/presentation/widgets/my_drawer.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  
  @override
  void initState() {
    super.initState();
    // ✅ جلب البيانات باستخدام الاسم الصحيح للدالة
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WalletProvider>().fetchWalletData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'المحفظة الإلكترونية',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            // ✅ زر التحديث اليدوي
            onPressed: () => context.read<WalletProvider>().fetchWalletData(),
            icon: const Icon(Icons.refresh, color: Color(0xFF2DBA9D)),
          ),
        ],
      ),
      drawer: const MyDrawer(), // القائمة الجانبية
      body: Consumer<WalletProvider>(
        builder: (context, provider, child) {
          
          // 1. حالة التحميل
          if (provider.state == ViewState.busy) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF2DBA9D)),
            );
          }

          final wallet = provider.wallet;

          // 2. حالة الخطأ أو عدم وجود محفظة
          if (wallet == null || provider.state == ViewState.error) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.warning_amber_rounded, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    provider.errorMessage ?? 'لا يمكن الوصول لبيانات المحفظة',
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    // ✅ زر إعادة المحاولة
                    onPressed: () => provider.fetchWalletData(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('إعادة المحاولة'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2DBA9D),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            );
          }

          // 3. حالة عرض البيانات
          return RefreshIndicator(
            // ✅ السحب للتحديث
            onRefresh: () async => await provider.fetchWalletData(),
            color: const Color(0xFF2DBA9D),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // --- بطاقة المحفظة (الرصيد + الكلية) ---
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2DBA9D), Color(0xFF168C72)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2DBA9D).withOpacity(0.4),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // الصف العلوي: اسم الكلية
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'بطاقة الطالب',
                              style: TextStyle(color: Colors.white70, fontSize: 14),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                wallet.college, 
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 25),

                        // الرصيد
                        const Text(
                          'الرصيد المتاح',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        const SizedBox(height: 5),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              wallet.balance.toStringAsFixed(2),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 42,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              wallet.currency,
                              style: const TextStyle(color: Colors.white, fontSize: 20),
                            ),
                          ],
                        ),
                        const SizedBox(height: 25),

                        // كود الربط (QR Link Code)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'كود الاستلام (الربط)',
                                    style: TextStyle(color: Colors.white70, fontSize: 12),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    wallet.linkCode,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 2.0,
                                    ),
                                  ),
                                ],
                              ),
                              const Icon(Icons.qr_code_2, color: Colors.white, size: 35),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // --- أزرار العمليات ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildActionButton(
                        icon: Icons.add_card_rounded,
                        label: 'شحن',
                        onTap: () {
                          // إضافة وظيفة الشحن
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("سيتم تفعيل الشحن قريباً")),
                          );
                        },
                      ),
                      _buildActionButton(
                        icon: Icons.history_rounded,
                        label: 'السجل',
                        onTap: () {
                           ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("سجل العمليات قادم قريباً")),
                          );
                        },
                      ),
                      _buildActionButton(
                        icon: Icons.send_rounded,
                        label: 'تحويل',
                        onTap: () {
                           ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("خدمة التحويل قادمة قريباً")),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ودجت خاصة لإنشاء الأزرار الدائرية
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(icon, color: const Color(0xFF2DBA9D), size: 30),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          label,
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}