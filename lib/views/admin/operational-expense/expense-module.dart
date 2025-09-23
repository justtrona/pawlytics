import 'package:flutter/material.dart';
import 'package:pawlytics/views/admin/operational-expense/operational-expense.dart';
import 'package:provider/provider.dart';
import 'package:pawlytics/views/admin/controllers/operational-expense-controller.dart';
import 'package:pawlytics/views/admin/model/operational-expense-model.dart';

class OperationalExpenseModule extends StatelessWidget {
  const OperationalExpenseModule({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => OperationalExpenseController(),
      child: OperationalExpense(),
    );
  }
}
