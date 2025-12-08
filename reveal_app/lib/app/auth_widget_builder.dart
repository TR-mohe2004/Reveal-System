import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reveal_app/app/data/providers/auth_provider.dart';
import 'package:reveal_app/app/presentation/screens/auth/welcome_screen.dart';
import 'package:reveal_app/app/presentation/screens/main_screen.dart';

class AuthWidgetBuilder extends StatelessWidget {
  const AuthWidgetBuilder({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        // التحقق من حالة تسجيل الدخول اعتماداً على التوكن
        if (authProvider.isLoggedIn) {
          return const MainScreen();
        }
        return const WelcomeScreen();
      },
    );
  }
}
