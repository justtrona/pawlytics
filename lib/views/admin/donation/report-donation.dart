import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  // Data
  final _client = Supabase.instance.client;
  bool _loading = true;
  String? _error;
  List<_DonationRow> _all = [];

  @override
  void initState() {
    super.initState();
    _loadDonations();
  }

  /* ====================== DATA LOAD ====================== */

  // try common human-readable fields
  String? _labelFrom(Map rel) {
    final candidates = ['title', 'name', 'program'];
    for (final k in candidates) {
      final v = rel[k];
      if (v is String && v.trim().isNotEmpty) return v;
    }
    return null;
  }

  // first non-null map among possible relation aliases
  Map<String, dynamic>? _firstRelMap(
    Map<String, dynamic> row,
    List<String> keys,
  ) {
    for (final k in keys) {
      final v = row[k];
      if (v is Map<String, dynamic>) return v;
    }
    return null;
  }

  Future<void> _loadDonations() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    // Prefer a readable label from any related row
    String? _labelFrom(Map rel) {
      for (final k in const ['title', 'name', 'program', 'purpose']) {
        final v = rel[k];
        if (v is String && v.trim().isNotEmpty) return v;
      }
      return null;
    }

    Map<String, dynamic>? _firstRelMap(
      Map<String, dynamic> row,
      List<String> keys,
    ) {
      for (final k in keys) {
        final v = row[k];
        if (v is Map<String, dynamic>) return v;
      }
      return null;
    }

    try {
      // ✅ alias FIRST, then table, then !fk_name
      final data = await _client
          .from('donations')
          .select('''
          id,
          donor_name,
          donor_phone,
          donation_date,
          donation_type,
          payment_method,
          amount,
          item,
          campaign_id,
          pet_id,
          manual_id,
          allocation_id,
          opex_id,
          opex_allocation_id,
          is_operational,

          campaign_rel:campaigns!donations_campaign_fk (*),
          pet_rel:pet_profiles!donations_pet_id_fkey (*),

          alloc_rel:operational_expense_allocations!donations_allocation_fk (*),
          opex_rel:operational_expense_allocations!donations_opex_id_fkey (*),
          alloc2_rel:operational_expense_allocations!donations_opex_allocation_fk (*),

          manual_rel:manual_donations!donations_manual_id_fkey (*)
        ''')
          .order('donation_date', ascending: true);

      final rows = <_DonationRow>[];

      for (final raw in (data as List)) {
        final m = Map<String, dynamic>.from(raw);

        final dateRaw = m['donation_date'];
        final dt = dateRaw is String
            ? DateTime.tryParse(dateRaw)
            : (dateRaw is DateTime ? dateRaw : null);

        String source = 'Uncategorized';
        String details = '—';

        if (m['campaign_id'] != null) {
          source = 'Campaign';
          final rel = _firstRelMap(m, ['campaign_rel']);
          details = rel != null ? (_labelFrom(rel) ?? 'Campaign') : 'Campaign';
        } else if (m['pet_id'] != null) {
          source = 'Pet';
          final rel = _firstRelMap(m, ['pet_rel']);
          details = rel != null ? (_labelFrom(rel) ?? 'Pet') : 'Pet';
        } else if (m['manual_id'] != null) {
          source = 'Manual';
          final rel = _firstRelMap(m, ['manual_rel']);
          details = rel != null
              ? (_labelFrom(rel) ?? 'Manual Entry')
              : 'Manual Entry';
        } else if (m['allocation_id'] != null ||
            m['opex_id'] != null ||
            m['opex_allocation_id'] != null ||
            (m['is_operational'] == true)) {
          source = 'Opex';
          final rel = _firstRelMap(m, ['alloc_rel', 'opex_rel', 'alloc2_rel']);
          details = rel != null
              ? (_labelFrom(rel) ?? 'Operating Expense')
              : 'Operating Expense';
        }

        rows.add(
          _DonationRow(
            id: (m['id'] as num).toInt(),
            date: dt ?? DateTime.now(),
            donor: (m['donor_name'] as String?)?.trim().isNotEmpty == true
                ? m['donor_name'] as String
                : 'Anonymous',
            donorPhone: (m['donor_phone'] as String?) ?? '',
            type: (m['donation_type'] as String?) ?? 'Unknown',
            payment: (m['payment_method'] as String?) ?? 'N/A',
            amount: (m['amount'] as num?)?.toDouble() ?? 0.0,
            item: (m['item'] as String?) ?? '',
            source: source,
            details: details,
          ),
        );
      }

      if (!mounted) return;
      setState(() {
        _all = rows;
        _loading = false;
      });
    } on PostgrestException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  /* ====================== HELPERS / FILTERS ====================== */

  String _money(num v, {bool withCents = true}) {
    final s = withCents ? v.toStringAsFixed(2) : v.toStringAsFixed(0);
    final parts = s.split('.');
    final re = RegExp(r'\B(?=(\d{3})+(?!\d))');
    final main = parts[0].replaceAllMapped(re, (m) => ',');
    return parts.length == 2 ? 'PHP $main.${parts[1]}' : 'PHP $main';
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
        return firstThisMonth.subtract(const Duration(seconds: 1));
      default:
        return null;
    }
  }

  List<_DonationRow> get _filtered {
    final start = _periodStart();
    final end = _periodEnd();
    return _all.where((r) {
      if (_donor != 'All Donors' && r.donor != _donor) return false;
      if (start != null && r.date.isBefore(start)) return false;
      if (end != null && r.date.isAfter(end)) return false;
      return true;
    }).toList()..sort((a, b) => a.date.compareTo(b.date));
  }

  int get _totalDonations => _filtered.length;
  double get _totalAmount =>
      _filtered.fold<double>(0.0, (sum, r) => sum + r.amount);

  int get _cashCount =>
      _filtered.where((r) => r.type.toLowerCase() == 'cash').length;
  int get _inKindCount =>
      _filtered.where((r) => r.type.toLowerCase() != 'cash').length;

  List<String> get _donorOptions {
    final donors = <String>{};
    for (final r in _all) {
      if (r.donor.trim().isEmpty) continue;
      donors.add(r.donor);
    }
    final list = ['All Donors', ...donors.toList()..sort()];
    if (!list.contains(_donor)) return ['All Donors'];
    return list;
  }

  String _dateCell(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.month)}/${two(d.day)}\n${d.year}';
  }

  /* ====================== UI ====================== */

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
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loadDonations,
            icon: const Icon(Icons.refresh_rounded, color: brand),
          ),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? _ErrorBox(message: _error!, onRetry: _loadDonations)
            : RefreshIndicator(
                onRefresh: _loadDonations,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  children: [
                    // Stats
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
                            title: 'Cash',
                            value: _cashCount.toString(),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _StatCard(
                            title: 'In-Kind',
                            value: _inKindCount.toString(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Period & Filter button
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

                    // Donor filter (populated from data)
                    _FilterDropdown(
                      label: _donorOptions.contains(_donor)
                          ? _donor
                          : 'All Donors',
                      items: _donorOptions,
                      onChanged: (v) => setState(() => _donor = v),
                    ),
                    const SizedBox(height: 14),

                    // Table
                    _TableCard(rows: rows),
                  ],
                ),
              ),
      ),
    );
  }
}

/* ====================== MODELS ====================== */

class _DonationRow {
  final int id;
  final DateTime date;
  final String donor;
  final String donorPhone;
  final String type; // Cash / In Kind / etc
  final String payment; // GCash / Bank / Cash / QR / N/A
  final double amount;
  final String item; // for in-kind
  final String source; // Campaign / Pet / Opex / Manual / Uncategorized
  final String details; // label from related table or fallback

  _DonationRow({
    required this.id,
    required this.date,
    required this.donor,
    required this.donorPhone,
    required this.type,
    required this.payment,
    required this.amount,
    required this.item,
    required this.source,
    required this.details,
  });
}

/* ====================== REUSABLE UI ====================== */

class _ErrorBox extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorBox({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.withOpacity(.2)),
        ),
        child: Column(
          children: [
            const Icon(Icons.error_outline, color: Colors.red),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

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

// Single card “table”
class _TableCard extends StatelessWidget {
  final List<_DonationRow> rows;
  const _TableCard({required this.rows});

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

  @override
  Widget build(BuildContext context) {
    final borderColor = Colors.blueGrey.shade200;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Header
          Container(
            height: 44,
            color: _DonationReportsState.brand,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: const [
                _HeadCell('Date', flex: 11),
                _HeadCell('Donor', flex: 18),
                _HeadCell('Source', flex: 12),
                _HeadCell('Details', flex: 22),
                _HeadCell('Type', flex: 10),
                _HeadCell('Payment', flex: 12),
                _HeadCell('Amount', flex: 15, alignEnd: true),
              ],
            ),
          ),

          // Body
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
                  color: i % 2 == 0 ? Colors.white : Colors.grey.shade50,
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
                      flex: 11,
                      child: Text(
                        _dateCell(rows[i].date),
                        style: const TextStyle(
                          color: _DonationReportsState.brand,
                          fontWeight: FontWeight.w800,
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
                          color: Colors.black87,
                          fontWeight: FontWeight.w700,
                          height: 1.1,
                        ),
                      ),
                    ),
                    // Source
                    Expanded(
                      flex: 12,
                      child: Text(
                        rows[i].source,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _DonationReportsState.textMuted,
                          fontWeight: FontWeight.w700,
                          height: 1.1,
                        ),
                      ),
                    ),
                    // Details
                    Expanded(
                      flex: 22,
                      child: Text(
                        rows[i].details,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.w600,
                          height: 1.1,
                        ),
                      ),
                    ),
                    // Type
                    Expanded(
                      flex: 10,
                      child: Text(
                        rows[i].type,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _DonationReportsState.textMuted,
                          fontWeight: FontWeight.w700,
                          height: 1.1,
                        ),
                      ),
                    ),
                    // Payment
                    Expanded(
                      flex: 12,
                      child: Text(
                        rows[i].payment,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _DonationReportsState.textMuted,
                          fontWeight: FontWeight.w700,
                          height: 1.1,
                        ),
                      ),
                    ),
                    // Amount
                    Expanded(
                      flex: 15,
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
