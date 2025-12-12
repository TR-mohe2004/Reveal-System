// lib/app/data/repositories/auth_repository.dart (النسخة الكاملة والمدمجة والنهائية)

import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthRepository {
  final auth.FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  // Singleton Pattern
  AuthRepository._privateConstructor()
      // ✨✨✨ هذا هو السطر الذي تم إصلاحه ✨✨✨
      : _firebaseAuth = auth.FirebaseAuth.instance, _firestore = FirebaseFirestore.instance;

  static final AuthRepository instance = AuthRepository._privateConstructor();

  // Stream للاستماع لتغيرات حالة المصادقة (تسجيل دخول/خروج)
  Stream<auth.User?> get authStateChanges => _firebaseAuth.authStateChanges();

  // --- ✨✨✨ القسم الجديد المضاف: المصادقة بالبريد الإلكتروني ✨✨✨ ---

  Future<auth.UserCredential> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String name, // اسم المستخدم الجديد
  }) async {
    try {
      // الخطوة 1: إنشاء المستخدم في Authentication
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user != null) {
        // الخطوة 2 (الأهم): إنشاء مستند الصلاحيات في Firestore
        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'email': email,
          'name': name,
          'role': 'user', // القيمة الافتراضية لأي مستخدم جديد هي 'user'
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      
      return userCredential;
    } on auth.FirebaseAuthException catch (_) {
      // إعادة رمي الخطأ الأصلي من Firebase للسماح للواجهة بمعالجته بشكل دقيق
      // مثلاً، يمكن للواجهة التحقق من e.code == 'email-already-in-use'
      rethrow;
    } catch (e) {
      // لأي أخطاء أخرى غير متوقعة
      throw Exception('فشل في إنشاء الحساب. حدث خطأ غير متوقع.');
    }
  }

  Future<auth.UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      return await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on auth.FirebaseAuthException catch (_) {
      // إعادة رمي الخطأ الأصلي من Firebase
      // يسمح للواجهة بالتحقق من e.code مثل 'user-not-found' أو 'wrong-password'
      rethrow;
    } catch (e) {
      // لأي أخطاء أخرى غير متوقعة
      throw Exception('فشل في تسجيل الدخول: ${e.toString()}');
    }
  }

  // --- 🔒🔒🔒 القسم القديم المحفوظ: المصادقة بالهاتف 🔒🔒🔒 ---
  // (تم الحفاظ عليه كما هو بالضبط بدون أي تغيير)

  // دالة إرسال رمز التحقق
  Future<void> sendOTP({
    required String phoneNumber,
    required Function(String, int?) onCodeSent,
    required Function(auth.PhoneAuthCredential) onVerificationCompleted,
    required Function(auth.FirebaseAuthException) onVerificationFailed,
  }) async {
    await _firebaseAuth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: onVerificationCompleted,
      verificationFailed: onVerificationFailed,
      codeSent: onCodeSent,
      codeAutoRetrievalTimeout: (String verificationId) {
        // لا نفعل شيئًا هنا حاليًا
      },
    );
  }

  // دالة التحقق من الرمز المدخل يدويًا
  Future<auth.UserCredential> verifyOTP({required String verificationId, required String smsCode}) async {
    auth.PhoneAuthCredential credential = auth.PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    return await _firebaseAuth.signInWithCredential(credential);
  }

  // دالة تسجيل الدخول باستخدام Credential (للتحقق التلقائي)
  Future<auth.UserCredential> signInWithCredential(auth.PhoneAuthCredential credential) async {
    return await _firebaseAuth.signInWithCredential(credential);
  }

  // --- 🚪 دالة تسجيل الخروج (مشتركة بين الطريقتين) ---
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  // --- 👤 دالة للحصول على المستخدم الحالي (مشتركة بين الطريقتين) ---
  auth.User? getCurrentUser() {
    return _firebaseAuth.currentUser;
  }
}
