import 'package:flutter/material.dart';

// تأكد أن هذه المسارات صحيحة وموجودة لديك
import 'package:reveal_app/app/presentation/screens/cart/cart_screen.dart';
import 'package:reveal_app/app/presentation/screens/home/home_screen.dart';
import 'package:reveal_app/app/presentation/screens/orders/orders_screen.dart';
import 'package:reveal_app/app/presentation/screens/wallet/wallet_screen.dart';
// تأكد من اسم الملف هل هو profile_screen_new.dart أم profile_screen.dart
import 'package:reveal_app/screens/profile_screen_new.dart'; 

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  // نبدأ من الصفحة الرئيسية (رقم 4 حسب ترتيبك)
  int _selectedIndex = 4; 

  // الألوان الرسمية
  final Color tealColor = const Color(0xFF009688);
  final Color orangeColor = const Color(0xFFFF5722);

  // قائمة الشاشات (يجب أن تطابق ترتيب الأيقونات في الأسفل)
  final List<Widget> _screens = const [
    WalletScreen(),       // Index 0
    CartScreen(),         // Index 1
    ProfileScreenNew(),   // Index 2
    OrdersScreen(),       // Index 3
    HomeScreen(),         // Index 4
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl, // جعل اتجاه التطبيق من اليمين لليسار
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        
        // عرض الشاشة المختارة مع الحفاظ على حالتها
        body: IndexedStack(
          index: _selectedIndex,
          children: _screens,
        ),
        
        // الشريط السفلي المخصص
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            boxShadow: [
              BoxShadow(color: Colors.black12, blurRadius: 10, spreadRadius: 1),
            ],
          ),
          child: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            selectedItemColor: Colors.white, // النص المختار أبيض (لأنه داخل دائرة)
            unselectedItemColor: Colors.grey, // النص غير المختار رمادي
            showSelectedLabels: true,
            showUnselectedLabels: true,
            selectedFontSize: 12,
            unselectedFontSize: 10,
            elevation: 0,
            items: [
              _buildNavItem(Icons.account_balance_wallet_outlined, Icons.account_balance_wallet, 'المحفظة', 0),
              _buildNavItem(Icons.shopping_cart_outlined, Icons.shopping_cart, 'السلة', 1),
              _buildNavItem(Icons.person_outline, Icons.person, 'الملف', 2),
              _buildNavItem(Icons.receipt_long_outlined, Icons.receipt_long, 'الطلبات', 3),
              _buildNavItem(Icons.home_outlined, Icons.home, 'الرئيسية', 4),
            ],
          ),
        ),
      ),
    );
  }

  // دالة مساعدة لإنشاء أيقونة تفاعلية (دائرة برتقالية عند الاختيار)
  BottomNavigationBarItem _buildNavItem(IconData icon, IconData activeIcon, String label, int index) {
    bool isSelected = _selectedIndex == index;
    return BottomNavigationBarItem(
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: isSelected
            ? BoxDecoration(
                color: orangeColor, // الخلفية البرتقالية عند التفعيل
                shape: BoxShape.circle,
                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
              )
            : null,
        child: Icon(
          isSelected ? activeIcon : icon, // تغيير الأيقونة عند الاختيار (Filled vs Outlined)
          color: isSelected ? Colors.white : tealColor, // الأيقونة بيضاء عند الاختيار، وتركواز عند عدم الاختيار
          size: 24,
        ),
      ),
      label: label,
    );
  }
}