// lib/app/data/repositories/college_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:reveal_app/app/data/models/college_model.dart';

class CollegeRepository {
  CollegeRepository._privateConstructor();
  static final CollegeRepository instance = CollegeRepository._privateConstructor();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late final CollectionReference _collegesCollection = _firestore.collection('colleges');

  Stream<List<College>> getCollegesStream() {
    try {
      return _collegesCollection
          .snapshots()
          .map((snapshot) {
            return snapshot.docs.map((doc) {
              // تم تحديث هذه الدالة لتتوافق مع الإصدار الجديد
              return College.fromFirestore(doc.id, doc.data() as Map<String, dynamic>);
            }).toList();
          })
          .handleError((error) {
            print("Error in getCollegesStream: $error");
            return [];
          });
    } catch (e) {
      print("Caught exception in getCollegesStream: $e");
      return Stream.value([]);
    }
  }
}
