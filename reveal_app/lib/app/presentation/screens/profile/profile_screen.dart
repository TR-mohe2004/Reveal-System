import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:reveal_app/app/data/models/user_model.dart';
import 'package:reveal_app/app/data/models/wallet_model.dart';
import 'package:reveal_app/app/data/providers/profile_image_provider.dart';
import 'package:reveal_app/app/data/services/api_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool isLoading = true;
  bool _isSavingProfile = false;
  User? userProfile;
  WalletModel? userWallet;

  final ApiService _apiService = ApiService();
  final ImagePicker _picker = ImagePicker();
  File? _localImage;

  final Color tealColor = const Color(0xFF009688);
  final Color orangeColor = const Color(0xFFFF5722);

  @override
  void initState() {
    super.initState();
    _fetchAllData();
  }

  Future<void> _fetchAllData() async {
    setState(() => isLoading = true);
    try {
      final user = await _apiService.getUserProfile();
      WalletModel? wallet;
      try {
        wallet = await _apiService.getWallet();
      } catch (_) {}

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

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("لم يتم اختيار صورة")),
        );
        return;
      }

      final directory = await getApplicationDocumentsDirectory();
      final rawPath = image.path;
      final ext = rawPath.contains('.') ? rawPath.split('.').last : 'jpg';
      final savedPath = '${directory.path}/profile_${DateTime.now().millisecondsSinceEpoch}.$ext';
      final savedImage = await File(rawPath).copy(savedPath);

      setState(() {
        _localImage = savedImage;
      });
      await context.read<ProfileImageProvider>().setPersistentImage(savedImage.path);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("تم حفظ الصورة محلياً")),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("حدث خطأ أثناء اختيار الصورة: $e")),
      );
    }
  }

  Future<void> _saveProfile(String fullName) async {
    if (_isSavingProfile) return;
    final name = fullName.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("الاسم مطلوب")),
      );
      return;
    }

    setState(() => _isSavingProfile = true);
    try {
      final updatedUser = await _apiService.updateUserProfile(fullName: name);
      if (!mounted) return;
      setState(() {
        userProfile = updatedUser;
      });

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_name', updatedUser.fullName);
      await prefs.setString('user_email', updatedUser.email);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("تم تحديث البيانات بنجاح")),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) setState(() => _isSavingProfile = false);
    }
  }

  void _showEditDialog() {
    final nameController = TextEditingController(text: userProfile?.fullName ?? '');
    final phoneValue = userProfile?.phoneNumber ?? '';

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
              controller: TextEditingController(text: phoneValue),
              enabled: false,
              decoration: const InputDecoration(labelText: "رقم الهاتف", prefixIcon: Icon(Icons.phone)),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("إلغاء")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: tealColor),
            onPressed: () {
              Navigator.pop(ctx);
              _saveProfile(nameController.text);
            },
            child: const Text("حفظ"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const defaultImage = "https://cdn-icons-png.flaticon.com/512/3135/3135715.png";
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
      joinedDate = parsed != null ? DateFormat('yyyy/MM/dd').format(parsed) : rawJoined;
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: tealColor))
          : userProfile == null
              ? const Center(child: Text("تعذر تحميل البيانات"))
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      SizedBox(
                        height: 260,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Positioned(
                              top: 0,
                              left: 0,
                              right: 0,
                              child: Container(
                                height: 200,
                                decoration: const BoxDecoration(
                                  image: DecorationImage(image: NetworkImage(headerImage), fit: BoxFit.cover),
                                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 0,
                              left: 0,
                              right: 0,
                              child: Container(
                                height: 200,
                                decoration: BoxDecoration(
                                  color: tealColor.withOpacity(0.7),
                                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
                                ),
                              ),
                            ),
                            const Positioned(
                              top: 40,
                              left: 16,
                              child: Text(
                                "الملف الشخصي",
                                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
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
                      ),
                      const SizedBox(height: 20),
                      Text(
                        userProfile!.fullName,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        userProfile!.email,
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                      const SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: ElevatedButton.icon(
                          onPressed: _showEditDialog,
                          icon: const Icon(Icons.edit, size: 18),
                          label: const Text("تعديل البيانات"),
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
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Column(
                          children: [
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
                                        const Text("رمز المحفظة (للربط)", style: TextStyle(color: Colors.white70, fontSize: 12)),
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
                            _buildInfoCard("رقم الهاتف", userProfile!.phoneNumber, Icons.phone_android),
                            _buildInfoCard("الجامعة", "الجامعة الأسمرية", Icons.school),
                            _buildInfoCard("تاريخ الانضمام", joinedDate, Icons.calendar_today),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
    );
  }

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
