import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DonationHistoryPage extends StatefulWidget {
  const DonationHistoryPage({super.key});

  @override
  State<DonationHistoryPage> createState() => _DonationHistoryPageState();
}

class _DonationHistoryPageState extends State<DonationHistoryPage> {
  // Brand palette
  static const brand = Color(0xFF1F2C47);
  static const peach = Color(0xFFEC8C69);
  static const bg = Color(0xFFF6F7F9);

  final supabase = Supabase.instance.client;
  late Future<List<Map<String, dynamic>>> _donationsFuture;

  // filters
  String _filter = 'All'; // All | Cash | In-kind

  @override
  void initState() {
    super.initState();
    _donationsFuture = fetchDonationHistory();
  }

  Future<void> _refresh() async {
    setState(() => _donationsFuture = fetchDonationHistory());
  }

  /// Fetch donation history with related pet & campaign names
  Future<List<Map<String, dynamic>>> fetchDonationHistory() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return [];

      // Use * to avoid column-name mismatches (donation_type vs donation_typ).
      // We still select the embeds explicitly.
      final response = await supabase
          .from('donations')
          .select(r'''
            *,
            pet_profiles (name),
            campaigns (program)
          ''')
          .eq('user_id', user.id)
          .order('donation_date', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (_) {
      return [];
    }
  }

  /// Target label: Program or Pet name (fallback to General)
  String getDonationTarget(Map<String, dynamic> d) {
    final pet = d['pet_profiles']?['name'];
    if (pet != null && pet.toString().isNotEmpty) return 'Pet: $pet';
    final program = d['campaigns']?['program'];
    if (program != null && program.toString().isNotEmpty) {
      return program; // shorter: show program only
    }
    return 'General Donation';
  }

  bool isInKind(Map<String, dynamic> d) {
    final typeA = (d['donation_type'] ?? '').toString().toLowerCase();
    final typeB = (d['donation_typ'] ?? '').toString().toLowerCase();

    final byType = typeA.contains('kind') || typeB.contains('kind');

    final amount = d['amount'];
    final hasNoAmount = amount == null || (amount is num && amount == 0);
    final item = (d['item'] ?? '').toString().trim();
    final qty = d['quantity'];
    final hasGoods = item.isNotEmpty || (qty is num && qty > 0);

    return byType || (hasNoAmount && hasGoods);
  }

  double parseAmount(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v.replaceAll(',', '')) ?? 0;
    return 0;
  }

  String formatDate(dynamic isoOrNull) {
    final s = isoOrNull?.toString();
    if (s == null || s.isEmpty) return 'Unknown date';
    try {
      final dt = DateTime.parse(s);
      return DateFormat('MMM d, yyyy • h:mm a').format(dt);
    } catch (_) {
      return s;
    }
  }

  /// Parse in-kind status from the row to (label, color).
  /// Falls back to 'Pending' if missing/unknown.
  ({String label, Color color}) parseInkindStatus(Map<String, dynamic> d) {
    final raw = (d['inkind_status'] ?? 'pending').toString().toLowerCase();
    if (raw == 'for_pickup' || raw == 'forpickup') {
      return (label: 'For Pickup', color: Colors.blue);
    }
    if (raw == 'received') {
      return (label: 'Received', color: Colors.green);
    }
    return (label: 'Pending', color: Colors.orange);
  }

  @override
  Widget build(BuildContext context) {
    final php = NumberFormat.currency(
      locale: 'en_PH',
      symbol: '₱',
      decimalDigits: 2,
    );

    return Scaffold(
      backgroundColor: bg,
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: CustomScrollView(
          slivers: [
            _HeaderSliver(onBack: () => Navigator.of(context).maybePop()),

            // Main content
            SliverToBoxAdapter(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _donationsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.only(top: 60),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (snapshot.hasError) {
                    return _ErrorBox(
                      message: 'Couldn’t load your donations.',
                      onRetry: _refresh,
                    );
                  }

                  // sort / map
                  final all = snapshot.data ?? [];
                  if (all.isEmpty) {
                    return const _EmptyBox();
                  }

                  // Totals
                  final cashTotal = all
                      .where((d) => !isInKind(d))
                      .fold<double>(0, (s, d) => s + parseAmount(d['amount']));
                  final inKindCount = all
                      .where(isInKind)
                      .fold<int>(0, (s, d) => s + 1);

                  // Filter
                  final list = _filter == 'All'
                      ? all
                      : _filter == 'Cash'
                      ? all.where((d) => !isInKind(d)).toList()
                      : all.where(isInKind).toList();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Totals strip
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                        child: _TotalsRow(
                          cashText: php.format(cashTotal),
                          inKindText:
                              '$inKindCount item${inKindCount == 1 ? '' : 's'}',
                        ),
                      ),

                      // Filter pills
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
                        child: _FilterRow(
                          active: _filter,
                          onSelect: (v) => setState(() => _filter = v),
                        ),
                      ),

                      const SizedBox(height: 2),

                      // Donation list
                      ...list.map((d) {
                        final inKind = isInKind(d);
                        final amount = parseAmount(d['amount']);
                        final date = formatDate(
                          d['donation_date'] ?? d['created_at'],
                        );
                        final label = getDonationTarget(d);
                        final qty = d['quantity'];
                        final item = (d['item'] ?? '').toString().trim();

                        // Only for in-kind: show status chip
                        String? statusLabel;
                        Color? statusColor;
                        if (inKind) {
                          final s = parseInkindStatus(d);
                          statusLabel = s.label;
                          statusColor = s.color;
                        }

                        return _DonationTile(
                          isInKind: inKind,
                          title: label,
                          subtitle: date,
                          amountOrItem: inKind
                              ? (item.isEmpty ? 'Unspecified item' : item)
                              : php.format(amount),
                          quantity: inKind
                              ? (qty == null
                                    ? null
                                    : (qty is num
                                          ? qty.toString()
                                          : qty.toString()))
                              : null,
                          // new:
                          statusLabel: statusLabel,
                          statusColor: statusColor,
                        );
                      }),

                      const SizedBox(height: 24),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* =============== Header =============== */

class _HeaderSliver extends StatelessWidget {
  const _HeaderSliver({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();

    return SliverAppBar(
      automaticallyImplyLeading: false,
      leading: canPop
          ? IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: onBack,
            )
          : null,
      pinned: true,
      expandedHeight: 140,
      elevation: 0,
      backgroundColor: const Color(0xFF1F2C47),
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F2D50), Color(0xFF3A4E7A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(18)),
        ),
        child: const FlexibleSpaceBar(
          titlePadding: EdgeInsetsDirectional.only(start: 56, bottom: 10),
          title: Text(
            'Donation History',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              letterSpacing: .2,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

/* =============== Totals row =============== */

class _TotalsRow extends StatelessWidget {
  const _TotalsRow({required this.cashText, required this.inKindText});

  final String cashText;
  final String inKindText;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(width: 2),
        _TotalChip(
          color: const Color(0xFF1F2C47),
          icon: Icons.payments_rounded,
          labelTop: 'Cash Donated',
          labelBottom: cashText,
        ),
        const SizedBox(width: 10),
        _TotalChip(
          color: const Color(0xFFEC8C69),
          icon: Icons.card_giftcard_rounded,
          labelTop: 'In-kind',
          labelBottom: inKindText,
        ),
        const SizedBox(width: 2),
      ],
    );
  }
}

class _TotalChip extends StatelessWidget {
  const _TotalChip({
    required this.color,
    required this.icon,
    required this.labelTop,
    required this.labelBottom,
  });

  final Color color;
  final IconData icon;
  final String labelTop;
  final String labelBottom;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: color.withOpacity(.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: color.withOpacity(.35)),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    labelTop,
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    labelBottom,
                    style: TextStyle(fontWeight: FontWeight.w900, color: color),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* =============== Filter row =============== */

class _FilterRow extends StatelessWidget {
  const _FilterRow({required this.active, required this.onSelect});
  final String active;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    Widget pill(String label) {
      final bool selected = active == label;
      return InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: () => onSelect(label),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF1F2C47) : Colors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? const Color(0xFF1F2C47) : Colors.grey.shade300,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : Colors.black87,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        pill('All'),
        const SizedBox(width: 8),
        pill('Cash'),
        const SizedBox(width: 8),
        pill('In-kind'),
      ],
    );
  }
}

/* =============== Donation tile =============== */

class _DonationTile extends StatelessWidget {
  const _DonationTile({
    required this.isInKind,
    required this.title,
    required this.subtitle,
    required this.amountOrItem,
    this.quantity,
    this.statusLabel,
    this.statusColor,
  });

  final bool isInKind;
  final String title;
  final String subtitle;
  final String amountOrItem;
  final String? quantity;

  // NEW: in-kind status
  final String? statusLabel;
  final Color? statusColor;

  @override
  Widget build(BuildContext context) {
    final Color tone = isInKind
        ? const Color(0xFFEC8C69)
        : const Color(0xFF1F2C47);

    Widget chip(String text, Color c) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: c.withOpacity(.10),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: c.withOpacity(.35)),
        ),
        child: Text(
          text,
          style: TextStyle(color: c, fontWeight: FontWeight.w700, fontSize: 11),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // leading icon
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: tone.withOpacity(.10),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: tone.withOpacity(.35)),
            ),
            child: Icon(
              isInKind ? Icons.card_giftcard_rounded : Icons.payments_rounded,
              color: tone,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          // text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // title + chips
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // chips: type + (optional) status
                    chip(isInKind ? 'In-kind' : 'Cash', tone),
                    if (isInKind &&
                        statusLabel != null &&
                        statusColor != null) ...[
                      const SizedBox(width: 6),
                      chip(statusLabel!, statusColor!),
                    ],
                  ],
                ),
                const SizedBox(height: 6),

                // amount or item/qty
                if (isInKind) ...[
                  Text(
                    amountOrItem,
                    style: TextStyle(color: tone, fontWeight: FontWeight.w800),
                  ),
                  if (quantity != null && quantity!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Qty: $quantity',
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ] else
                  Text(
                    amountOrItem,
                    style: TextStyle(
                      color: tone,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),

                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.black54, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/* =============== Empty & Error =============== */

class _EmptyBox extends StatelessWidget {
  const _EmptyBox();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 80),
      child: Column(
        children: const [
          Icon(Icons.inbox_outlined, size: 56, color: Colors.black26),
          SizedBox(height: 10),
          Text(
            'No donations found',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 6),
          Text(
            'Your donations will appear here.',
            style: TextStyle(color: Colors.black54, fontSize: 12),
          ),
          SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 80),
      child: Column(
        children: [
          const Icon(Icons.error_outline, size: 56, color: Colors.redAccent),
          const SizedBox(height: 10),
          Text(
            message,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
