import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:pawlytics/views/admin/controllers/operational-expense-controller.dart';
import 'package:pawlytics/views/admin/model/operational-expense-model.dart';
import 'package:pawlytics/views/admin/model/donation-model.dart';

class OperationalExpense extends StatefulWidget {
  const OperationalExpense({super.key});

  @override
  State<OperationalExpense> createState() => _OperationalExpenseState();
}

class _OperationalExpenseState extends State<OperationalExpense> {
  final _dateFmt = DateFormat('MMM d, yyyy');

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<OperationalExpenseController>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Operational Expense'),
        leading: const BackButton(),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            // Progress / Goal
            const SizedBox(height: 12),
            Center(
              child: Text(
                "Monthly Goal",
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                "₱${controller.expenseGoal.toStringAsFixed(2)}",
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: controller.progress,
              minHeight: 16,
              backgroundColor: Colors.grey[300],
              color: controller.progress < 1.0 ? Colors.blue : Colors.green,
              borderRadius: BorderRadius.circular(8),
            ),
            const SizedBox(height: 8),
            Text(
              // ✅ cash-only contributes to peso progress
              "₱${controller.totalDonationsCash.toStringAsFixed(2)} / ₱${controller.expenseGoal.toStringAsFixed(2)} donated",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),

            const Divider(height: 40),

            // Allocation breakdown
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Expense Breakdown",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "Long press to delete",
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (controller.operationalExpenseList.isEmpty)
              const Center(
                child: Text(
                  "No allocations yet.",
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ...controller.operationalExpenseList.asMap().entries.map((entry) {
              final index = entry.key;
              final expense = entry.value;

              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ListTile(
                  leading: const Icon(Icons.pie_chart, color: Colors.blue),
                  title: Text(
                    expense.category,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    "₱${expense.amount.toStringAsFixed(2)} "
                    "(${(controller.allocationPercent(index) * 100).toStringAsFixed(1)}%)",
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.orange),
                        onPressed: () {
                          final categoryController = TextEditingController(
                            text: expense.category,
                          );
                          final amountController = TextEditingController(
                            text: expense.amount.toString(),
                          );
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text("Edit Allocation"),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  TextField(
                                    controller: categoryController,
                                    decoration: const InputDecoration(
                                      labelText: "Category",
                                    ),
                                  ),
                                  TextField(
                                    controller: amountController,
                                    decoration: const InputDecoration(
                                      labelText: "Amount",
                                      prefixText: "₱ ",
                                    ),
                                    keyboardType: TextInputType.number,
                                  ),
                                ],
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text(
                                    "Cancel",
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    controller.updateAllocation(
                                      index,
                                      OperationalExpenseModel(
                                        category: categoryController.text,
                                        amount:
                                            double.tryParse(
                                              amountController.text,
                                            ) ??
                                            expense.amount,
                                      ),
                                    );
                                    Navigator.pop(context);
                                  },
                                  child: const Text("Update"),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => controller.removeAllocation(index),
                      ),
                    ],
                  ),
                ),
              );
            }),

            const Divider(height: 40),

            // Donations
            Text(
              "Donations",
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            if (controller.donations.isEmpty)
              const Center(
                child: Text(
                  "No donations yet.",
                  style: TextStyle(color: Colors.grey),
                ),
              ),

            // ✅ Render cash vs in-kind safely
            ...controller.donations.asMap().entries.map((entry) {
              final index = entry.key;
              final d = entry.value;
              final donor = (d.donorName.isEmpty) ? 'Anonymous' : d.donorName;
              final dateStr = _dateFmt.format(d.date);

              final isCash = d.type == DonationType.cash;
              final title = isCash
                  ? "₱${(d.amount ?? 0).toStringAsFixed(2)} from $donor"
                  : "${(d.item ?? 'In-kind item')} × ${(d.quantity ?? 0)} from $donor";

              final subtitle = isCash
                  ? "Cash • ${d.paymentMethod ?? '—'} • $dateStr"
                  : "In-Kind • $dateStr";

              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ListTile(
                  leading: Icon(
                    isCash ? Icons.payments : Icons.inventory_2,
                    color: isCash ? Colors.green : Colors.deepPurple,
                  ),
                  title: Text(title),
                  subtitle: Text(subtitle),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => controller.removeDonation(index),
                  ),
                ),
              );
            }),
          ],
        ),
      ),

      // FAB: Add Allocation
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text("Add Allocation"),
        onPressed: () {
          final categoryController = TextEditingController();
          final amountController = TextEditingController();
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text("Add Allocation"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: categoryController,
                    decoration: const InputDecoration(labelText: "Category"),
                  ),
                  TextField(
                    controller: amountController,
                    decoration: const InputDecoration(
                      labelText: "Amount",
                      prefixText: "₱ ",
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    "Cancel",
                    style: TextStyle(color: Colors.red),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (categoryController.text.isNotEmpty &&
                        amountController.text.isNotEmpty) {
                      controller.addAllocation(
                        OperationalExpenseModel(
                          category: categoryController.text,
                          amount: double.tryParse(amountController.text) ?? 0,
                        ),
                      );
                    }
                    Navigator.pop(context);
                  },
                  child: const Text("Add"),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:pawlytics/views/admin/controllers/operational-expense-controller.dart';
// import 'package:pawlytics/views/admin/model/operational-expense-model.dart';

// class OperationalExpense extends StatefulWidget {
//   const OperationalExpense({super.key});

//   @override
//   State<OperationalExpense> createState() => _OperationalExpenseState();
// }

// class _OperationalExpenseState extends State<OperationalExpense> {
//   @override
//   Widget build(BuildContext context) {
//     final controller = Provider.of<OperationalExpenseController>(context);

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Operational Expense'),
//         leading: const BackButton(),
//         backgroundColor: Colors.white,
//         foregroundColor: Colors.black,
//         centerTitle: true,
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.edit),
//             tooltip: "Set Monthly Goal",
//             onPressed: () {
//               final goalController = TextEditingController();
//               showDialog(
//                 context: context,
//                 builder: (context) => AlertDialog(
//                   title: const Text("Set Expense Goal"),
//                   content: TextField(
//                     controller: goalController,
//                     decoration: const InputDecoration(
//                       labelText: "Enter goal amount",
//                       prefixText: "₱ ",
//                     ),
//                     keyboardType: TextInputType.number,
//                   ),
//                   actions: [
//                     TextButton(
//                         onPressed: () => Navigator.pop(context),
//                         child: const Text("Cancel")),
//                     ElevatedButton(
//                         onPressed: () {
//                           if (goalController.text.isNotEmpty) {
//                             controller.setGoal(
//                                 double.tryParse(goalController.text) ??
//                                     controller.expenseGoal);
//                           }
//                           Navigator.pop(context);
//                         },
//                         child: const Text("Save")),
//                   ],
//                 ),
//               );
//             },
//           )
//         ],
//       ),
//       body: SafeArea(
//         child: ListView(
//           padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
//           children: [
//             const SizedBox(height: 12),
//             Center(
//               child: Text(
//                 "Monthly Expense Goal",
//                 style: Theme.of(context).textTheme.titleMedium,
//               ),
//             ),
//             const SizedBox(height: 8),
//             Center(
//               child: Text(
//                 "₱${controller.expenseGoal.toStringAsFixed(2)}",
//                 style: Theme.of(context)
//                     .textTheme
//                     .headlineSmall
//                     ?.copyWith(fontWeight: FontWeight.bold),
//               ),
//             ),
//             const SizedBox(height: 16),
//             LinearProgressIndicator(
//               value: controller.progress,
//               minHeight: 14,
//               backgroundColor: Colors.grey[300],
//               color: controller.progress < 1.0 ? Colors.blue : Colors.green,
//               borderRadius: BorderRadius.circular(8),
//             ),
//             const SizedBox(height: 8),
//             Text(
//               "₱${controller.totalOperationalExpenses.toStringAsFixed(2)} of ₱${controller.expenseGoal.toStringAsFixed(2)}",
//               textAlign: TextAlign.center,
//               style: const TextStyle(fontSize: 14),
//             ),
//             const Divider(height: 32),

//             // Breakdown section
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Text(
//                   "Expense Breakdown",
//                   style: Theme.of(context).textTheme.titleMedium,
//                 ),
//                 Text(
//                   "Long press to delete",
//                   style: TextStyle(
//                       fontSize: 12, color: Colors.grey[600]),
//                 )
//               ],
//             ),
//             const SizedBox(height: 8),

//             ...controller.OperationalExpenseList.asMap().entries.map((entry) {
//               final index = entry.key;
//               final expense = entry.value;

//               return Card(
//                 shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(12)),
//                 elevation: 2,
//                 margin: const EdgeInsets.symmetric(vertical: 6),
//                 child: ListTile(
//                   leading: const Icon(Icons.pie_chart, color: Colors.blue),
//                   title: Text(expense.category,
//                       style: const TextStyle(fontWeight: FontWeight.w600)),
//                   subtitle: Text("Expense #${index + 1}"),
//                   trailing: Row(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       Text(
//                         "₱${expense.amount.toStringAsFixed(2)}",
//                         style: const TextStyle(fontWeight: FontWeight.bold),
//                       ),
//                       const SizedBox(width: 12),
//                       IconButton(
//                         icon: const Icon(Icons.edit, color: Colors.orange),
//                         onPressed: () {
//                           final categoryController =
//                               TextEditingController(text: expense.category);
//                           final amountController =
//                               TextEditingController(text: expense.amount.toString());
//                           showDialog(
//                             context: context,
//                             builder: (context) => AlertDialog(
//                               title: const Text("Edit Expense"),
//                               content: Column(
//                                 mainAxisSize: MainAxisSize.min,
//                                 children: [
//                                   TextField(
//                                     controller: categoryController,
//                                     decoration: const InputDecoration(
//                                         labelText: "Category"),
//                                   ),
//                                   TextField(
//                                     controller: amountController,
//                                     decoration: const InputDecoration(
//                                       labelText: "Amount",
//                                       prefixText: "₱ ",
//                                     ),
//                                     keyboardType: TextInputType.number,
//                                   ),
//                                 ],
//                               ),
//                               actions: [
//                                 TextButton(
//                                     onPressed: () => Navigator.pop(context),
//                                     child: const Text("Cancel")),
//                                 ElevatedButton(
//                                     onPressed: () {
//                                       controller.updateExpense(
//                                           index,
//                                           OperationalExpenseModel(
//                                               category:
//                                                   categoryController.text,
//                                               amount: double.tryParse(
//                                                       amountController.text) ??
//                                                   expense.amount));
//                                       Navigator.pop(context);
//                                     },
//                                     child: const Text("Update")),
//                               ],
//                             ),
//                           );
//                         },
//                       ),
//                       IconButton(
//                         icon: const Icon(Icons.delete, color: Colors.red),
//                         onPressed: () => controller.removeExpense(index),
//                       ),
//                     ],
//                   ),
//                 ),
//               );
//             }),
//           ],
//         ),
//       ),
//       floatingActionButton: FloatingActionButton(
//         child: const Icon(Icons.add),
//         onPressed: () {
//           final categoryController = TextEditingController();
//           final amountController = TextEditingController();
//           showDialog(
//             context: context,
//             builder: (context) => AlertDialog(
//               title: const Text("Add Expense"),
//               content: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   TextField(
//                     controller: categoryController,
//                     decoration: const InputDecoration(labelText: "Category"),
//                   ),
//                   TextField(
//                     controller: amountController,
//                     decoration: const InputDecoration(
//                       labelText: "Amount",
//                       prefixText: "₱ ",
//                     ),
//                     keyboardType: TextInputType.number,
//                   ),
//                 ],
//               ),
//               actions: [
//                 TextButton(
//                     onPressed: () => Navigator.pop(context),
//                     child: const Text("Cancel")),
//                 ElevatedButton(
//                     onPressed: () {
//                       if (categoryController.text.isNotEmpty &&
//                           amountController.text.isNotEmpty) {
//                         controller.addExpense(OperationalExpenseModel(
//                           category: categoryController.text,
//                           amount: double.tryParse(amountController.text) ?? 0,
//                         ));
//                       }
//                       Navigator.pop(context);
//                     },
//                     child: const Text("Add")),
//               ],
//             ),
//           );
//         },
//       ),
//     );
//   }
// }
