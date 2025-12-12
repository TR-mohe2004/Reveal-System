import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reveal_app/app/data/models/college_model.dart';
import 'package:reveal_app/app/data/providers/auth_provider.dart';
import 'package:reveal_app/app/data/providers/college_provider.dart';
import 'package:reveal_app/app/presentation/screens/cart/cart_screen.dart';
import 'package:reveal_app/app/presentation/screens/home/home_screen.dart';
import 'package:reveal_app/app/presentation/screens/orders/orders_screen.dart';
import 'package:reveal_app/app/presentation/screens/profile/profile_screen.dart';
import 'package:reveal_app/app/presentation/screens/wallet/wallet_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 4; // Default to Home

  final List<Widget> _screens = const [
    WalletScreen(), // 0
    CartScreen(), // 1
    ProfileScreen(), // 2
    OrdersScreen(), // 3
    HomeScreen(), // 4
  ];

  static const List<String> _screenTitles = [
    'المحفظة',
    'السلة',
    'الملف الشخصي',
    'الطلبات',
    'الرئيسية',
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;
    final fullName = user?.fullName ?? '';
    final email = user?.email ?? '';
    final initial = fullName.isNotEmpty ? fullName[0].toUpperCase() : 'R';

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          title: _buildAppBarTitle(),
          centerTitle: true,
          backgroundColor: Colors.white,
          elevation: 0,
          actions: [
            Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu, color: Colors.black),
                onPressed: () => Scaffold.of(context).openEndDrawer(),
              ),
            ),
          ],
          leading: _selectedIndex == 4
              ? IconButton(
                  icon: const Icon(Icons.favorite_border, color: Colors.black),
                  onPressed: () {
                    // TODO: navigate to favorites
                  },
                )
              : null,
          automaticallyImplyLeading: false,
        ),
        endDrawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              UserAccountsDrawerHeader(
                accountName: Text(fullName.isNotEmpty ? fullName : 'المستخدم'),
                accountEmail: Text(email),
                currentAccountPicture: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Text(
                    initial,
                    style: const TextStyle(fontSize: 40.0, color: Color(0xFF2DBA9D)),
                  ),
                ),
                decoration: const BoxDecoration(
                  color: Color(0xFF2DBA9D),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('حول التطبيق'),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: navigate to about screen
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text('تسجيل الخروج', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('تسجيل الخروج'),
                      content: const Text('هل أنت متأكد من تسجيل الخروج؟'),
                      actions: <Widget>[
                        TextButton(
                          child: const Text('إلغاء'),
                          onPressed: () => Navigator.of(ctx).pop(),
                        ),
                        TextButton(
                          child: const Text('خروج', style: TextStyle(color: Colors.red)),
                          onPressed: () {
                            Navigator.of(ctx).pop();
                            context.read<AuthProvider>().logout();
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
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
              BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet_outlined), label: 'المحفظة'),
              BottomNavigationBarItem(icon: Icon(Icons.shopping_cart_outlined), label: 'السلة'),
              BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'الملف'),
              BottomNavigationBarItem(icon: Icon(Icons.receipt_long_outlined), label: 'الطلبات'),
              BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'الرئيسية'),
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

  Widget _buildAppBarTitle() {
    if (_selectedIndex == 4) {
      return Consumer<CollegeProvider>(
        builder: (context, collegeProvider, child) {
          switch (collegeProvider.state) {
            case CollegeState.loading:
            case CollegeState.initial:
              return const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 3),
              );
            case CollegeState.error:
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('خطأ في جلب الكليات', style: TextStyle(color: Colors.red)),
                  IconButton(
                    icon: const Icon(Icons.refresh, color: Colors.red),
                    onPressed: () => collegeProvider.fetchColleges(),
                  ),
                ],
              );
            case CollegeState.loaded:
              if (collegeProvider.selectedCollege == null) {
                return const Text('اختر الكلية');
              }
              return DropdownButton<College>(
                value: collegeProvider.selectedCollege,
                underline: const SizedBox.shrink(),
                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.black),
                items: collegeProvider.availableColleges.map((college) {
                  return DropdownMenuItem<College>(
                    value: college,
                    child: Text(
                      college.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                        fontSize: 18,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (newCollege) {
                  if (newCollege != null) {
                    collegeProvider.selectCollege(newCollege);
                  }
                },
              );
          }
        },
      );
    }
    return Text(
      _screenTitles[_selectedIndex],
      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
    );
  }
}

