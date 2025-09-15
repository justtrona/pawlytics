// utility_model.dart

class Utility {
  final String type;      // e.g. Water, Electricity
  final double amount;    // Goal amount
  final DateTime dueDate; // Due date
  final String status;    // Paid, Due, Stocked

  Utility({
    required this.type,
    required this.amount,
    required this.dueDate,
    required this.status,
  });

  // Optional: copyWith for easy updates
  Utility copyWith({
    String? type,
    double? amount,
    DateTime? dueDate,
    String? status,
  }) {
    return Utility(
      type: type ?? this.type,
      amount: amount ?? this.amount,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
    );
  }

  @override
  String toString() {
    return 'Utility(type: $type, amount: $amount, dueDate: $dueDate, status: $status)';
  }
}
