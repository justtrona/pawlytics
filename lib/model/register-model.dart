class RegisterModel {
  final String? id;
  final String fullName;
  final String email;
  final String password;
  final String phoneNumber;
  final DateTime createdAt;
  final String role; // <-- NEW ATTRIBUTE (admin or donor)

  RegisterModel({
    this.id,
    required this.fullName,
    required this.email,
    required this.password,
    required this.phoneNumber,
    required this.role, // <-- required so user must choose
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory RegisterModel.fromMap(Map<String, dynamic> map) {
    return RegisterModel(
      id: map['id'],
      fullName: map['fullName'],
      email: map['email'],
      password: map['password'],
      phoneNumber: map['phone_number'],
      role: map['role'] ?? 'donor', // default role if missing
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'fullName': fullName,
      'email': email,
      'password': password,
      'phone_number': phoneNumber,
      'role': role,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
