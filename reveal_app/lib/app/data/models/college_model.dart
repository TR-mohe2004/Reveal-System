class College {
  final String id;
  final String name;
  final String? image; // Make image nullable

  College({required this.id, required this.name, this.image});

  factory College.fromJson(Map<String, dynamic> json) {
    return College(
      id: json['id'].toString(), // Ensure id is a string
      name: json['name'],
      image: json['image'],
    );
  }

  factory College.fromFirestore(String id, Map<String, dynamic> data) {
    return College(
      id: id,
      name: data['name'] ?? '',
      image: data['image'],
    );
  }

  // For comparison in DropdownButton
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is College && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
