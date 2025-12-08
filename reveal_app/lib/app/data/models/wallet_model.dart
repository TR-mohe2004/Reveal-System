// lib/app/data/models/wallet_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

/// Wallet: يمثل نموذج البيانات (Data Model) للمحفظة.
/// هذا الكلاس يحدد شكل بيانات المحفظة وكيفية قراءتها من Firestore.
class Wallet {
  final String id;          // معرف المحفظة الفريد (Document ID)
  final double balance;     // الرصيد الحالي
  final String collegeId;   // معرف الكلية التي تتبعها المحفظة
  final String linkCode;    // كود الربط الذي يستخدمه الطالب

  Wallet({
    required this.id,
    required this.balance,
    required this.collegeId,
    required this.linkCode,
  });

  /// دالة مصنعية (Factory Constructor) لتحويل مستند Firestore إلى كائن Wallet.
  factory Wallet.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return Wallet(
      id: doc.id,
      balance: (data['balance'] ?? 0).toDouble(),
      collegeId: data['collegeId'] ?? '',
      linkCode: data['linkCode'] ?? '',
    );
  }

  /// دالة مصنعية لتحويل JSON من Django API
  factory Wallet.fromJson(Map<String, dynamic> json) {
    return Wallet(
      id: json['id']?.toString() ?? '',
      balance: double.tryParse(json['balance'].toString()) ?? 0.0,
      collegeId: json['college']?.toString() ?? '',
      linkCode: json['link_code'] ?? '',
    );
  }
}
