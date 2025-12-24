import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:reveal_app/app/data/providers/profile_image_provider.dart'; // مكتبة اختيار الصور
import 'package:reveal_app/app/data/models/user_model.dart';
import 'package:reveal_app/app/data/models/wallet_model.dart';
import 'package:reveal_app/app/data/services/api_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool isLoading = true;
  User? userProfile;
  WalletModel? userWallet; // نحتاج المحفظة لعرض كود الربط
  
  final ApiService _apiService = ApiService();
  final ImagePicker _picker = ImagePicker();
  File? _localImage; // لحفظ الصورة المختارة محلياً قبل الرفع

  final Color tealColor = const Color(0xFF009688);
  final Color orangeColor = const Color(0xFFFF5722);

  @override
  void initState() {
    super.initState();
    _fetchAllData();
  }

  // جلب بيانات المستخدم + بيانات المحفظة
  Future<void> _fetchAllData() async {
    setState(() => isLoading = true);
    try {
      // 1. جلب البروفايل
      final user = await _apiService.getUserProfile();
      // 2. جلب المحفظة (عشان كود الربط)
      WalletModel? wallet;
      try {
        wallet = await _apiService.getWallet();
      } catch (_) {
        // قد لا يملك محفظة بعد
      }

      if (mounted) {
        setState(() {
          userProfile = user;
          userWallet = wallet;
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading profile: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  // دالة اختيار صورة
  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _localImage = File(image.path);
      });
      context.read<ProfileImageProvider>().setPersistentImage(image.path);
      // هنا مفروض يتم استدعاء دالة API لرفع الصورة للسيرفر
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("تم حفظ الصورة الجديدة محلياً")),
      );
    }
  }

  // دالة تعديل البيانات (فتح نافذة)
  void _showEditDialog() {
    final nameController = TextEditingController(text: userProfile?.fullName);
    final phoneController = TextEditingController(text: userProfile?.phoneNumber);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("تعديل البيانات"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "الاسم الكامل", prefixIcon: Icon(Icons.person)),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(labelText: "رقم الهاتف", prefixIcon: Icon(Icons.phone)),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("إلغاء")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: tealColor),
            onPressed: () {
              // هنا استدعاء API لتحديث البيانات
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("تم تحديث البيانات بنجاح (محاكاة)")),
              );
            },
            child: const Text("حفظ"),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const defaultImage = "https://cdn-icons-png.flaticon.com/512/3135/3135715.png";
    // صورة خلفية جمالية
    const headerImage = "https://images.unsplash.com/photo-1557683316-973673baf926?w=800&q=80"; 

    final persistedPath = context.watch<ProfileImageProvider>().localPath;
    final localPath = _localImage?.path ?? persistedPath;
    final networkImage = (userProfile?.profileImage ?? '').trim();
    final ImageProvider<Object> profileImage;
    if (localPath != null && File(localPath).existsSync()) {
      profileImage = FileImage(File(localPath)) as ImageProvider<Object>;
    } else if (networkImage.isNotEmpty) {
      profileImage = NetworkImage(networkImage) as ImageProvider<Object>;
    } else {
      profileImage = NetworkImage(defaultImage) as ImageProvider<Object>;
    }

    String joinedDate = "--";
    final rawJoined = userProfile?.dateJoined;
    if (rawJoined != null && rawJoined.trim().isNotEmpty) {
      final parsed = DateTime.tryParse(rawJoined);
      joinedDate = parsed != null ? DateFormat('yyyy-MM-dd').format(parsed) : rawJoined;
    }

    return Scaffold(
      backgroundColor: Colors.grey[50], // خلفية فاتحة جداً
      
      // لا نحتاج AppBar لأننا سنستخدم تصميم Stack مخصص
      // ولكن لكي يظهر زر القائمة، سنضعه فوق الصورة
      
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: tealColor))
          : userProfile == null
              ? const Center(child: Text("تعذر تحميل البيانات"))
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      // --- 1. الهيدر والصورة ---
                      Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.center,
                        children: [
                          // خلفية الهيدر
                          Container(
                            height: 200,
                            width: double.infinity,
                            decoration: const BoxDecoration(
                              image: DecorationImage(image: NetworkImage(headerImage), fit: BoxFit.cover),
                              borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
                            ),
                          ),
                          // طبقة شفافة فوق الخلفية
                          Container(
                            height: 200,
                            decoration: BoxDecoration(
                              color: tealColor.withOpacity(0.7),
                              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
                            ),
                          ),
                          
                          // زر القائمة الجانبية (Custom AppBar)
                          Positioned(
                            top: 40,
                            left: 16,
                            child: const Text(
                              "حسابي",
                              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                          ),

                          // صورة البروفايل مع زر التعديل
                          Positioned(
                            bottom: -50,
                            child: Stack(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                                  child: CircleAvatar(
                                    radius: 60,
                                    backgroundImage: profileImage,
                                  ),
                                ),
                                // أيقونة الكاميرا لتغيير الصورة
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: InkWell(
                                    onTap: _pickImage,
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: orangeColor,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 2),
                                      ),
                                      child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 60), // مسافة عشان الصورة النازلة

                      // --- 2. الإسم والبريد ---
                      Text(
                        userProfile!.fullName,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        userProfile!.email,
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),

                      const SizedBox(height: 20),

                      // --- 3. زر تعديل البيانات ---
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: ElevatedButton.icon(
                          onPressed: _showEditDialog,
                          icon: const Icon(Icons.edit, size: 18),
                          label: const Text("تعديل الملف الشخصي"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: tealColor,
                            elevation: 0,
                            side: BorderSide(color: tealColor),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            minimumSize: const Size(double.infinity, 45),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // --- 4. البطاقات (المعلومات وكود المحفظة) ---
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Column(
                          children: [
                            // كرت كود الربط (المهم جداً)
                            if (userWallet != null)
                              Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(colors: [orangeColor, Colors.deepOrange]),
                                  borderRadius: BorderRadius.circular(15),
                                  boxShadow: [BoxShadow(color: orangeColor.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text("كود المحفظة (للشحن)", style: TextStyle(color: Colors.white70, fontSize: 12)),
                                        const SizedBox(height: 4),
                                        SelectableText(
                                          userWallet!.linkCode.isEmpty ? "---" : userWallet!.linkCode,
                                          style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2),
                                        ),
                                      ],
                                    ),
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                                      child: const Icon(Icons.qr_code, color: Colors.white, size: 28),
                                    ),
                                  ],
                                ),
                              ),

                            // باقي المعلومات
                            _buildInfoCard("رقم الهاتف", userProfile!.phoneNumber, Icons.phone_android),
                            _buildInfoCard("الكلية", "كلية تقنية المعلومات", Icons.school), // يمكن جلبها من المودل لاحقاً
                            _buildInfoCard("تاريخ الانضمام", joinedDate, Icons.calendar_today),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
      
      // القائمة الجانبية (نفس الموجودة في MainScreen)
    );
  }

  // تصميم الكارت الصغير
  Widget _buildInfoCard(String label, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: tealColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: tealColor, size: 20),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
