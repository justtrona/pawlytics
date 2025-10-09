import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pawlytics/views/admin/model/operational-expense-model.dart';
import 'package:pawlytics/views/admin/model/donation-model.dart';

double _toD(dynamic v) {
  if (v is num) return v.toDouble();
  if (v == null) return 0.0;
  return double.tryParse('$v') ?? 0.0;
}

DateTime? _toDate(dynamic v) {
  if (v == null) return null;
  try {
    return DateTime.parse('$v');
  } catch (_) {
    return null;
  }
}

class OpexMonthProgress {
  final DateTime? monthStart, monthEnd;
  final double goalAmount, cashRaised, inkindRaised, totalRaised, progressRatio;

  OpexMonthProgress({
    required this.monthStart,
    required this.monthEnd,
    required this.goalAmount,
    required this.cashRaised,
    required this.inkindRaised,
    required this.totalRaised,
    required this.progressRatio,
  });

  factory OpexMonthProgress.fromMap(Map<String, dynamic> m) {
    return OpexMonthProgress(
      monthStart: _toDate(m['month_start']),
      monthEnd: _toDate(m['month_end']),
      goalAmount: _toD(m['goal_amount']),
      cashRaised: _toD(m['cash_raised']),
      inkindRaised: _toD(m['inkind_raised']),
      totalRaised: _toD(m['total_raised']),
      progressRatio: _toD(m['progress_ratio']),
    );
  }
}

class MonthSummary {
  final int opexId;
  final DateTime monthStart, monthEnd;
  final double goalAmount, cashRaised, progressRatio;
  final String state;

  MonthSummary({
    required this.opexId,
    required this.monthStart,
    required this.monthEnd,
    required this.goalAmount,
    required this.cashRaised,
    required this.progressRatio,
    required this.state,
  });

  factory MonthSummary.fromMap(Map<String, dynamic> m) {
    return MonthSummary(
      opexId: (m['opex_id'] as num).toInt(),
      monthStart: DateTime.parse('${m['month_start']}'),
      monthEnd: DateTime.parse('${m['month_end']}'),
      goalAmount: _toD(m['goal_amount']),
      cashRaised: _toD(m['cash_raised']),
      progressRatio: _toD(m['progress_ratio']),
      state: (m['state'] ?? '').toString(),
    );
  }
}

class OperationalExpenseController extends ChangeNotifier {
  final SupabaseClient _sb = Supabase.instance.client;

  final List<OperationalExpenseModel> _operationalExpenseList = [];
  final List<DonationModel> _donations = []; // UI-only list
  bool _loading = false;

  OpexMonthProgress? _progress;
  final Map<int, double> _raisedByAllocationId = {};
  final List<MonthSummary> _history = [];

  // --- Getters ---
  bool get loading => _loading;
  List<OperationalExpenseModel> get operationalExpenseList =>
      List.unmodifiable(_operationalExpenseList);
  List<DonationModel> get donations => List.unmodifiable(_donations);
  List<MonthSummary> get history => List.unmodifiable(_history);

  double get expenseGoal => _progress?.goalAmount ?? 0.0;
  double get totalDonationsCash => _progress?.cashRaised ?? 0.0; // from view
  double get totalDonationsInKind => _progress?.inkindRaised ?? 0.0;
  double get totalRaised => _progress?.totalRaised ?? 0.0;

  double get progress {
    final p = _progress?.progressRatio ?? 0.0;
    return (p.isFinite && !p.isNaN) ? p.clamp(0.0, 1.0) : 0.0;
  }

  DateTime? get currentMonthEnd => _progress?.monthEnd;
  bool get isCurrentMonthClosed {
    final end = _progress?.monthEnd;
    if (end == null) return false;
    return DateTime.now().isAfter(end);
  }

  bool get isCurrentMonthCompleted => progress >= 1.0;

  /// ---------------- Single source of truth totals ----------------
  /// Sum of all manual category amounts (admin-entered)
  double get manualAllocationsTotal =>
      _operationalExpenseList.fold<double>(0.0, (s, e) => s + e.amount);

  /// Alias: if your progress view’s cash_raised actually represents tracked expense,
  /// keep this alias; update mapping here if your schema changes.
  double get trackedExpensesCash => totalDonationsCash;

  /// Canonical monthly expense total shown on Admin header
  double get totalExpensesThisMonth =>
      manualAllocationsTotal + trackedExpensesCash;

  /// ---------------------------------------------------------------

  double allocationPercent(int index) {
    if (expenseGoal <= 0 ||
        index < 0 ||
        index >= _operationalExpenseList.length) {
      return 0.0;
    }
    return _operationalExpenseList[index].amount / expenseGoal;
  }

  double raisedForAllocationId(int? id) {
    if (id == null) return 0.0;
    return _raisedByAllocationId[id] ?? 0.0;
  }

  double allocationProgress(int index) {
    if (index < 0 || index >= _operationalExpenseList.length) return 0.0;
    final row = _operationalExpenseList[index];
    final raised = raisedForAllocationId(row.id);
    if (row.amount <= 0) return 0.0;
    final p = raised / row.amount;
    return p.isFinite ? p.clamp(0.0, 1.0) : 0.0;
  }

  static const _allocTable = 'operational_expense_allocations';
  static const _progressView = 'v_opex_month_progress';
  static const _allocBreakdownView = 'v_opex_allocation_breakdown';
  static const _historyView = 'v_opex_months_summary';

  Future<void> loadAllocations() async {
    _loading = true;
    notifyListeners();
    try {
      final rowsDyn = await _sb
          .from(_allocTable)
          .select('id, category, amount, created_at, updated_at, due_date')
          .order('id', ascending: true);
      final rows = (rowsDyn as List).cast<Map<String, dynamic>>();
      _operationalExpenseList
        ..clear()
        ..addAll(rows.map(OperationalExpenseModel.fromMap));

      await _loadProgress();
      await _loadAllocationBreakdown();
      await _loadHistory();
    } catch (e, st) {
      debugPrint('loadAllocations error: $e');
      debugPrintStack(stackTrace: st);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> _loadProgress() async {
    try {
      final res = await _sb.from(_progressView).select().limit(1);
      if (res is List && res.isNotEmpty) {
        _progress = OpexMonthProgress.fromMap(
          res.first as Map<String, dynamic>,
        );
      } else {
        _progress = OpexMonthProgress(
          monthStart: null,
          monthEnd: null,
          goalAmount: 0,
          cashRaised: 0,
          inkindRaised: 0,
          totalRaised: 0,
          progressRatio: 0,
        );
      }
    } catch (e) {
      debugPrint('load progress error: $e');
      _progress = OpexMonthProgress(
        monthStart: null,
        monthEnd: null,
        goalAmount: 0,
        cashRaised: 0,
        inkindRaised: 0,
        totalRaised: 0,
        progressRatio: 0,
      );
    }
  }

  Future<void> _loadAllocationBreakdown() async {
    _raisedByAllocationId.clear();
    try {
      final res = await _sb.from(_allocBreakdownView).select();
      if (res is List) {
        for (final r in res) {
          final m = r as Map<String, dynamic>;
          final id = (m['allocation_id'] as num?)?.toInt();
          final raised = _toD(m['cash_raised']);
          if (id != null) _raisedByAllocationId[id] = raised;
        }
      }
    } catch (e) {
      debugPrint('load allocation breakdown error: $e');
    }
  }

  Future<void> _loadHistory() async {
    _history.clear();
    try {
      final res = await _sb.from(_historyView).select().order('month_start');
      if (res is List && res.isNotEmpty) {
        _history.addAll(
          res.cast<Map<String, dynamic>>().map(MonthSummary.fromMap),
        );
      }
    } catch (e) {
      debugPrint('load history skipped: $e');
    }
  }

  Future<void> _postMutateReload() async {
    await _loadProgress();
    await _loadAllocationBreakdown();
    await _loadHistory();
    notifyListeners();
  }

  Future<bool> addAllocation(OperationalExpenseModel input) async {
    try {
      final inserted = await _sb
          .from(_allocTable)
          .insert(input.toInsert())
          .select('id, category, amount, created_at, updated_at, due_date')
          .maybeSingle();

      if (inserted != null) {
        _operationalExpenseList.insert(
          0,
          OperationalExpenseModel.fromMap(inserted as Map<String, dynamic>),
        );
        await _postMutateReload();
        return true;
      }

      final rpcRes = await _sb.rpc(
        'admin_insert_opex_allocation',
        params: {'p_category': input.category, 'p_amount': input.amount},
      );
      if (rpcRes == null) return false;

      _operationalExpenseList.insert(
        0,
        OperationalExpenseModel.fromMap((rpcRes as Map<String, dynamic>)),
      );
      await _postMutateReload();
      return true;
    } catch (e, st) {
      debugPrint('addAllocation error: $e');
      debugPrintStack(stackTrace: st);
      return false;
    }
  }

  Future<bool> updateAllocation(
    int index,
    OperationalExpenseModel updated,
  ) async {
    final item = _operationalExpenseList[index];
    if (item.id == null) return false;

    final id = item.id!;
    final payload = <String, dynamic>{
      'category': updated.category,
      'amount': updated.amount,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };

    try {
      final updatedRow = await _sb
          .from(_allocTable)
          .update(payload)
          .eq('id', id)
          .select('id, category, amount, created_at, updated_at, due_date')
          .maybeSingle();

      if (updatedRow != null) {
        _operationalExpenseList[index] = OperationalExpenseModel.fromMap(
          updatedRow as Map<String, dynamic>,
        );
        await _postMutateReload();
        return true;
      }

      final rpcRes = await _sb.rpc(
        'admin_update_opex_allocation',
        params: {
          'p_id': id,
          'p_category': updated.category,
          'p_amount': updated.amount,
        },
      );
      if (rpcRes == null) return false;

      _operationalExpenseList[index] = OperationalExpenseModel.fromMap(
        (rpcRes as Map<String, dynamic>),
      );
      await _postMutateReload();
      return true;
    } catch (e, st) {
      debugPrint('updateAllocation error: $e');
      debugPrintStack(stackTrace: st);
      return false;
    }
  }

  Future<bool> removeAllocation(int index) async {
    if (index < 0 || index >= _operationalExpenseList.length) return false;
    final item = _operationalExpenseList[index];
    if (item.id == null) return false;

    final id = item.id!;
    try {
      final deletedRow = await _sb
          .from(_allocTable)
          .delete()
          .eq('id', id)
          .select('id')
          .maybeSingle();

      if (deletedRow != null) {
        _operationalExpenseList.removeAt(index);
        await _postMutateReload();
        return true;
      }

      final rpcRes = await _sb.rpc(
        'admin_delete_opex_allocation',
        params: {'p_id': id},
      );
      if (rpcRes == null) return false;

      _operationalExpenseList.removeAt(index);
      await _postMutateReload();
      return true;
    } catch (e, st) {
      debugPrint('removeAllocation error: $e');
      debugPrintStack(stackTrace: st);
      return false;
    }
  }

  // UI-only list helpers (unchanged)
  void addDonation(DonationModel d) {
    _donations.add(d);
    notifyListeners();
  }

  void updateDonation(int i, DonationModel d) {
    if (i >= 0 && i < _donations.length) {
      _donations[i] = d;
      notifyListeners();
    }
  }

  void removeDonation(int i) {
    if (i >= 0 && i < _donations.length) {
      _donations.removeAt(i);
      notifyListeners();
    }
  }
}
