import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:reveal_app/app/data/models/college_model.dart'; // ✅ استدعاء المودل الجديد

class CollegeRepository {
  CollegeRepository._privateConstructor();
  static final CollegeRepository instance = CollegeRepository._privateConstructor();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // تأكد أن اسم المجموعة في فايربيز هو 'colleges' أو 'cafes' حسب هيكلتك
  late final CollectionReference _collegesCollection = _firestore.collection('colleges');

  // ✅ تم تغيير النوع المرجع إلى Stream<List<CollegeModel>>
  Stream<List<CollegeModel>> getCollegesStream() {
    try {
      return _collegesCollection
          .snapshots()
          .map((snapshot) {
            return snapshot.docs.map((doc) {
              // ✅ استخدام دالة التحويل من المودل الجديد
              return CollegeModel.fromFirestore(doc.id, doc.data() as Map<String, dynamic>);
            }).toList();
          })
          .handleError((error) {
            debugPrint('Error in getCollegesStream: $error');
            return <CollegeModel>[]; // إرجاع قائمة فارغة عند الخطأ
          });
    } catch (e) {
      debugPrint('Caught exception in getCollegesStream: $e');
      return Stream.value([]);
    }
  }
}