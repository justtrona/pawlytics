class RegisterModel {
  final String? id;
  final String fullName;
  final String email;
  final String password;
  final String phoneNumber;
  final DateTime createdAt;

  RegisterModel({
    this.id,
    required this.fullName,
    required this.email,
    required this.password,
    required this.phoneNumber,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory RegisterModel.fromMap(Map<String, dynamic> map) {
    return RegisterModel(
      id: map['id'],
      fullName: map['fullName'], 
      email: map['email'],
      password: map['password'],
      phoneNumber: map['phone_number'],
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
      'created_at': createdAt.toIso8601String(),
    };
  }
}
