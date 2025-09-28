class DropoffLocation {
  final int? id;
  final String organization;
  final String address;
  final DateTime scheduledAt;
  final String phone;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  DropoffLocation({
    this.id,
    required this.organization,
    required this.address,
    required this.scheduledAt,
    required this.phone,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  factory DropoffLocation.fromMap(Map<String, dynamic> map) {
    DateTime parseTs(dynamic v) {
      if (v == null) return DateTime.now();
      if (v is DateTime) return v;
      return DateTime.tryParse(v.toString()) ?? DateTime.now();
    }

    return DropoffLocation(
      id: map['id'] as int?,
      organization: map['organization']?.toString() ?? '',
      address: map['address']?.toString() ?? '',
      scheduledAt: parseTs(map['scheduled_at']),
      phone: map['phone']?.toString() ?? '',
      status: map['status']?.toString() ?? 'Active',
      createdAt: map['created_at'] != null ? parseTs(map['created_at']) : null,
      updatedAt: map['updated_at'] != null ? parseTs(map['updated_at']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'organization': organization,
      'address': address,
      // use ISO8601 string for timestamp columns
      'scheduled_at': scheduledAt.toIso8601String(),
      'phone': phone,
      'status': status,
    };
  }
}
