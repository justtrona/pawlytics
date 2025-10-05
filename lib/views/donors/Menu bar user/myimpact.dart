import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// reuse your goals controller
import 'package:pawlytics/views/donors/controller/goal-opex-controller.dart';

/// Impact Page — Minimal / Non-card UI + help "?" + carded Monthly Goals
class ImpactPage extends StatefulWidget {
  const ImpactPage({super.key});

  @override
  State<ImpactPage> createState() => _ImpactPageState();
}

class _ImpactPageState extends State<ImpactPage> {
  // brand
  static const brand = Color(0xFF1F2C47);
  static const peach = Color(0xFFEC8C69);

  // formats
  final _php0 = NumberFormat.currency(
    locale: 'en_PH',
    symbol: '₱',
    decimalDigits: 0,
  );
  final _php2 = NumberFormat.currency(
    locale: 'en_PH',
    symbol: '₱',
    decimalDigits: 2,
  );
  final _dateFmt = DateFormat('MMM d, yyyy');

  // data: total cash (user) & monthly goals
  final _supabase = Supabase.instance.client;
  late Future<double> _totalCashFuture;
  final _goal = OpexAllocationsController();

  // outcome estimate
  static const double _pesosPerAnimalHelp = 500.0; // ₱500 ≈ 1 animal helped

  // card style for the Monthly Goals only
  final BorderSide _cardBorder = BorderSide(color: Colors.grey.shade300);
  final List<BoxShadow> _cardShadow = const [
    BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3)),
  ];

  @override
  void initState() {
    super.initState();
    _totalCashFuture = _fetchTotalCash();
    _goal.addListener(_onGoalChange);
    _goal.loadAllocations();
  }

  @override
  void dispose() {
    _goal.removeListener(_onGoalChange);
    _goal.dispose();
    super.dispose();
  }

  void _onGoalChange() {
    if (mounted) setState(() {});
  }

  Future<double> _fetchTotalCash() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return 0.0;
      final rows = await _supabase
          .from('donations')
          .select('amount, donation_type')
          .eq('user_id', user.id);

      double sum = 0.0;
      for (final r in rows) {
        final type = (r['donation_type'] ?? '').toString().toLowerCase();
        if (type.contains('kind')) continue; // skip in-kind
        final a = r['amount'];
        if (a is num)
          sum += a.toDouble();
        else if (a is String)
          sum += double.tryParse(a.replaceAll(',', '')) ?? 0.0;
      }
      return sum;
    } catch (_) {
      return 0.0;
    }
  }

  String _pct(double v) => '${(v * 100).clamp(0, 100).toStringAsFixed(0)}%';

  @override
  Widget build(BuildContext context) {
    // compute monthly goal from controller
    final items = _goal.items;
    final raised = items.fold<double>(0, (s, e) => s + e.raised);
    final goal = items.fold<double>(0, (s, e) => s + e.amount);
    final prog = goal > 0 ? (raised / goal).clamp(0.0, 1.0) : 0.0;

    final isClosed = _goal.isClosed;
    final due = _goal.monthEnd == null ? '—' : _dateFmt.format(_goal.monthEnd!);

    final estimateText =
        'Estimate: ₱${_pesosPerAnimalHelp.toStringAsFixed(0)} ≈ 1 animal helped. '
        'Actual costs vary by partner.';

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
        centerTitle: true,
        title: const Text(
          'Impact',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: _goal.loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
            onPressed: () async {
              await _goal.loadAllocations();
              setState(() => _totalCashFuture = _fetchTotalCash());
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _goal.loadAllocations();
          setState(() => _totalCashFuture = _fetchTotalCash());
        },
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // ======= HERO BANNER (with mini "?" help) =======
            _HeroBanner(
              title: 'Total Help You Gave',
              futureValue: _totalCashFuture,
              fmt: _php2,
              animalsFrom: (amount) => (amount / _pesosPerAnimalHelp).floor(),
              // NEW: small outlined "?" with tooltip + dialog
              helpIcon: _MiniHelpIcon(helpText: estimateText),
            ),

            // ======= THIS MONTH (now in a CARD) =======
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: _CardShell(
                border: _cardBorder,
                shadow: _cardShadow,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // header row with status + due
                    Row(
                      children: [
                        const Text(
                          'This Month’s Goal',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: brand,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _Chip(
                          label: isClosed ? 'Closed' : 'Active',
                          color: isClosed ? Colors.grey : brand,
                        ),
                        const Spacer(),
                        Text(
                          'Due: $due',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // raised / goal / percent
                    Row(
                      children: [
                        Text(
                          _php0.format(raised),
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
                        const Spacer(),
                        Text(
                          'of ${_php0.format(goal)} • ${_pct(prog)}',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // progress bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: prog,
                        minHeight: 12,
                        backgroundColor: Colors.grey.shade300,
                        valueColor: const AlwaysStoppedAnimation(brand),
                      ),
                    ),
                    if (isClosed)
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text(
                          'This month is closed. New donations are not accepted.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.redAccent,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 18),
            const _SectionHeader(text: 'Where Your Money Went'),
            // ======= ALLOCATION LIST (simple rows + dividers outside card) =======
            const _AllocationRow(label: 'Food', value: 520),
            const _AllocationRow(label: 'Medicine', value: 340),
            const _AllocationRow(label: 'Shelter', value: 690),
            const _AllocationRow(label: 'Other', value: 105),

            const SizedBox(height: 18),
            const _SectionHeader(text: 'Stories'),
            const _StoryRow(
              icon: Icons.pets,
              title: 'Max found a foster home',
              line: 'Your gift covered medicine & 3 days of care.',
              date: '3 days ago',
            ),
            const _DividerIndent(),
            const _StoryRow(
              icon: Icons.volunteer_activism_outlined,
              title: 'Food restock at Happy Paws',
              line: 'Thanks to you, 72 meals were served this week.',
              date: '1 week ago',
            ),

            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                estimateText,
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

/* ====================== UI bits ====================== */

class _MiniHelpIcon extends StatelessWidget {
  const _MiniHelpIcon({required this.helpText});
  final String helpText;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: helpText,
      preferBelow: true,
      child: IconButton(
        icon: const Icon(Icons.help_outline, color: Colors.white70, size: 20),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        onPressed: () {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('How we estimate impact'),
              content: Text(helpText),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _HeroBanner extends StatelessWidget {
  const _HeroBanner({
    required this.title,
    required this.futureValue,
    required this.fmt,
    required this.animalsFrom,
    this.helpIcon,
  });

  final String title;
  final Future<double> futureValue;
  final NumberFormat fmt;
  final int Function(double) animalsFrom;
  final Widget? helpIcon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 22),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0F2D50), Color(0xFF3A4E7A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: FutureBuilder<double>(
          future: futureValue,
          builder: (context, snap) {
            final loading = snap.connectionState == ConnectionState.waiting;
            final value = snap.data ?? 0.0;
            final animals = animalsFrom(value);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title row with optional mini help "?"
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.w700,
                          letterSpacing: .2,
                        ),
                      ),
                    ),
                    if (helpIcon != null) helpIcon!,
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  loading ? '…' : fmt.format(value),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  loading ? 'Calculating…' : 'About $animals animals helped',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _CardShell extends StatelessWidget {
  const _CardShell({
    required this.child,
    required this.border,
    required this.shadow,
  });
  final Widget child;
  final BorderSide border;
  final List<BoxShadow> shadow;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.fromBorderSide(border),
        boxShadow: shadow,
      ),
      child: child,
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(.09),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(.25)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: color,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
      child: Row(
        children: [
          Text(
            text,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: _ImpactPageState.brand,
            ),
          ),
        ],
      ),
    );
  }
}

class _AllocationRow extends StatelessWidget {
  const _AllocationRow({required this.label, required this.value});
  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    // simple static total for demo rows
    const total = 520 + 340 + 690 + 105;
    final pct = total == 0 ? 0.0 : (value / total);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(width: 110, child: Text(label)),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 10,
                    backgroundColor: Colors.grey.shade300,
                    valueColor: const AlwaysStoppedAnimation(
                      _ImpactPageState.brand,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text('${(pct * 100).toStringAsFixed(0)}%'),
            ],
          ),
          const _DividerIndent(),
        ],
      ),
    );
  }
}

class _StoryRow extends StatelessWidget {
  const _StoryRow({
    required this.icon,
    required this.title,
    required this.line,
    required this.date,
  });
  final IconData icon;
  final String title;
  final String line;
  final String date;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: _ImpactPageState.brand.withOpacity(.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: _ImpactPageState.brand, size: 22),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      subtitle: Text(line),
      trailing: Text(
        date,
        style: const TextStyle(fontSize: 12, color: Colors.black54),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      dense: true,
    );
  }
}

class _DividerIndent extends StatelessWidget {
  const _DividerIndent();

  @override
  Widget build(BuildContext context) {
    return const Divider(indent: 16, endIndent: 16, height: 18);
  }
}
