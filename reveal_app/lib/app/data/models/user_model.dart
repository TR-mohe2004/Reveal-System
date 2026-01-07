class User {
  final int id;
  final String fullName;
  final String email;
  final String phoneNumber;
  final String? secondaryPhone;
  final String? profileImage;
  final String? dateJoined;

  User({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    this.secondaryPhone,
    this.profileImage,
    this.dateJoined,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      fullName: json['full_name'] ?? json['name'] ?? 'مستخدم',
      email: json['email'] ?? '',
      phoneNumber: json['phone_number'] ?? json['phone'] ?? '',
      secondaryPhone: json['secondary_phone'] ?? json['secondary_phone_number'],
      profileImage: json['profile_image_url'] ?? json['image'],
      dateJoined: json['date_joined'] ?? json['joined_at'] ?? json['created_at'],
    );
  }

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
