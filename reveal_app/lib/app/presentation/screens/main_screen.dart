// lib/app/presentation/screens/main_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // لتحديث الحالة عند تغيير الكلية
import 'package:shared_preferences/shared_preferences.dart'; // لجلب الاسم والصورة المحفوظة

// استدعاء الصفحات
import 'wallet/wallet_screen.dart';
import 'cart/cart_screen.dart';
import 'orders/orders_screen.dart';
import 'home/home_screen.dart';
import 'profile/profile_screen.dart'; // تأكد من الاسم الصحيح

// استدعاء المودل والخدمات إذا لزم الأمر
import '../../data/services/api_service.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 4; // نبدأ من الرئيسية
  String _userName = "جاري التحميل...";
  String _userEmail = "";
  String? _userImage; // مسار الصورة إذا وجدت

  // الألوان الرسمية
  final Color tealColor = const Color(0xFF009688);
  final Color orangeColor = const Color(0xFFFF5722);

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // جلب بيانات المستخدم الحقيقية للدرج
  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('user_name') ?? "يا بطل";
      _userEmail = prefs.getString('user_email') ?? "";
      _userImage = prefs.getString('user_image'); // نفترض أننا حفظنا مسار الصورة عند الدخول
    });

    // محاولة جلب أحدث البيانات من السيرفر
    try {
      final api = ApiService();
      final user = await api.getUserProfile();
      setState(() {
        _userName = user.fullName;
        _userEmail = user.email;
        // _userImage = user.image; // إذا كان المودل يدعم الصورة
      });
    } catch (e) {
      // تجاهل الخطأ، نعتمد على الكاش
    }
  }

  final List<String> _titles = [
    'المحفظة الإلكترونية',
    'سلة المشتريات',
    'الملف الشخصي',
    'طلباتي السابقة',
    'جامعة زليتن', 
  ];

  // صفحات التطبيق
  final List<Widget> _screens = const [
    WalletScreen(),       // 0
    CartScreen(),         // 1
    ProfileScreen(),      // 2
    OrdersScreen(),       // 3
    HomeScreen(),         // 4
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
        // 1. الشريط العلوي (يظهر في كل الصفحات)
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          title: Text(
            _titles[_selectedIndex],
            style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
          ),
          iconTheme: const IconThemeData(color: Colors.black),
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications_active_outlined, color: Colors.amber), // تنبيه بلون مميز
              onPressed: () {},
            ),
          ],
        ),

        // 2. القائمة الجانبية (Hamburger Menu) الواقعية
        drawer: _buildDrawer(),

        // 3. المحتوى
        body: IndexedStack(
          index: _selectedIndex,
          children: _screens,
        ),

        // 4. الشريط السفلي
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            boxShadow: [
              BoxShadow(color: Colors.black12, blurRadius: 15, spreadRadius: 1),
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

  // --- تصميم القائمة الجانبية المطور (Real Drawer) ---
  Widget _buildDrawer() {
    return Drawer(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(topLeft: Radius.circular(30), bottomLeft: Radius.circular(30)),
      ),
      child: Column(
        children: [
          // رأس القائمة المطور
          Container(
            padding: const EdgeInsets.only(top: 50, bottom: 20, right: 20, left: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [tealColor, const Color(0xFF4DB6AC)]),
              borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(30)),
            ),
            child: Row(
              children: [
                // الصورة (نفس منطق البروفايل)
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: const [BoxShadow(blurRadius: 10, color: Colors.black26)],
                  ),
                  child: CircleAvatar(
                    radius: 35,
                    backgroundColor: Colors.white,
                    backgroundImage: (_userImage != null && _userImage!.isNotEmpty)
                        ? NetworkImage(_userImage!) // صورة من السيرفر
                        : null,
                    child: (_userImage == null || _userImage!.isEmpty)
                        ? Text(
                            _userName.isNotEmpty ? _userName[0].toUpperCase() : "A",
                            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: tealColor),
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 15),
                // الاسم والايميل
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _userName,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 5),
                      Text(
                        _userEmail,
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // عناصر القائمة
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 10),
              children: [
                _buildDrawerItem(Icons.home_rounded, "الرئيسية", 4),
                _buildDrawerItem(Icons.person_rounded, "الملف الشخصي", 2),
                _buildDrawerItem(Icons.account_balance_wallet_rounded, "المحفظة", 0),
                
                const Divider(thickness: 1, indent: 20, endIndent: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Text("الكليات المتاحة", style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold)),
                ),
                
                // الكليات الثلاث الحقيقية
                _buildCollegeItem("مقهى كلية اللغة العربية", Icons.book),
                _buildCollegeItem("مقهى كلية تقنية المعلومات", Icons.computer),
                _buildCollegeItem("مقهى كلية الاقتصاد", Icons.attach_money),

                const Divider(thickness: 1, indent: 20, endIndent: 20),
                
                _buildSimpleItem(Icons.settings_outlined, "الإعدادات", () {}),
                _buildSimpleItem(Icons.help_outline, "المساعدة والدعم", () {}),
                
                const SizedBox(height: 20),
                _buildSimpleItem(Icons.logout, "تسجيل الخروج", () {
                   // منطق الخروج هنا (مسح التوكن والانتقال لصفحة الدخول)
                }, isDestructive: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // عنصر القائمة الأساسي (للتنقل بين التبويبات)
  Widget _buildDrawerItem(IconData icon, String title, int indexTarget) {
    bool isSelected = _selectedIndex == indexTarget;
    return ListTile(
      leading: Icon(icon, color: isSelected ? tealColor : Colors.grey[700]),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? tealColor : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        ),
      ),
      selected: isSelected,
      selectedTileColor: tealColor.withOpacity(0.05),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.horizontal(right: Radius.circular(20))),
      onTap: () {
        Navigator.pop(context);
        _onItemTapped(indexTarget);
      },
    );
  }

  // عنصر الكلية (تفاعلي)
  Widget _buildCollegeItem(String title, IconData icon) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, size: 20, color: tealColor),
      ),
      title: Text(title, style: const TextStyle(fontSize: 14)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
      onTap: () {
        Navigator.pop(context); // إغلاق القائمة
        _onItemTapped(4); // الذهاب للرئيسية
        // هنا مستقبلاً يمكن تمرير "ID الكلية" للفلترة في HomeScreen
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("تم اختيار $title")));
      },
    );
  }

  // عنصر بسيط (إعدادات، خروج...)
  Widget _buildSimpleItem(IconData icon, String title, VoidCallback onTap, {bool isDestructive = false}) {
    return ListTile(
      leading: Icon(icon, color: isDestructive ? Colors.red : Colors.grey[700]),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? Colors.red : Colors.black87,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
    );
  }

  // أيقونة الشريط السفلي
  BottomNavigationBarItem _buildNavItem(IconData icon, IconData activeIcon, String label, int index) {
    bool isSelected = _selectedIndex == index;
    return BottomNavigationBarItem(
      icon: Container(
        padding: const EdgeInsets.all(10),
        decoration: isSelected
            ? BoxDecoration(
                color: orangeColor,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: orangeColor.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 4))],
              )
            : null,
        child: Icon(
          isSelected ? activeIcon : icon,
          color: isSelected ? Colors.white : tealColor,
          size: 22,
        ),
      ),
      label: label,
    );
  }
}