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
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OperationalExpenseController>().loadAllocations();
    });
  }

  Future<void> _refresh() async {
    await context.read<OperationalExpenseController>().loadAllocations();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<OperationalExpenseController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Operational Expense'),
        leading: const BackButton(),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
          ),
        ],
      ),
      body: SafeArea(
        child: controller.loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _refresh,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  children: [
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
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
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
                      color: controller.progress < 1.0
                          ? Colors.blue
                          : Colors.green,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "₱${controller.totalDonationsCash.toStringAsFixed(2)} / ₱${controller.expenseGoal.toStringAsFixed(2)} donated",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const Divider(height: 40),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Expense Breakdown",
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          "Long press to delete",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    if (controller.operationalExpenseList.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Text(
                            "No allocations yet.",
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      )
                    else
                      ...controller.operationalExpenseList.asMap().entries.map((
                        entry,
                      ) {
                        final index = entry.key;
                        final expense = entry.value;

                        return Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          child: ListTile(
                            onLongPress: () =>
                                controller.removeAllocation(index),
                            leading: const Icon(
                              Icons.pie_chart,
                              color: Colors.blue,
                            ),
                            title: Text(
                              expense.category,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              "₱${expense.amount.toStringAsFixed(2)} "
                              "(${(controller.allocationPercent(index) * 100).toStringAsFixed(1)}%)",
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit,
                                    color: Colors.orange,
                                  ),
                                  onPressed: () {
                                    // capture the provider instance BEFORE the dialog
                                    final opex = context
                                        .read<OperationalExpenseController>();

                                    final categoryController =
                                        TextEditingController(
                                          text: expense.category,
                                        );
                                    final amountController =
                                        TextEditingController(
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
                                              keyboardType:
                                                  TextInputType.number,
                                            ),
                                          ],
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context),
                                            child: const Text(
                                              "Cancel",
                                              style: TextStyle(
                                                color: Colors.red,
                                              ),
                                            ),
                                          ),
                                          ElevatedButton(
                                            onPressed: () async {
                                              final newCategory =
                                                  categoryController.text
                                                      .trim();
                                              final newAmount =
                                                  double.tryParse(
                                                    amountController.text,
                                                  ) ??
                                                  expense.amount;

                                              await opex.updateAllocation(
                                                index,
                                                OperationalExpenseModel(
                                                  id: expense.id,
                                                  category: newCategory.isEmpty
                                                      ? expense.category
                                                      : newCategory,
                                                  amount: newAmount,
                                                ),
                                              );

                                              if (context.mounted)
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
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  onPressed: () =>
                                      controller.removeAllocation(index),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),

                    const Divider(height: 40),

                    Text(
                      "Donations",
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),

                    if (controller.donations.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Text(
                            "No donations yet.",
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      )
                    else
                      ...controller.donations.asMap().entries.map((entry) {
                        final index = entry.key;
                        final d = entry.value;
                        final donor = (d.donorName.isEmpty)
                            ? 'Anonymous'
                            : d.donorName;
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
      ),

      // FAB: Add Allocation
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text("Add Allocation"),
        onPressed: () {
          // capture the provider instance BEFORE opening the dialog
          final opex = context.read<OperationalExpenseController>();

          final categoryController = TextEditingController();
          final amountController = TextEditingController();

          showDialog(
            context: context,
            builder: (context) {
              bool saving = false;
              String? error;

              return StatefulBuilder(
                builder: (context, setState) => AlertDialog(
                  title: const Text("Add Allocation"),
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
                      if (error != null) ...[
                        const SizedBox(height: 8),
                        Text(error!, style: const TextStyle(color: Colors.red)),
                      ],
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: saving ? null : () => Navigator.pop(context),
                      child: const Text(
                        "Cancel",
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: saving
                          ? null
                          : () async {
                              final category = categoryController.text.trim();
                              final amount =
                                  double.tryParse(amountController.text) ?? 0;

                              if (category.isEmpty || amount <= 0) {
                                setState(
                                  () => error =
                                      'Please provide a category and a positive amount.',
                                );
                                return;
                              }

                              setState(() {
                                saving = true;
                                error = null;
                              });

                              try {
                                await opex.addAllocation(
                                  OperationalExpenseModel(
                                    category: category,
                                    amount: amount,
                                  ),
                                );

                                if (context.mounted) {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Allocation added'),
                                    ),
                                  );
                                }
                              } catch (e) {
                                setState(() {
                                  saving = false;
                                  error = e.toString();
                                });
                              }
                            },
                      child: saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text("Add"),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
