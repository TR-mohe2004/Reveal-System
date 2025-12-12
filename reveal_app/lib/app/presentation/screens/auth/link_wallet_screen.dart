import 'package:flutter/material.dart';
import 'package:reveal_app/app/data/services/api_service.dart';

/// شاشة جديدة تتيح للمستخدم إدخال كود الربط لربط حسابه بالمحفظة
class LinkWalletScreen extends StatefulWidget {
  const LinkWalletScreen({super.key});

  @override
  State<LinkWalletScreen> createState() => _LinkWalletScreenState();
}

class _LinkWalletScreenState extends State<LinkWalletScreen> {
  final _codeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  /// دالة معالجة عملية الربط
  Future<void> _handleLinkWallet() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final apiService = ApiService();
      final success = await apiService.linkWalletWithCode(_codeController.text.trim());

      if (success && mounted) {
        // نجحت العملية، انتقل إلى الشاشة الرئيسية
        Navigator.of(context).pushNamedAndRemoveUntil('/main', (route) => false);
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
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
                  const SizedBox(height: 60),
                  const Icon(Icons.wallet_membership_outlined, size: 80, color: Color(0xFF2DBA9D)),
                  const SizedBox(height: 20),
                  const Text(
                    'ربط المحفظة',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'الرجاء إدخال كود الربط الذي استلمته من مسؤول المقهى لتفعيل محفظتك.',
                    textAlign: TextAlign.center, // ✨ إضافة const ✨
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 40),
                  TextFormField(
                    controller: _codeController,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 4),
                    decoration: InputDecoration(
                      hintText: 'XXX-XXX', // ✨ إضافة const ✨
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) { // ✨ إضافة const ✨
                        return 'الرجاء إدخال كود الربط';
                      }
                      return null;
                    },
                  ),
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        _errorMessage!,
                        textAlign: TextAlign.center, // ✨ إضافة const ✨
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  const SizedBox(height: 30),
                  SizedBox(
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleLinkWallet,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2DBA9D),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ), // ✨ إضافة const ✨
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'تأكيد وربط',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                    ),
                  ), // ✨ إضافة const ✨
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}