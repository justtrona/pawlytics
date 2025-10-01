// lib/models/opex_allocation.dart
class OpexAllocation {
  final int id;
  final String category;
  final double amount;
  final DateTime? neededBy;
  final String status; // e.g., "open", "closed"
  final double raised; // optional; 0 if not present in table/view

  OpexAllocation({
    required this.id,
    required this.category,
    required this.amount,
    required this.neededBy,
    required this.status,
    required this.raised,
  });

  static double _d(dynamic v) =>
      v is num ? v.toDouble() : double.tryParse('${v ?? ''}') ?? 0.0;

  static DateTime? _date(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    if (v is String && v.isNotEmpty) {
      try {
        return DateTime.parse(v);
      } catch (_) {}
    }
    return null;
  }

  String get statusLabel => status.isEmpty ? '—' : status.toUpperCase();

  factory OpexAllocation.fromMap(Map<String, dynamic> m) {
    return OpexAllocation(
      id: m['id'] is int ? m['id'] as int : int.tryParse('${m['id']}') ?? 0,
      category: (m['category'] ?? 'Untitled').toString(),
      amount: _d(m['amount']),
      neededBy: _date(m['needed_by']),
      status: (m['status'] ?? '').toString(),
      // If you later add a column/view field like raised_amount, we pick it up:
      raised: _d(m['raised_amount'] ?? m['raised']),
    );
  }
}
