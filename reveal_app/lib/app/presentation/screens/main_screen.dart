import 'package:flutter/material.dart';
import 'package:reveal_app/app/presentation/screens/cart/cart_screen.dart';
import 'package:reveal_app/app/presentation/screens/home/home_screen.dart';
import 'package:reveal_app/app/presentation/screens/orders/orders_screen.dart';
import 'package:reveal_app/app/presentation/screens/wallet/wallet_screen.dart';
import 'package:reveal_app/screens/profile_screen_new.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 4; // Default to Home

  final List<Widget> _screens = const [
    WalletScreen(), // 0
    CartScreen(),   // 1
    ProfileScreenNew(),// 2
    OrdersScreen(), // 3
    HomeScreen(),   // 4
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: IndexedStack(
          index: _selectedIndex,
          children: _screens,
        ),
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            boxShadow: [
              BoxShadow(color: Colors.black12, blurRadius: 10, spreadRadius: 1),
            ],
          ),
          child: BottomNavigationBar(
            items: const <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                  icon: Icon(Icons.account_balance_wallet_outlined),
                  label: 'المحفظة'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.shopping_cart_outlined), 
                  label: 'السلة'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline), 
                  label: 'الملف'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.receipt_long_outlined), 
                  label: 'الطلبات'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.home_outlined), 
                  label: 'الرئيسية'),
            ],
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            selectedItemColor: const Color(0xFF2DBA9D),
            unselectedItemColor: Colors.grey,
            showUnselectedLabels: true,
            selectedFontSize: 12,
            unselectedFontSize: 12,
            elevation: 0,
          ),
        ),
      ),
    );
  }
}
