// lib/app/presentation/screens/main_screen.dart

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // لتحديث الحالة عند تغيير الكلية
import 'package:shared_preferences/shared_preferences.dart';
import 'package:reveal_app/app/data/providers/notification_provider.dart';
import 'package:reveal_app/app/data/providers/navigation_provider.dart';
import 'package:reveal_app/app/data/providers/profile_image_provider.dart'; // لجلب الاسم والصورة المحفوظة

// استدعاء الصفحات
import 'wallet/wallet_screen.dart';
import 'cart/cart_screen.dart';
import 'orders/orders_screen.dart';
import 'home/home_screen.dart';
import 'profile/profile_screen.dart';
import 'notifications/notifications_screen.dart';
import 'settings/settings_screen.dart';
import 'support/support_screen.dart'; // تأكد من الاسم الصحيح

// استدعاء المودل والخدمات إذا لزم الأمر
import '../../data/services/api_service.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with SingleTickerProviderStateMixin {
  String _userName = "جاري التحميل...";
  String _userEmail = "";
  String? _userImage; // مسار الصورة إذا وجدت

  // الألوان الرسمية
  final Color tealColor = const Color(0xFF009688);
  final Color orangeColor = const Color(0xFFFF5722);

  late final AnimationController _bellController;
  late final Animation<double> _bellPulse;
  Timer? _notificationTimer;
  bool _isRefreshingNotifications = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _bellController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _bellPulse = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _bellController, curve: Curves.easeInOut),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().load();
      _startNotificationPolling();
    });
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
      await prefs.setString('user_name', user.fullName);
      await prefs.setString('user_email', user.email);
      if (user.profileImage != null && user.profileImage!.isNotEmpty) {
        await prefs.setString('user_image', user.profileImage!);
      } else {
        await prefs.remove('user_image');
      }
      setState(() {
        _userName = user.fullName;
        _userEmail = user.email;
        _userImage = user.profileImage;
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
    context.read<NavigationProvider>().setIndex(index);
  }

  void _startNotificationPolling() {
    if (_notificationTimer != null) {
      return;
    }
    _refreshNotifications();
    _notificationTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      _refreshNotifications();
    });
  }

  Future<void> _refreshNotifications() async {
    if (_isRefreshingNotifications) {
      return;
    }
    _isRefreshingNotifications = true;
    final provider = context.read<NotificationProvider>();

    try {
      final api = ApiService();
      final orders = await api.getOrders();
      if (!mounted) {
        return;
      }
      await provider.refreshFromOrders(orders);
    } catch (_) {
      // ignore polling errors
    } finally {
      _isRefreshingNotifications = false;
    }
  }

  @override
  void dispose() {
    _notificationTimer?.cancel();
    _bellController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = context.watch<NavigationProvider>().currentIndex;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        // 1. الشريط العلوي (يظهر في كل الصفحات)
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          title: Text(
            _titles[currentIndex],
            style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
          ),
          iconTheme: const IconThemeData(color: Colors.black),
          actions: [
            Consumer<NotificationProvider>(
              builder: (context, provider, _) {
                final count = provider.unreadCount;
                if (count > 0 && !_bellController.isAnimating) {
                  _bellController.repeat(reverse: true);
                } else if (count == 0 && _bellController.isAnimating) {
                  _bellController.stop();
                }

                return Stack(
                  alignment: Alignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications_active_outlined, color: Colors.amber),
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                        );
                        await context.read<NotificationProvider>().markAllRead();
                      },
                    ),
                    if (count > 0)
                      Positioned(
                        top: 10,
                        right: 10,
                        child: ScaleTransition(
                          scale: _bellPulse,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),

        // 2. القائمة الجانبية (Hamburger Menu) الواقعية
        drawer: _buildDrawer(),

        // 3. المحتوى
        body: IndexedStack(
          index: currentIndex,
          children: _screens,
        ),

        // 4. الشريط السفلي
        bottomNavigationBar: SafeArea(
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 18, offset: const Offset(0, 8)),
              ],
            ),
            child: Row(
              children: [
                _buildBottomNavItem(Icons.account_balance_wallet_outlined, Icons.account_balance_wallet, 'المحفظة', 0),
                _buildBottomNavItem(Icons.shopping_cart_outlined, Icons.shopping_cart, 'السلة', 1),
                _buildBottomNavItem(Icons.person_outline, Icons.person, 'الملف', 2),
                _buildBottomNavItem(Icons.receipt_long_outlined, Icons.receipt_long, 'الطلبات', 3),
                _buildBottomNavItem(Icons.home_outlined, Icons.home, 'الرئيسية', 4),
              ],
            ),
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
            child: Builder(
              builder: (context) {
                final localProfilePath = context.watch<ProfileImageProvider>().localPath;
                ImageProvider<Object>? profileImage;
                if (localProfilePath != null && File(localProfilePath).existsSync()) {
                  profileImage = FileImage(File(localProfilePath)) as ImageProvider<Object>;
                } else if (_userImage != null && _userImage!.isNotEmpty) {
                  profileImage = NetworkImage(_userImage!) as ImageProvider<Object>;
                }
                return Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: const [BoxShadow(blurRadius: 10, color: Colors.black26)],
                      ),
                      child: CircleAvatar(
                        radius: 35,
                        backgroundColor: Colors.white,
                        backgroundImage: profileImage,
                        child: profileImage == null
                            ? Text(
                                _userName.isNotEmpty ? _userName[0].toUpperCase() : "A",
                                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: tealColor),
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(width: 15),
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
                );
              },
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
                
                _buildSimpleItem(Icons.settings_outlined, "الإعدادات", () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  );
                }),
                _buildSimpleItem(Icons.help_outline, "المساعدة والدعم", () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SupportScreen()),
                  );
                }),
                
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
    bool isSelected = context.watch<NavigationProvider>().currentIndex == indexTarget;
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

  Widget _buildBottomNavItem(IconData icon, IconData activeIcon, String label, int index) {
    final isSelected = context.watch<NavigationProvider>().currentIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () => _onItemTapped(index),
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? tealColor.withOpacity(0.08) : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: isSelected ? orangeColor : Colors.grey.shade100,
                  shape: BoxShape.circle,
                  boxShadow: isSelected
                      ? [BoxShadow(color: orangeColor.withOpacity(0.35), blurRadius: 10, offset: const Offset(0, 4))]
                      : [],
                ),
                child: Icon(
                  isSelected ? activeIcon : icon,
                  color: isSelected ? Colors.white : tealColor,
                  size: 20,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? tealColor : Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
