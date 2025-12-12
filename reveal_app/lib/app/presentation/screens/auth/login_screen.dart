import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reveal_app/app/data/providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // متغير للتحكم في إظهار/إخفاء كلمة السر
  bool _isPasswordVisible = false;
  
  // متغيرات للتحكم في حقول الإدخال
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // دالة الدخول المعدلة
  void _onLoginPressed() async {
    if (_formKey.currentState!.validate()) {
      // إغلاق لوحة المفاتيح
      FocusScope.of(context).unfocus();

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      // المحاولة لتسجيل الدخول (نرسل رقم الهاتف بدلاً من الإيميل)
      final success = await authProvider.login(
        _phoneController.text.trim(),
        _passwordController.text.trim(),
      );

      if (!mounted) return;

      if (success) {
        // الانتقال للصفحة الرئيسية وحذف ما قبلها
        Navigator.of(context).pushNamedAndRemoveUntil('/main', (route) => false);
      } else {
        // إظهار رسالة خطأ
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.errorMessage ?? 'فشل تسجيل الدخول'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // الاستماع للتغييرات في AuthProvider لعرض مؤشر التحميل
    final isLoading = context.select<AuthProvider, bool>((p) => p.status == AuthStatus.authenticating);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Column(
            children: [
              // زر الرجوع في الأعلى
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        shape: BoxShape.rectangle,
                        border: Border.all(color: Colors.grey.shade300, width: 1.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.black),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ),
              
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 10),
                        // العنوان الرئيسي
                        const Text(
                          'سجل الدخول',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'قم بإدخال رقم الهاتف وكلمة السر',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 48),

                        // حقل رقم الهاتف
                        const Text('رقم الهاتف', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          textDirection: TextDirection.ltr, // لجعل الرقم يكتب من اليسار
                          textAlign: TextAlign.right,
                          decoration: InputDecoration(
                            hintText: 'أدخل رقم الهاتف',
                            hintTextDirection: TextDirection.rtl,
                            filled: true,
                            fillColor: Colors.grey[100],
                            contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide.none,
                            ),
                            // العلم والرمز الدولي
                            suffixIcon: Padding( // Suffix لأنه RTL
                              padding: const EdgeInsets.all(8.0),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    '+218', 
                                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)
                                  ),
                                  const SizedBox(width: 8),
                                  // مكان العلم - صورة دائرية
                                  Container(
                                    width: 28,
                                    height: 28,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                    ),
                                    child: ClipOval(
                                      child: Image.asset(
                                        'assets/images/libya_flag.png',
                                        fit: BoxFit.cover,
                                        errorBuilder: (c,o,s) => const Icon(Icons.flag, size: 20),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'الرجاء إدخال رقم الهاتف';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),

                        // حقل كلمة السر
                        const Text('كلمة السر', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: !_isPasswordVisible,
                          decoration: InputDecoration(
                            hintText: 'أدخل كلمة السر',
                            filled: true,
                            fillColor: Colors.grey[100],
                            contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide.none,
                            ),
                            prefixIcon: IconButton( // Prefix لأنه RTL
                              icon: Icon(
                                _isPasswordVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                color: Colors.grey,
                              ),
                              onPressed: () {
                                setState(() {
                                  _isPasswordVisible = !_isPasswordVisible;
                                });
                              },
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'الرجاء إدخال كلمة السر';
                            }
                            return null;
                          },
                        ),
                        
                        // رابط "نسيت كلمة السر؟"
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerLeft, // يسار في RTL يعني اليمين؟ لا، Alignment يتبع الشاشة
                          // في RTL، centerLeft هو اليسار الفعلي. الصورة تظهر النص في الوسط؟؟ لا، نسيت كلمة السر تحت الحقل.
                          child: TextButton(
                            onPressed: () {},
                            child: const Text(
                              'نسيت كلمة السر؟',
                              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // زر تسجيل الدخول
                        ElevatedButton(
                          onPressed: isLoading ? null : _onLoginPressed,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2DBA9D), // اللون التركوازي
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            elevation: 0,
                          ),
                          child: isLoading 
                              ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Text(
                                'تسجيل الدخول',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                        ),
                        const SizedBox(height: 32),

                        // فاصل "أو"
                        const OrDivider(),
                        const SizedBox(height: 24),

                        // جوجل
                         Center(
                           child: Column(
                             children: [
                               const Text("أو إستخدام حساب جوجل", style: TextStyle(color: Colors.grey)),
                               const SizedBox(height: 10),
                               InkWell(
                                 onTap: (){},
                                 child: const Text("Google", 
                                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue)
                                 )
                               )
                             ],
                           )
                         ),
                        // لتطابق التصميم بدقة، يبدو أن "أو استخدام حساب جوجل" هو الفاصل نفسه، وتحته Google Logo
                        // سأبقي OrDivider كما هو وأضع Google تحته.
                        
                        // رابط إنشاء حساب
                         const SizedBox(height: 40),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            GestureDetector(
                              onTap: () => Navigator.pushNamed(context, '/signup'),
                              child: const Text(
                                'أنشئ حساب؟',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ),
                            const SizedBox(width: 5),
                            const Text('لا تملك حساب؟', style: TextStyle(color: Colors.grey, fontSize: 16)),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),

              // الشريط السفلي (اللغة والوضع)
              Padding(
                padding: const EdgeInsets.only(bottom: 20.0, left: 20, right: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildBottomOption(icon: Icons.sunny, label: "الوضع: نهاري", color: Colors.orange),
                    const SizedBox(width: 15),
                    // خيار اللغة مع العلم
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFF2DBA9D)),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 20, 
                            height: 20, 
                            child: ClipOval(
                              child: Image.asset('assets/images/libya_flag.png', fit: BoxFit.cover)
                            )
                          ),
                          const SizedBox(width: 8),
                          const Text("اللغة: العربية", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomOption({required IconData icon, required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF2DBA9D)),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }
}

// ويدجت مخصص للخط الفاصل مع كلمة "أو"
class OrDivider extends StatelessWidget {
  const OrDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Text(
            'أو إستخدام حساب جوجل',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }
}
