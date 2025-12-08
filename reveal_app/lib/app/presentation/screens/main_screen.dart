import 'package:flutter/material.dart';
// نستخدم هنا اسم المشروع reveal_app للوصول للملفات بشكل مباشر وصحيح 100%
import 'package:reveal_app/app/presentation/widgets/my_drawer.dart';
import 'package:reveal_app/app/presentation/screens/home/home_screen.dart';
import 'package:reveal_app/app/presentation/screens/orders/orders_screen.dart';
import 'package:reveal_app/app/presentation/screens/profile/profile_screen.dart';
import 'package:reveal_app/app/presentation/screens/cart/cart_screen.dart';
import 'package:reveal_app/app/presentation/screens/wallet/wallet_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  // مؤشر الصفحة النشطة، يبدأ من 4 (الرئيسية)
  int _selectedIndex = 4; 

  // (تصحيح هام): قمنا بإزالة const من هنا لأن الشاشات متغيرة وليست ثابتة
  // وتم تغيير static const إلى final
  final List<Widget> _screens = [
    const WalletScreen(),   // 0
    const CartScreen(),     // 1
    const ProfileScreen(),  // 2
    const OrdersScreen(),   // 3
    const HomeScreen(),     // 4
  ];

  // قائمة العناوين
  static const List<String> _screenTitles = [
    'المحفظة',
    'السلة',
    'حسابي',
    'طلباتي',
    'المطاعم',
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
        appBar: AppBar(
          title: Text(_screenTitles[_selectedIndex]),
          centerTitle: true,
          // أيقونة المفضلة تظهر فقط في الرئيسية
          leading: _selectedIndex == 4
              ? IconButton(
                  icon: const Icon(Icons.favorite_border),
                  onPressed: () { /* TODO: Navigate to favorites */ },
                )
              : null,
          actions: [
            Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => Scaffold.of(context).openEndDrawer(),
              ),
            ),
          ],
        ),
        
        endDrawer: const MyDrawer(),
        
        // الجسم (Body)
        body: IndexedStack(
          index: _selectedIndex,
          children: _screens,
        ),
        
        // الشريط السفلي
        bottomNavigationBar: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet_outlined), label: 'المحفظة'),
            BottomNavigationBarItem(icon: Icon(Icons.shopping_cart_outlined), label: 'السلة'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'الحساب'),
            BottomNavigationBarItem(icon: Icon(Icons.receipt_long_outlined), label: 'طلباتي'),
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'الرئيسية'),
          ],
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFFF27E49),
          unselectedItemColor: Colors.grey[600],
          showUnselectedLabels: true,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}