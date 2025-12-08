import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:reveal_app/app/data/providers/auth_provider.dart';
import 'package:reveal_app/app/data/providers/cart_provider.dart';
import 'package:reveal_app/app/data/providers/product_provider.dart';
import 'package:reveal_app/app/data/providers/wallet_provider.dart';
import 'package:reveal_app/app/data/providers/favorites_provider.dart';
import 'package:reveal_app/app/data/providers/college_provider.dart';
import 'package:reveal_app/app/presentation/screens/auth/welcome_screen.dart';
import 'package:reveal_app/app/presentation/screens/auth/login_screen.dart';
import 'package:reveal_app/app/presentation/screens/auth/signup_screen.dart';
import 'package:reveal_app/app/presentation/screens/main_screen.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
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
        theme: ThemeData(
          primarySwatch: Colors.teal,
          scaffoldBackgroundColor: Colors.white,
          fontFamily: 'GoogleFonts', 
        ),
        routes: {
          '/welcome': (context) => const WelcomeScreen(),
          '/login': (context) => const LoginScreen(),
          '/signup': (context) => const SignupScreen(),
          '/main': (context) => const MainScreen(),
        },
        home: const WelcomeScreen(), // البداية دائماً من الترحيب
      ),
    );
  }
}
