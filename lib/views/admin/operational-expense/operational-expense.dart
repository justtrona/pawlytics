// lib/views/admin/pages/operational-expense.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:pawlytics/views/admin/controllers/operational-expense-controller.dart';
import 'package:pawlytics/views/admin/model/operational-expense-model.dart';

class OperationalExpense extends StatefulWidget {
  const OperationalExpense({super.key});

  @override
  State<OperationalExpense> createState() => _OperationalExpenseState();
}

class _OperationalExpenseState extends State<OperationalExpense>
    with WidgetsBindingObserver {
  final _dateFmt = DateFormat('MMM d, yyyy');
  final _monthFmt = DateFormat('MMMM yyyy');
  final _php = NumberFormat.currency(locale: 'en_PH', symbol: '₱');

  /// Dropdown selection. `null` => current (active) month.
  int? _selectedHistoryIndex;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<OperationalExpenseController>().loadAllocations();
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      _refresh();
    }
  }

  Future<void> _refresh() async {
    await context.read<OperationalExpenseController>().loadAllocations();
    if (mounted) setState(() {});
  }

  Future<bool> _confirm({
    required String title,
    required String message,
    String confirmText = 'Delete',
    String cancelText = 'Cancel',
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(cancelText, style: const TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(confirmText),
          ),
        ],
      ),
    );
    return ok == true;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<OperationalExpenseController>();

    // ---- Month filter items ----
    final monthChoices = <_MonthChoice>[
      _MonthChoice.current(
        label:
            'Current (${c.currentMonthEnd == null ? '—' : _monthFmt.format(c.currentMonthEnd!.subtract(const Duration(days: 1)))})',
      ),
      ...c.history.asMap().entries.map(
        (e) => _MonthChoice.history(
          indexInHistory: e.key,
          label: _monthFmt.format(e.value.monthStart),
        ),
      ),
    ];

    final selectedChoice = _selectedHistoryIndex == null
        ? monthChoices.first
        : monthChoices
              .skip(1)
              .firstWhere((m) => m.indexInHistory == _selectedHistoryIndex);

    final viewingCurrent = _selectedHistoryIndex == null;

    // Header fields for current view
    final isClosed = c.isCurrentMonthClosed;
    final isCompleted = c.isCurrentMonthCompleted;
    final dueStr = c.currentMonthEnd == null
        ? '—'
        : _dateFmt.format(c.currentMonthEnd!);
    final totalThisMonth = c.totalExpensesThisMonth; // manual + tracked

    return Scaffold(
      appBar: AppBar(
        title: const Text('Monthly Expense Tracker'),
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
        child: c.loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _refresh,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  children: [
                    // ------- Month filter -------
                    Row(
                      children: [
                        const Icon(Icons.calendar_month, color: Colors.blue),
                        const SizedBox(width: 8),
                        const Text(
                          'Month:',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButton<_MonthChoice>(
                            value: selectedChoice,
                            isExpanded: true,
                            underline: const SizedBox(),
                            items: monthChoices
                                .map(
                                  (m) => DropdownMenuItem<_MonthChoice>(
                                    value: m,
                                    child: Row(
                                      children: [
                                        if (m.isCurrent)
                                          const Icon(
                                            Icons.bolt,
                                            size: 16,
                                            color: Colors.blue,
                                          )
                                        else
                                          const Icon(
                                            Icons.history,
                                            size: 16,
                                            color: Colors.grey,
                                          ),
                                        const SizedBox(width: 8),
                                        Text(m.label),
                                      ],
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (m) {
                              if (m == null) return;
                              setState(() {
                                _selectedHistoryIndex = m.isCurrent
                                    ? null
                                    : m.indexInHistory;
                              });
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // ------------- CURRENT MONTH -------------
                    if (viewingCurrent) ...[
                      _HeaderCard(
                        title: "Total Expenses (This Month)",
                        value: _php.format(totalThisMonth),
                        statusText: isCompleted
                            ? 'Completed'
                            : (isClosed ? 'Closed' : 'Active'),
                        statusColor: isCompleted
                            ? Colors.green
                            : (isClosed ? Colors.black54 : Colors.blue),
                        icon: isCompleted
                            ? Icons.check_circle
                            : (isClosed ? Icons.lock_clock : Icons.bolt),
                        subText: 'As of: $dueStr',
                        warnClosed: isClosed && !isCompleted,
                      ),

                      const Divider(height: 40),

                      // ------- CATEGORIES (manual + tracked shown as "spent") -------
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Expense Categories (This Month)",
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

                      if (c.operationalExpenseList.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: Text(
                              "No categories yet.",
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        )
                      else
                        ...c.operationalExpenseList.asMap().entries.map((
                          entry,
                        ) {
                          final index = entry.key;
                          final expense = entry.value;
                          final tracked = c.raisedForAllocationId(expense.id);
                          final spent = tracked + expense.amount;

                          Future<void> _deleteThis() async {
                            final ok = await _confirm(
                              title: 'Are you sure you want to delete?',
                              message:
                                  'This will permanently remove “${expense.category}”.',
                            );
                            if (!ok) return;
                            final success = await c.removeAllocation(index);
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  success
                                      ? 'Category deleted'
                                      : 'Failed to delete category',
                                ),
                              ),
                            );
                          }

                          final categoryController = TextEditingController(
                            text: expense.category,
                          );
                          final amountController = TextEditingController(
                            text: expense.amount.toString(),
                          );

                          return Card(
                            key: ValueKey(
                              expense.id ?? '${expense.category}-$index',
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            child: ListTile(
                              onLongPress: _deleteThis,
                              leading: const Icon(
                                Icons.receipt,
                                color: Colors.blue,
                              ),
                              title: Text(
                                expense.category,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(
                                  '${_php.format(spent)} spent this month',
                                ),
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
                                      showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text("Edit Expense"),
                                          content: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              TextField(
                                                controller: categoryController,
                                                decoration:
                                                    const InputDecoration(
                                                      labelText:
                                                          "Expense Title",
                                                    ),
                                              ),
                                              TextField(
                                                controller: amountController,
                                                decoration:
                                                    const InputDecoration(
                                                      labelText: "Amount (₱)",
                                                      prefixText: "₱ ",
                                                    ),
                                                keyboardType:
                                                    const TextInputType.numberWithOptions(
                                                      signed: false,
                                                      decimal: true,
                                                    ),
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
                                                await c.updateAllocation(
                                                  index,
                                                  OperationalExpenseModel(
                                                    id: expense.id,
                                                    category:
                                                        newCategory.isEmpty
                                                        ? expense.category
                                                        : newCategory,
                                                    amount: newAmount,
                                                  ),
                                                );
                                                if (context.mounted) {
                                                  Navigator.pop(context);
                                                }
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
                                    onPressed: _deleteThis,
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),

                      const SizedBox(height: 24),
                    ]
                    // ------------- PREVIOUS MONTH (read-only) -------------
                    else ...[
                      _PreviousMonthHeader(
                        summary: c.history[_selectedHistoryIndex!],
                        monthFmt: _monthFmt,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'This is a past month. Editing categories is disabled.',
                        style: TextStyle(color: Colors.black54, fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
      ),

      // FAB only for current month
      floatingActionButton: viewingCurrent
          ? FloatingActionButton.extended(
              icon: const Icon(Icons.add),
              label: const Text("Add Expense"),
              onPressed: () {
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
                        title: const Text("Add Expense"),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextField(
                              controller: categoryController,
                              decoration: const InputDecoration(
                                labelText: "Expense Title",
                              ),
                            ),
                            TextField(
                              controller: amountController,
                              decoration: const InputDecoration(
                                labelText: "Amount (₱)",
                                prefixText: "₱ ",
                              ),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    signed: false,
                                    decimal: true,
                                  ),
                            ),
                            if (error != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                error!,
                                style: const TextStyle(color: Colors.red),
                              ),
                            ],
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: saving
                                ? null
                                : () => Navigator.pop(context),
                            child: const Text(
                              "Cancel",
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: saving
                                ? null
                                : () async {
                                    final category = categoryController.text
                                        .trim();
                                    final amount =
                                        double.tryParse(
                                          amountController.text.trim().isEmpty
                                              ? '0'
                                              : amountController.text.trim(),
                                        ) ??
                                        0.0;

                                    if (category.isEmpty) {
                                      setState(
                                        () => error =
                                            'Please provide a category.',
                                      );
                                      return;
                                    }
                                    if (amount < 0) {
                                      setState(
                                        () => error =
                                            'Amount cannot be negative.',
                                      );
                                      return;
                                    }

                                    setState(() {
                                      saving = true;
                                      error = null;
                                    });

                                    final ok = await opex.addAllocation(
                                      OperationalExpenseModel(
                                        category: category,
                                        amount: amount,
                                      ),
                                    );

                                    if (!mounted) return;
                                    Navigator.pop(context);

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          ok
                                              ? 'Category added'
                                              : 'Failed to add category',
                                        ),
                                      ),
                                    );
                                  },
                            child: saving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text("Add"),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            )
          : null,
    );
  }
}

/* ============================ helpers ============================ */

class _MonthChoice {
  final String label;
  final bool isCurrent;
  final int? indexInHistory; // used when !isCurrent

  _MonthChoice.current({required this.label})
    : isCurrent = true,
      indexInHistory = null;

  _MonthChoice.history({required this.indexInHistory, required this.label})
    : isCurrent = false;
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.title,
    required this.value,
    required this.statusText,
    required this.statusColor,
    required this.icon,
    required this.subText,
    required this.warnClosed,
  });

  final String title;
  final String value;
  final String statusText;
  final Color statusColor;
  final IconData icon;
  final String subText;
  final bool warnClosed;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F4FF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(color: Colors.black87),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  children: [
                    Icon(icon, size: 16, color: statusColor),
                    const SizedBox(width: 6),
                    Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: Colors.blue.shade600,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subText,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: Colors.black54),
          ),
          if (warnClosed) ...[
            const SizedBox(height: 8),
            const Text(
              'Month is closed. Adding new entries should be disabled.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.redAccent),
            ),
          ],
        ],
      ),
    );
  }
}

class _PreviousMonthHeader extends StatelessWidget {
  const _PreviousMonthHeader({required this.summary, required this.monthFmt});

  final MonthSummary summary;
  final DateFormat monthFmt;

  Color _statusColor(String s) {
    switch (s) {
      case 'completed':
        return Colors.green;
      case 'closed':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(summary.state);
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(top: 8),
      child: ListTile(
        leading: Icon(Icons.history, color: statusColor),
        title: Text(monthFmt.format(summary.monthStart)),
        // 👇 removed the "₱xxx total" subtitle
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(.12),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            summary.state,
            style: TextStyle(
              color: statusColor,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}

// // lib/views/admin/pages/operational-expense.dart
// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import 'package:provider/provider.dart';

// import 'package:pawlytics/views/admin/controllers/operational-expense-controller.dart';
// import 'package:pawlytics/views/admin/model/operational-expense-model.dart';
// import 'package:pawlytics/views/admin/model/donation-model.dart';

// class OperationalExpense extends StatefulWidget {
//   const OperationalExpense({super.key});

//   @override
//   State<OperationalExpense> createState() => _OperationalExpenseState();
// }

// class _OperationalExpenseState extends State<OperationalExpense> {
//   final _dateFmt = DateFormat('MMM d, yyyy');
//   final _monthFmt = DateFormat('MMMM yyyy');
//   final _php = NumberFormat.currency(locale: 'en_PH', symbol: '₱');

//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       context.read<OperationalExpenseController>().loadAllocations();
//     });
//   }

//   Future<void> _refresh() async {
//     await context.read<OperationalExpenseController>().loadAllocations();
//   }

//   double _clamp01(double v) => (v.isFinite ? v.clamp(0.0, 1.0) : 0.0);

//   Color _statusColor(String s) {
//     switch (s) {
//       case 'completed':
//         return Colors.green;
//       case 'closed':
//         return Colors.grey;
//       default:
//         return Colors.blue;
//     }
//   }

//   Future<bool> _confirm({
//     required String title,
//     required String message,
//     String confirmText = 'Delete',
//     String cancelText = 'Cancel',
//   }) async {
//     final ok = await showDialog<bool>(
//       context: context,
//       builder: (ctx) => AlertDialog(
//         title: Text(title),
//         content: Text(message),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(ctx, false),
//             child: Text(cancelText, style: const TextStyle(color: Colors.red)),
//           ),
//           ElevatedButton(
//             onPressed: () => Navigator.pop(ctx, true),
//             child: Text(confirmText),
//           ),
//         ],
//       ),
//     );
//     return ok == true;
//   }

//   @override
//   Widget build(BuildContext context) {
//     final c = context.watch<OperationalExpenseController>();

//     final isClosed = c.isCurrentMonthClosed;
//     final isCompleted = c.isCurrentMonthCompleted;
//     final dueStr = c.currentMonthEnd == null
//         ? '—'
//         : _dateFmt.format(c.currentMonthEnd!);

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Operational Expense'),
//         leading: const BackButton(),
//         backgroundColor: Colors.white,
//         foregroundColor: Colors.black,
//         centerTitle: true,
//         actions: [
//           IconButton(
//             tooltip: 'Refresh',
//             icon: const Icon(Icons.refresh),
//             onPressed: _refresh,
//           ),
//         ],
//       ),
//       body: SafeArea(
//         child: c.loading
//             ? const Center(child: CircularProgressIndicator())
//             : RefreshIndicator(
//                 onRefresh: _refresh,
//                 child: ListView(
//                   physics: const AlwaysScrollableScrollPhysics(),
//                   padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
//                   children: [
//                     // ------- HEADER CARD -------
//                     Container(
//                       margin: const EdgeInsets.only(top: 8, bottom: 8),
//                       padding: const EdgeInsets.symmetric(
//                         horizontal: 16,
//                         vertical: 16,
//                       ),
//                       decoration: BoxDecoration(
//                         color: const Color(0xFFF8F4FF),
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.center,
//                         children: [
//                           Row(
//                             mainAxisAlignment: MainAxisAlignment.center,
//                             children: [
//                               Text(
//                                 "Monthly Goal",
//                                 style: Theme.of(context).textTheme.titleMedium
//                                     ?.copyWith(color: Colors.black87),
//                               ),
//                               const SizedBox(width: 8),
//                               Container(
//                                 padding: const EdgeInsets.symmetric(
//                                   horizontal: 10,
//                                   vertical: 4,
//                                 ),
//                                 decoration: BoxDecoration(
//                                   color: isCompleted
//                                       ? Colors.green.withOpacity(.12)
//                                       : (isClosed
//                                             ? Colors.black26
//                                             : Colors.blue.withOpacity(.12)),
//                                   borderRadius: BorderRadius.circular(999),
//                                 ),
//                                 child: Row(
//                                   children: [
//                                     Icon(
//                                       isCompleted
//                                           ? Icons.check_circle
//                                           : (isClosed
//                                                 ? Icons.lock_clock
//                                                 : Icons.bolt),
//                                       size: 16,
//                                       color: isCompleted
//                                           ? Colors.green
//                                           : (isClosed
//                                                 ? Colors.black54
//                                                 : Colors.blue),
//                                     ),
//                                     const SizedBox(width: 6),
//                                     Text(
//                                       isCompleted
//                                           ? 'Completed'
//                                           : (isClosed ? 'Closed' : 'Active'),
//                                       style: TextStyle(
//                                         fontSize: 12,
//                                         fontWeight: FontWeight.w600,
//                                         color: isCompleted
//                                             ? Colors.green
//                                             : (isClosed
//                                                   ? Colors.black54
//                                                   : Colors.blue),
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                             ],
//                           ),
//                           const SizedBox(height: 6),
//                           Text(
//                             _php.format(c.expenseGoal),
//                             style: Theme.of(context).textTheme.headlineSmall
//                                 ?.copyWith(
//                                   fontWeight: FontWeight.w700,
//                                   color: Colors.blue.shade600,
//                                   letterSpacing: 0.2,
//                                 ),
//                           ),
//                           const SizedBox(height: 6),
//                           Text(
//                             'Due: $dueStr',
//                             style: Theme.of(context).textTheme.labelMedium
//                                 ?.copyWith(color: Colors.black54),
//                           ),
//                           const SizedBox(height: 12),
//                           ClipRRect(
//                             borderRadius: BorderRadius.circular(10),
//                             child: LinearProgressIndicator(
//                               value: _clamp01(c.progress),
//                               minHeight: 14,
//                               backgroundColor: Colors.grey.shade300,
//                               color: c.progress < 1.0
//                                   ? Colors.blue
//                                   : Colors.green,
//                             ),
//                           ),
//                           const SizedBox(height: 8),
//                           Text(
//                             '${_php.format(c.totalDonationsCash)} / ${_php.format(c.expenseGoal)} donated',
//                             textAlign: TextAlign.center,
//                             style: const TextStyle(
//                               fontSize: 14,
//                               fontWeight: FontWeight.w600,
//                               color: Colors.black87,
//                             ),
//                           ),
//                           if (isClosed && !isCompleted) ...[
//                             const SizedBox(height: 8),
//                             const Text(
//                               'Month is closed. New donations should be disabled in the donor app.',
//                               textAlign: TextAlign.center,
//                               style: TextStyle(
//                                 fontSize: 12,
//                                 color: Colors.redAccent,
//                               ),
//                             ),
//                           ],
//                         ],
//                       ),
//                     ),

//                     const Divider(height: 40),

//                     // ------- LIST HEADER -------
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         Text(
//                           "Expense Breakdown",
//                           style: Theme.of(context).textTheme.titleMedium
//                               ?.copyWith(fontWeight: FontWeight.bold),
//                         ),
//                         Text(
//                           "Long press to delete",
//                           style: TextStyle(
//                             fontSize: 12,
//                             color: Colors.grey[600],
//                           ),
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 8),

//                     // ------- ALLOCATIONS LIST -------
//                     if (c.operationalExpenseList.isEmpty)
//                       const Padding(
//                         padding: EdgeInsets.symmetric(vertical: 24),
//                         child: Center(
//                           child: Text(
//                             "No allocations yet.",
//                             style: TextStyle(color: Colors.grey),
//                           ),
//                         ),
//                       )
//                     else
//                       ...c.operationalExpenseList.asMap().entries.map((entry) {
//                         final index = entry.key;
//                         final expense = entry.value;

//                         final raised = c.raisedForAllocationId(expense.id);
//                         final goal = expense.amount;
//                         final pct = goal > 0
//                             ? (raised / goal * 100).clamp(0, 100)
//                             : 0;
//                         final rowProgress = c.allocationProgress(index);

//                         Future<void> _deleteThis() async {
//                           final ok = await _confirm(
//                             title: 'Delete allocation?',
//                             message:
//                                 'This will permanently remove “${expense.category}”.',
//                           );
//                           if (!ok) return;
//                           final success = await c.removeAllocation(index);
//                           if (!mounted) return;
//                           ScaffoldMessenger.of(context).showSnackBar(
//                             SnackBar(
//                               content: Text(
//                                 success
//                                     ? 'Allocation deleted'
//                                     : 'Failed to delete allocation',
//                               ),
//                             ),
//                           );
//                         }

//                         return Card(
//                           key: ValueKey(
//                             expense.id ?? '${expense.category}-$index',
//                           ),
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(12),
//                           ),
//                           elevation: 2,
//                           margin: const EdgeInsets.symmetric(vertical: 6),
//                           child: ListTile(
//                             onLongPress: _deleteThis, // confirmation added
//                             leading: const Icon(
//                               Icons.pie_chart,
//                               color: Colors.blue,
//                             ),
//                             title: Text(
//                               expense.category,
//                               style: const TextStyle(
//                                 fontWeight: FontWeight.w600,
//                               ),
//                             ),

//                             // Raised / Goal + mini progress bar
//                             subtitle: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 Text(
//                                   '${_php.format(raised)} of ${_php.format(goal)} (${pct.toStringAsFixed(1)}%)',
//                                 ),
//                                 const SizedBox(height: 6),
//                                 ClipRRect(
//                                   borderRadius: BorderRadius.circular(6),
//                                   child: LinearProgressIndicator(
//                                     value: _clamp01(rowProgress),
//                                     minHeight: 8,
//                                     backgroundColor: Colors.grey.shade300,
//                                     color: rowProgress < 1.0
//                                         ? Colors.blue
//                                         : Colors.green,
//                                   ),
//                                 ),
//                                 const SizedBox(height: 4),
//                                 Text(
//                                   'Share of monthly goal: ${(c.allocationPercent(index) * 100).toStringAsFixed(1)}%',
//                                   style: TextStyle(
//                                     fontSize: 12,
//                                     color: Colors.grey[700],
//                                   ),
//                                 ),
//                               ],
//                             ),

//                             trailing: Row(
//                               mainAxisSize: MainAxisSize.min,
//                               children: [
//                                 IconButton(
//                                   icon: const Icon(
//                                     Icons.edit,
//                                     color: Colors.orange,
//                                   ),
//                                   onPressed: () {
//                                     final opex = context
//                                         .read<OperationalExpenseController>();

//                                     final categoryController =
//                                         TextEditingController(
//                                           text: expense.category,
//                                         );
//                                     final amountController =
//                                         TextEditingController(
//                                           text: expense.amount.toString(),
//                                         );

//                                     showDialog(
//                                       context: context,
//                                       builder: (context) => AlertDialog(
//                                         title: const Text("Edit Allocation"),
//                                         content: Column(
//                                           mainAxisSize: MainAxisSize.min,
//                                           children: [
//                                             TextField(
//                                               controller: categoryController,
//                                               decoration: const InputDecoration(
//                                                 labelText: "Category",
//                                               ),
//                                             ),
//                                             TextField(
//                                               controller: amountController,
//                                               decoration: const InputDecoration(
//                                                 labelText: "Amount",
//                                                 prefixText: "₱ ",
//                                               ),
//                                               keyboardType:
//                                                   TextInputType.number,
//                                             ),
//                                           ],
//                                         ),
//                                         actions: [
//                                           TextButton(
//                                             onPressed: () =>
//                                                 Navigator.pop(context),
//                                             child: const Text(
//                                               "Cancel",
//                                               style: TextStyle(
//                                                 color: Colors.red,
//                                               ),
//                                             ),
//                                           ),
//                                           ElevatedButton(
//                                             onPressed: () async {
//                                               final newCategory =
//                                                   categoryController.text
//                                                       .trim();
//                                               final newAmount =
//                                                   double.tryParse(
//                                                     amountController.text,
//                                                   ) ??
//                                                   expense.amount;

//                                               await opex.updateAllocation(
//                                                 index,
//                                                 OperationalExpenseModel(
//                                                   id: expense.id,
//                                                   category: newCategory.isEmpty
//                                                       ? expense.category
//                                                       : newCategory,
//                                                   amount: newAmount,
//                                                 ),
//                                               );

//                                               if (context.mounted) {
//                                                 Navigator.pop(context);
//                                               }
//                                             },
//                                             child: const Text("Update"),
//                                           ),
//                                         ],
//                                       ),
//                                     );
//                                   },
//                                 ),
//                                 IconButton(
//                                   icon: const Icon(
//                                     Icons.delete,
//                                     color: Colors.red,
//                                   ),
//                                   onPressed: _deleteThis, // confirmation added
//                                 ),
//                               ],
//                             ),
//                           ),
//                         );
//                       }),

//                     const SizedBox(height: 24),

//                     // ------- HISTORY (Previous months) -------
//                     if (c.history.isNotEmpty) ...[
//                       Text(
//                         "Previous Months",
//                         style: Theme.of(context).textTheme.titleMedium
//                             ?.copyWith(fontWeight: FontWeight.bold),
//                       ),
//                       const SizedBox(height: 8),
//                       ...c.history.map((m) {
//                         final statusColor = _statusColor(m.state);
//                         return Card(
//                           margin: const EdgeInsets.symmetric(vertical: 6),
//                           child: ListTile(
//                             leading: Icon(Icons.history, color: statusColor),
//                             title: Text(_monthFmt.format(m.monthStart)),
//                             subtitle: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 Text(
//                                   '${_php.format(m.cashRaised)} / ${_php.format(m.goalAmount)} • ${(m.progressRatio * 100).toStringAsFixed(1)}%',
//                                 ),
//                                 const SizedBox(height: 4),
//                                 LinearProgressIndicator(
//                                   value: _clamp01(m.progressRatio),
//                                   minHeight: 6,
//                                 ),
//                               ],
//                             ),
//                             trailing: Container(
//                               padding: const EdgeInsets.symmetric(
//                                 horizontal: 10,
//                                 vertical: 4,
//                               ),
//                               decoration: BoxDecoration(
//                                 color: statusColor.withOpacity(.12),
//                                 borderRadius: BorderRadius.circular(999),
//                               ),
//                               child: Text(
//                                 m.state,
//                                 style: TextStyle(
//                                   color: statusColor,
//                                   fontWeight: FontWeight.w700,
//                                   fontSize: 12,
//                                 ),
//                               ),
//                             ),
//                           ),
//                         );
//                       }),
//                       const SizedBox(height: 16),
//                     ],

//                     const Divider(height: 40),

//                     // ------- DONATIONS LIST (UI-only) -------
//                     Text(
//                       "Donations",
//                       style: Theme.of(context).textTheme.titleMedium?.copyWith(
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                     const SizedBox(height: 8),

//                     if (c.donations.isEmpty)
//                       const Padding(
//                         padding: EdgeInsets.symmetric(vertical: 24),
//                         child: Center(
//                           child: Text(
//                             "No donations yet.",
//                             style: TextStyle(color: Colors.grey),
//                           ),
//                         ),
//                       )
//                     else
//                       ...c.donations.asMap().entries.map((entry) {
//                         final index = entry.key;
//                         final d = entry.value;
//                         final donor = (d.donorName.isEmpty)
//                             ? 'Anonymous'
//                             : d.donorName;
//                         final dateStr = _dateFmt.format(d.date);

//                         final isCash = d.type == DonationType.cash;
//                         final title = isCash
//                             ? "${_php.format(d.amount ?? 0)} from $donor"
//                             : "${(d.item ?? 'In-kind item')} × ${(d.quantity ?? 0)} from $donor";
//                         final subtitle = isCash
//                             ? "Cash • ${d.paymentMethod ?? '—'} • $dateStr"
//                             : "In-Kind • $dateStr";

//                         Future<void> _deleteDonation() async {
//                           final ok = await _confirm(
//                             title: 'Delete donation?',
//                             message: 'Remove this donation card permanently?',
//                           );
//                           if (!ok) return;
//                           c.removeDonation(index);
//                           if (!mounted) return;
//                           ScaffoldMessenger.of(context).showSnackBar(
//                             const SnackBar(content: Text('Donation removed')),
//                           );
//                         }

//                         return Card(
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(12),
//                           ),
//                           elevation: 2,
//                           margin: const EdgeInsets.symmetric(vertical: 6),
//                           child: ListTile(
//                             leading: Icon(
//                               isCash ? Icons.payments : Icons.inventory_2,
//                               color: isCash ? Colors.green : Colors.deepPurple,
//                             ),
//                             title: Text(title),
//                             subtitle: Text(subtitle),
//                             trailing: IconButton(
//                               icon: const Icon(Icons.delete, color: Colors.red),
//                               onPressed: _deleteDonation, // confirmation added
//                             ),
//                           ),
//                         );
//                       }),
//                   ],
//                 ),
//               ),
//       ),

//       // ------- FAB: Add Allocation -------
//       floatingActionButton: FloatingActionButton.extended(
//         icon: const Icon(Icons.add),
//         label: const Text("Add Allocation"),
//         onPressed: () {
//           final opex = context.read<OperationalExpenseController>();
//           final categoryController = TextEditingController();
//           final amountController = TextEditingController();

//           showDialog(
//             context: context,
//             builder: (context) {
//               bool saving = false;
//               String? error;

//               return StatefulBuilder(
//                 builder: (context, setState) => AlertDialog(
//                   title: const Text("Add Allocation"),
//                   content: Column(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       TextField(
//                         controller: categoryController,
//                         decoration: const InputDecoration(
//                           labelText: "Category",
//                         ),
//                       ),
//                       TextField(
//                         controller: amountController,
//                         decoration: const InputDecoration(
//                           labelText: "Amount",
//                           prefixText: "₱ ",
//                         ),
//                         keyboardType: TextInputType.number,
//                       ),
//                       if (error != null) ...[
//                         const SizedBox(height: 8),
//                         Text(error!, style: const TextStyle(color: Colors.red)),
//                       ],
//                     ],
//                   ),
//                   actions: [
//                     TextButton(
//                       onPressed: saving ? null : () => Navigator.pop(context),
//                       child: const Text(
//                         "Cancel",
//                         style: TextStyle(color: Colors.red),
//                       ),
//                     ),
//                     ElevatedButton(
//                       onPressed: saving
//                           ? null
//                           : () async {
//                               final category = categoryController.text.trim();
//                               final amount =
//                                   double.tryParse(amountController.text) ?? 0;

//                               if (category.isEmpty || amount <= 0) {
//                                 setState(
//                                   () => error =
//                                       'Please provide a category and a positive amount.',
//                                 );
//                                 return;
//                               }

//                               setState(() {
//                                 saving = true;
//                                 error = null;
//                               });

//                               try {
//                                 final ok = await opex.addAllocation(
//                                   OperationalExpenseModel(
//                                     category: category,
//                                     amount: amount,
//                                   ),
//                                 );

//                                 if (!mounted) return;
//                                 Navigator.pop(context);

//                                 ScaffoldMessenger.of(context).showSnackBar(
//                                   SnackBar(
//                                     content: Text(
//                                       ok
//                                           ? 'Allocation added'
//                                           : 'Failed to add allocation',
//                                     ),
//                                   ),
//                                 );
//                               } catch (e) {
//                                 setState(() {
//                                   saving = false;
//                                   error = e.toString();
//                                 });
//                               }
//                             },
//                       child: saving
//                           ? const SizedBox(
//                               width: 18,
//                               height: 18,
//                               child: CircularProgressIndicator(strokeWidth: 2),
//                             )
//                           : const Text("Add"),
//                     ),
//                   ],
//                 ),
//               );
//             },
//           );
//         },
//       ),
//     );
//   }
// }
