import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:reveal_app/app/core/enums/view_state.dart';
import 'package:reveal_app/app/data/providers/wallet_provider.dart';
import 'package:reveal_app/app/data/models/transaction_model.dart';

class WalletHistoryScreen extends StatefulWidget {
  const WalletHistoryScreen({super.key});

  @override
  State<WalletHistoryScreen> createState() => _WalletHistoryScreenState();
}

class _WalletHistoryScreenState extends State<WalletHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WalletProvider>().fetchWalletData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('سجل المحفظة'),
        centerTitle: true,
      ),
      body: Consumer<WalletProvider>(
        builder: (context, provider, _) {
          if (provider.state == ViewState.busy && provider.wallet == null) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF009688)));
          }

          if (provider.state == ViewState.error && provider.wallet == null) {
            return _buildError(provider);
          }

          final wallet = provider.wallet;
          final transactions = wallet?.transactions ?? [];
          if (transactions.isEmpty) {
            return _buildEmpty();
          }

          return RefreshIndicator(
            onRefresh: () => provider.fetchWalletData(),
            color: const Color(0xFF009688),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: transactions.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                return _buildTransactionCard(transactions[index]);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildTransactionCard(TransactionModel transaction) {
    final isDebit = transaction.isDebit;
    final color = isDebit ? Colors.red : Colors.green;
    final sign = isDebit ? '-' : '+';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: color.withOpacity(0.12),
            child: Icon(
              isDebit ? Icons.arrow_upward : Icons.arrow_downward,
              color: color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                if (transaction.subtitle.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    transaction.subtitle,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 6),
                Text(
                  transaction.date,
                  style: TextStyle(color: Colors.grey[500], fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$sign${transaction.amount.toStringAsFixed(2)} د.ل',
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'لا توجد عمليات بعد',
            style: TextStyle(fontSize: 18, color: Colors.grey[600], fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text('ستظهر عمليات الشحن والخصم هنا.', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildError(WalletProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 60, color: Colors.red[300]),
          const SizedBox(height: 10),
          Text(provider.errorMessage ?? 'تعذر تحميل السجل'),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => provider.fetchWalletData(),
            child: const Text('إعادة المحاولة'),
          ),
        ],
      ),
    );
  }
}
