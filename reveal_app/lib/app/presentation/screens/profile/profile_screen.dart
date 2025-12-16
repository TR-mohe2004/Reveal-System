import 'dart:io'; // للتعامل مع ملفات الصور
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // مكتبة اختيار الصور

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // 1. تعريف المتغيرات لحفظ البيانات
  bool isEditing = false; // هل نحن في وضع التعديل أم العرض؟
  File? _profileImage; // لحفظ الصورة المختارة من الاستوديو

  // 2. تعريف المتحكمات (Controllers) لربط النصوص بالخانات
  final TextEditingController _nameController = TextEditingController(text: "أحمد سليمان");
  final TextEditingController _phoneController = TextEditingController(text: "091-5016621");
  final TextEditingController _addressController = TextEditingController(text: "طرابلس، ليبيا");
  final TextEditingController _emailController = TextEditingController(text: "ahmed@reveal.com");

  // دالة لاختيار الصورة من المعرض
  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

  // دالة لحفظ البيانات (أو التبديل بين الوضعين)
  void _toggleEdit() {
    setState(() {
      if (isEditing) {
        // هنا يمكنك إضافة كود إرسال البيانات للسيرفر (API) لاحقاً
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("تم حفظ التعديلات بنجاح ✅"), backgroundColor: Colors.green),
        );
      }
      isEditing = !isEditing; // عكس الحالة
    });
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF009688);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // --- القسم العلوي: الصورة والغلاف ---
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                // الغلاف الخلفي
                Container(
                  height: 220,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: primaryColor,
                    image: const DecorationImage(
                      image: AssetImage('assets/images/welcome_bg.png'),
                      fit: BoxFit.cover,
                      opacity: 0.4,
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(40),
                      bottomRight: Radius.circular(40),
                    ),
                  ),
                ),

                // الصورة الشخصية (القابلة للتغيير)
                Positioned(
                  bottom: -50,
                  child: GestureDetector(
                    onTap: isEditing ? _pickImage : null, // السماح بالضغط فقط عند التعديل
                    child: Stack(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(5),
                          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                          child: CircleAvatar(
                            radius: 65,
                            backgroundColor: Colors.grey[200],
                            backgroundImage: _profileImage != null
                                ? FileImage(_profileImage!) as ImageProvider // عرض الصورة الجديدة
                                : const AssetImage('assets/images/logo.png'), // عرض الصورة الافتراضية
                          ),
                        ),
                        // أيقونة الكاميرا تظهر فقط في وضع التعديل
                        if (isEditing)
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(color: Colors.orange, shape: BoxShape.circle),
                              child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // زر الرجوع أو العنوان
                Positioned(
                  top: 50,
                  child: const Text(
                    "ملفي الشخصي",
                    style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 70),

            // --- قسم البيانات ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                children: [
                  // زر التعديل / الحفظ
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("المعلومات الشخصية", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      TextButton.icon(
                        onPressed: _toggleEdit,
                        icon: Icon(isEditing ? Icons.check : Icons.edit, color: primaryColor),
                        label: Text(isEditing ? "حفظ" : "تعديل", style: TextStyle(color: primaryColor)),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // حقول الإدخال (تتغير حسب الوضع)
                  _buildEditableCard("الاسم واللقب", _nameController, Icons.person, isEditing),
                  _buildEditableCard("رقم الهاتف", _phoneController, Icons.phone, isEditing, isNumber: true),
                  _buildEditableCard("العنوان", _addressController, Icons.location_on, isEditing),
                  _buildEditableCard("البريد الإلكتروني", _emailController, Icons.email, isEditing),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ودجت ذكي: يتحول من نص عادي إلى حقل إدخال
  Widget _buildEditableCard(String label, TextEditingController controller, IconData icon, bool isEdit, {bool isNumber = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5)),
        ],
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: const Color(0xFF009688).withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(icon, color: const Color(0xFF009688)),
        ),
        title: Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        subtitle: isEdit
            ? TextFormField(
                controller: controller,
                keyboardType: isNumber ? TextInputType.phone : TextInputType.text,
                decoration: const InputDecoration(
                  border: UnderlineInputBorder(),
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 5),
                ),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
              )
            : Text(
                controller.text, // عرض النص المحفوظ
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
      ),
    );
  }
}