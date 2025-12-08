import 'package:flutter/material.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  // متغير لتتبع الوضع الحالي (نهاري أو ليلي)
  bool isDarkMode = false;

  @override
  Widget build(BuildContext context) {
    // تحديد الألوان بناءً على الوضع الحالي
    final colors = isDarkMode ? _darkColors : _lightColors;

    return Scaffold(
      // لون الخلفية يتغير مع الوضع
      backgroundColor: colors['background'],
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // مساحة فارغة في الأعلى لدفع المحتوى للأسفل
              const Spacer(flex: 2),

              // 1. الشعار (Logo)
              // تأكد أن الصورة موجودة في assets/images/logo.png
              Image.asset(
                'assets/images/logo.png',
                height: 180, 
                // إضافة معالجة في حال لم تكن الصورة موجودة حتى لا ينهار التطبيق
                errorBuilder: (context, error, stackTrace) {
                  return Icon(Icons.fastfood, size: 100, color: colors['icon']);
                },
              ),
              const SizedBox(height: 32),

              // 2. نص الترحيب
              Text(
                'أهلاً بكم إلى\nتطبيق ريفيل!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  // لون النص يتغير مع الوضع
                  color: colors['primaryText'],
                ),
              ),
              const SizedBox(height: 16),

              // 3. النص الفرعي
              Text(
                'النص الفرعي سيوضع هنا، وهو تجربة عملية لرؤية التطبيق العامة.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  // لون النص يتغير مع الوضع
                  color: colors['secondaryText'],
                ),
              ),
              const SizedBox(height: 48),

              // 4. زر تسجيل الدخول
              ElevatedButton(
                onPressed: () {
                  // --- تم التعديل هنا لتفعيل الانتقال ---
                  // نستخدم pushNamed لأننا عرفنا الروابط في main.dart
                  Navigator.pushNamed(context, '/login');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2DBA9D), // اللون الأخضر
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  'تسجيل الدخول',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 5. زر إنشاء حساب جديد
              ElevatedButton(
                onPressed: () {
                  // --- تم التعديل هنا لتفعيل الانتقال ---
                  Navigator.pushNamed(context, '/signup');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF27E49), // اللون البرتقالي
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  'إنشاء حساب جديد',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),

              // مساحة فارغة لدفع الأزرار السفلية للأسفل
              const Spacer(flex: 3),

              // 6. أزرار الوضع واللغة
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // زر تغيير الوضع
                  TextButton.icon(
                    onPressed: () {
                      // تحديث حالة الواجهة لتبديل الوضع
                      setState(() {
                        isDarkMode = !isDarkMode;
                      });
                    },
                    icon: Icon(
                      isDarkMode ? Icons.wb_sunny_outlined : Icons.nightlight_round,
                      color: colors['icon'],
                      size: 20,
                    ),
                    label: Text(
                      isDarkMode ? 'الوضع: ليلي' : 'الوضع: نهاري',
                      style: TextStyle(color: colors['secondaryText']),
                    ),
                    style: TextButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(color: colors['border']!),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  // زر تغيير اللغة
                  TextButton.icon(
                    onPressed: () {
                    
                    },
                    icon: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: const Icon(Icons.flag, size: 20, color: Colors.green),
                    ),
                    label: Text(
                      'اللغة: العربية',
                      style: TextStyle(color: colors['secondaryText']),
                    ),
                    style: TextButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(color: colors['border']!),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24), // مساحة إضافية في الأسفل
            ],
          ),
        ),
      ),
    );
  }

  // تعريف مجموعات الألوان (كما هي تماماً)
  static const Map<String, Color> _lightColors = {
    'background': Colors.white,
    'primaryText': Color(0xFF333333),
    'secondaryText': Color(0xFF666666),
    'icon': Color(0xFFF27E49),
    'border': Color(0xFFDDDDDD),
  };

  static const Map<String, Color> _darkColors = {
    'background': Color(0xFF121212),
    'primaryText': Colors.white,
    'secondaryText': Color(0xFFBBBBBB),
    'icon': Color(0xFFF27E49),
    'border': Color(0xFF444444),
  };
}