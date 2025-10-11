import 'package:flutter/foundation.dart';

/// App roles stored in `public.registration.role`
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
  final String? id; // registration.id (uuid or text)
  final String fullName; // registration.fullName
  final String email; // registration.email
  final UiRole role; // registration.role
  final String? phoneNumber; // registration.phone_number (optional)
  final DateTime? createdAt; // registration.created_at (optional)

  const AdminUser({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    this.phoneNumber,
    this.createdAt,
  });

  factory AdminUser.fromMap(Map<String, dynamic> m) {
    return AdminUser(
      id: m['id']?.toString(),
      fullName: (m['fullName'] ?? '').toString(),
      email: (m['email'] ?? '').toString(),
      role: roleFromString(m['role']?.toString()),
      phoneNumber: m['phone_number']?.toString(),
      createdAt: m['created_at'] != null
          ? DateTime.tryParse(m['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'fullName': fullName,
    'email': email,
    'role': roleToString(role),
    if (phoneNumber != null) 'phone_number': phoneNumber,
    if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
  };

  AdminUser copyWith({
    String? id,
    String? fullName,
    String? email,
    UiRole? role,
    String? phoneNumber,
    DateTime? createdAt,
  }) {
    return AdminUser(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      role: role ?? this.role,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
