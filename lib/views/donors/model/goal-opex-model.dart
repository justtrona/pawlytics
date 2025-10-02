// lib/views/donors/model/goal-opex-model.dart
class OpexAllocation {
  final int id;
  final String category;
  final double amount;

  /// Sum of donations attributed to this allocation (for the current month).
  /// If your query doesn’t return it, it defaults to 0.
  final double raised;

  final DateTime? createdAt;

  OpexAllocation({
    required this.id,
    required this.category,
    required this.amount,
    this.raised = 0.0,
    this.createdAt,
  });

  /// Robust number parser
  static double _toD(dynamic v) {
    if (v is num) return v.toDouble();
    if (v == null) return 0.0;
    return double.tryParse('$v') ?? 0.0;
  }

  /// Try multiple common keys so this works with different SQL/view shapes.
  /// - `raised` or `total_raised`
  /// - OR sum of `cash_raised` + `inkind_raised`
  static double _extractRaised(Map<String, dynamic> m) {
    if (m.containsKey('raised')) return _toD(m['raised']);
    if (m.containsKey('total_raised')) return _toD(m['total_raised']);
    final cash = _toD(m['cash_raised']);
    final inKind = _toD(m['inkind_raised']);
    if (cash > 0 || inKind > 0) return cash + inKind;
    return 0.0;
  }

  factory OpexAllocation.fromMap(Map<String, dynamic> m) {
    return OpexAllocation(
      id: m['id'] is int ? m['id'] as int : int.tryParse('${m['id']}') ?? 0,
      category: (m['category'] ?? 'Untitled').toString(),
      amount: _toD(m['amount']),
      raised: _extractRaised(m),
      createdAt: m['created_at'] == null
          ? null
          : DateTime.parse(m['created_at'].toString()),
    );
  }

  OpexAllocation copyWith({
    int? id,
    String? category,
    double? amount,
    double? raised,
    DateTime? createdAt,
  }) {
    return OpexAllocation(
      id: id ?? this.id,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      raised: raised ?? this.raised,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'category': category,
    'amount': amount,
    'raised': raised,
    'created_at': createdAt?.toIso8601String(),
  };

  /// -------- Computed helpers --------

  double get remaining {
    final rem = amount - raised;
    return rem.isNaN ? 0.0 : rem.clamp(0, double.infinity);
    // (if you want negatives to indicate overfunded, drop clamp)
  }

  double get progress {
    if (amount <= 0) return 0.0;
    final p = raised / amount;
    return p.isNaN ? 0.0 : p.clamp(0.0, 1.0);
  }

  bool get isFunded => remaining <= 0;

  String get statusLabel {
    if (isFunded) return 'Fully funded';
    if (progress >= 0.75) return 'Almost there';
    if (progress >= 0.40) return 'In progress';
    return 'Open';
  }
}
