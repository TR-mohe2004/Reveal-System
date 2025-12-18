import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:reveal_app/app/data/models/product_model.dart'; // ✅ استدعاء المودل الجديد

class ProductRepository {
  ProductRepository._privateConstructor();
  static final ProductRepository instance = ProductRepository._privateConstructor();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late final CollectionReference _productsCollection = _firestore.collection('products');

  // ✅ تم تغيير النوع المرجع إلى Stream<List<ProductModel>>
  Stream<List<ProductModel>> getProductsStream() {
    try {
      return _productsCollection
          .snapshots()
          .map((snapshot) {
            return snapshot.docs.map((doc) {
              // ✅ تحويل البيانات للمودل الجديد
              // ملاحظة: ProductModel لا يحتوي على fromFirestore افتراضياً
              // لذا نستخدم fromJson ونمرر الـ id يدوياً إذا لزم الأمر
              Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
              data['id'] = doc.id; // دمج الـ ID مع البيانات
              return ProductModel.fromJson(data);
            }).toList();
          })
          .handleError((error) {
            debugPrint('Error in getProductsStream: $error');
            return <ProductModel>[];
          });
    } catch (e) {
      debugPrint('Caught exception in getProductsStream: $e');
      return Stream.value([]);
    }
  }
  
  // دالة لجلب المنتجات حسب الكلية (مهمة جداً للفلترة)
  Stream<List<ProductModel>> getProductsByCollege(String collegeId) {
     return _productsCollection
        .where('college_id', isEqualTo: collegeId)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
            data['id'] = doc.id;
            return ProductModel.fromJson(data);
          }).toList();
        });
  }
}