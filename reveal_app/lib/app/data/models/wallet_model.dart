class WalletModel {
  final int id;
  final double balance;
  final String currency;
  final String college;
  final String linkCode;
  final String lastUpdate;
  final String fullName; // اسم الطالب للعرض
  
  // قائمة العمليات لعرضها أسفل الكرت
  final List<WalletTransaction> transactions;

  WalletModel({
    required this.id,
    required this.balance,
    required this.currency,
    required this.college,
    required this.linkCode,
    required this.lastUpdate,
    this.fullName = "الطالب",
    this.transactions = const [],
  });

  factory WalletModel.fromJson(Map<String, dynamic> json) {
    var txnList = json['transactions'] as List? ?? [];
    List<WalletTransaction> parsedTransactions = txnList.map((i) => WalletTransaction.fromJson(i)).toList();

    return WalletModel(
      id: json['id'] ?? 0,
      balance: double.tryParse(json['balance'].toString()) ?? 0.00,
      currency: json['currency'] ?? 'د.ل',
      college: json['college']?.toString() ?? 'غير محدد',
      linkCode: json['link_code']?.toString() ?? '---',
      lastUpdate: json['updated_at']?.toString() ?? '',
      fullName: json['full_name'] ?? "الطالب",
      transactions: parsedTransactions,
    );
  }
}

// كلاس العمليات المالية (مطلوب للجدول السفلي)
class WalletTransaction {
  final String id;
  final double amount;
  final String type; // purchase, topup
  final String description; // اسم الكافيتيريا أو التفاصيل
  final String date;
  final String collegeName;

  WalletTransaction({
    required this.id,
    required this.amount,
    required this.type,
    required this.description,
    required this.date,
    this.collegeName = '',
  });

  factory WalletTransaction.fromJson(Map<String, dynamic> json) {
    return WalletTransaction(
      id: json['id'].toString(),
      amount: double.tryParse(json['amount'].toString()) ?? 0.0,
      type: json['type'] ?? json['transaction_type'] ?? 'purchase',
      description: json['description'] ?? json['college_name'] ?? 'عملية مالية',
      collegeName: json['college_name'] ?? json['description'] ?? '',
      date: json['created_at'] ?? json['timestamp'] ?? DateTime.now().toString(),
    );
  }
  
  // مساعد لتحويل التاريخ
  DateTime get dateObj {
     try { return DateTime.parse(date); } catch(_) { return DateTime.now(); }
  }
}
