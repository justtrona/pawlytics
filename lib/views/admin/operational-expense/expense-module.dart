// lib/views/admin/operational-expense/operational-expense-module.dart
import 'package:flutter/material.dart';
import 'package:pawlytics/views/admin/operational-expense/operational-expense.dart';

class OperationalExpenseModule extends StatelessWidget {
  const OperationalExpenseModule({super.key});

  @override
  Widget build(BuildContext context) {
    // Do NOT wrap with ChangeNotifierProvider here.
    // It will use the shared provider from main.dart.
    return const OperationalExpense();
  }
}
