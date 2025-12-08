import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reveal_app/app/data/providers/auth_provider.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  // متغيرات للتحكم في حقول الإدخال
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // متغيرات لإدارة الحالة
  bool _isPasswordVisible = false;
  bool _agreedToTerms = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // دالة التسجيل المعدلة
  void _onSignupPressed() async {
    // التحقق من صحة النموذج أولاً
    if (_formKey.currentState!.validate()) {
      // التحقق من الموافقة على الشروط
      if (!_agreedToTerms) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('الرجاء الموافقة على شروط وقواعد الإستخدام'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      // إغلاق الكيبورد
      FocusScope.of(context).unfocus();

      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // إظهار دائرة تحميل
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (c) => const Center(child: CircularProgressIndicator()),
      );

      // محاولة إنشاء الحساب
      // نرسل رقم هاتف افتراضي '0000000000' لأن الباك اند يطلبه، لكننا لم نضعه في الواجهة بعد
      final success = await authProvider.signup(
        _nameController.text.trim(),
        _emailController.text.trim(),
        _passwordController.text.trim(),
         
      );

      Navigator.pop(context); // إغلاق دائرة التحميل

      if (success) {
        // الانتقال إلى الشاشة الرئيسية
        Navigator.of(context).pushNamedAndRemoveUntil('/main', (route) => false);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(
            content: Text(authProvider.errorMessage ?? 'فشل إنشاء الحساب'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // باقي الكود (build) كما هو تماماً في رسالتك...
    // سأختصره هنا لعدم التكرار، انسخ الجزء العلوي فقط واستبدله في ملفك
    // واحتفظ بباقي التصميم (buildTextField, buildEmailField...) كما هو.
    
    // ... (نفس كود التصميم الذي أرسلته لي) ...
    
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
                   // ... (نفس محتوى العمود الذي أرسلته)
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

                  // 2. العنوان
                  const Text(
                    'إنشاء حساب جديد',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                  // ... إلخ (باقي الكود كما هو)
                  
                  // عند الزر، تأكد أنه يستدعي _onSignupPressed التي عدلناها في الأعلى
                  ElevatedButton(
                    onPressed: _onSignupPressed,
                    // ... الستايل كما هو
                    child: const Text(
                      'إنشاء الحساب',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                  
                  // ... باقي الكود
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ... (باقي الودجات المساعدة كما هي)
  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide.none,
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildEmailField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('البريد الإلكتروني', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            hintText: 'أدخل البريد الإلكتروني',
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide.none,
            ),
            prefixIcon: const Icon(Icons.email_outlined, color: Colors.grey),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'الرجاء إدخال البريد الإلكتروني';
            }
            if (!value.contains('@')) {
              return 'عنوان البريد الإلكتروني غير صحيح';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('كلمة السر', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextFormField(
          controller: _passwordController,
          obscureText: !_isPasswordVisible,
          decoration: InputDecoration(
            hintText: 'أدخل كلمة السر',
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide.none,
            ),
            prefixIcon: IconButton(
              icon: Icon(
                _isPasswordVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: Colors.grey,
              ),
              onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'الرجاء إدخال كلمة السر';
            }
            if (value.length < 8) {
              return 'يجب أن تكون كلمة السر 8 أحرف على الأقل';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildTermsAndConditions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Checkbox(
          value: _agreedToTerms,
          onChanged: (bool? value) {
            setState(() {
              _agreedToTerms = value!;
            });
          },
          activeColor: const Color(0xFF2DBA9D),
        ),
        Expanded(
          child: RichText(
            textAlign: TextAlign.start,
            text: TextSpan(
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              children: [
                const TextSpan(text: 'عن طريق المتابعة، أنا أوافق على '),
                TextSpan(
                  text: 'شروط وقواعد الإستخدام',
                  style: const TextStyle(
                    color: Color(0xFF2DBA9D),
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.underline,
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () {},
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class OrDivider extends StatelessWidget {
  const OrDivider({super.key});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Text('أو إستخدام حساب جوجل', style: TextStyle(color: Colors.grey[600])),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }
}