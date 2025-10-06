import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:supabase_flutter/supabase_flutter.dart';

class DonorsAnalytics extends StatefulWidget {
  const DonorsAnalytics({super.key});

  @override
  State<DonorsAnalytics> createState() => _DonorsAnalyticsState();
}

class _DonorsAnalyticsState extends State<DonorsAnalytics> {
  // === DATA FROM DB ===
  List<double> _weekData = const [];

  // KPI values
  String _totalReceivedText = '₱0.00'; // all-time total
  String _topDonorsText = '—'; // top 3 donors by amount (last 90d)
  String _avgGiftText = '₱0.00'; // median gift (month-to-date)

  // Donation frequency (last 12 months)
  String _freqPct = '0%';
  String _occPct = '0%';
  String _onePct = '0%';

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadFromDb();
  }

  Future<void> _loadFromDb() async {
    try {
      final sb = Supabase.instance.client;

      // ----- 1) TOTAL RECEIVED (all-time) -----
      final totalRows = await sb.from('donations').select('amount');
      final totalReceived = (totalRows as List)
          .map((r) => (r['amount'] as num?)?.toDouble() ?? 0.0)
          .fold<double>(0.0, (a, b) => a + b);

      // ----- 2) TOP DONORS (last 90 days) -----
      final since90 = DateTime.now()
          .subtract(const Duration(days: 90))
          .toIso8601String();
      final rawTopRows = await sb
          .from('donations')
          .select('donor_name, amount')
          .not('donor_name', 'is', null)
          .gte('donation_date', since90);

      final Map<String, double> sumByDonor = {};
      for (final r in (rawTopRows as List)) {
        final dn = r['donor_name'];
        if (dn == null) continue;
        final name = (dn as String).trim();
        if (name.isEmpty) continue;
        final amt = (r['amount'] as num?)?.toDouble() ?? 0.0;
        sumByDonor.update(name, (v) => v + amt, ifAbsent: () => amt);
      }
      final topDonorNames = sumByDonor.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final topDonorsJoined = topDonorNames.isEmpty
          ? '—'
          : topDonorNames.take(3).map((e) => e.key).join(', ');

      // ----- 3) AVG GIFT (median) Month-to-Date -----
      final monthStart = DateTime(DateTime.now().year, DateTime.now().month);
      final amountsRows = await sb
          .from('donations')
          .select('amount')
          .gte('donation_date', monthStart.toIso8601String());
      final amounts =
          (amountsRows as List)
              .map((r) => (r['amount'] as num?)?.toDouble())
              .where((v) => v != null)
              .cast<double>()
              .toList()
            ..sort();
      final median = _median(amounts);

      // ----- 4) LAST 7 DAYS SERIES (sum per day) -----
      final since7 = DateTime.now().subtract(const Duration(days: 6));
      final weekRows = await sb
          .from('donations')
          .select('donation_date, amount')
          .gte(
            'donation_date',
            DateTime(since7.year, since7.month, since7.day).toIso8601String(),
          );
      final perDay = _sumByDay(weekRows as List);

      // ----- 5) DONATION FREQUENCY (last 12 months) -----
      final since12m = DateTime.now().subtract(const Duration(days: 365));
      final freqRows = await sb
          .from('donations')
          .select('donor_name')
          .not('donor_name', 'is', null)
          .gte(
            'donation_date',
            DateTime(
              since12m.year,
              since12m.month,
              since12m.day,
            ).toIso8601String(),
          );

      final Map<String, int> perDonorCounts = {};
      for (final r in (freqRows as List)) {
        final dn = r['donor_name'];
        if (dn == null) continue;
        final name = (dn as String).trim();
        if (name.isEmpty) continue;
        perDonorCounts.update(name, (v) => v + 1, ifAbsent: () => 1);
      }
      final totalDonors = perDonorCounts.length;
      int frequent = 0, occasional = 0, oneTime = 0;
      for (final n in perDonorCounts.values) {
        if (n >= 12)
          frequent++; // ≥ 12 in last 12 months
        else if (n >= 2)
          occasional++; // 2–11
        else
          oneTime++; // = 1
      }
      double pct(int x) => totalDonors == 0 ? 0.0 : (x * 100.0 / totalDonors);
      final freqPctVal = pct(frequent);
      final occPctVal = pct(occasional);
      final onePctVal = pct(oneTime);

      setState(() {
        _weekData = perDay;
        _totalReceivedText = _formatCurrency(totalReceived);
        _topDonorsText = topDonorsJoined;
        _avgGiftText = _formatCurrency(median);

        _freqPct = '${freqPctVal.toStringAsFixed(0)}%';
        _occPct = '${occPctVal.toStringAsFixed(0)}%';
        _onePct = '${onePctVal.toStringAsFixed(0)}%';

        _loading = false;
      });
    } catch (e) {
      setState(() {
        _weekData = const [0, 0, 0, 0, 0, 0, 0];
        _totalReceivedText = '₱0.00';
        _topDonorsText = '—';
        _avgGiftText = '₱0.00';
        _freqPct = '0%';
        _occPct = '0%';
        _onePct = '0%';
        _loading = false;
      });
    }
  }

  // Build 7 daily totals (last 7 calendar days, oldest→newest)
  List<double> _sumByDay(List rows) {
    final now = DateTime.now();
    final start = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(const Duration(days: 6));

    final keys = <String>[];
    final buckets = <String, double>{};
    for (int i = 0; i < 7; i++) {
      final d = start.add(Duration(days: i));
      final k =
          '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      keys.add(k);
      buckets[k] = 0.0;
    }

    for (final r in rows) {
      final ts = r['donation_date'] as String?;
      final amt = (r['amount'] as num?)?.toDouble() ?? 0.0;
      if (ts == null) continue;
      final d = DateTime.tryParse(ts);
      if (d == null) continue;
      final day = DateTime(d.year, d.month, d.day);
      final k =
          '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
      if (buckets.containsKey(k)) {
        buckets[k] = (buckets[k] ?? 0) + amt;
      }
    }

    return keys.map((k) => buckets[k] ?? 0.0).toList(growable: false);
  }

  double _median(List<double> xs) {
    if (xs.isEmpty) return 0.0;
    final n = xs.length;
    if (n.isOdd) return xs[n ~/ 2];
    return (xs[n ~/ 2 - 1] + xs[n ~/ 2]) / 2.0;
  }

  String _formatCurrency(double v) => '₱${v.toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF0F2D50);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () => Navigator.maybePop(context),
          color: Colors.black87,
        ),
        title: const Text(
          'Donor Behavior Analytics',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: false,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              children: [
                // === Trend ===
                _Card(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _SectionHeader(
                        title: 'Last 7 days',
                        subtitle: 'Amount received',
                      ),
                      const SizedBox(height: 4),
                      AspectRatio(
                        aspectRatio: 1.7,
                        child: _SparkAreaChart(
                          data: _weekData,
                          maxHint: 50000,
                          lineColor: navy,
                          fillTop: navy.withOpacity(.16),
                          fillBottom: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _AxisLabel('Mon'),
                          _AxisLabel('Tue'),
                          _AxisLabel('Wed'),
                          _AxisLabel('Thu'),
                          _AxisLabel('Fri'),
                          _AxisLabel('Sat'),
                          _AxisLabel('Sun'),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // === KPIs (same layout) ===
                _Card(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 10,
                  ),
                  child: Row(
                    children: [
                      _KpiMini(
                        title: 'Total Received',
                        value: _totalReceivedText,
                      ),
                      const _KpiDivider(),
                      _KpiMini(title: 'Top Donors', value: _topDonorsText),
                      const _KpiDivider(),
                      _KpiMini(title: 'Avg Gift', value: _avgGiftText),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // === Donation Frequency (now dynamic) ===
                _Card(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      _SectionHeader(
                        title: 'Donation Frequency',
                        subtitle: 'Share of donors',
                      ),
                      SizedBox(height: 8),
                    ],
                  ),
                ),
                _Card(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _StatChip(
                              title: 'Frequent',
                              value: _freqPct,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _StatChip(
                              title: 'Occasional',
                              value: _occPct,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _StatChip(title: 'One-time', value: _onePct),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Frequent = ≥1/mo · Occasional = 1–3/yr',
                        style: TextStyle(color: Colors.black54, fontSize: 11),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
    );
  }
}

/// ======= Widgets =======

class _Card extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  const _Card({required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  const _SectionHeader({required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    final titleStyle = const TextStyle(
      color: Color(0xFF0F2D50),
      fontSize: 18,
      fontWeight: FontWeight.w800,
      height: 1.1,
    );
    final subStyle = TextStyle(color: Colors.grey.shade600, fontSize: 12);
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: titleStyle),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(subtitle!, style: subStyle),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _KpiMini extends StatelessWidget {
  final String title;
  final String value;
  const _KpiMini({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _KpiDivider extends StatelessWidget {
  const _KpiDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 44,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: Colors.grey.shade200,
    );
  }
}

class _StatChip extends StatelessWidget {
  final String title;
  final String value;
  const _StatChip({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F2D50),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _AxisLabel extends StatelessWidget {
  final String text;
  const _AxisLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
    );
  }
}

/// ======= Chart =======

class _SparkAreaChart extends StatelessWidget {
  final List<double> data;
  final double maxHint; // e.g., 50000
  final Color lineColor;
  final Color fillTop;
  final Color fillBottom;

  const _SparkAreaChart({
    required this.data,
    required this.maxHint,
    required this.lineColor,
    required this.fillTop,
    required this.fillBottom,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _SparkAreaPainter(
        data: data,
        maxHint: maxHint,
        lineColor: lineColor,
        fillTop: fillTop,
        fillBottom: fillBottom,
        gridColor: Colors.grey.shade300,
      ),
    );
  }
}

class _SparkAreaPainter extends CustomPainter {
  final List<double> data;
  final double maxHint;
  final Color lineColor;
  final Color fillTop;
  final Color fillBottom;
  final Color gridColor;

  _SparkAreaPainter({
    required this.data,
    required this.maxHint,
    required this.lineColor,
    required this.fillTop,
    required this.fillBottom,
    required this.gridColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    // Grid (light, 4 horizontal lines)
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    const rows = 4;
    for (int r = 0; r <= rows; r++) {
      final dy = size.height / rows * r;
      canvas.drawLine(Offset(0, dy), Offset(size.width, dy), gridPaint);
    }

    // Build smooth path
    final maxVal = math.max(data.reduce(math.max), 1);
    final cap = math.max(maxHint, maxVal);
    final p = Path();
    for (int i = 0; i < data.length; i++) {
      final x = (size.width / (data.length - 1)) * i;
      final y = size.height - (data[i].clamp(0, cap) / cap) * size.height;
      if (i == 0) {
        p.moveTo(x, y);
      } else {
        final prevX = (size.width / (data.length - 1)) * (i - 1);
        final prevY =
            size.height - (data[i - 1].clamp(0, cap) / cap) * size.height;
        final c = (prevX + x) / 2;
        p.cubicTo(c, prevY, c, y, x, y);
      }
    }

    // Area fill
    final area = Path.from(p)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final shader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [fillTop, fillBottom],
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final fillPaint = Paint()..shader = shader;
    canvas.drawPath(area, fillPaint);

    // Line
    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(p, linePaint);
  }

  @override
  bool shouldRepaint(covariant _SparkAreaPainter old) {
    return old.data != data ||
        old.maxHint != maxHint ||
        old.lineColor != lineColor ||
        old.fillTop != fillTop ||
        old.fillBottom != fillBottom ||
        old.gridColor != gridColor;
  }
}
