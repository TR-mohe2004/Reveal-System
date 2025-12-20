import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

// --- استيراد المزودات (Providers) ---
// ملاحظة: إذا كان هناك ملف غير موجود، قم بتعليق السطر الخاص به مؤقتاً
import 'package:reveal_app/app/data/providers/auth_provider.dart';
import 'package:reveal_app/app/data/providers/cart_provider.dart';
import 'package:reveal_app/app/data/providers/product_provider.dart';
import 'package:reveal_app/app/data/providers/wallet_provider.dart'; // ✅ مهم جداً
import 'package:reveal_app/app/data/providers/favorites_provider.dart';
import 'package:reveal_app/app/data/providers/college_provider.dart';

// --- استيراد الشاشات ---
import 'package:reveal_app/app/presentation/screens/auth/welcome_screen.dart';
import 'package:reveal_app/app/presentation/screens/auth/login_screen.dart';
import 'package:reveal_app/app/presentation/screens/auth/signup_screen.dart';
import 'package:reveal_app/app/presentation/screens/auth/link_wallet_screen.dart';
import 'package:reveal_app/app/presentation/screens/main_screen.dart';
import 'package:reveal_app/app/presentation/screens/wallet/wallet_screen.dart'; // إضافة المحفظة للمسارات

// ملف إعدادات الفايربيز
import 'package:reveal_app/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint("✅ Firebase Initialized Successfully");
  } catch (e) {
    debugPrint("❌ Firebase Initialization Error: $e");
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      // قائمة المزودات لإدارة الحالة
      providers: [
        // تأكد من أن الكلاسات هذه موجودة بالفعل داخل ملفاتها
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => WalletProvider()), // ✅ هذا هو محرك المحفظة الجديد
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => FavoritesProvider()),
        ChangeNotifierProvider(create: (_) => CollegeProvider()),
      ],
      child: MaterialApp(
        title: 'Reveal App',
        debugShowCheckedModeBanner: false,
        
        // --- 1. إعدادات اللغة والاتجاه ---
        // هذا الكود يجبر التطبيق بالكامل أن يكون عربي (RTL)
        builder: (context, child) {
          return Directionality(
            textDirection: TextDirection.rtl,
            child: child!,
          );
        },

        // --- 2. إعدادات الثيم (الألوان والخطوط) ---
        theme: ThemeData(
          primaryColor: const Color(0xFF009688), // Teal Color
          primarySwatch: Colors.teal,
          scaffoldBackgroundColor: const Color(0xFFF9F9F9),
          
          // إعداد الخطوط (Google Fonts Cairo)
          textTheme: GoogleFonts.cairoTextTheme(Theme.of(context).textTheme),
          
          // إعداد الشريط العلوي الافتراضي
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            iconTheme: IconThemeData(color: Colors.black),
            titleTextStyle: TextStyle(
              color: Colors.black, 
              fontSize: 20, 
              fontWeight: FontWeight.bold, 
              fontFamily: 'Cairo'
            ),
          ),
          
          // إعداد الأزرار الافتراضية
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF009688),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        
        // --- 3. المسارات (Routes) ---
        initialRoute: '/welcome', // أول صفحة تفتح
        routes: {
          '/welcome': (context) => const WelcomeScreen(),
          '/login': (context) => const LoginScreen(),
          '/signup': (context) => const SignupScreen(),
          '/main': (context) => const MainScreen(),
          '/wallet': (context) => const WalletScreen(), // مسار المحفظة المباشر
          '/link-wallet': (context) => const LinkWalletScreen(),
        },
      ),
    );
  }
}