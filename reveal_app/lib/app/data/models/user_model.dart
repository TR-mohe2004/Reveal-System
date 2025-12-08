class User {
  final int id;
  final String fullName;
  final String email;
  final String phoneNumber;
  final String? profileImage;

  User({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    this.profileImage,
  });

  // تحويل البيانات القادمة من الباك اند (JSON) إلى كائن مستخدم
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      fullName: json['full_name'] ?? 'مستخدم', // الاسم من دجانغو
      email: json['email'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
      profileImage: json['profile_image_url'],
    );
  }
}