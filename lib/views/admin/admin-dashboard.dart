import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pawlytics/views/admin/admin-menu.dart';
import 'package:pawlytics/views/admin/admin_widgets/stats-grid.dart';
import 'package:pawlytics/route/route.dart' as route;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math' as math;

// NEW: shared controller
import 'package:provider/provider.dart';
import 'package:pawlytics/views/admin/controllers/operational-expense-controller.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  static const brandColor = Color.fromARGB(255, 15, 45, 80);

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  // ----- Admin identity (new) -----
  String _adminName = 'Admin';
  String _adminEmail = '';

  // ----- Live state -----
  double _todayTotalNum = 0.0;
  double _monthTotalNum = 0.0;

  String get _todayTotal => _formatCurrency(_todayTotalNum);
  String get _monthTotal => _formatCurrency(_monthTotalNum);

  List<double> _weekTotals = const [0, 0, 0, 0, 0, 0, 0];
  List<String> _weekLabels = const [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  List<_DonationRowData> _latestDonationRows = const [];

  // Top campaigns (dynamic)
  List<_SimpleCampaign> _topCampaigns = const [];

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OperationalExpenseController>().loadAllocations();
      _loadAdminIdentity();
      _loadDashboard();
    });
  }

  Future<void> _loadAdminIdentity() async {
    try {
      final sb = Supabase.instance.client;
      final user = sb.auth.currentUser;
      if (user == null) return;

      final row = await sb
          .from('registration')
          .select('fullName,email')
          .eq('id', user.id)
          .maybeSingle();

      final fullName = (row?['fullName'] ?? '').toString().trim();
      final emailFromReg = (row?['email'] ?? '').toString().trim();
      final emailFallback = (user.email ?? '').trim();

      setState(() {
        _adminName = fullName.isNotEmpty
            ? fullName
            : (emailFromReg.isNotEmpty
                  ? emailFromReg.split('@').first
                  : (emailFallback.isNotEmpty
                        ? emailFallback.split('@').first
                        : 'Admin'));
        _adminEmail = emailFromReg.isNotEmpty ? emailFromReg : emailFallback;
      });
    } catch (_) {}
  }

  Future<void> _loadDashboard() async {
    try {
      final sb = Supabase.instance.client;

      // Today
      final now = DateTime.now();
      final dayStart = DateTime(now.year, now.month, now.day);
      final todayRows = await sb
          .from('donations')
          .select('amount')
          .gte('donation_date', dayStart.toIso8601String());
      final today = (todayRows as List)
          .map((r) => (r['amount'] as num?)?.toDouble() ?? 0.0)
          .fold<double>(0.0, (a, b) => a + b);

      // This month
      final monthStart = DateTime(now.year, now.month);
      final monthRows = await sb
          .from('donations')
          .select('amount')
          .gte('donation_date', monthStart.toIso8601String());
      final month = (monthRows as List)
          .map((r) => (r['amount'] as num?)?.toDouble() ?? 0.0)
          .fold<double>(0.0, (a, b) => a + b);

      // Last 7 days
      final since7 = dayStart.subtract(const Duration(days: 6));
      final weekRows = await sb
          .from('donations')
          .select('donation_date, amount')
          .gte('donation_date', since7.toIso8601String());

      final keys = <DateTime>[];
      final buckets = <String, double>{};
      final labels = <String>[];
      const wd = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

      for (int i = 0; i < 7; i++) {
        final d = since7.add(Duration(days: i));
        keys.add(d);
        final k = _dateKey(d);
        buckets[k] = 0.0;
        labels.add(wd[d.weekday - 1]);
      }

      for (final r in (weekRows as List)) {
        final ts = r['donation_date'] as String?;
        final amt = (r['amount'] as num?)?.toDouble() ?? 0.0;
        if (ts == null) continue;
        final dt = DateTime.tryParse(ts);
        if (dt == null) continue;
        final k = _dateKey(DateTime(dt.year, dt.month, dt.day));
        if (buckets.containsKey(k)) buckets[k] = (buckets[k] ?? 0) + amt;
      }
      final weekTotals = keys.map((d) => buckets[_dateKey(d)] ?? 0.0).toList();

      // Latest donations
      final lastRows = await sb
          .from('donations')
          .select(
            'donor_name, amount, donation_type, item, quantity, donation_date',
          )
          .order('donation_date', ascending: false)
          .limit(6);

      final latestRows = (lastRows as List)
          .map<_DonationRowData>((r) {
            final donor =
                ((r['donor_name'] as String?)?.trim().isNotEmpty ?? false)
                ? (r['donor_name'] as String).trim()
                : 'Anonymous';
            final amount = (r['amount'] as num?)?.toDouble() ?? 0.0;
            final type = (r['donation_type'] as String?)?.trim() ?? 'Cash';
            final item = (r['item'] as String?)?.trim();
            final qty = r['quantity'] is int
                ? r['quantity'] as int?
                : (r['quantity'] as num?)?.toInt();

            return _DonationRowData(
              donor: donor,
              type: type,
              amount: amount,
              item: item,
              quantity: qty,
            );
          })
          .toList(growable: false);

      // Top campaigns (latest 6)
      final campRows = await sb
          .from('campaigns')
          .select('program,fundraising_goal,currency,created_at')
          .order('created_at', ascending: false)
          .limit(6);

      final topCamps = (campRows as List)
          .map<_SimpleCampaign>((r) {
            final name = (r['program'] ?? '').toString().trim();
            final currency = (r['currency'] ?? 'PHP')
                .toString()
                .trim()
                .toUpperCase();
            final goal = (r['fundraising_goal'] is num)
                ? (r['fundraising_goal'] as num).toDouble()
                : double.tryParse('${r['fundraising_goal']}') ?? 0.0;
            return _SimpleCampaign(
              program: name.isEmpty ? 'Campaign' : name,
              goal: goal,
              currency: currency,
            );
          })
          .toList(growable: false);

      setState(() {
        _todayTotalNum = today;
        _monthTotalNum = month;
        _weekTotals = weekTotals;
        _weekLabels = labels;
        _latestDonationRows = latestRows;
        _topCampaigns = topCamps;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _todayTotalNum = 0.0;
        _monthTotalNum = 0.0;
        _weekTotals = const [0, 0, 0, 0, 0, 0, 0];
        _weekLabels = const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        _latestDonationRows = const [];
        _topCampaigns = const [];
        _loading = false;
      });
    }
  }

  // ---------------- helpers ----------------

  static String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  // Keeps PHP for the big cards & chart tooltips
  String _formatCurrency(double v) =>
      'PHP ${v.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\\d)(?=(\\d{3})+\\.)'), (m) => '${m[1]},')}';

  // Plain number (no currency) for Top Campaigns list
  String _formatMoneyPlain(double v) => v
      .toStringAsFixed(2)
      .replaceAllMapped(RegExp(r'(\\d)(?=(\\d{3})+\\.)'), (m) => '${m[1]},');

  // Formats with per-row currency but returns PLAIN number only (as requested)
  String _formatCurrencyAny(double v, [String? _]) => _formatMoneyPlain(v);

  double _niceMax(double v) {
    if (v <= 100) return (v / 25).ceil() * 25.0;
    if (v <= 1000) return (v / 100).ceil() * 100.0;
    if (v <= 5000) return (v / 500).ceil() * 500.0;
    if (v <= 10000) return (v / 1000).ceil() * 1000.0;
    return (v / 2000).ceil() * 2000.0;
  }

  String _moneyShort(double v) {
    if (v >= 1000000)
      return '₱${(v / 1000000).toStringAsFixed(v % 1000000 == 0 ? 0 : 1)}M';
    if (v >= 1000)
      return '₱${(v / 1000).toStringAsFixed(v % 1000 == 0 ? 0 : 1)}k';
    return '₱${v.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<OperationalExpenseController>();
    final totalExpensesThisMonth = c.totalExpensesThisMonth;
    final remainingNum = _monthTotalNum - totalExpensesThisMonth;
    final remainingStr = _formatCurrency(remainingNum);

    final double yRawMax = _weekTotals.isEmpty
        ? 0.0
        : _weekTotals.reduce(math.max);
    final double yMax = _niceMax(math.max(yRawMax, 1.0));
    final double yInterval = math.max(yMax / 4.0, 1.0);

    return Scaffold(
      backgroundColor: Colors.white,
      endDrawer: Drawer(child: menuBar()),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 90),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // -------- Top balance card --------
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: AdminDashboard.brandColor,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(50),
                    bottomRight: Radius.circular(50),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: () =>
                              Navigator.pushNamed(context, route.adminProfile),
                          style: ElevatedButton.styleFrom(
                            shape: const CircleBorder(),
                            padding: EdgeInsets.zero,
                            backgroundColor: Colors.transparent,
                            elevation: 0,
                          ),
                          child: const CircleAvatar(
                            radius: 25,
                            backgroundImage: AssetImage(
                              "assets/images/avatar.png",
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _adminName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              _adminEmail.isEmpty ? ' ' : _adminEmail,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Builder(
                          builder: (innerCtx) => IconButton(
                            icon: const Icon(
                              Icons.menu_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                            onPressed: () =>
                                Scaffold.of(innerCtx).openEndDrawer(),
                            tooltip: 'Open menu',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Center(
                      child: Text(
                        "Remaining Funds",
                        style: TextStyle(fontSize: 14, color: Colors.white70),
                      ),
                    ),
                    Center(
                      child: Text(
                        remainingStr,
                        style: const TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.all(15.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _KeyValueSmall(title: "Today", value: _todayTotal),
                          _KeyValueSmall(
                            title: "This Month",
                            value: _monthTotal,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // -------- Line chart (7-day totals) --------
              Container(
                height: 220,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.grey.shade100,
                ),
                padding: const EdgeInsets.all(12),
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : LineChart(
                        LineChartData(
                          minX: 0.0,
                          maxX: 6.0,
                          minY: 0.0,
                          maxY: yMax,
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: true,
                            horizontalInterval: yInterval,
                            verticalInterval: 1.0,
                            getDrawingHorizontalLine: (v) => FlLine(
                              color: Colors.grey.shade300,
                              strokeWidth: 1,
                            ),
                            getDrawingVerticalLine: (v) => FlLine(
                              color: Colors.grey.shade200,
                              strokeWidth: 1,
                            ),
                          ),
                          titlesData: FlTitlesData(
                            topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 46,
                                interval: yInterval,
                                getTitlesWidget: (value, _) => Text(
                                  _moneyShort(value),
                                  style: const TextStyle(fontSize: 11),
                                ),
                              ),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                interval: 1.0,
                                getTitlesWidget: (value, _) {
                                  final i = value.toInt();
                                  if (i < 0 || i > 6) return const SizedBox();
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Text(
                                      _weekLabels[i],
                                      style: const TextStyle(fontSize: 11),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          lineTouchData: LineTouchData(
                            enabled: true,
                            touchTooltipData: LineTouchTooltipData(
                              tooltipBgColor: Colors.black87,
                              getTooltipItems: (touched) => touched
                                  .map(
                                    (s) => LineTooltipItem(
                                      '${_weekLabels[s.x.toInt()]}\n${_formatCurrency(s.y)}',
                                      const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                          lineBarsData: [
                            LineChartBarData(
                              isCurved: true,
                              preventCurveOverShooting: true,
                              spots: List.generate(
                                7,
                                (i) => FlSpot(i.toDouble(), _weekTotals[i]),
                              ),
                              barWidth: 3,
                              color: AdminDashboard.brandColor,
                              dotData: FlDotData(
                                show: true,
                                getDotPainter: (s, _, __, ___) =>
                                    FlDotCirclePainter(
                                      radius: 3.5,
                                      color: AdminDashboard.brandColor,
                                      strokeColor: Colors.white,
                                      strokeWidth: 2,
                                    ),
                              ),
                              belowBarData: BarAreaData(
                                show: true,
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    AdminDashboard.brandColor.withOpacity(.22),
                                    AdminDashboard.brandColor.withOpacity(0.0),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
              ),

              const SizedBox(height: 20),

              const StatsGrid(),

              const SizedBox(height: 12),

              _LatestDonationsSection(items: _latestDonationRows),

              const SizedBox(height: 12),

              // ---- Dynamic Top Campaigns (NO PHP label) ----
              _CardListSection(
                title: "Top Campaigns",
                items: _topCampaigns
                    .map(
                      (c) => _Item(
                        c.program,
                        _formatCurrencyAny(
                          c.goal,
                          c.currency,
                        ), // returns plain number
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
      ),

      floatingActionButton: SizedBox(
        width: 200,
        height: 55,
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0F2D50), Color(0xFFEC8C69)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              stops: [0.3, 1.0],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 6,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            onPressed: () =>
                Navigator.pushNamed(context, route.donationReports),
            child: const Text(
              "Show Reports",
              style: TextStyle(
                fontSize: 17,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

// -------------------------------------------------------------------
// Helper models & widgets
// -------------------------------------------------------------------

class _SimpleCampaign {
  final String program;
  final double goal;
  final String currency;
  _SimpleCampaign({
    required this.program,
    required this.goal,
    required this.currency,
  });
}

class _DonationRowData {
  final String donor;
  final String type; // 'Cash' or 'InKind'
  final double amount;
  final String? item;
  final int? quantity;
  const _DonationRowData({
    required this.donor,
    required this.type,
    required this.amount,
    this.item,
    this.quantity,
  });
}

class _LatestDonationsSection extends StatelessWidget {
  final List<_DonationRowData> items;
  const _LatestDonationsSection({required this.items});

  // NO PHP label here — plain number
  String _formatMoneyPlain(double v) => v
      .toStringAsFixed(2)
      .replaceAllMapped(RegExp(r'(\\d)(?=(\\d{3})+\\.)'), (m) => '${m[1]},');

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
            child: const Text(
              "Latest Donations",
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
          ),
          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: Text(
                'No data yet',
                style: TextStyle(color: Colors.black54),
              ),
            )
          else
            ...List.generate(items.length, (index) {
              final it = items[index];
              final isInKind = it.type.toLowerCase() == 'inkind';
              final pillText = isInKind ? 'IN-KIND' : 'CASH';
              final pillColor = isInKind
                  ? const Color(0xFFEC8C69)
                  : const Color(0xFF0F2D50);
              final subtitle = isInKind
                  ? ((it.quantity ?? 0) > 0 && (it.item ?? '').isNotEmpty
                        ? '${it.quantity} × ${it.item}'
                        : (it.item ?? 'In-kind'))
                  : 'Cash';
              final isLast = index == items.length - 1;

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: pillColor.withOpacity(.12),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: pillColor.withOpacity(.6),
                            ),
                          ),
                          child: Text(
                            pillText,
                            style: TextStyle(
                              color: pillColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: .4,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                it.donor,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                subtitle,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          _formatMoneyPlain(it.amount), // no PHP
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isLast) const Divider(height: 1),
                ],
              );
            }),
        ],
      ),
    );
  }
}

class _KeyValueSmall extends StatelessWidget {
  final String title;
  final String value;
  const _KeyValueSmall({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 15, color: Colors.white70),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

class _Item {
  final String left;
  final String right;
  const _Item(this.left, this.right);
}

class _CardListSection extends StatelessWidget {
  final String title;
  final List<_Item> items;

  const _CardListSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
          ),
          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: Text(
                'No data yet',
                style: TextStyle(color: Colors.black54),
              ),
            )
          else
            ...List.generate(items.length, (index) {
              final item = items[index];
              final isLast = index == items.length - 1;
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            item.left,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          item.right, // already plain number
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isLast) const Divider(height: 1),
                ],
              );
            }),
        ],
      ),
    );
  }
}
