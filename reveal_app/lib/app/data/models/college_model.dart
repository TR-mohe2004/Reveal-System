// lib/app/data/models/college_model.dart

/// يمثل نموذج البيانات لكائن "الكلية"
class College {
  final String id;
  final String name;
  final String imageUrl;

  College({
    required this.id,
    required this.name,
    required this.imageUrl,
  });

  /// --- هذا هو الجزء الذي تم تعديله ---
  /// دالة مصنعية (Factory) لتحويل بيانات Firestore إلى كائن College.
  /// تستقبل ID المستند وخريطة البيانات (data) من Firestore.
  factory College.fromFirestore(String id, Map<String, dynamic> data) {
    return College(
      id: id, // الـ ID يأتي من المستند نفسه
      name: data['name'] ?? 'اسم غير معروف', // اقرأ حقل 'name' من البيانات
      imageUrl: data['imageUrl'] ?? '', // اقرأ حقل 'imageUrl' من البيانات
    );
  }
}
