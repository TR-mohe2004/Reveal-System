class TransactionModel {
  final String id;
  final String title;
  final String subtitle;
  final String date;
  final double amount;
  final bool isDebit;
  final String type;
  final String source;

  TransactionModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.date,
    required this.amount,
    required this.isDebit,
    required this.type,
    required this.source,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    final rawType = (json['transaction_type'] ?? json['type'] ?? '').toString().toUpperCase();
    final isDebitTransaction = rawType == 'WITHDRAWAL' || rawType == 'DEBIT' || rawType == 'PURCHASE';
    final typeDisplay = (json['type_display'] ?? '').toString();
    final collegeName = (json['college_name'] ?? '').toString();
    final description = (json['description'] ?? '').toString();
    final title = typeDisplay.isNotEmpty
        ? typeDisplay
        : (description.isNotEmpty ? description : 'عملية مالية');
    final subtitle = collegeName.isNotEmpty ? collegeName : description;
    final date = (json['created_at_formatted'] ?? json['created_at'] ?? json['date'] ?? '').toString();
    final amount = double.tryParse(json['amount']?.toString() ?? '') ?? 0.0;
    final source = (json['source'] ?? '').toString();

    return TransactionModel(
      id: json['id']?.toString() ?? '',
      title: title,
      subtitle: subtitle,
      date: date,
      amount: amount,
      isDebit: isDebitTransaction,
      type: rawType,
      source: source,
    );
  }
}
