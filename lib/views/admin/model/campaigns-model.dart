enum CampaignStatus { active, inactive, due }

class Campaign {
  final int id;
  final String program;
  final String category;
  final double fundraisingGoal;
  final String currency;
  final DateTime deadline;
  final String description;
  final bool notifyAt75;

  /// New: whether admins have deactivated the campaign (DB column: is_active)
  final bool isActive;

  final DateTime createdAt;
  final DateTime updatedAt;

  Campaign({
    required this.id,
    required this.program,
    required this.category,
    required this.fundraisingGoal,
    required this.currency,
    required this.deadline,
    required this.description,
    required this.notifyAt75,
    required this.isActive, // 👈 new
    required this.createdAt,
    required this.updatedAt,
  });

  /// Computed status:
  /// - inactive: explicitly turned off by admins (is_active = false)
  /// - due: past the deadline (and still active)
  /// - active: otherwise
  CampaignStatus get status {
    if (!isActive) return CampaignStatus.inactive;
    return deadline.isBefore(DateTime.now())
        ? CampaignStatus.due
        : CampaignStatus.active;
  }

  /// Handy label if you prefer strings in the UI
  String get statusLabel {
    switch (status) {
      case CampaignStatus.active:
        return 'active';
      case CampaignStatus.inactive:
        return 'inactive';
      case CampaignStatus.due:
        return 'due';
    }
  }

  // ---- parsing helpers (unchanged) ----
  static int _parseId(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  static double _parseDouble(dynamic v) {
    if (v is double) return v;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0.0;
    return 0.0;
  }

  static DateTime _parseDate(dynamic v) {
    if (v == null) return DateTime.now();
    if (v is DateTime) return v;
    if (v is String && v.isNotEmpty) return DateTime.parse(v);
    if (v is int) {
      return v > 1000000000000
          ? DateTime.fromMillisecondsSinceEpoch(v)
          : DateTime.fromMillisecondsSinceEpoch(v * 1000);
    }
    return DateTime.now();
  }

  static bool _parseBool(dynamic v, {bool fallback = false}) {
    if (v is bool) return v;
    if (v is int) return v != 0;
    if (v is String) {
      final s = v.toLowerCase();
      return s == 'true' || s == '1';
    }
    return fallback;
  }

  static String _parseString(dynamic v, String fallback) {
    if (v == null) return fallback;
    if (v is String) return v;
    return v.toString();
  }

  factory Campaign.fromMap(Map<String, dynamic> map) {
    return Campaign(
      id: _parseId(map['id']),
      program: _parseString(map['program'], 'Untitled Program'),
      category: _parseString(map['category'], 'Uncategorized'),
      fundraisingGoal: _parseDouble(map['fundraising_goal']),
      currency: _parseString(map['currency'], 'PHP'),
      deadline: _parseDate(map['deadline']),
      description: _parseString(map['description'], 'No description provided'),
      notifyAt75: _parseBool(map['notify_at_75']),
      isActive: _parseBool(map['is_active'], fallback: true), // 👈 default true
      createdAt: _parseDate(map['created_at']),
      updatedAt: _parseDate(map['updated_at']),
    );
  }

  /// Convert to map for insert/update
  Map<String, dynamic> toMap({bool forInsert = true}) {
    final map = <String, dynamic>{
      'program': program,
      'category': category,
      'fundraising_goal': fundraisingGoal,
      'currency': currency,
      'deadline': deadline.toIso8601String(),
      'description': description,
      'notify_at_75': notifyAt75,
      'is_active': isActive, // 👈 new column
    };

    if (!forInsert) {
      map['id'] = id;
      map['created_at'] = createdAt.toIso8601String();
      map['updated_at'] = updatedAt.toIso8601String();
    }

    return map;
  }
}

// class Campaign {
//   final int id;
//   final String program;
//   final String category;
//   final double fundraisingGoal;
//   final String currency;
//   final DateTime deadline;
//   final String description;
//   final bool notifyAt75;
//   final DateTime createdAt;
//   final DateTime updatedAt;

//   Campaign({
//     required this.id,
//     required this.program,
//     required this.category,
//     required this.fundraisingGoal,
//     required this.currency,
//     required this.deadline,
//     required this.description,
//     required this.notifyAt75,
//     required this.createdAt,
//     required this.updatedAt,
//   });

//   /// Robust parsing that tolerates null / different input types from Supabase
//   factory Campaign.fromMap(Map<String, dynamic> map) {
//     int parseId(dynamic v) {
//       if (v is int) return v;
//       if (v is num) return v.toInt();
//       if (v is String) return int.tryParse(v) ?? 0;
//       return 0;
//     }

//     double parseDouble(dynamic v) {
//       if (v is double) return v;
//       if (v is num) return v.toDouble();
//       if (v is String) return double.tryParse(v) ?? 0.0;
//       return 0.0;
//     }

//     DateTime parseDate(dynamic v) {
//       if (v == null) return DateTime.now();
//       if (v is DateTime) return v;
//       if (v is String) {
//         // some servers may return an empty string
//         if (v.isEmpty) return DateTime.now();
//         return DateTime.parse(v);
//       }
//       if (v is int) {
//         // treat large ints as milliseconds, smaller as seconds
//         if (v > 1000000000000) return DateTime.fromMillisecondsSinceEpoch(v);
//         return DateTime.fromMillisecondsSinceEpoch(v * 1000);
//       }
//       return DateTime.now();
//     }

//     bool parseBool(dynamic v) {
//       if (v == null) return false;
//       if (v is bool) return v;
//       if (v is int) return v != 0;
//       if (v is String) {
//         final s = v.toLowerCase();
//         return s == 'true' || s == '1';
//       }
//       return false;
//     }

//     String parseString(dynamic v, String fallback) {
//       if (v == null) return fallback;
//       if (v is String) return v;
//       return v.toString();
//     }

//     return Campaign(
//       id: parseId(map['id']),
//       program: parseString(map['program'], 'Untitled Program'),
//       category: parseString(map['category'], 'Uncategorized'),
//       fundraisingGoal: parseDouble(map['fundraising_goal']),
//       currency: parseString(map['currency'], 'PHP'),
//       deadline: parseDate(map['deadline']),
//       description: parseString(map['description'], 'No description provided'),
//       notifyAt75: parseBool(map['notify_at_75']),
//       createdAt: parseDate(map['created_at']),
//       updatedAt: parseDate(map['updated_at']),
//     );
//   }

//   /// When inserting new rows, call toMap(forInsert: true) — it will omit id/timestamps.
//   Map<String, dynamic> toMap({bool forInsert = true}) {
//     final map = <String, dynamic>{
//       'program': program,
//       'category': category,
//       'fundraising_goal': fundraisingGoal,
//       'currency': currency,
//       'deadline': deadline.toIso8601String(),
//       'description': description,
//       'notify_at_75': notifyAt75,
//     };

//     if (!forInsert) {
//       // include DB-managed fields only when updating/serializing existing object
//       map['id'] = id;
//       map['created_at'] = createdAt.toIso8601String();
//       map['updated_at'] = updatedAt.toIso8601String();
//     }

//     return map;
//   }
// }

// // class Campaign {
// //   final int id;
// //   final String program;
// //   final String category;
// //   final double fundraisingGoal;
// //   final String currency;
// //   final DateTime deadline;
// //   final String description;
// //   final bool notifyAt75;
// //   final DateTime createdAt;
// //   final DateTime updatedAt;

// //   Campaign({
// //     required this.id,
// //     required this.program,
// //     required this.category,
// //     required this.fundraisingGoal,
// //     required this.currency,
// //     required this.deadline,
// //     required this.description,
// //     required this.notifyAt75,
// //     required this.createdAt,
// //     required this.updatedAt,
// //   });

// //   factory Campaign.fromMap(Map<String, dynamic> map) {
// //     return Campaign(
// //       id: map['id'] as int,
// //       program: map['program'] as String,
// //       category: map['category'] as String,
// //       fundraisingGoal: (map['fundraising_goal'] as num).toDouble(),
// //       currency: map['currency'] as String,
// //       deadline: DateTime.parse(map['deadline']),
// //       description: map['description'] ?? '',
// //       notifyAt75: map['notify_at_75'] ?? false,
// //       createdAt: DateTime.parse(map['created_at']),
// //       updatedAt: DateTime.parse(map['updated_at']),
// //     );
// //   }

// //   Map<String, dynamic> toMap() {
// //     return {
// //       'id': id,
// //       'program': program,
// //       'category': category,
// //       'fundraising_goal': fundraisingGoal,
// //       'currency': currency,
// //       'deadline': deadline.toIso8601String(),
// //       'description': description,
// //       'notify_at_75': notifyAt75,
// //       'created_at': createdAt.toIso8601String(),
// //       'updated_at': updatedAt.toIso8601String(),
// //     };
// //   }
// // }
