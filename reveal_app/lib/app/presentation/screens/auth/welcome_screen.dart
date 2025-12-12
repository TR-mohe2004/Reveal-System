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
          child: _buildContent(context, colors),
        ),
      ),
    );
  }

  // ✨ ويدجت بناء المحتوى الرئيسي (لتحسين التنظيم)
  Widget _buildContent(BuildContext context, Map<String, Color> colors) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Spacer(flex: 2),
        _buildLogo(colors),
        const SizedBox(height: 32),
        _buildWelcomeText(colors),
        const SizedBox(height: 48),
        _buildAuthButtons(context, colors),
        const Spacer(flex: 3),
        _buildSettingsButtons(colors),
        const SizedBox(height: 24),
      ],
    );
  }

  // ويدجت الشعار
  Widget _buildLogo(Map<String, Color> colors) {
    return Image.asset(
      'assets/images/logo.png',
      height: 180,
      errorBuilder: (context, error, stackTrace) {
        return Icon(Icons.fastfood, size: 100, color: colors['icon']);
      },
    );
  }

  // ويدجت نصوص الترحيب
  Widget _buildWelcomeText(Map<String, Color> colors) {
    return Column(
      children: [
        Text(
          'أهلاً بكم إلى\nتطبيق ريفيل!',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: colors['primaryText'],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'النص الفرعي سيوضع هنا، وهو تجربة عملية لرؤية التطبيق العامة.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            color: colors['secondaryText'],
          ),
        ),
      ],
    );
  }

  // ويدجت أزرار الدخول وإنشاء الحساب
  Widget _buildAuthButtons(BuildContext context, Map<String, Color> colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton(
          onPressed: () => Navigator.pushNamed(context, '/login'),
          style: ElevatedButton.styleFrom(
            backgroundColor: colors['loginButton'], // ✨ استخدام لون من الثيم
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)), // ✨ إضافة const ✨
          ),
          child: const Text(
            'تسجيل الدخول',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () => Navigator.pushNamed(context, '/signup'),
          style: ElevatedButton.styleFrom(
            backgroundColor: colors['signupButton'], // ✨ استخدام لون من الثيم
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)), // ✨ إضافة const ✨
          ),
          child: const Text(
            'إنشاء حساب جديد',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
      ],
    );
  }

  // ويدجت أزرار الإعدادات (الثيم واللغة)
  Widget _buildSettingsButtons(Map<String, Color> colors) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // زر تغيير الوضع
        TextButton.icon(
          onPressed: () => setState(() => isDarkMode = !isDarkMode),
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
              side: BorderSide(color: colors['border'] ?? Colors.grey), // ✨ إضافة const ✨
            ),
          ),
        ),
        const SizedBox(width: 16),
        // زر تغيير اللغة (غير فعال حالياً)
        TextButton.icon(
          onPressed: () { /* TODO: Implement language change logic */ },
          icon: const Icon(Icons.language, size: 20, color: Color(0xFF2DBA9D)),
          label: Text(
            'اللغة: العربية',
            style: TextStyle(color: colors['secondaryText']),
          ),
          style: TextButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: colors['border'] ?? Colors.grey), // ✨ إضافة const ✨
            ),
          ),
        ),
      ],
    );
  }

  // تعريف مجموعات الألوان (كما هي تماماً)
  static const Map<String, Color> _lightColors = {
    'background': Colors.white,
    'primaryText': Color(0xFF333333),
    'secondaryText': Color(0xFF666666),
    'icon': Color(0xFFF27E49), // برتقالي
    'border': Color(0xFFDDDDDD),
    'loginButton': Color(0xFF2DBA9D), // أخضر
    'signupButton': Color(0xFFF27E49), // برتقالي
  };

  static const Map<String, Color> _darkColors = {
    'background': Color(0xFF121212),
    'primaryText': Colors.white,
    'secondaryText': Color(0xFFBBBBBB),
    'icon': Color(0xFFF27E49), // برتقالي
    'border': Color(0xFF444444),
    'loginButton': Color(0xFF2DBA9D), // أخضر
    'signupButton': Color(0xFFF27E49), // برتقالي
  };
}