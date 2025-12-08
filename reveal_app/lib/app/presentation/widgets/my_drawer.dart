// lib/presentation/widgets/my_drawer.dart

import 'package:flutter/material.dart';

class MyDrawer extends StatelessWidget {
  const MyDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          // Header of the Drawer
          const UserAccountsDrawerHeader(
            accountName: Text(
              "اسم المستخدم",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            accountEmail: Text("user@example.com"),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                "U", // Placeholder for user initial
                style: TextStyle(fontSize: 40.0, color: Color(0xFFF27E49)),
              ),
            ),
            decoration: BoxDecoration(
              color: Color(0xFF2DBA9D), // Main green color
            ),
          ),
          // Drawer Items
          ListTile(
            leading: const Icon(Icons.home_outlined),
            title: const Text('الرئيسية'),
            onTap: () {
              // Close the drawer and navigate
              Navigator.pop(context);
              // TODO: Navigate to Home if not already there
            },
          ),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('الملف الشخصي'),
            onTap: () {
              Navigator.pop(context);
              // TODO: Navigate to Profile Screen
            },
          ),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('سجل الطلبات'),
            onTap: () {
              Navigator.pop(context);
              // TODO: Navigate to Orders History Screen
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: const Text('الإعدادات'),
            onTap: () {
              Navigator.pop(context);
              // TODO: Navigate to Settings Screen
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('تسجيل الخروج', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context);
              // TODO: Implement logout functionality
            },
          ),
        ],
      ),
    );
  }
}
