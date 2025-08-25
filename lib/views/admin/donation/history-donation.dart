import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;

class DonationHistory extends StatefulWidget {
  const DonationHistory({super.key});

  @override
  State<DonationHistory> createState() => _DonationHistoryState();
}

class _DonationHistoryState extends State<DonationHistory> {
  // Theme
  static const brand = Color(0xFF27374D);
  static const softGrey = Color(0xFFE9EEF3);
  static const textMuted = Color(0xFF6A7886);
  static const success = Color(0xFF25AE5F);

  // Filters
  String _campaignFilter = 'All campaigns';
  String _dateFilter = 'Last 30 days';
  int _typeIndex = 0; // 0 = Cash, 1 = In-Kind

  // For selection highlight
  int? _selectedIdx;

  // Mock data (built relative to "now" so it shows under Last 30 days)
  late final List<_Donation> _all;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();

    _all = [
      _Donation(
        donor: 'John D.',
        amount: 1500,
        fund: 'Medical Funds',
        method: 'BDO',
        methodIcon: Icons.account_balance_outlined,
        status: _DonationStatus.processed,
        type: _DonationType.cash,
        date: DateTime(
          now.year,
          now.month,
          now.day,
          8,
          0,
        ).subtract(const Duration(days: 2)),
      ),
      _Donation(
        donor: 'Mary D.',
        amount: 500,
        fund: 'Medical Funds',
        method: 'GCash',
        methodIcon: Icons.account_balance_wallet_outlined,
        status: _DonationStatus.processed,
        type: _DonationType.cash,
        date: DateTime(
          now.year,
          now.month,
          now.day,
          8,
          0,
        ).subtract(const Duration(days: 5)),
      ),
      _Donation(
        donor: 'John D.',
        amount: 500,
        fund: 'General Funds',
        method: 'Maya',
        methodIcon: Icons.credit_card_outlined,
        status: _DonationStatus.processed,
        type: _DonationType.cash,
        date: DateTime(
          now.year,
          now.month,
          now.day,
          17,
          0,
        ).subtract(const Duration(days: 8)),
      ),
      _Donation(
        donor: 'Max C.',
        amount: 2500,
        fund: 'Food & Shelter',
        method: 'In-kind: Dog food',
        methodIcon: Icons.inventory_2_outlined,
        status: _DonationStatus.processed,
        type: _DonationType.inKind,
        date: DateTime(
          now.year,
          now.month,
          now.day,
          15,
          30,
        ).subtract(const Duration(days: 10)),
      ),
    ];
  }

  // Helpers
  String _money(num v) {
    final s = v.toStringAsFixed(0);
    final re = RegExp(r'\B(?=(\d{3})+(?!\d))');
    return 'PHP ${s.replaceAllMapped(re, (m) => ',')}';
  }

  String _dateOnly(DateTime d) {
    const months = [
      '',
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[d.month]} ${d.day}, ${d.year}';
  }

  String _timeOnly(DateTime d) {
    final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final mm = d.minute.toString().padLeft(2, '0');
    final ampm = d.hour >= 12 ? 'PM' : 'AM';
    return '$h:$mm $ampm';
  }

  String _dateFmt(DateTime d) => '${_dateOnly(d)}\n${_timeOnly(d)}';

  List<_Donation> get _filtered {
    final now = DateTime.now();
    DateTime? start;
    if (_dateFilter == 'Last 7 days')
      start = now.subtract(const Duration(days: 7));
    if (_dateFilter == 'Last 30 days')
      start = now.subtract(const Duration(days: 30));
    if (_dateFilter == 'This year') start = DateTime(now.year);

    return _all.where((d) {
      if (_typeIndex == 0 && d.type != _DonationType.cash) return false;
      if (_typeIndex == 1 && d.type != _DonationType.inKind) return false;
      if (_campaignFilter != 'All campaigns' && d.fund != _campaignFilter) {
        return false;
      }
      if (start != null && d.date.isBefore(start)) return false;
      return true;
    }).toList()..sort((a, b) => b.date.compareTo(a.date));
  }

  Future<String?> _pickOption(
    BuildContext context, {
    required String title,
    required List<String> options,
    required String current,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 6),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            ...options.map(
              (o) => ListTile(
                title: Text(
                  o,
                  style: TextStyle(
                    color: o == current ? brand : Colors.black87,
                    fontWeight: o == current
                        ? FontWeight.w700
                        : FontWeight.w500,
                  ),
                ),
                trailing: o == current
                    ? const Icon(Icons.check, color: brand)
                    : null,
                onTap: () => Navigator.pop(ctx, o),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ——— DETAILS SHEET ———
  Future<void> _showDonationInfo(_Donation d) async {
    final ref = 'TXN-${d.date.millisecondsSinceEpoch.toString().substring(5)}';

    await showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              8,
              16,
              16 + MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        d.donor,
                        style: const TextStyle(
                          color: brand,
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    const _StatusChip(status: _DonationStatus.processed),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  _money(d.amount),
                  style: const TextStyle(
                    color: brand,
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),

                _InfoRow(label: 'Fund', value: d.fund),
                const SizedBox(height: 8),
                _InfoRow(
                  label: 'Payment Method',
                  value: d.method,
                  leading: Icon(d.methodIcon, size: 18, color: brand),
                ),
                const SizedBox(height: 8),
                _InfoRow(label: 'Date', value: _dateOnly(d.date)),
                const SizedBox(height: 8),
                _InfoRow(label: 'Time', value: _timeOnly(d.date)),
                const SizedBox(height: 8),

                Row(
                  children: [
                    Expanded(
                      child: _InfoRow(label: 'Reference ID', value: ref),
                    ),
                    IconButton(
                      tooltip: 'Copy reference',
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: ref));
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Reference copied')),
                          );
                        }
                      },
                      icon: const Icon(Icons.copy_rounded, color: brand),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.mail_outline_rounded),
                        label: const Text('Resend Receipt'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: brand,
                          side: const BorderSide(color: brand, width: 1.2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Receipt re-sent to ${d.donor}'),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: brand,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Close'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final pillsGap = 10.0;
    final items = _filtered;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Donation History'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            // Top filter pills
            Row(
              children: [
                Expanded(
                  child: _FilterPill(
                    label: _campaignFilter,
                    onTap: () async {
                      final v = await _pickOption(
                        context,
                        title: 'Campaigns',
                        options: const [
                          'All campaigns',
                          'Medical Funds',
                          'General Funds',
                          'Food & Shelter',
                        ],
                        current: _campaignFilter,
                      );
                      if (v != null) setState(() => _campaignFilter = v);
                    },
                  ),
                ),
                SizedBox(width: pillsGap),
                Expanded(
                  child: _FilterPill(
                    label: _dateFilter,
                    onTap: () async {
                      final v = await _pickOption(
                        context,
                        title: 'Date range',
                        options: const [
                          'Last 7 days',
                          'Last 30 days',
                          'This year',
                          'All time',
                        ],
                        current: _dateFilter,
                      );
                      if (v != null) setState(() => _dateFilter = v);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Segmented Cash / In-Kind
            Row(
              children: [
                Expanded(
                  child: _SegmentButton(
                    label: 'Cash',
                    selected: _typeIndex == 0,
                    onTap: () => setState(() => _typeIndex = 0),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _SegmentButton(
                    label: 'In-Kind',
                    selected: _typeIndex == 1,
                    onTap: () => setState(() => _typeIndex = 1),
                    light: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Donation list (with selection highlight)
            for (var i = 0; i < items.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _DonationCard(
                  data: items[i],
                  money: _money,
                  dateFmt: _dateFmt,
                  selected: _selectedIdx == i,
                  onTap: () {
                    setState(() => _selectedIdx = i);
                    _showDonationInfo(items[i]);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ===== Models =====
enum _DonationType { cash, inKind }

enum _DonationStatus { processed }

class _Donation {
  final String donor;
  final int amount;
  final String fund;
  final String method;
  final IconData methodIcon;
  final _DonationType type;
  final _DonationStatus status;
  final DateTime date;

  _Donation({
    required this.donor,
    required this.amount,
    required this.fund,
    required this.method,
    required this.methodIcon,
    required this.type,
    required this.status,
    required this.date,
  });
}

// ===== UI Bits =====
class _FilterPill extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _FilterPill({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _DonationHistoryState.softGrey,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _DonationHistoryState.brand,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.expand_more_rounded,
                size: 18,
                color: _DonationHistoryState.brand,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool light;

  const _SegmentButton({
    required this.label,
    required this.selected,
    required this.onTap,
    this.light = false,
  });

  @override
  Widget build(BuildContext context) {
    final bg = selected
        ? _DonationHistoryState.brand
        : (light ? _DonationHistoryState.softGrey : Colors.white);
    final fg = selected ? Colors.white : _DonationHistoryState.brand;
    final side = BorderSide(
      color: selected ? _DonationHistoryState.brand : Colors.blueGrey.shade200,
      width: 1.3,
    );

    return SizedBox(
      height: 40,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          side: side,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
        child: Text(label),
      ),
    );
  }
}

class _DonationCard extends StatelessWidget {
  final _Donation data;
  final String Function(num) money;
  final String Function(DateTime) dateFmt;
  final VoidCallback? onTap;
  final bool selected;

  const _DonationCard({
    required this.data,
    required this.money,
    required this.dateFmt,
    this.onTap,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    final baseBorder = Border.all(color: Colors.blueGrey.shade200);
    final blue = Colors.lightBlue.shade400;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: selected ? Border.all(color: blue, width: 2) : baseBorder,
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: blue.withOpacity(.25),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.donor,
                      style: const TextStyle(
                        color: _DonationHistoryState.brand,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      money(data.amount),
                      style: const TextStyle(
                        color: _DonationHistoryState.brand,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      data.fund,
                      style: const TextStyle(
                        color: _DonationHistoryState.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          width: 28,
                          height: 24,
                          decoration: BoxDecoration(
                            color: _DonationHistoryState.softGrey,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            data.methodIcon,
                            size: 18,
                            color: _DonationHistoryState.brand,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            data.method,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _DonationHistoryState.textMuted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Right column
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const _StatusChip(status: _DonationStatus.processed),
                  const SizedBox(height: 12),
                  Text(
                    dateFmt(data.date),
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      color: _DonationHistoryState.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final _DonationStatus status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _DonationHistoryState.success.withOpacity(.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _DonationHistoryState.success, width: 1.2),
      ),
      child: const Text(
        'Processed',
        style: TextStyle(
          color: _DonationHistoryState.success,
          fontWeight: FontWeight.w800,
          fontSize: 11,
          letterSpacing: .2,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Widget? leading;
  const _InfoRow({required this.label, required this.value, this.leading});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (leading != null) ...[leading!, const SizedBox(width: 8)],
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: _DonationHistoryState.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _DonationHistoryState.brand,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
