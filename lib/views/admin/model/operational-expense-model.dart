// class OperationalExpenseModel {
//   final String category;
//   final double amount;

//   OperationalExpenseModel ({
//       required this.category,
//       required this.amount,
//   });
// }

// // class operationalexpensemodel{
// //   final String category;
// //   final double amount;

// //  operationalexpensemodel({required this.category, required this.amount});
// // }

// lib/views/admin/model/operational-expense-model.dart
class OperationalExpenseModel {
  final int? id; // null before insert
  final String category;
  final double amount;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  OperationalExpenseModel({
    this.id,
    required this.category,
    required this.amount,
    this.createdAt,
    this.updatedAt,
  });

  factory OperationalExpenseModel.fromMap(Map<String, dynamic> m) {
    DateTime? _dt(dynamic v) =>
        v == null ? null : (v is DateTime ? v : DateTime.tryParse('$v'));
    double _d(dynamic v) =>
        v is num ? v.toDouble() : double.tryParse('$v') ?? 0.0;

    return OperationalExpenseModel(
      id: (m['id'] is int) ? m['id'] as int : int.tryParse('${m['id']}'),
      category: (m['category'] ?? '').toString(),
      amount: _d(m['amount']),
      createdAt: _dt(m['created_at']),
      updatedAt: _dt(m['updated_at']),
    );
  }

  /// For INSERT only (let DB fill id/created_at/updated_at)
  Map<String, dynamic> toInsert() => {'category': category, 'amount': amount};

  /// For UPDATE
  Map<String, dynamic> toUpdate() => {'category': category, 'amount': amount};
}
