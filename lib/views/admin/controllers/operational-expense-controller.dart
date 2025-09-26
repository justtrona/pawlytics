import 'package:flutter/material.dart';
import 'package:pawlytics/views/admin/model/operational-expense-model.dart';
import 'package:pawlytics/views/admin/model/donation-model.dart';
// If your path is `lib/models/donation_model.dart`, use:
// import 'package:pawlytics/models/donation_model.dart';

class OperationalExpenseController extends ChangeNotifier {
  // --- Seed allocations (admin can CRUD these) ---
  final List<OperationalExpenseModel> _operationalExpenseList = [
    OperationalExpenseModel(category: 'Drinking Water', amount: 5000),
    OperationalExpenseModel(category: 'Utility Water', amount: 3000),
    OperationalExpenseModel(category: 'Electricity', amount: 5000),
  ];

  // --- Donations captured via ManageDonation/Admin form ---
  final List<DonationModel> _donations = [];

  // === Goals / Progress ===

  /// Total expense goal (sum of allocation amounts)
  double get expenseGoal =>
      _operationalExpenseList.fold(0.0, (sum, e) => sum + (e.amount));

  /// Unmodifiable views
  List<OperationalExpenseModel> get operationalExpenseList =>
      List.unmodifiable(_operationalExpenseList);
  List<DonationModel> get donations => List.unmodifiable(_donations);

  /// Only CASH donations contribute to meeting the peso goal
  double get totalDonationsCash => _donations.fold(0.0, (sum, d) {
    if (d.type == DonationType.cash && (d.amount ?? 0) > 0) {
      return sum + (d.amount ?? 0);
    }
    return sum;
  });

  /// Optional: track total quantity of in-kind items (across all items)
  int get totalInKindQuantity => _donations.fold(0, (sum, d) {
    if (d.type == DonationType.inKind && (d.quantity ?? 0) > 0) {
      return sum + (d.quantity ?? 0);
    }
    return sum;
  });

  /// Optional: a quick grouping of in-kind item counts by item name
  Map<String, int> get inKindItemBreakdown {
    final map = <String, int>{};
    for (final d in _donations) {
      if (d.type == DonationType.inKind && (d.item ?? '').trim().isNotEmpty) {
        final key = d.item!.trim();
        final qty = d.quantity ?? 0;
        map[key] = (map[key] ?? 0) + qty;
      }
    }
    return map;
  }

  /// Progress toward meeting the operational expense goal (0..1)
  double get progress =>
      expenseGoal == 0 ? 0 : (totalDonationsCash / expenseGoal);

  // Convenience slices
  List<DonationModel> get cashDonations =>
      _donations.where((d) => d.type == DonationType.cash).toList();
  List<DonationModel> get inKindDonations =>
      _donations.where((d) => d.type == DonationType.inKind).toList();

  // === Allocation CRUD ===
  void addAllocation(OperationalExpenseModel expense) {
    _operationalExpenseList.add(expense);
    notifyListeners();
  }

  void updateAllocation(int index, OperationalExpenseModel updatedExpense) {
    if (index < 0 || index >= _operationalExpenseList.length) return;
    _operationalExpenseList[index] = updatedExpense;
    notifyListeners();
  }

  void removeAllocation(int index) {
    if (index < 0 || index >= _operationalExpenseList.length) return;
    _operationalExpenseList.removeAt(index);
    notifyListeners();
  }

  // === Donation CRUD ===
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

  // === UI helpers ===

  /// Percent share (0..1) of a given allocation versus total goal
  double allocationPercent(int index) {
    if (expenseGoal == 0 ||
        index < 0 ||
        index >= _operationalExpenseList.length) {
      return 0;
    }
    return _operationalExpenseList[index].amount / expenseGoal;
  }

  /// (Optional) Reset everything (useful for tests/admin tools)
  void clearAll() {
    _operationalExpenseList.clear();
    _donations.clear();
    notifyListeners();
  }
}
