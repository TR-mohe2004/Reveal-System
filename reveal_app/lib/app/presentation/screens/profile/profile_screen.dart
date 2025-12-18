import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:reveal_app/app/data/services/api_service.dart';
// ✅ استخدام المودل العام
import 'package:reveal_app/app/data/models/user_model.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool isLoading = true;
  User? userProfile; // استخدام UserModel العام
  final ApiService _apiService = ApiService();

  final Color tealColor = const Color(0xFF009688);

  @override
  void initState() {
    super.initState();
    fetchUserProfile();
  }

  Future<void> fetchUserProfile() async {
    try {
      // محاولة جلب البيانات من السيرفر
      final user = await _apiService.getUserProfile();
      if (mounted) {
        setState(() {
          userProfile = user;
          isLoading = false;
        });
      }
    } catch (e) {
      // إذا فشل السيرفر، نستخدم بيانات الفايربيز المؤقتة
      final fbUser = auth.FirebaseAuth.instance.currentUser;
      if (mounted) {
        setState(() {
          if (fbUser != null) {
            // ✅ إنشاء كائن User يدوياً مع معالجة القيم الفارغة
            userProfile = User(
              id: 0,
              fullName: fbUser.displayName ?? "مستخدم التطبيق",
              email: fbUser.email ?? "no-email",
              phoneNumber: fbUser.phoneNumber ?? "غير متوفر",
              profileImage: fbUser.photoURL,
            );
          }
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // صورة افتراضية
    const defaultImage = "https://cdn-icons-png.flaticon.com/512/3135/3135715.png";
    const headerImage = "https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=500&q=80";

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
           Builder(builder: (context) => IconButton(icon: const Icon(Icons.menu, color: Colors.black), onPressed: () => Scaffold.of(context).openDrawer())),
        ],
        title: const Align(alignment: Alignment.centerRight, child: Text("حسابي", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold))),
      ),
      drawer: const Drawer(child: Center(child: Text("القائمة الجانبية"))),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: tealColor))
          : userProfile == null 
             ? const Center(child: Text("يجب تسجيل الدخول"))
             : SingleChildScrollView(
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.center, clipBehavior: Clip.none,
                    children: [
                      Container(
                        height: 140, margin: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          image: const DecorationImage(image: NetworkImage(headerImage), fit: BoxFit.cover),
                        ),
                      ),
                      Positioned(
                        bottom: -50,
                        child: CircleAvatar(
                          radius: 54, backgroundColor: Colors.white,
                          child: CircleAvatar(
                            radius: 50,
                            backgroundImage: NetworkImage(userProfile!.profileImage ?? defaultImage),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 60),
                  
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      children: [
                        const SizedBox(height: 10),
                        _buildInfoCard("الإسم واللقب", userProfile!.fullName, Icons.person),
                        _buildInfoCard("رقم الهاتف", userProfile!.phoneNumber, Icons.phone),
                        _buildInfoCard("البريد الإلكتروني", userProfile!.email, Icons.email),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoCard(String label, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: tealColor),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}