// lib/views/admin/controllers/operational-expense-controller.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pawlytics/views/admin/model/operational-expense-model.dart';
import 'package:pawlytics/views/admin/model/donation-model.dart';

class OperationalExpenseController extends ChangeNotifier {
  final SupabaseClient _sb = Supabase.instance.client;

  // In-memory state
  final List<OperationalExpenseModel> _operationalExpenseList = [];
  final List<DonationModel> _donations = []; // keep your existing type
  bool _loading = false;

  bool get loading => _loading;
  List<OperationalExpenseModel> get operationalExpenseList =>
      List.unmodifiable(_operationalExpenseList);
  List<DonationModel> get donations => List.unmodifiable(_donations);

  // ----- Derived -----
  double get expenseGoal =>
      _operationalExpenseList.fold(0.0, (sum, e) => sum + e.amount);

  double get totalDonationsCash => _donations.fold(0.0, (sum, d) {
    if (d.type == DonationType.cash && (d.amount ?? 0) > 0) {
      return sum + (d.amount ?? 0);
    }
    return sum;
  });

  double get progress =>
      expenseGoal == 0 ? 0 : (totalDonationsCash / expenseGoal);

  double allocationPercent(int index) {
    if (expenseGoal == 0 ||
        index < 0 ||
        index >= _operationalExpenseList.length) {
      return 0;
    }
    return _operationalExpenseList[index].amount / expenseGoal;
  }

  // ---------- Remote CRUD for allocations ----------
  static const _table = 'operational_expense_allocations';

  Future<void> loadAllocations() async {
    _loading = true;
    notifyListeners();
    try {
      final rows = await _sb
          .from(_table)
          .select()
          .order('created_at', ascending: false);

      _operationalExpenseList
        ..clear()
        ..addAll(
          (rows as List).map(
            (e) => OperationalExpenseModel.fromMap(e as Map<String, dynamic>),
          ),
        );
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// CREATE (called by your Add dialog)
  Future<void> addAllocation(OperationalExpenseModel input) async {
    final inserted = await _sb
        .from(_table)
        .insert(input.toInsert())
        .select()
        .single(); // returns the created row

    _operationalExpenseList.insert(
      0,
      OperationalExpenseModel.fromMap(inserted as Map<String, dynamic>),
    );
    notifyListeners();
  }

  /// UPDATE by index (uses row id)
  Future<void> updateAllocation(
    int index,
    OperationalExpenseModel updated,
  ) async {
    final item = _operationalExpenseList[index];
    if (item.id == null) return;

    final updatedRow = await _sb
        .from(_table)
        .update(updated.toUpdate())
        .eq('id', item.id!)
        .select()
        .single();

    _operationalExpenseList[index] = OperationalExpenseModel.fromMap(
      updatedRow as Map<String, dynamic>,
    );
    notifyListeners();
  }

  /// DELETE by index (uses row id)
  Future<void> removeAllocation(int index) async {
    final item = _operationalExpenseList[index];
    if (item.id != null) {
      await _sb.from(_table).delete().eq('id', item.id!);
    }
    _operationalExpenseList.removeAt(index);
    notifyListeners();
  }

  // ---------- Donations (in-memory for now) ----------
  // These match how your UI currently calls the controller.
  // Later, if you want donations persisted to Supabase, we can
  // swap these out for real inserts/updates/deletes.
  void addDonation(DonationModel donation) {
    _donations.add(donation);
    notifyListeners();
  }

  void updateDonation(int index, DonationModel updated) {
    if (index < 0 || index >= _donations.length) return;
    _donations[index] = updated;
    notifyListeners();
  }

  void removeDonation(int index) {
    if (index < 0 || index >= _donations.length) return;
    _donations.removeAt(index);
    notifyListeners();
  }
}
