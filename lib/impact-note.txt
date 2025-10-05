import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Optional: only for the Monthly Goal card
import 'package:pawlytics/views/donors/controller/goal-opex-controller.dart';

class ImpactPage extends StatefulWidget {
  const ImpactPage({super.key});
  @override
  State<ImpactPage> createState() => _ImpactPageState();
}

class _ImpactPageState extends State<ImpactPage> {
  // Brand
  static const brand = Color(0xFF1F2C47);
  static const peach = Color(0xFFEC8C69);

  // Formats
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

  // Outcome estimate (for the little "?")
  static const double _pesosPerAnimalHelp = 500.0; // ₱500 ≈ 1 animal helped

  // Supabase + monthly goal controller
  final _supabase = Supabase.instance.client;
  late Future<double> _totalCashFuture;
  final _goal = OpexAllocationsController();

  // Card style for the Monthly Goals only
  final BorderSide _cardBorder = BorderSide(color: Colors.grey.shade300);
  final List<BoxShadow> _cardShadow = const [
    BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3)),
  ];

  // ===== Program → Bucket (edit as your list changes) =====
  static const Map<String, String> kProgramToBucket = {
    'Shelters Improvement': 'Shelter',
    'Surgery': 'Medicine',
    'Dog Pound': 'Shelter',
    'Rescue': 'Shelter',
    'Stray Animals': 'Shelter',
    'Vaccination': 'Medicine',
    'Spay/Neuter': 'Medicine',
    'Pet Food': 'Food',
    'Medical Supplies': 'Medicine',
    'Outreach and Awareness': 'Other',
    'All Campaigns': 'Other',
  };

  /// Where to count donations tied to a specific pet in the bucket chart
  static const String kPetDefaultBucket =
      'Medicine'; // change to 'Shelter' if you prefer

  /// Buckets you do NOT want to render in the donut
  static const Set<String> kHiddenBuckets = {'Food', 'Medicine'};

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
        if (a is num) {
          sum += a.toDouble();
        } else if (a is String) {
          sum += double.tryParse(a.replaceAll(',', '')) ?? 0.0;
        }
      }
      return sum;
    } catch (_) {
      return 0.0;
    }
  }

  String _pct(double v) => '${(v * 100).clamp(0, 100).toStringAsFixed(0)}%';

  @override
  Widget build(BuildContext context) {
    // Optional Monthly Goal (from your Opex controller)
    final items = _goal.items;
    final raised = items.fold<double>(0, (s, e) => s + e.raised);
    final goal = items.fold<double>(0, (s, e) => s + e.amount);
    final prog = goal > 0 ? (raised / goal).clamp(0.0, 1.0) : 0.0;
    final isClosed = _goal.isClosed;
    final due = _goal.monthEnd == null ? '—' : _dateFmt.format(_goal.monthEnd!);

    final estimateText =
        'Estimate: ₱${_pesosPerAnimalHelp.toStringAsFixed(0)} ≈ 1 animal helped. Actual costs vary by partner.';

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
            _HeroBanner(
              title: 'Total Help You Gave',
              futureValue: _totalCashFuture,
              fmt: _php2,
              animalsFrom: (amount) => (amount / _pesosPerAnimalHelp).floor(),
              helpIcon: _MiniHelpIcon(helpText: estimateText),
            ),

            // Monthly goal (single card)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: _CardShell(
                border: _cardBorder,
                shadow: _cardShadow,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
            _CompactMoneySection(
              programToBucket: kProgramToBucket,
              petDefaultBucket: kPetDefaultBucket,
              hideBuckets: kHiddenBuckets, // still hides Food/Medicine
              overallRaised: raised,
              overallGoal: goal,
              php: _php0,
            ),

            const SizedBox(height: 18),
            const _SectionHeader(text: 'In-Kind Donations (Top 5)'),
            const _InKindBarFromDonations(),

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
                Row(
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

/* ====================== Data helpers ====================== */

Future<List<Map<String, dynamic>>> _fetchUserDonationsRows() async {
  final supabase = Supabase.instance.client;
  final user = supabase.auth.currentUser;
  if (user == null) return [];
  final rows = await supabase
      .from('donations')
      .select(
        'amount, donation_type, item, quantity, campaigns(program), pet_profiles(name)',
      )
      .eq('user_id', user.id);
  return List<Map<String, dynamic>>.from(rows);
}

double _parseAmount(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v.replaceAll(',', '')) ?? 0;
  return 0;
}

double _parseQty(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v.replaceAll(',', '')) ?? 0;
  return 0;
}

/* ====================== COMPACT CHART SECTION ====================== */

class _CompactMoneySection extends StatelessWidget {
  const _CompactMoneySection({
    required this.programToBucket,
    required this.petDefaultBucket,
    required this.hideBuckets,
    required this.overallRaised,
    required this.overallGoal,
    required this.php,
  });

  final Map<String, String> programToBucket;
  final String petDefaultBucket;
  final Set<String> hideBuckets;

  final double overallRaised;
  final double overallGoal;
  final NumberFormat php;

  @override
  Widget build(BuildContext context) {
    final goalProgress = overallGoal <= 0
        ? 0.0
        : (overallRaised / overallGoal).clamp(0.0, 1.0);

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _fetchUserDonationsRows(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }
        if (snap.hasError) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Couldn’t load allocation right now.',
              style: TextStyle(color: Colors.redAccent),
            ),
          );
        }

        final rows = snap.data ?? const [];

        // ---- cash totals by bucket (hiding Food/Medicine) ----
        final totals = <String, double>{};
        String bucketFor(Map<String, dynamic> r) {
          final program = (r['campaigns']?['program'] ?? '').toString().trim();
          if (program.isNotEmpty) {
            final hit = programToBucket.entries.firstWhere(
              (e) => e.key.toLowerCase() == program.toLowerCase(),
              orElse: () => const MapEntry<String, String>('', ''),
            );
            if (hit.key.isNotEmpty) return hit.value;
          }
          final pet = (r['pet_profiles']?['name'] ?? '').toString().trim();
          if (pet.isNotEmpty) return petDefaultBucket;
          return 'Other';
        }

        for (final r in rows) {
          final type = (r['donation_type'] ?? '').toString().toLowerCase();
          if (type.contains('kind')) continue; // cash only here
          final amt = _parseAmount(r['amount']);
          if (amt <= 0) continue;
          final b = bucketFor(r);
          if (hideBuckets.contains(b)) continue;
          totals[b] = (totals[b] ?? 0) + amt;
        }

        if (totals.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'No cash donations to analyze yet.',
              style: TextStyle(color: Colors.black54),
            ),
          );
        }

        final total = totals.values.fold<double>(0, (s, v) => s + v);
        final slices = totals.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        // palette (loops if needed)
        final colors = <Color>[
          _ImpactPageState.brand,
          const Color(0xFF3A4E7A),
          const Color(0xFF7A8BB6),
          const Color(0xFFB6C2DB),
        ];

        // Responsive: compact row, stacks on very narrow widths
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: LayoutBuilder(
            builder: (context, c) {
              final isNarrow = c.maxWidth < 360;
              final donutSize = isNarrow ? 140.0 : 160.0;
              final gaugeSize = isNarrow ? 88.0 : 96.0;

              final donut = SizedBox(
                width: donutSize,
                height: donutSize,
                child: CustomPaint(
                  painter: _MiniDonutPainter(
                    values: slices.map((e) => e.value).toList(),
                    colors: List<Color>.generate(
                      slices.length,
                      (i) => colors[i % colors.length],
                    ),
                  ),
                ),
              );

              final gauge = SizedBox(
                width: gaugeSize,
                height: gaugeSize,
                child: CustomPaint(
                  painter: _GoalGaugePainter(
                    progress: goalProgress,
                    color: _ImpactPageState.peach,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${(goalProgress * 100).toStringAsFixed(0)}%',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: _ImpactPageState.brand,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Goal',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.black.withOpacity(.6),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );

              final legend = Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 12, top: 4, bottom: 4),
                  child: Column(
                    children: [
                      for (int i = 0; i < slices.length; i++) ...[
                        _LegendRow(
                          color: colors[i % colors.length],
                          label: slices[i].key,
                          percent: total == 0 ? 0 : (slices[i].value / total),
                        ),
                        if (i < slices.length - 1) const SizedBox(height: 6),
                      ],
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          '${php.format(overallRaised)} / ${php.format(overallGoal)}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.black54,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );

              if (isNarrow) {
                // stack vertically for tiny widths
                return Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [donut, const SizedBox(width: 12), gauge],
                    ),
                    const SizedBox(height: 10),
                    legend,
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [donut, const SizedBox(width: 12), gauge, legend],
              );
            },
          ),
        );
      },
    );
  }
}

/* ---------------- painters & legend rows ---------------- */

class _MiniDonutPainter extends CustomPainter {
  _MiniDonutPainter({required this.values, required this.colors});
  final List<double> values;
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    final total = values.fold<double>(0, (s, v) => s + v);
    if (total <= 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    final stroke = radius * .35; // thick for visibility

    // light track
    final track = Paint()
      ..color = Colors.grey.shade300
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    canvas.drawCircle(center, radius * .78, track);

    // slices
    double start = -math.pi / 2;
    for (int i = 0; i < values.length; i++) {
      final sweep = (values[i] / total) * 2 * math.pi;
      final p = Paint()
        ..color = colors[i]
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius * .78),
        start,
        sweep,
        false,
        p,
      );
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _MiniDonutPainter old) =>
      old.values != values || old.colors != colors;
}

class _GoalGaugePainter extends CustomPainter {
  _GoalGaugePainter({required this.progress, required this.color});
  final double progress; // 0..1
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2, cy = size.height / 2;
    final r = math.min(cx, cy);
    final stroke = r * .18;

    // background ring
    final bg = Paint()
      ..color = Colors.black12
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    canvas.drawCircle(Offset(cx, cy), r * .72, bg);

    // progress ring (rounded ends)
    if (progress > 0) {
      final p = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: r * .72),
        -math.pi / 2,
        progress * 2 * math.pi,
        false,
        p,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GoalGaugePainter old) =>
      old.progress != progress || old.color != color;
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({
    required this.color,
    required this.label,
    required this.percent,
  });

  final Color color;
  final String label;
  final double percent;

  @override
  Widget build(BuildContext context) {
    final pctText = '${(percent * 100).toStringAsFixed(0)}%';
    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(width: 6),
            Text(pctText, style: const TextStyle(color: Colors.black87)),
          ],
        ),
        const SizedBox(height: 4),
        LayoutBuilder(
          builder: (context, c) => Stack(
            children: [
              Container(
                height: 6,
                width: c.maxWidth,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              Container(
                height: 6,
                width: c.maxWidth * percent,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/* ====================== In-Kind Donations (Top 5 mini bars) ====================== */

class _InKindBarFromDonations extends StatelessWidget {
  const _InKindBarFromDonations();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _fetchUserDonationsRows(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }
        if (snap.hasError) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Couldn’t load in-kind donations.',
              style: TextStyle(color: Colors.redAccent),
            ),
          );
        }

        final rows = snap.data ?? const [];

        final qtyByItem = <String, double>{};
        for (final r in rows) {
          final type = (r['donation_type'] ?? '').toString().toLowerCase();
          if (!type.contains('kind')) continue;
          final rawItem = (r['item'] ?? '').toString().trim();
          final item = rawItem.isEmpty ? 'Unspecified item' : rawItem;
          final qty = _parseQty(r['quantity']);
          qtyByItem[item] = (qtyByItem[item] ?? 0) + (qty > 0 ? qty : 1);
        }

        if (qtyByItem.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'No in-kind donations yet.',
              style: TextStyle(color: Colors.black54),
            ),
          );
        }

        final sorted = qtyByItem.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        final top = sorted.take(5).toList();
        final maxV = top.first.value;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Column(
            children: [
              for (final e in top)
                _HBar(label: e.key, value: e.value, max: maxV),
            ],
          ),
        );
      },
    );
  }
}

class _HBar extends StatelessWidget {
  const _HBar({required this.label, required this.value, required this.max});
  final String label;
  final double value;
  final double max;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: Text(label, overflow: TextOverflow.ellipsis)),
              Text(
                'x${value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 1)}',
              ),
            ],
          ),
          const SizedBox(height: 6),
          LayoutBuilder(
            builder: (context, c) {
              final w = max <= 0 ? 0.0 : (value / max) * c.maxWidth;
              return Stack(
                children: [
                  Container(
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  Container(
                    width: w,
                    height: 10,
                    decoration: BoxDecoration(
                      color: _ImpactPageState.brand,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
