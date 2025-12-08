import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reveal_app/app/core/enums/view_state.dart';
import 'package:reveal_app/app/data/providers/wallet_provider.dart';

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('محفظتي')),
      body: Consumer<WalletProvider>(
        builder: (context, provider, child) {
          if (provider.state == ViewState.busy) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.wallet == null) {
             return Center(
               child: Column(
                 mainAxisAlignment: MainAxisAlignment.center,
                 children: [
                   const Icon(Icons.account_balance_wallet_outlined, size: 80, color: Colors.grey),
                   const SizedBox(height: 16),
                   const Text('لا توجد محفظة مرتبطة', style: TextStyle(fontSize: 18, color: Colors.grey)),
                   const SizedBox(height: 24),
                   ElevatedButton(
                     onPressed: () {
                       provider.fetchUserWallet();
                     }, 
                     child: const Text('تحديث')
                   )
                 ],
               ),
             );
          }

          final wallet = provider.wallet!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // بطاقة الرصيد
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2DBA9D), Color(0xFF1A9F84)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(color: Colors.teal.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5)),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'الرصيد الحالي',
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${wallet.balance.toStringAsFixed(2)} د.ل',
                        style: const TextStyle(
                          color: Colors.white, 
                          fontSize: 36, 
                          fontWeight: FontWeight.bold
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'رقم المحفظة: ${wallet.id}',
                        style: const TextStyle(color: Colors.white38, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                
                // زر التحديث
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => provider.fetchUserWallet(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('تحديث الرصيد'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
