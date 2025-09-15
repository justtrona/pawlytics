class Campaign {
  final int id;
  final String program;
  final String category;
  final double fundraisingGoal;
  final String currency;
  final DateTime deadline;
  final String description;
  final bool notifyAt75;
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
    required this.createdAt,
    required this.updatedAt,
  });

  factory Campaign.fromMap(Map<String, dynamic> map) {
    return Campaign(
      id: map['id'] as int,
      program: map['program'] as String,
      category: map['category'] as String,
      fundraisingGoal: (map['fundraising_goal'] as num).toDouble(),
      currency: map['currency'] as String,
      deadline: DateTime.parse(map['deadline']),
      description: map['description'] ?? '',
      notifyAt75: map['notify_at_75'] ?? false,
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'program': program,
      'category': category,
      'fundraising_goal': fundraisingGoal,
      'currency': currency,
      'deadline': deadline.toIso8601String(),
      'description': description,
      'notify_at_75': notifyAt75,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
