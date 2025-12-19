import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart'; 

// --- استيراد المزودات (Providers) ---
// تأكد أن هذه الملفات موجودة في المسار المحدد
import 'package:reveal_app/app/data/providers/auth_provider.dart';
import 'package:reveal_app/app/data/providers/cart_provider.dart';
import 'package:reveal_app/app/data/providers/product_provider.dart';
import 'package:reveal_app/app/data/providers/wallet_provider.dart';
import 'package:reveal_app/app/data/providers/favorites_provider.dart';
import 'package:reveal_app/app/data/providers/college_provider.dart';

// --- استيراد الشاشات ---
import 'package:reveal_app/app/presentation/screens/auth/welcome_screen.dart';
import 'package:reveal_app/app/presentation/screens/auth/login_screen.dart';
import 'package:reveal_app/app/presentation/screens/auth/signup_screen.dart';
import 'package:reveal_app/app/presentation/screens/auth/link_wallet_screen.dart';
import 'package:reveal_app/app/presentation/screens/main_screen.dart';

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
      // قائمة المزودات لإدارة الحالة (State Management)
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => WalletProvider()),
        ChangeNotifierProvider(create: (_) => FavoritesProvider()),
        ChangeNotifierProvider(create: (_) => CollegeProvider()),
      ],
      child: MaterialApp(
        title: 'Reveal App',
        debugShowCheckedModeBanner: false,
        
        // إعدادات الثيم (الخطوط والألوان)
        theme: ThemeData(
          primarySwatch: Colors.teal,
          scaffoldBackgroundColor: const Color(0xFFF9F9F9),
          // استخدام خط كايرو لجميع نصوص التطبيق
          textTheme: GoogleFonts.cairoTextTheme(Theme.of(context).textTheme),
          
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.transparent,
            elevation: 0,
            iconTheme: IconThemeData(color: Colors.black),
            titleTextStyle: TextStyle(
              color: Colors.black, 
              fontSize: 20, 
              fontWeight: FontWeight.bold, 
              fontFamily: 'Cairo'
            ),
          ),
        ),
        
        // تعريف المسارات للتنقل السهل
        routes: {
          '/welcome': (context) => const WelcomeScreen(),
          '/login': (context) => const LoginScreen(),
          '/signup': (context) => const SignupScreen(),
          '/link-wallet': (context) => const LinkWalletScreen(),
          '/main': (context) => const MainScreen(),
        },
        // نقطة البداية
        home: const WelcomeScreen(), 
      ),
    );
  }
}