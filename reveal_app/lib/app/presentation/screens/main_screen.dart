// lib/app/presentation/screens/main_screen.dart

import 'package:flutter/material.dart';

// --- الاستدعاءات (Imports) ---
// هذه المسارات نسبية وتعتمد على أن الملفات موجودة داخل مجلداتها الخاصة
import 'wallet/wallet_screen.dart';
import 'cart/cart_screen.dart';
import 'orders/orders_screen.dart';
import 'home/home_screen.dart';

// تنبيه: تأكد من اسم ملف البروفايل داخل مجلد profile
// إذا كان اسمه profile_screen.dart اترك السطر التالي، وإذا كان profile_screen_new.dart عدله
import 'profile/profile_screen.dart'; 

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  // نبدأ من الصفحة الرئيسية (index 4)
  int _selectedIndex = 4;

  // الألوان الرسمية
  final Color tealColor = const Color(0xFF009688);
  final Color orangeColor = const Color(0xFFFF5722);

  // عناوين الصفحات لتغيير الـ AppBar ديناميكياً
  final List<String> _titles = [
    'المحفظة الإلكترونية',
    'سلة المشتريات',
    'الملف الشخصي',
    'طلباتي السابقة',
    'جامعة زليتن', // تم التعديل
  ];

  // قائمة الشاشات
  // ملاحظة هامة: لتجنب تكرار القوائم، يجب حذف الـ Scaffold والـ AppBar من داخل هذه الشاشات
  final List<Widget> _screens = const [
    WalletScreen(),       // Index 0
    CartScreen(),         // Index 1
    ProfileScreen(),      // Index 2 (أو ProfileScreenNew حسب اسم الكلاس)
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
      textDirection: TextDirection.rtl,
      child: Scaffold(
        // 1. الشريط العلوي الموحد (يظهر في كل الصفحات)
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          title: Text(
            _titles[_selectedIndex], // العنوان يتغير حسب الصفحة
            style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
          iconTheme: const IconThemeData(color: Colors.black), // لون أيقونة القائمة
          actions: [
            // إضافة أيقونة التنبيهات
            IconButton(
              icon: const Icon(Icons.notifications_none),
              onPressed: () {},
            ),
          ],
        ),

        // 2. القائمة الجانبية الموحدة (Hamburger Menu)
        drawer: _buildDrawer(),

        // 3. جسم الصفحة (يحتفظ بحالة الصفحات)
        body: IndexedStack(
          index: _selectedIndex,
          children: _screens,
        ),

        // 4. الشريط السفلي الموحد
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
            selectedItemColor: Colors.white,
            unselectedItemColor: Colors.grey,
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

  // --- تصميم القائمة الجانبية (Drawer) ---
  Widget _buildDrawer() {
    return Drawer(
      child: Column(
        children: [
          // رأس القائمة (بيانات المستخدم)
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(color: tealColor),
            accountName: const Text(
              "أحمد محمد", // اسم افتراضي بدلاً من زائر
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            accountEmail: const Text("Student ID: 21901044"), // رقم قيد افتراضي
            currentAccountPicture: const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.person, size: 40, color: Colors.grey),
            ),
          ),
          
          // عناصر القائمة
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerItem(Icons.home, "الرئيسية", 4),
                _buildDrawerItem(Icons.receipt_long, "طلباتي السابقة", 3),
                _buildDrawerItem(Icons.shopping_cart, "سلة المشتريات", 1),
                _buildDrawerItem(Icons.account_balance_wallet, "المحفظة الإلكترونية", 0),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.store),
                  title: const Text("كلية العلوم (مقهى 1)"),
                  onTap: () {
                    // هنا سنضيف منطق الانتقال للمقهى المحدد
                    Navigator.pop(context); 
                    _onItemTapped(4); // العودة للرئيسية حالياً
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.store),
                  title: const Text("كلية الهندسة (مقهى 2)"),
                  onTap: () {
                    Navigator.pop(context);
                    _onItemTapped(4);
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.settings, color: Colors.grey),
                  title: const Text("الإعدادات"),
                  onTap: () {},
                ),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text("تسجيل الخروج", style: TextStyle(color: Colors.red)),
                  onTap: () {
                    // منطق تسجيل الخروج
                  },
                ),
              ],
            ),
          ),
          
          // تذييل القائمة
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              "Reveal App v1.0",
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  // عنصر في القائمة الجانبية يقوم بتغيير التبويب
  Widget _buildDrawerItem(IconData icon, String title, int indexTarget) {
    return ListTile(
      leading: Icon(icon, color: _selectedIndex == indexTarget ? tealColor : Colors.grey[700]),
      title: Text(
        title,
        style: TextStyle(
          color: _selectedIndex == indexTarget ? tealColor : Colors.black,
          fontWeight: _selectedIndex == indexTarget ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      onTap: () {
        Navigator.pop(context); // إغلاق القائمة
        _onItemTapped(indexTarget); // الانتقال للصفحة المطلوبة
      },
    );
  }

  // تصميم أيقونة الشريط السفلي
  BottomNavigationBarItem _buildNavItem(IconData icon, IconData activeIcon, String label, int index) {
    bool isSelected = _selectedIndex == index;
    return BottomNavigationBarItem(
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: isSelected
            ? BoxDecoration(
                color: orangeColor,
                shape: BoxShape.circle,
                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
              )
            : null,
        child: Icon(
          isSelected ? activeIcon : icon,
          color: isSelected ? Colors.white : tealColor,
          size: 24,
        ),
      ),
      label: label,
    );
  }
}