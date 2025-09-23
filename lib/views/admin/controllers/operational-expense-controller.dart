import 'package:flutter/material.dart';
import 'package:pawlytics/views/admin/model/donation-model.dart';
import 'package:pawlytics/views/admin/model/operational-expense-model.dart';
// import 'package:pawlytics/views/admin/model/donation-model.dart'; // new file

class OperationalExpenseController extends ChangeNotifier {
  final List<OperationalExpenseModel> _operationalExpenseList = [
    OperationalExpenseModel(category: 'Drinking Water', amount: 5000),
    OperationalExpenseModel(category: 'Utility Water', amount: 3000),
    OperationalExpenseModel(category: 'Electricity', amount: 5000),
  ];

  final List<DonationModel> _donations = [];

// dire gi total ang breakdown sa allocations
  double get expenseGoal =>
      _operationalExpenseList.fold(0, (sum, e) => sum + e.amount);

  List<OperationalExpenseModel> get operationalExpenseList =>
      List.unmodifiable(_operationalExpenseList);

  List<DonationModel> get donations => List.unmodifiable(_donations);

  double get totalDonations =>
      _donations.fold(0, (sum, d) => sum + d.amount);

  double get progress =>
      expenseGoal == 0 ? 0 : (totalDonations / expenseGoal);

  // Allocation 
  void addAllocation(OperationalExpenseModel expense) {
    _operationalExpenseList.add(expense);
    notifyListeners();
  }

  void updateAllocation(int index, OperationalExpenseModel updatedExpense) {
    _operationalExpenseList[index] = updatedExpense;
    notifyListeners();
  }

  void removeAllocation(int index) {
    _operationalExpenseList.removeAt(index);
    notifyListeners();
  }
//Donation

  void addDonation(DonationModel donation) {
    _donations.add(donation);
    notifyListeners();
  }

  void removeDonation(int index) {
    _donations.removeAt(index);
    notifyListeners();
  }

  // ui para makita ang % breakdown
  double allocationPercent(int index) {
    if (expenseGoal == 0) return 0;
    return _operationalExpenseList[index].amount / expenseGoal;
  }
}



// import 'dart:math';
// import 'package:flutter/material.dart';
// // import 'package:pawlytics/route/route.dart' as route;
// import 'package:pawlytics/views/admin/model/operational-expense-model.dart';

// class OperationalExpenseController extends ChangeNotifier {
//   double _expenseGoal = 50000; //sample only

//   final List<OperationalExpenseModel> _OperationalExpenseList = [
//     OperationalExpenseModel(category: 'Drinking Water', amount: 5000),
//     OperationalExpenseModel(category: 'Utility Water', amount: 3000),
//     OperationalExpenseModel(category: 'Electricity', amount: 5000),
//   ];
    
//     double get expenseGoal => _expenseGoal;

//     List<OperationalExpenseModel> get OperationalExpenseList  => List.unmodifiable(_OperationalExpenseList);

//     double get totalOperationalExpenses =>
//       _OperationalExpenseList.fold(0, (sum,e) => sum + e.amount);

//     double get progress =>
//         (totalOperationalExpenses / _expenseGoal);

//     void setGoal(double goal) {
//       _expenseGoal = goal;
//       notifyListeners();
//     }

//     void updateExpense(int index, OperationalExpenseModel updatedExpense) {
//       OperationalExpenseList[index] = updatedExpense;
//     notifyListeners();
//     }


//     void addExpense(OperationalExpenseModel expense) {
//       _OperationalExpenseList.add(expense);
//       notifyListeners();
//     }

//     void removeExpense (int index) {
//       _OperationalExpenseList.removeAt(index);
//       notifyListeners();
//     }
// }