// lib/app/presentation/screens/auth/otp_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';

class OTPScreen extends StatefulWidget {
  final String phoneNumber; // لاستقبال رقم الهاتف من الشاشة السابقة

  const OTPScreen({super.key, required this.phoneNumber});

  @override
  State<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> {
  final _pinController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  // متغيرات المؤقت الزمني
  Timer? _timer;
  int _start = 60;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    startTimer();
  }

  void startTimer() {
    setState(() {
      _canResend = false;
      _start = 60;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_start == 0) {
        setState(() {
          _canResend = true;
          timer.cancel();
        });
      } else {
        setState(() {
          _start--;
        });
      }
    });
  }

  @override
  void dispose() {
    _pinController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // تصميم حقول الإدخال الافتراضية والمُركزة
    final defaultPinTheme = PinTheme(
      width: 56,
      height: 56,
      textStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        shape: BoxShape.circle,
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyDecorationWith(
      border: Border.all(color: const Color(0xFF2DBA9D), width: 2),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. زر الرجوع
                  Align(
                    alignment: Alignment.topLeft,
                    child: IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          shape: BoxShape.rectangle,
                          border: Border.all(color: Colors.grey.shade400, width: 1.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.arrow_forward_ios, size: 18),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // 2. الشعار
                  // TODO: استبدل الأيقونة بصورة الشعار الحقيقية
                  const Icon(Icons.qr_code_scanner, size: 80, color: Color(0xFF2DBA9D)),
                  const SizedBox(height: 32),

                  // 3. العنوان الرئيسي
                  const Text(
                    'أدخل رمز التأكيد',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'قم بإدخال الرمز الذي تم إرساله على الرقم',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  Text(
                    widget.phoneNumber, // عرض رقم الهاتف
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 48),

                  // 4. حقول إدخال الـ OTP
                  Pinput(
                    controller: _pinController,
                    length: 5,
                    defaultPinTheme: defaultPinTheme,
                    focusedPinTheme: focusedPinTheme,
                    submittedPinTheme: defaultPinTheme.copyDecorationWith(
                      border: Border.all(color: Colors.green, width: 2),
                    ),
                    pinputAutovalidateMode: PinputAutovalidateMode.onSubmit,
                    showCursor: true,
                    onCompleted: (pin) {
                      // TODO: Implement OTP verification logic
                      debugPrint('Completed: $pin');
                    },
                  ),
                  const SizedBox(height: 32),

                  // 5. رابط إعادة الإرسال مع المؤقت
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: _canResend ? startTimer : null, // تفعيل الزر عند انتهاء المؤقت
                        child: Text(
                          'إعادة الإرسال',
                          style: TextStyle(
                            color: _canResend ? const Color(0xFFF27E49) : Colors.grey,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                      Text(
                        _canResend ? 'لم يصلك الرمز؟' : 'يمكنك إعادة الإرسال بعد: $_start ثانية',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // 6. زر المتابعة
                  ElevatedButton(
                    onPressed: () {
                      // TODO: Implement OTP verification logic
                      if (_formKey.currentState!.validate()) {
                        debugPrint('Submitting OTP: ${_pinController.text}');
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2DBA9D),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text(
                      'المتابعة',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
