import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DonationReports extends StatefulWidget {
  const DonationReports({super.key});

  @override
  State<DonationReports> createState() => _DonationReportsState();
}

class _DonationReportsState extends State<DonationReports> {
  // Theme
  static const brand = Color(0xFF27374D);
  static const softGrey = Color(0xFFF4F7FA);
  static const line = Color(0xFFE6EDF4);
  static const textMuted = Color(0xFF6A7886);
  static const danger = Color(0xFFCC3D3D);
  static const success = Color(0xFF2E7D32);
  static const warning = Color(0xFFB26A00);

  final _client = Supabase.instance.client;

  // Filters
  String _period = 'This Month';
  String _payment = 'All Payments';
  String _type = 'All Types';
  String _donor = 'All Donors';
  String _status = 'All Statuses';
  String _query = '';
  DateTime? _from;
  DateTime? _to;

  // Paging + cache
  final _pageSize = 100;
  int _page = 0;
  bool _hasMore = true;
  bool _fetching = false;
  String? _error;

  final List<_DonationRow> _allRows = [];
  final Set<String> _donorSet = {};
  final Set<String> _statusSet = {'Paid', 'Pending', 'For Pickup', 'Received'};

  // Helpers
  String _money(num v) {
    final s = v.toStringAsFixed(2);
    final p = s.split('.');
    final main = p[0].replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (m) => ',',
    );
    return 'PHP $main.${p[1]}';
  }

  String _dateShort(DateTime d) => DateFormat('MM/dd').format(d);
  String _dateFull(DateTime d) => DateFormat('MM/dd/yyyy').format(d);
  DateTime _endOfDay(DateTime d) =>
      DateTime(d.year, d.month, d.day, 23, 59, 59, 999);

  void _computePeriodRange() {
    final now = DateTime.now();
    switch (_period) {
      case 'This Month':
        _from = DateTime(now.year, now.month, 1);
        _to = _endOfDay(DateTime(now.year, now.month + 1, 0));
        break;
      case 'Last Month':
        final firstThisMonth = DateTime(now.year, now.month, 1);
        final lastLastMonth = firstThisMonth.subtract(const Duration(days: 1));
        _from = DateTime(lastLastMonth.year, lastLastMonth.month, 1);
        _to = _endOfDay(lastLastMonth);
        break;
      case 'This Year':
        _from = DateTime(now.year, 1, 1);
        _to = _endOfDay(DateTime(now.year, 12, 31));
        break;
      case 'All Time':
        _from = null;
        _to = null;
        break;
      case 'Custom':
        break;
    }
  }

  @override
  void initState() {
    super.initState();
    _computePeriodRange();
    _load(reset: true);
  }

  Future<void> _pickFrom() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _from ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (d != null) setState(() => _from = d);
  }

  Future<void> _pickTo() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _to ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (d != null) setState(() => _to = d);
  }

  Future<void> _refresh() => _load(reset: true);

  String _mapInkindStatus(dynamic s) {
    final v = (s ?? 'pending').toString().toLowerCase();
    if (v == 'received') return 'Received';
    if (v == 'for_pickup' || v == 'forpickup') return 'For Pickup';
    return 'Pending';
  }

  Future<void> _load({required bool reset}) async {
    if (_fetching) return;
    setState(() {
      _fetching = true;
      _error = null;
      if (reset) {
        _page = 0;
        _hasMore = true;
        _allRows.clear();
        _donorSet.clear();
      }
    });

    if (_period != 'Custom') _computePeriodRange();

    try {
      // IMPORTANT: No "status" here; we derive it from donation_type/inkind_status
      const cols = '''
        id, donor_name, donor_phone, donation_date, donation_type, inkind_status,
        payment_method, amount, item,
        campaign_id, pet_id, manual_id,
        allocation_id, opex_id, opex_allocation_id, is_operational
      ''';

      final from = _page * _pageSize;
      final to = from + _pageSize - 1;

      final data =
          await _client
                  .from('donations')
                  .select(cols)
                  .order('donation_date', ascending: false)
                  .range(from, to)
              as List<dynamic>;

      final page = <_DonationRow>[];
      for (final raw in data) {
        final m = Map<String, dynamic>.from(raw as Map);

        final dateRaw = m['donation_date'];
        final dt = dateRaw is String
            ? (DateTime.tryParse(dateRaw) ?? DateTime.now())
            : (dateRaw is DateTime ? dateRaw : DateTime.now());

        final donor = (m['donor_name'] as String?)?.trim().isNotEmpty == true
            ? m['donor_name'] as String
            : 'Anonymous';

        String source = 'Uncategorized';
        if (m['campaign_id'] != null) {
          source = 'Campaign';
        } else if (m['pet_id'] != null) {
          source = 'Pet';
        } else if (m['manual_id'] != null) {
          source = 'Manual';
        } else if (m['allocation_id'] != null ||
            m['opex_id'] != null ||
            m['opex_allocation_id'] != null ||
            (m['is_operational'] == true)) {
          source = 'Opex';
        }

        final type = (m['donation_type'] as String?) ?? 'Unknown';
        final payment = (m['payment_method'] as String?) ?? 'N/A';

        // Derive status
        final status = type.toLowerCase() == 'cash'
            ? 'Paid'
            : _mapInkindStatus(m['inkind_status']);

        _statusSet.add(status);

        page.add(
          _DonationRow(
            id: (m['id'] as num).toInt(),
            date: dt,
            donor: donor,
            donorPhone: (m['donor_phone'] as String?) ?? '',
            type: type,
            payment: payment,
            amount: (m['amount'] as num?)?.toDouble() ?? 0.0,
            item: (m['item'] as String?) ?? '',
            source: source,
            status: status,
          ),
        );

        if (donor.trim().isNotEmpty) _donorSet.add(donor);
      }

      setState(() {
        _allRows.addAll(page);
        _hasMore = data.length == _pageSize;
        if (_hasMore) _page += 1;
      });
    } on PostgrestException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _fetching = false);
    }
  }

  // In-memory filter + search
  List<_DonationRow> get _filtered {
    final start = _from;
    final end = _to == null ? null : _endOfDay(_to!);
    final q = _query.trim().toLowerCase();

    return _allRows.where((r) {
      if (start != null && r.date.isBefore(start)) return false;
      if (end != null && r.date.isAfter(end)) return false;

      if (_payment != 'All Payments' &&
          r.payment.toLowerCase() != _payment.toLowerCase()) {
        return false;
      }

      if (_type == 'Cash' && r.type.toLowerCase() != 'cash') return false;
      if (_type == 'In-Kind' && r.type.toLowerCase() == 'cash') return false;

      if (_donor != 'All Donors' && r.donor != _donor) return false;

      if (_status != 'All Statuses' &&
          r.status.toLowerCase() != _status.toLowerCase())
        return false;

      if (q.isNotEmpty) {
        final hay = '${r.donor} ${r.item} ${r.source} ${r.payment} ${r.status}'
            .toLowerCase();
        if (!hay.contains(q)) return false;
      }
      return true;
    }).toList();
  }

  int get _totalDonations => _filtered.length;
  double get _totalAmount => _filtered.fold(0.0, (s, r) => s + r.amount);
  int get _cashCount =>
      _filtered.where((r) => r.type.toLowerCase() == 'cash').length;
  int get _inKindCount =>
      _filtered.where((r) => r.type.toLowerCase() != 'cash').length;

  int get _forPickupCount =>
      _filtered.where((r) => r.status.toLowerCase() == 'for pickup').length;
  int get _receivedCount =>
      _filtered.where((r) => r.status.toLowerCase() == 'received').length;

  List<String> get _donorOptions => [
    'All Donors',
    ..._donorSet.toList()..sort(),
  ];
  List<String> get _statusOptions {
    final opts = <String>{'All Statuses', ..._statusSet};
    final common = [
      'All Statuses',
      'Paid',
      'Pending',
      'For Pickup',
      'Received',
    ];
    final rest = opts.where((e) => !common.contains(e)).toList()..sort();
    return [...common.where(opts.contains), ...rest];
  }

  OutlineInputBorder _border(Color c) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(color: c),
  );

  String _rangeLabel() {
    if (_from == null && _to == null) return 'All Time';
    final f = _from != null ? _dateFull(_from!) : '…';
    final t = _to != null ? _dateFull(_to!) : '…';
    return '$f → $t';
  }

  // ---------- EXPORTS ----------
  Future<void> _exportFilteredCsv() async {
    await _exportCsvFromRows(_filtered, 'donation_report_filtered');
  }

  Future<void> _exportAllCsv() async {
    try {
      const cols = '''
        id, donor_name, donor_phone, donation_date, donation_type, inkind_status,
        payment_method, amount, item,
        campaign_id, pet_id, manual_id,
        allocation_id, opex_id, opex_allocation_id, is_operational
      ''';

      final all = <_DonationRow>[];
      int page = 0;
      while (true) {
        final from = page * 1000;
        final to = from + 999;
        final data =
            await _client
                    .from('donations')
                    .select(cols)
                    .order('donation_date', ascending: false)
                    .range(from, to)
                as List<dynamic>;
        if (data.isEmpty) break;

        for (final raw in data) {
          final m = Map<String, dynamic>.from(raw as Map);
          final dateRaw = m['donation_date'];
          final dt = dateRaw is String
              ? (DateTime.tryParse(dateRaw) ?? DateTime.now())
              : (dateRaw is DateTime ? dateRaw : DateTime.now());
          final donor = (m['donor_name'] as String?)?.trim().isNotEmpty == true
              ? m['donor_name'] as String
              : 'Anonymous';

          String source = 'Uncategorized';
          if (m['campaign_id'] != null) {
            source = 'Campaign';
          } else if (m['pet_id'] != null) {
            source = 'Pet';
          } else if (m['manual_id'] != null) {
            source = 'Manual';
          } else if (m['allocation_id'] != null ||
              m['opex_id'] != null ||
              m['opex_allocation_id'] != null ||
              (m['is_operational'] == true)) {
            source = 'Opex';
          }

          final type = (m['donation_type'] as String?) ?? 'Unknown';
          final payment = (m['payment_method'] as String?) ?? 'N/A';
          final status = type.toLowerCase() == 'cash'
              ? 'Paid'
              : _mapInkindStatus(m['inkind_status']);

          all.add(
            _DonationRow(
              id: (m['id'] as num).toInt(),
              date: dt,
              donor: donor,
              donorPhone: (m['donor_phone'] as String?) ?? '',
              type: type,
              payment: payment,
              amount: (m['amount'] as num?)?.toDouble() ?? 0.0,
              item: (m['item'] as String?) ?? '',
              source: source,
              status: status,
            ),
          );
        }

        if (data.length < 1000) break;
        page++;
      }

      await _exportCsvFromRows(all, 'donation_report_all');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Export failed: $e')));
    }
  }

  Future<void> _exportCsvFromRows(
    List<_DonationRow> rows,
    String baseName,
  ) async {
    if (rows.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No rows to export.')));
      return;
    }

    String esc(String s) => '"${s.replaceAll('"', '""')}"';

    final b = StringBuffer()
      ..writeln(
        [
          'ID',
          'Date',
          'Donor',
          'Source',
          'Type',
          'Payment',
          'Amount',
          'Status',
          'Phone',
          'Item',
        ].join(','),
      );

    for (final r in rows) {
      b.writeln(
        [
          r.id.toString(),
          _dateFull(r.date),
          esc(r.donor),
          esc(r.source),
          esc(r.type),
          esc(r.payment),
          r.amount.toStringAsFixed(2),
          esc(r.status),
          esc(r.donorPhone),
          esc(r.item),
        ].join(','),
      );
    }

    final dir = await getTemporaryDirectory();
    final fp =
        '${dir.path}/${baseName}_${DateTime.now().millisecondsSinceEpoch}.csv';
    final file = File(fp);
    await file.writeAsString(b.toString());
    if (!mounted) return;
    await Share.shareXFiles([XFile(file.path)], text: 'Donation report');
  }

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    final rows = _filtered;
    final loadingFirst = _fetching && _allRows.isEmpty;

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
            tooltip: 'Export Filtered CSV',
            onPressed: _exportFilteredCsv,
            icon: const Icon(Icons.file_download_outlined, color: brand),
          ),
          IconButton(
            tooltip: 'Export ALL CSV',
            onPressed: _exportAllCsv,
            icon: const Icon(Icons.cloud_download_outlined, color: brand),
          ),
          IconButton(
            onPressed: () => _load(reset: true),
            icon: const Icon(Icons.refresh_rounded, color: brand),
            tooltip: 'Refresh',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: SizedBox(
              height: 40,
              child: TextField(
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  hintText: 'Search donor, item, source, payment, status…',
                  prefixIcon: const Icon(Icons.search_rounded, color: brand),
                  filled: true,
                  fillColor: softGrey,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  enabledBorder: _border(softGrey),
                  focusedBorder: _border(brand),
                ),
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: _error != null
            ? _ErrorBox(message: _error!, onRetry: () => _load(reset: true))
            : RefreshIndicator(
                onRefresh: _refresh,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  children: [
                    // KPI Cards
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            title: 'Total Donations',
                            value: '$_totalDonations',
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
                          child: _StatCard(title: 'Cash', value: '$_cashCount'),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _StatCard(
                            title: 'In-Kind',
                            value: '$_inKindCount',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _BadgeStatCard(
                            title: 'For Pickup',
                            value: '$_forPickupCount',
                            chipColor: warning.withOpacity(.12),
                            textColor: warning,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _BadgeStatCard(
                            title: 'Received',
                            value: '$_receivedCount',
                            chipColor: success.withOpacity(.12),
                            textColor: success,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Filters
                    _FilterToolbar(
                      period: _period,
                      onPeriodChanged: (v) {
                        setState(() {
                          _period = v;
                          if (_period != 'Custom') _computePeriodRange();
                        });
                      },
                      rangeLabel: _period == 'Custom' ? null : _rangeLabel(),
                      from: _from != null ? _dateFull(_from!) : '—',
                      to: _to != null ? _dateFull(_to!) : '—',
                      onPickFrom: _pickFrom,
                      onPickTo: _pickTo,
                      payment: _payment,
                      onPaymentChanged: (v) => setState(() => _payment = v),
                      type: _type,
                      onTypeChanged: (v) => setState(() => _type = v),
                      donor: _donorOptions.contains(_donor)
                          ? _donor
                          : 'All Donors',
                      donorOptions: _donorOptions,
                      onDonorChanged: (v) => setState(() => _donor = v),
                      status: _statusOptions.contains(_status)
                          ? _status
                          : 'All Statuses',
                      statusOptions: _statusOptions,
                      onStatusChanged: (v) => setState(() => _status = v),
                      onApply: () => setState(() {}),
                    ),

                    const SizedBox(height: 16),

                    // TABLE
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: line),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: loadingFirst
                          ? const Padding(
                              padding: EdgeInsets.all(24),
                              child: Center(child: CircularProgressIndicator()),
                            )
                          : rows.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.all(16),
                              child: Text(
                                'No donations found for the selected filters.',
                                style: TextStyle(
                                  color: textMuted,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            )
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: DataTable(
                                  headingRowColor: MaterialStateProperty.all(
                                    brand,
                                  ),
                                  headingTextStyle: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                  ),
                                  dataRowMinHeight: 44,
                                  dataRowMaxHeight: 64,
                                  columns: const [
                                    DataColumn(label: Text('Date')),
                                    DataColumn(label: Text('Donor')),
                                    DataColumn(label: Text('Source')),
                                    DataColumn(label: Text('Type')),
                                    DataColumn(label: Text('Payment')),
                                    DataColumn(label: Text('Status')),
                                    DataColumn(
                                      label: Align(
                                        alignment: Alignment.centerRight,
                                        child: Text('Amount'),
                                      ),
                                    ),
                                  ],
                                  rows: List.generate(rows.length, (i) {
                                    final r = rows[i];
                                    final bg = i % 2 == 0
                                        ? Colors.white
                                        : Colors.grey.shade50;
                                    TextStyle base(
                                      bool end, [
                                      FontWeight? w,
                                      Color? c,
                                    ]) => TextStyle(
                                      color:
                                          c ?? (end ? brand : Colors.black87),
                                      fontWeight: w ?? FontWeight.w600,
                                    );

                                    Color statusColor() {
                                      final s = r.status.toLowerCase();
                                      if (s.contains('received')) {
                                        return success;
                                      }
                                      if (s.contains('pending')) {
                                        return Colors.orange;
                                      }
                                      if (s.contains('pickup') ||
                                          s.contains('pick up')) {
                                        return warning;
                                      }
                                      if (s.contains('paid')) {
                                        return brand;
                                      }
                                      return Colors.black87;
                                    }

                                    return DataRow(
                                      color: MaterialStateProperty.all(bg),
                                      cells: [
                                        DataCell(
                                          Text(
                                            '${_dateShort(r.date)}\n${r.date.year}',
                                            style: base(false, FontWeight.w800),
                                          ),
                                        ),
                                        DataCell(
                                          Text(r.donor, style: base(false)),
                                        ),
                                        DataCell(
                                          Text(r.source, style: base(false)),
                                        ),
                                        DataCell(
                                          Text(r.type, style: base(false)),
                                        ),
                                        DataCell(
                                          Text(r.payment, style: base(false)),
                                        ),
                                        DataCell(
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: statusColor().withOpacity(
                                                .12,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(999),
                                            ),
                                            child: Text(
                                              r.status,
                                              style: base(
                                                false,
                                                FontWeight.w800,
                                                statusColor(),
                                              ),
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          Align(
                                            alignment: Alignment.centerRight,
                                            child: Text(
                                              _money(r.amount),
                                              style: base(
                                                true,
                                                FontWeight.w800,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  }),
                                ),
                              ),
                            ),
                    ),

                    const SizedBox(height: 12),
                    if (!loadingFirst && _hasMore)
                      SizedBox(
                        height: 44,
                        child: OutlinedButton.icon(
                          onPressed: () => _load(reset: false),
                          icon: const Icon(Icons.expand_more_rounded),
                          label: const Text('Load more'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: brand,
                            side: const BorderSide(color: brand),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
      ),
    );
  }
}

/* ---------- Model ---------- */
class _DonationRow {
  final int id;
  final DateTime date;
  final String donor;
  final String donorPhone;
  final String type;
  final String payment;
  final double amount;
  final String item;
  final String source;
  final String status;

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
    required this.status,
  });
}

/* ---------- Reusable UI ---------- */

class _FilterToolbar extends StatelessWidget {
  static const brand = _DonationReportsState.brand;
  static const softGrey = _DonationReportsState.softGrey;

  final String period;
  final ValueChanged<String> onPeriodChanged;

  final String? rangeLabel;
  final String from;
  final String to;
  final VoidCallback onPickFrom;
  final VoidCallback onPickTo;

  final String payment;
  final ValueChanged<String> onPaymentChanged;

  final String type;
  final ValueChanged<String> onTypeChanged;

  final String donor;
  final List<String> donorOptions;
  final ValueChanged<String> onDonorChanged;

  final String status;
  final List<String> statusOptions;
  final ValueChanged<String> onStatusChanged;

  final VoidCallback onApply;

  const _FilterToolbar({
    required this.period,
    required this.onPeriodChanged,
    required this.rangeLabel,
    required this.from,
    required this.to,
    required this.onPickFrom,
    required this.onPickTo,
    required this.payment,
    required this.onPaymentChanged,
    required this.type,
    required this.onTypeChanged,
    required this.donor,
    required this.donorOptions,
    required this.onDonorChanged,
    required this.status,
    required this.statusOptions,
    required this.onStatusChanged,
    required this.onApply,
  });

  OutlineInputBorder _border(Color c) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(color: c),
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Row 1
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: period,
                isExpanded: true,
                items:
                    const [
                          'This Month',
                          'Last Month',
                          'This Year',
                          'All Time',
                          'Custom',
                        ]
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                onChanged: (v) => v == null ? null : onPeriodChanged(v),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: softGrey,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  enabledBorder: _border(softGrey),
                  focusedBorder: _border(brand),
                ),
                borderRadius: BorderRadius.circular(12),
                icon: const Icon(Icons.expand_more_rounded, color: brand),
                style: const TextStyle(
                  color: brand,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 10),
            if (rangeLabel != null)
              Expanded(
                child: _RangeBox(label: 'Date Range', value: rangeLabel!),
              )
            else ...[
              Expanded(
                child: InkWell(
                  onTap: onPickFrom,
                  child: _RangeBox(label: 'From', value: from),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: InkWell(
                  onTap: onPickTo,
                  child: _RangeBox(label: 'To', value: to),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 10),
        // Row 2
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: payment,
                isExpanded: true,
                items:
                    const [
                          'All Payments',
                          'Cash',
                          'GCash',
                          'Bank Transfer',
                          'QR',
                        ]
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                onChanged: (v) => v == null ? null : onPaymentChanged(v),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: softGrey,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  enabledBorder: _border(softGrey),
                  focusedBorder: _border(brand),
                ),
                borderRadius: BorderRadius.circular(12),
                icon: const Icon(Icons.expand_more_rounded, color: brand),
                style: const TextStyle(
                  color: brand,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: type,
                isExpanded: true,
                items: const ['All Types', 'Cash', 'In-Kind']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => v == null ? null : onTypeChanged(v),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: softGrey,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  enabledBorder: _border(softGrey),
                  focusedBorder: _border(brand),
                ),
                borderRadius: BorderRadius.circular(12),
                icon: const Icon(Icons.expand_more_rounded, color: brand),
                style: const TextStyle(
                  color: brand,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // Row 3
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: donor,
                isExpanded: true,
                items: donorOptions
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => v == null ? null : onDonorChanged(v),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: softGrey,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  enabledBorder: _border(softGrey),
                  focusedBorder: _border(brand),
                ),
                borderRadius: BorderRadius.circular(12),
                icon: const Icon(Icons.expand_more_rounded, color: brand),
                style: const TextStyle(
                  color: brand,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: status,
                isExpanded: true,
                items: statusOptions
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => v == null ? null : onStatusChanged(v),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: softGrey,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  enabledBorder: _border(softGrey),
                  focusedBorder: _border(brand),
                ),
                borderRadius: BorderRadius.circular(12),
                icon: const Icon(Icons.expand_more_rounded, color: brand),
                style: const TextStyle(
                  color: brand,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              height: 40,
              child: ElevatedButton.icon(
                onPressed: onApply,
                icon: const Icon(Icons.filter_alt_outlined),
                label: const Text('Apply Filters'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: brand,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

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

class _BadgeStatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color chipColor;
  final Color textColor;

  const _BadgeStatCard({
    required this.title,
    required this.value,
    required this.chipColor,
    required this.textColor,
  });

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
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _DonationReportsState.textMuted,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: chipColor,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              value,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w900,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RangeBox extends StatelessWidget {
  final String label;
  final String value;
  const _RangeBox({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: _DonationReportsState.softGrey,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Flexible(
            flex: 11,
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _DonationReportsState.textMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            flex: 19,
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  color: _DonationReportsState.brand,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
