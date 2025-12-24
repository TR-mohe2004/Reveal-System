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
import 'package:reveal_app/app/data/providers/notification_provider.dart';
import 'package:reveal_app/app/data/providers/theme_provider.dart';
import 'package:reveal_app/app/data/providers/navigation_provider.dart';
import 'package:reveal_app/app/data/providers/profile_image_provider.dart';

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
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()..loadTheme()),
        ChangeNotifierProvider(create: (_) => ProfileImageProvider()..load()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) => MaterialApp(
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
        
        darkTheme: ThemeData(
          brightness: Brightness.dark,
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF2DBA9D),
            secondary: Color(0xFFF4A259),
            background: Color(0xFF0F1116),
            surface: Color(0xFF1B2128),
          ),
          scaffoldBackgroundColor: const Color(0xFF0F1116),
          cardColor: const Color(0xFF1B2128),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF12161C),
            elevation: 0,
            centerTitle: true,
            iconTheme: IconThemeData(color: Colors.white),
            titleTextStyle: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontFamily: 'Cairo',
            ),
          ),
          bottomNavigationBarTheme: const BottomNavigationBarThemeData(
            backgroundColor: Color(0xFF12161C),
            selectedItemColor: Color(0xFFF4A259),
            unselectedItemColor: Colors.white70,
            showUnselectedLabels: true,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2DBA9D),
              foregroundColor: Colors.white,
            ),
          ),
          textTheme: GoogleFonts.cairoTextTheme(ThemeData.dark().textTheme).apply(
            bodyColor: Colors.white,
            displayColor: Colors.white,
          ),
        ),
        themeMode: themeProvider.themeMode,

        // --- 3. المسارات (Routes) ---
        home: const AuthGate(),
        routes: {
          '/welcome': (context) => const WelcomeScreen(),
          '/login': (context) => const LoginScreen(),
          '/signup': (context) => const SignupScreen(),
          '/main': (context) => const MainScreen(),
          '/wallet': (context) => const WalletScreen(), // مسار المحفظة المباشر
          '/link-wallet': (context) => const LinkWalletScreen(),
        },
      ),
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final status = context.watch<AuthProvider>().status;
    switch (status) {
      case AuthStatus.authenticated:
        return const MainScreen();
      case AuthStatus.unauthenticated:
        return const WelcomeScreen();
      case AuthStatus.authenticating:
      case AuthStatus.uninitialized:
      default:
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
    }
  }
}
