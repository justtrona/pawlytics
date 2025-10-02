// lib/views/donors/goals/goal_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pawlytics/views/donors/controller/goal-opex-controller.dart';
import 'package:pawlytics/views/donors/model/goal-opex-model.dart';
import 'package:pawlytics/views/donors/HomeScreenButtons/DonatePage.dart';

class GoalPage extends StatefulWidget {
  const GoalPage({super.key});

  @override
  State<GoalPage> createState() => _GoalPageState();
}

class _GoalPageState extends State<GoalPage> {
  final _controller = OpexAllocationsController();
  final _searchController = TextEditingController();
  final _php = NumberFormat.currency(
    locale: 'en_PH',
    symbol: '₱',
    decimalDigits: 0,
  );

  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChange);
    _controller.loadAllocations(); // loads items for the current month
  }

  void _onChange() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onChange);
    _controller.dispose();
    _searchController.dispose();
    super.dispose();
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

  String _percent(double value) =>
      '${(value * 100).clamp(0, 100).toStringAsFixed(0)}%';

  @override
  Widget build(BuildContext context) {
    // Filtered list for the allocations section only
    final filtered = _controller.items
        .where(
          (e) => e.category.toLowerCase().contains(_searchQuery.toLowerCase()),
        )
        .toList();

    // ✅ Header totals must NOT use the filtered list.
    // Use all items so the header always shows the full month status.
    final allItems = _controller.items;
    final headerGoal = allItems.fold<double>(0, (s, e) => s + e.amount);
    final headerRaised = allItems.fold<double>(0, (s, e) => s + e.raised);
    final headerProg = headerGoal > 0
        ? (headerRaised / headerGoal).clamp(0.0, 1.0)
        : 0.0;

    const brand = Color(0xFF1F2C47);
    const peach = Color(0xFFEC8C69);
    final cardBorder = BorderSide(color: Colors.grey.shade300);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
        centerTitle: true,
        title: const Text(
          'Goals',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _controller.loadAllocations,
          ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: _controller.loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: () async => _controller.loadAllocations(),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                  children: [
                    // Search
                    _SearchBar(
                      controller: _searchController,
                      onChanged: (v) => setState(() => _searchQuery = v),
                    ),
                    const SizedBox(height: 16),

                    // Summary Card — now decoupled from search
                    _SummaryCard(
                      brand: brand,
                      peach: peach,
                      border: cardBorder,
                      title: "This Month’s Goal",
                      raisedLabel: _php.format(headerRaised),
                      goalLabel: _php.format(headerGoal),
                      progress: headerProg,
                      percentText: _percent(headerProg),
                    ),
                    const SizedBox(height: 16),

                    if (filtered.isEmpty)
                      _EmptyState(
                        onClear: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    else
                      ...List.generate(filtered.length, (i) {
                        final e = filtered[i];
                        final progress = e.amount > 0
                            ? (e.raised / e.amount).clamp(0.0, 1.0)
                            : 0.0;
                        final remaining = (e.amount - e.raised).clamp(
                          0,
                          double.infinity,
                        );

                        return _GoalCard(
                          icon: _iconFor(e.category),
                          title: e.category,
                          subtitle: e.statusLabel,
                          trailingLabel: _percent(progress),
                          progress: progress,
                          amountNeededLabel:
                              '${_php.format(e.raised)} of ${_php.format(e.amount)}',
                          remainingLabel: remaining <= 0
                              ? 'Fully funded'
                              : 'Remaining: ${_php.format(remaining)}',
                          border: cardBorder,
                          brand: brand,
                        );
                      }),
                  ],
                ),
              ),
      ),

      // Donate FAB — still targets most underfunded allocation
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _controller.items.isEmpty
          ? null
          : SafeArea(
              minimum: const EdgeInsets.all(16),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF0F2D50), Color(0xFFEC8C69)],
                  ),
                  borderRadius: BorderRadius.circular(36),
                  boxShadow: const [
                    BoxShadow(
                      blurRadius: 14,
                      offset: Offset(0, 8),
                      color: Colors.black26,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(36),
                  child: FloatingActionButton.extended(
                    heroTag: 'donateFab',
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    icon: const Icon(Icons.volunteer_activism_rounded),
                    label: const Text(
                      'Donate Now',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    tooltip: 'Support the animals',
                    onPressed: () async {
                      HapticFeedback.lightImpact();
                      final target = _controller.items.reduce((a, b) {
                        final aRem = (a.amount - a.raised).clamp(
                          0,
                          double.infinity,
                        );
                        final bRem = (b.amount - b.raised).clamp(
                          0,
                          double.infinity,
                        );
                        return aRem >= bRem ? a : b;
                      });
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DonatePage(
                            opexId: target.id,
                            campaignTitle: 'General Fund',
                          ),
                        ),
                      );
                      await _controller.loadAllocations();
                    },
                  ),
                ),
              ),
            ),
    );
  }
}

/* ---------- UI Pieces ---------- */

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Search utility needs',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                tooltip: 'Clear',
                icon: const Icon(Icons.close_rounded),
                onPressed: () {
                  controller.clear();
                  onChanged('');
                },
              ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
      onChanged: onChanged,
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.brand,
    required this.peach,
    required this.border,
    required this.title,
    required this.raisedLabel,
    required this.goalLabel,
    required this.progress,
    required this.percentText,
  });

  final Color brand;
  final Color peach;
  final BorderSide border;
  final String title;
  final String raisedLabel;
  final String goalLabel;
  final double progress;
  final String percentText;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.fromBorderSide(border),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: brand,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          raisedLabel,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'raised',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'of $goalLabel',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: peach.withOpacity(.12),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: peach.withOpacity(.35)),
                ),
                child: Text(
                  percentText,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: peach.darken(0.12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 12,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation(brand),
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailingLabel,
    required this.progress,
    required this.amountNeededLabel,
    required this.remainingLabel,
    required this.border,
    required this.brand,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String trailingLabel;
  final double progress;
  final String amountNeededLabel;
  final String remainingLabel;
  final BorderSide border;
  final Color brand;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.fromBorderSide(border),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: brand.withOpacity(.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: brand, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  trailingLabel,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation(brand),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.payments_outlined,
                size: 16,
                color: Colors.black54,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  amountNeededLabel,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                remainingLabel == 'Fully funded'
                    ? Icons.verified_rounded
                    : Icons.timelapse_rounded,
                size: 16,
                color: remainingLabel == 'Fully funded'
                    ? Colors.green
                    : Colors.black54,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  remainingLabel,
                  style: TextStyle(
                    fontSize: 12,
                    color: remainingLabel == 'Fully funded'
                        ? Colors.green
                        : Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onClear});
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          const Icon(Icons.inbox_outlined, size: 56, color: Colors.black26),
          const SizedBox(height: 10),
          const Text(
            'No utilities found',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          const Text(
            'Try a different keyword or clear your search.',
            style: TextStyle(color: Colors.black54, fontSize: 12),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onClear,
            icon: const Icon(Icons.close_rounded),
            label: const Text('Clear search'),
          ),
        ],
      ),
    );
  }
}

/* ---------- Small color helper ---------- */
extension ColorShade on Color {
  Color darken([double amount = .1]) {
    assert(amount >= 0 && amount <= 1);
    final f = 1 - amount;
    return Color.fromARGB(
      alpha,
      (red * f).round(),
      (green * f).round(),
      (blue * f).round(),
    );
  }

  Color lighten([double amount = .1]) {
    assert(amount >= 0 && amount <= 1);
    return Color.fromARGB(
      alpha,
      (red + (255 - red) * amount).round(),
      (green + (255 - green) * amount).round(),
      (blue + (255 - blue) * amount).round(),
    );
  }
}
