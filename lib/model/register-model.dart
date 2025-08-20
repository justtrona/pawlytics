class registerModel {
  final String? id;
  final String fullName;
  final String email;
  final String password;
  final DateTime? createdAt;

  registerModel({
    this.id,
    required this.fullName,
    required this.email,
    required this.password,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
}
