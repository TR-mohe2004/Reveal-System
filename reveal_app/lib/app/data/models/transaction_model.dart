class TransactionModel {
  final String id;
  final String title;
  final String date;
  final double amount;
  final bool isDebit; // true = خصم (شراء), false = إضافة (شحن)

  TransactionModel({
    required this.id,
    required this.title,
    required this.date,
    required this.amount,
    required this.isDebit,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    // تحديد نوع العملية (شراء أو شحن)
    String type = json['type'] ?? 'purchase';
    bool isDebitTransaction = type == 'purchase' || type == 'debit';

    return TransactionModel(
      id: json['id'].toString(),
      // العنوان يكون اسم الكلية أو وصف العملية
      title: json['college_name'] ?? json['description'] ?? 'عملية مالية',
      date: json['created_at'] ?? json['timestamp'] ?? DateTime.now().toString(),
      // تحويل آمن للرقم
      amount: double.tryParse(json['amount'].toString()) ?? 0.0,
      isDebit: isDebitTransaction,
    );
  }
} 