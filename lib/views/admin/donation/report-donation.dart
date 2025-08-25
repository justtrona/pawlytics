import 'package:flutter/material.dart';

class DonationReports extends StatefulWidget {
  const DonationReports({super.key});

  @override
  State<DonationReports> createState() => _DonationReportsState();
}

class _DonationReportsState extends State<DonationReports> {
  // Theme
  static const brand = Color(0xFF27374D);
  static const softGrey = Color(0xFFE9EEF3);
  static const textMuted = Color(0xFF6A7886);

  // Filters
  String _period = 'This Month';
  String _donor = 'All Donors';

  // Sample data to populate the table
  final _rows = <_DonationRow>[
    _DonationRow(
      date: DateTime(2025, 6, 1),
      campaign: 'Emergency Surgery for Peter',
      donor: 'Francis M.',
      amount: 200.00,
      recurring: false,
    ),
    _DonationRow(
      date: DateTime(2025, 6, 11),
      campaign: 'Shelter Renovation',
      donor: 'John D.',
      amount: 500.00,
      recurring: false,
    ),
    _DonationRow(
      date: DateTime(2025, 6, 18),
      campaign: 'Emergency Surgery for Peter',
      donor: 'Mary M.',
      amount: 1200.00,
      recurring: true,
    ),
    _DonationRow(
      date: DateTime(2025, 6, 21),
      campaign: 'Medical Treatment for Peter',
      donor: 'Martin P.',
      amount: 800.00,
      recurring: false,
    ),
    // Sample donation added for your visual example
    _DonationRow(
      date: DateTime(2025, 6, 29),
      campaign: 'Medical Funds',
      donor: 'Max T.',
      amount: 1500.00,
      recurring: false,
    ),
    _DonationRow(
      date: DateTime(2025, 6, 25),
      campaign: 'Animal Care Fund',
      donor: 'Jenna S.',
      amount: 400.00,
      recurring: true,
    ),
  ];

  // Helpers
  String _money(num v, {bool withCents = true}) {
    final s = withCents ? v.toStringAsFixed(2) : v.toStringAsFixed(0);
    final parts = s.split('.');
    final re = RegExp(r'\B(?=(\d{3})+(?!\d))');
    final main = parts[0].replaceAllMapped(re, (m) => ',');
    return parts.length == 2 ? 'PHP $main.${parts[1]}' : 'PHP $main';
  }

  String _dateCell(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.month)}/${two(d.day)}\n${d.year}';
  }

  DateTime? _periodStart() {
    final now = DateTime.now();
    switch (_period) {
      case 'This Month':
        return DateTime(now.year, now.month, 1);
      case 'Last Month':
        final last = DateTime(now.year, now.month - 1, 1);
        return DateTime(last.year, last.month, 1);
      case 'This Year':
        return DateTime(now.year, 1, 1);
      case 'All Time':
      default:
        return null;
    }
  }

  DateTime? _periodEnd() {
    final now = DateTime.now();
    switch (_period) {
      case 'Last Month':
        final firstThisMonth = DateTime(now.year, now.month, 1);
        return firstThisMonth.subtract(const Duration(days: 1));
      default:
        return null; // open-ended
    }
  }

  List<_DonationRow> get _filtered {
    final start = _periodStart();
    final end = _periodEnd();
    return _rows.where((r) {
      if (_donor != 'All Donors' && r.donor != _donor) return false;
      if (start != null && r.date.isBefore(start)) return false;
      if (end != null && r.date.isAfter(end)) return false;
      return true;
    }).toList()..sort((a, b) => a.date.compareTo(b.date));
  }

  int get _totalDonations => _filtered.length;
  double get _totalAmount =>
      _filtered.fold<double>(0.0, (sum, r) => sum + r.amount);
  int get _oneTimeCount => _filtered.where((r) => !r.recurring).length;
  int get _recurringCount => _filtered.where((r) => r.recurring).length;

  List<String> get _donorOptions => [
    'All Donors',
    ...{for (final r in _rows) r.donor},
  ];

  @override
  Widget build(BuildContext context) {
    final rows = _filtered;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Donation Reports'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            // Stats cards
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: 'Total Donations',
                    value: _totalDonations.toString(),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StatCard(
                    title: 'Total Amount',
                    value: _money(_totalAmount),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: 'One-Time Donations',
                    value: _oneTimeCount.toString(),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StatCard(
                    title: 'Recurring Donations',
                    value: _recurringCount.toString(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Period + Filter
            Row(
              children: [
                Expanded(
                  child: _FilterDropdown(
                    label: _period,
                    items: const [
                      'This Month',
                      'Last Month',
                      'This Year',
                      'All Time',
                    ],
                    onChanged: (v) => setState(() => _period = v),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  height: 40,
                  child: ElevatedButton(
                    onPressed: () => setState(() {}),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: brand,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Filter'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Donor filter
            _FilterDropdown(
              label: _donor,
              items: _donorOptions,
              onChanged: (v) => setState(() => _donor = v),
            ),
            const SizedBox(height: 14),

            // >>> SINGLE ROUNDED TABLE CARD (like your screenshot)
            _TableCard(rows: rows),
          ],
        ),
      ),
    );
  }
}

// ===== Models =====
class _DonationRow {
  final DateTime date;
  final String campaign;
  final String donor;
  final double amount;
  final bool recurring;

  _DonationRow({
    required this.date,
    required this.campaign,
    required this.donor,
    required this.amount,
    required this.recurring,
  });
}

// ===== UI Bits =====

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  const _StatCard({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 74,
      decoration: BoxDecoration(
        color: _DonationReportsState.softGrey,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _DonationReportsState.textMuted,
              fontWeight: FontWeight.w700,
              height: 1.1,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              color: _DonationReportsState.brand,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  final String label;
  final List<String> items;
  final ValueChanged<String> onChanged;

  const _FilterDropdown({
    required this.label,
    required this.items,
    required this.onChanged,
  });

  OutlineInputBorder _border(Color c) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(color: c),
  );

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: label,
      isExpanded: true,
      items: items
          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
          .toList(),
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
      decoration: InputDecoration(
        filled: true,
        fillColor: _DonationReportsState.softGrey,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        enabledBorder: _border(_DonationReportsState.softGrey),
        focusedBorder: _border(_DonationReportsState.brand),
      ),
      borderRadius: BorderRadius.circular(12),
      icon: const Icon(
        Icons.expand_more_rounded,
        color: _DonationReportsState.brand,
      ),
      style: const TextStyle(
        color: _DonationReportsState.brand,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

// ===== New: Single card table =====
class _TableCard extends StatelessWidget {
  final List<_DonationRow> rows;
  const _TableCard({required this.rows});

  @override
  Widget build(BuildContext context) {
    final borderColor = Colors.blueGrey.shade200;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
      ),
      clipBehavior: Clip.antiAlias, // clip header rounded corners
      child: Column(
        children: [
          // Header inside same card
          Container(
            height: 44,
            color: _DonationReportsState.brand,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: const [
                _HeadCell('Date', flex: 12),
                _HeadCell('Campaign', flex: 26),
                _HeadCell('Donor', flex: 18),
                _HeadCell('Amount', flex: 16, alignEnd: true),
              ],
            ),
          ),

          // Rows
          if (rows.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              child: const Text(
                'No donations found for the selected filters.',
                style: TextStyle(
                  color: _DonationReportsState.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else
            for (int i = 0; i < rows.length; i++)
              Container(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                decoration: BoxDecoration(
                  color: i % 2 == 0
                      ? Colors.white
                      : Colors.grey.shade50, // alternate row colors
                  border: Border(
                    bottom: BorderSide(
                      color: i == rows.length - 1
                          ? Colors.transparent
                          : borderColor,
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date
                    Expanded(
                      flex: 12,
                      child: Text(
                        _dateCell(rows[i].date),
                        style: const TextStyle(
                          color: _DonationReportsState.brand,
                          fontWeight: FontWeight.w800,
                          height: 1.1,
                        ),
                      ),
                    ),
                    // Campaign
                    Expanded(
                      flex: 26,
                      child: Text(
                        rows[i].campaign,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.w600,
                          height: 1.1,
                        ),
                      ),
                    ),
                    // Donor
                    Expanded(
                      flex: 18,
                      child: Text(
                        rows[i].donor,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _DonationReportsState.textMuted,
                          fontWeight: FontWeight.w700,
                          height: 1.1,
                        ),
                      ),
                    ),
                    // Amount (muted color like the mock)
                    Expanded(
                      flex: 16,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          _money(rows[i].amount),
                          style: const TextStyle(
                            color: _DonationReportsState.textMuted,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }

  // reuse same date/money helpers locally (kept simple)
  String _money(num v) {
    final s = v.toStringAsFixed(2);
    final parts = s.split('.');
    final re = RegExp(r'\B(?=(\d{3})+(?!\d))');
    final main = parts[0].replaceAllMapped(re, (m) => ',');
    return 'PHP $main.${parts[1]}';
  }

  String _dateCell(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.month)}/${two(d.day)}\n${d.year}';
  }
}

class _HeadCell extends StatelessWidget {
  final String text;
  final int flex;
  final bool alignEnd;
  const _HeadCell(this.text, {this.flex = 1, this.alignEnd = false});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Align(
        alignment: alignEnd ? Alignment.centerRight : Alignment.centerLeft,
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
