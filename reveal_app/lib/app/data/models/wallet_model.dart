import 'package:reveal_app/app/data/models/transaction_model.dart';

class WalletModel {
  final int id;
  final double balance;
  final String currency;
  final String college;
  final String linkCode;
  final String userFullName;
  final List<TransactionModel> transactions;

  WalletModel({
    required this.id,
    required this.balance,
    required this.currency,
    required this.college,
    required this.linkCode,
    required this.userFullName,
    required this.transactions,
  });

  factory WalletModel.fromJson(Map<String, dynamic> json) {
    final rawBalance = json['balance'];
    final parsedBalance = rawBalance is num
        ? rawBalance.toDouble()
        : double.tryParse(rawBalance?.toString() ?? '') ?? 0.0;

    final rawTransactions = json['transactions'] ?? json['recent_transactions'];
    final transactions = <TransactionModel>[];
    if (rawTransactions is List) {
      for (final item in rawTransactions) {
        if (item is Map<String, dynamic>) {
          transactions.add(TransactionModel.fromJson(item));
        } else if (item is Map) {
          transactions.add(TransactionModel.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }

    return WalletModel(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      balance: parsedBalance,
      currency: (json['currency'] ?? '').toString(),
      college: (json['college'] ?? '').toString(),
      linkCode: (json['link_code'] ?? '').toString(),
      userFullName: (json['user_full_name'] ?? json['full_name'] ?? '').toString(),
      transactions: transactions,
    );
  }
}
