// lib/views/donors/goals/goal_page.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pawlytics/views/donors/model/goal-opex-model.dart';
import 'package:pawlytics/views/donors/controller/goal-opex-controller.dart';
// import '../../../controllers/opex_allocations_controller.dart';
// import '../../../models/opex_allocation.dart';

class GoalPage extends StatefulWidget {
  const GoalPage({super.key});

  @override
  State<GoalPage> createState() => _GoalPageState();
}

class _GoalPageState extends State<GoalPage> {
  final _controller = OpexAllocationsController();
  final _searchController = TextEditingController();
  final _dateFmt = DateFormat('MMMM d, yyyy');

  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onControllerChange);
    _controller.loadAllocations();
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChange);
    _controller.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onControllerChange() {
    if (mounted) setState(() {});
  }

  IconData _iconFor(String name) {
    final s = name.toLowerCase();
    if (s.contains('electric')) return Icons.flash_on_outlined;
    if (s.contains('drink') || s.contains('water')) {
      return s.contains('drink')
          ? Icons.local_drink_outlined
          : Icons.water_drop_outlined;
    }
    if (s.contains('food')) return Icons.restaurant_outlined;
    if (s.contains('rent')) return Icons.home_outlined;
    return Icons.payments_outlined;
  }

  @override
  Widget build(BuildContext context) {
    // Filter list
    final List<OpexAllocation> filtered = _controller.items.where((e) {
      return e.category.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    // Totals
    final double totalGoal = filtered.fold<double>(
      0,
      (sum, e) => sum + e.amount,
    );
    final double totalRaised = filtered.fold<double>(
      0,
      (sum, e) => sum + e.raised,
    );
    final double overallProgress = totalGoal > 0
        ? (totalRaised / totalGoal).clamp(0.0, 1.0)
        : 0.0;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Goals",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2C47),
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _controller.loadAllocations,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _controller.loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Search
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: "Search Utility Needs",
                      hintStyle: const TextStyle(color: Colors.grey),
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      filled: true,
                      fillColor: Colors.grey.shade200,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 0,
                        horizontal: 16,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (value) => setState(() => _searchQuery = value),
                  ),
                  const SizedBox(height: 20),

                  // Overall goal card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 6,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Overall Goal",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F2C47),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Center(
                          child: Text(
                            "Php ${totalRaised.toStringAsFixed(0)} of Php ${totalGoal.toStringAsFixed(0)}",
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: overallProgress,
                            backgroundColor: Colors.grey.shade300,
                            color: const Color(0xFF1F2C47),
                            minHeight: 12,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // List
                  Expanded(
                    child: filtered.isEmpty
                        ? const Center(
                            child: Text(
                              "No utilities found",
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final e = filtered[index];
                              return _breakdownCard(
                                icon: _iconFor(e.category),
                                title: e.category,
                                status: e.statusLabel,
                                deadline: e.neededBy != null
                                    ? _dateFmt.format(e.neededBy!)
                                    : 'No deadline',
                                total: e.amount,
                                raised: e.raised,
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _breakdownCard({
    required IconData icon,
    required String title,
    required String status,
    required String deadline,
    required double total,
    required double raised,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, size: 28, color: const Color(0xFF1F2C47)),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        status,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Text(
                "Needed by $deadline",
                style: const TextStyle(fontSize: 12, color: Color(0xFF1F2C47)),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Text(
            "Est. Php ${total.toStringAsFixed(0)} needed",
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 6),
          Text(
            "Php ${raised.toStringAsFixed(0)} of Php ${total.toStringAsFixed(0)}",
            style: const TextStyle(fontSize: 12, color: Color(0xFF1F2C47)),
          ),
        ],
      ),
    );
  }
}
