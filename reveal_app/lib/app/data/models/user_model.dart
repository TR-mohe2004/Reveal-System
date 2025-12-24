class User {
  final int id;
  final String fullName;
  final String email;       // ✨ نص إجباري كما طلبت ✨
  final String phoneNumber; // ✨ نص إجباري كما طلبت ✨
  final String? secondaryPhone;
  final String? profileImage;

  User({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    this.secondaryPhone,
    this.profileImage,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      // التعامل مع الـ ID سواء جاء كنص أو رقم
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      
      fullName: json['full_name'] ?? json['name'] ?? 'مستخدم',
      
      // قيم افتراضية فارغة كما طلبت لتجنب الـ Null
      email: json['email'] ?? '', 
      phoneNumber: json['phone_number'] ?? json['phone'] ?? '',
      secondaryPhone: json['secondary_phone'] ?? json['secondary_phone_number'],
      
      profileImage: json['profile_image_url'] ?? json['image'],
    );
  }

  // دالة مفيدة لتحديث البيانات
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'email': email,
      'phone_number': phoneNumber,
      'secondary_phone': secondaryPhone,
    };
  }
}
