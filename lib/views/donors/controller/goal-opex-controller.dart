// lib/views/donors/controller/goal-opex-controller.dart
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pawlytics/views/donors/model/goal-opex-model.dart';

class OpexMonthSummary {
  final DateTime monthStart;
  final DateTime monthEnd;
  final double goalAmount;
  final double cashRaised;
  final double progressRatio;
  final String state; // 'active' | 'completed' | 'closed'

  OpexMonthSummary({
    required this.monthStart,
    required this.monthEnd,
    required this.goalAmount,
    required this.cashRaised,
    required this.progressRatio,
    required this.state,
  });

  factory OpexMonthSummary.fromMap(Map<String, dynamic> m) {
    DateTime d(v) => DateTime.parse(v.toString()).toLocal();
    double n(v) => v is num ? v.toDouble() : double.tryParse('$v') ?? 0.0;

    return OpexMonthSummary(
      monthStart: d(m['month_start']),
      monthEnd: d(m['month_end']),
      goalAmount: n(m['goal_amount']),
      cashRaised: n(m['cash_raised']),
      progressRatio: n(m['progress_ratio']),
      state: (m['state'] ?? 'active').toString(),
    );
  }
}

class OpexAllocationsController extends ChangeNotifier {
  final SupabaseClient _sb = Supabase.instance.client;

  bool _loading = false;
  bool get loading => _loading;

  final List<OpexAllocation> _items = [];
  List<OpexAllocation> get items => List.unmodifiable(_items);

  // Current month bounds
  DateTime? _monthStart;
  DateTime? _monthEnd;
  DateTime? get monthStart => _monthStart;
  DateTime? get monthEnd => _monthEnd;

  bool get isClosed {
    if (_monthEnd == null) return false;
    return DateTime.now().isAfter(_monthEnd!);
  }

  /// Previous months summaries
  final List<OpexMonthSummary> _history = [];
  List<OpexMonthSummary> get history => List.unmodifiable(_history);

  final bool includeInKind = false;

  Future<void> loadAllocations() async {
    _loading = true;
    notifyListeners();

    try {
      final nowUtc = DateTime.now().toUtc();
      final monthStartUtc = DateTime.utc(nowUtc.year, nowUtc.month, 1);
      final nextMonthStartUtc = (nowUtc.month == 12)
          ? DateTime.utc(nowUtc.year + 1, 1, 1)
          : DateTime.utc(nowUtc.year, nowUtc.month + 1, 1);

      _monthStart = monthStartUtc.toLocal();
      _monthEnd = nextMonthStartUtc
          .subtract(const Duration(seconds: 1))
          .toLocal();

      // (1) Allocations
      final resAlloc = await _sb
          .from('operational_expense_allocations')
          .select()
          .gte('created_at', monthStartUtc.toIso8601String())
          .lt('created_at', nextMonthStartUtc.toIso8601String())
          .order('created_at', ascending: true);

      final allocations = (resAlloc as List)
          .cast<Map<String, dynamic>>()
          .map(OpexAllocation.fromMap)
          .toList();

      // (2) Donations
      var donationQuery = _sb
          .from('donations')
          .select('opex_id, donation_type, amount')
          .gte('donation_date', monthStartUtc.toIso8601String())
          .lt('donation_date', nextMonthStartUtc.toIso8601String())
          .not('opex_id', 'is', null);

      if (!includeInKind) {
        donationQuery = donationQuery.eq('donation_type', 'Cash');
      }

      final resDon = await donationQuery;
      final donationRows = (resDon as List).cast<Map<String, dynamic>>();

      final Map<int, double> raisedByAlloc = {};
      for (final row in donationRows) {
        final id = int.tryParse('${row['opex_id']}') ?? 0;
        if (id == 0) continue;

        final amt = row['amount'] is num
            ? (row['amount'] as num).toDouble()
            : double.tryParse('${row['amount']}') ?? 0.0;
        if (amt <= 0) continue;

        raisedByAlloc.update(id, (v) => v + amt, ifAbsent: () => amt);
      }

      final merged = allocations
          .map((a) => a.copyWith(raised: raisedByAlloc[a.id] ?? 0.0))
          .toList();

      _items
        ..clear()
        ..addAll(merged);

      // (3) Load history (previous months summary)
      await _loadHistory();
    } catch (e, st) {
      _items.clear();
      debugPrint('loadAllocations error: $e');
      debugPrintStack(stackTrace: st);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> _loadHistory() async {
    _history.clear();
    try {
      final res = await _sb
          .from(
            'v_opex_month_progress',
          ) // ← you need to create this view if not existing
          .select()
          .order('month_start', ascending: false)
          .limit(6); // show last 6 months

      if (res is List) {
        _history.addAll(res.map((m) => OpexMonthSummary.fromMap(m)));
      }
    } catch (e) {
      debugPrint('loadHistory error: $e');
    }
  }
}
