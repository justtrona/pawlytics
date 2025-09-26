import 'package:flutter/foundation.dart';

enum UiRole { donor, staff, admin }

UiRole roleFromString(String? raw) {
  final v = (raw ?? 'donor').toLowerCase();
  if (v == 'admin') return UiRole.admin;
  if (v == 'staff') return UiRole.staff;
  return UiRole.donor;
}

String roleToString(UiRole r) {
  switch (r) {
    case UiRole.admin:
      return 'admin';
    case UiRole.staff:
      return 'staff';
    case UiRole.donor:
    default:
      return 'donor';
  }
}

@immutable
class AdminUser {
  final String? id;
  final String fullName;
  final String email;
  final String phoneNumber;
  final DateTime createdAt;
  final UiRole role;

  const AdminUser({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.createdAt,
    required this.role,
  });

  factory AdminUser.fromMap(Map<String, dynamic> m) {
    return AdminUser(
      id: m['id'] as String?,
      fullName: (m['fullName'] ?? '') as String,
      email: (m['email'] ?? '') as String,
      phoneNumber: (m['phone_number'] ?? '') as String,
      createdAt: m['created_at'] != null
          ? DateTime.parse(m['created_at'] as String)
          : DateTime.now(),
      role: roleFromString(m['role'] as String?),
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'fullName': fullName,
    'email': email,
    'phone_number': phoneNumber,
    'created_at': createdAt.toIso8601String(),
    'role': roleToString(role),
  };
}
