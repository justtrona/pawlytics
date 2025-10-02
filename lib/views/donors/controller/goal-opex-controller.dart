// lib/views/donors/controller/goal-opex-controller.dart
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pawlytics/views/donors/model/goal-opex-model.dart';

class OpexAllocationsController extends ChangeNotifier {
  final SupabaseClient _sb = Supabase.instance.client;

  bool _loading = false;
  bool get loading => _loading;

  final List<OpexAllocation> _items = [];
  List<OpexAllocation> get items => List.unmodifiable(_items);

  /// Sum only cash by default. Set true if you store fair value for in-kind in `amount`.
  final bool includeInKind = false;

  Future<void> loadAllocations() async {
    _loading = true;
    notifyListeners();

    try {
      // Current month bounds (UTC)
      final nowUtc = DateTime.now().toUtc();
      final monthStartUtc = DateTime.utc(nowUtc.year, nowUtc.month, 1);
      final nextMonthStartUtc = (nowUtc.month == 12)
          ? DateTime.utc(nowUtc.year + 1, 1, 1)
          : DateTime.utc(nowUtc.year, nowUtc.month + 1, 1);

      // (1) Allocations for this month (by created_at)
      List<Map<String, dynamic>> allocRows;
      try {
        final res = await _sb
            .from('operational_expense_allocations')
            .select()
            .gte('created_at', monthStartUtc.toIso8601String())
            .lt('created_at', nextMonthStartUtc.toIso8601String())
            .order('created_at', ascending: true);
        allocRows = (res as List).cast<Map<String, dynamic>>();
      } on PostgrestException catch (e) {
        debugPrint('allocations SELECT failed: ${e.code} ${e.message}');
        rethrow;
      }

      // Fallback: if empty, try without date filter (helps diagnose RLS/timezone)
      if (allocRows.isEmpty) {
        debugPrint(
          '[allocations] Empty with month filter; trying without date…',
        );
        try {
          final res = await _sb
              .from('operational_expense_allocations')
              .select()
              .order('created_at', ascending: true)
              .limit(50);
          allocRows = (res as List).cast<Map<String, dynamic>>();
          if (allocRows.isEmpty) {
            debugPrint('[allocations] Still empty → RLS or no data.');
          } else {
            debugPrint(
              '[allocations] Rows exist without filter; check created_at/timezone.',
            );
          }
        } on PostgrestException catch (e) {
          debugPrint(
            'allocations SELECT (no filter) failed: ${e.code} ${e.message}',
          );
          rethrow;
        }
      }

      final allocations = allocRows.map(OpexAllocation.fromMap).toList();

      if (allocations.isEmpty) {
        _items
          ..clear()
          ..addAll(allocations);
        return;
      }

      // (2) Donations this month (by donation_date), joined to OPEX via opex_id
      var donationQuery = _sb
          .from('donations')
          .select('opex_id, donation_type, amount')
          .gte('donation_date', monthStartUtc.toIso8601String())
          .lt('donation_date', nextMonthStartUtc.toIso8601String())
          .not('opex_id', 'is', null);

      if (includeInKind) {
        donationQuery = donationQuery.or(
          'donation_type.eq.Cash,donation_type.eq.InKind',
        );
      } else {
        donationQuery = donationQuery.eq('donation_type', 'Cash');
      }

      List<Map<String, dynamic>> donationRows;
      try {
        final res = await donationQuery;
        donationRows = (res as List).cast<Map<String, dynamic>>();
      } on PostgrestException catch (e) {
        debugPrint('donations SELECT failed: ${e.code} ${e.message}');
        donationRows = const [];
      }

      // (3) Group sum(amount) by opex_id
      final Map<int, double> raisedByAlloc = {};
      for (final row in donationRows) {
        final id = row['opex_id'] is int
            ? row['opex_id'] as int
            : int.tryParse('${row['opex_id']}') ?? 0;
        if (id == 0) continue;

        final rawAmt = row['amount'];
        final amt = rawAmt is num
            ? rawAmt.toDouble()
            : double.tryParse('$rawAmt') ?? 0.0;
        if (amt <= 0) continue;

        raisedByAlloc.update(id, (v) => v + amt, ifAbsent: () => amt);
      }

      // (4) Merge totals into allocations
      final merged = allocations
          .map((a) => a.copyWith(raised: raisedByAlloc[a.id] ?? 0.0))
          .toList();

      _items
        ..clear()
        ..addAll(merged);
    } catch (e, st) {
      _items.clear();
      debugPrint('loadAllocations error: $e');
      debugPrintStack(stackTrace: st);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
