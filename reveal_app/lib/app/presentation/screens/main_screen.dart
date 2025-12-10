import 'package:flutter/material.dart';
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
  // نبدأ من الصفحة الرئيسية (index 4 في القائمة أدناه)
  int _selectedIndex = 4; 

  // قائمة الصفحات (تأكد من ترتيبها ليتطابق مع الشريط السفلي)
  // 0: المحفظة, 1: السلة, 2: الحساب, 3: الطلبات, 4: الرئيسية
  final List<Widget> _screens = [
    const WalletScreen(),   // 0
    const CartScreen(),     // 1
    const ProfileScreen(),  // 2
    const OrdersScreen(),   // 3
    const HomeScreen(),     // 4
  ];

  // عناوين الصفحات للعرض في الشريط العلوي
  static const List<String> _screenTitles = [
    'محفظتي',
    'سلة المشتريات',
    'ملفي الشخصي',
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
    // استخدام Directionality لضمان اتجاه التطبيق من اليمين لليسار
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        // منع تحرك الشاشة عند ظهور الكيبورد
        resizeToAvoidBottomInset: false,
        
        // الشريط العلوي (يظهر فقط العنوان والقائمة الجانبية)
        appBar: AppBar(
          title: Text(
            _screenTitles[_selectedIndex],
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
          ),
          centerTitle: true,
          backgroundColor: Colors.white,
          elevation: 0,
          // زر القائمة الجانبية (Drawer)
          actions: [
            Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu, color: Colors.black),
                onPressed: () => Scaffold.of(context).openEndDrawer(),
              ),
            ),
          ],
          // إخفاء زر الرجوع التلقائي
          leading: _selectedIndex == 4 
             ? IconButton(
                 icon: const Icon(Icons.favorite_border, color: Colors.black),
                 onPressed: () {
                   // يمكن توجيه المستخدم للمفضلة هنا
                 },
               )
             : null,
          automaticallyImplyLeading: false, 
        ),

        // القائمة الجانبية
        endDrawer: const MyDrawer(),

        // جسم الصفحة (نستخدم IndexedStack للحفاظ على حالة الصفحات)
        body: IndexedStack(
          index: _selectedIndex,
          children: _screens,
        ),

        // الشريط السفلي
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(color: Colors.black12, blurRadius: 10, spreadRadius: 1),
            ],
          ),
          child: BottomNavigationBar(
            items: const <BottomNavigationBarItem>[
              BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet_outlined), label: 'المحفظة'),
              BottomNavigationBarItem(icon: Icon(Icons.shopping_cart_outlined), label: 'السلة'),
              BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'الحساب'),
              BottomNavigationBarItem(icon: Icon(Icons.receipt_long_outlined), label: 'طلباتي'),
              BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'الرئيسية'),
            ],
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            selectedItemColor: const Color(0xFF2DBA9D), // اللون الأساسي للتطبيق
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