// lib/app/data/models/wallet_model.dart

class Wallet {
  final int id;             // معرف المحفظة
  final double balance;     // الرصيد الحالي
  final String currency;    // العملة
  final String college;     // اسم الكلية (الجديد)
  final String linkCode;    // كود الربط (الجديد)
  final String lastUpdate;  // تاريخ آخر تحديث

  Wallet({
    required this.id,
    required this.balance,
    required this.currency,
    required this.college,
    required this.linkCode,
    required this.lastUpdate,
  });

  /// دالة تحويل JSON القادم من الباك اند إلى كائن Wallet
  factory Wallet.fromJson(Map<String, dynamic> json) {
    return Wallet(
      // استخدام (?? 0) لتجنب الخطأ لو كانت القيمة null
      id: json['id'] ?? 0,
      
      // تحويل آمن للرقم سواء جاء نصاً أو رقماً
      balance: double.tryParse(json['balance'].toString()) ?? 0.00,
      
      currency: json['currency'] ?? 'د.ل',
      
      // الحقول الجديدة التي أضفناها في المنظومة
      college: json['college']?.toString() ?? 'غير محدد',
      linkCode: json['link_code']?.toString() ?? '---',
      
      // تاريخ التحديث (اختياري)
      lastUpdate: json['updated_at']?.toString() ?? '',
    );
  }

  /// دالة لتحويل الكائن إلى JSON (للاستخدام المستقبلي إذا احتجنا إرساله)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'balance': balance,
      'currency': currency,
      'college': college,
      'link_code': linkCode,
    };
  }
}