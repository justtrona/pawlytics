import 'package:flutter/material.dart';

class DonorsAnalytics extends StatefulWidget {
  const DonorsAnalytics({super.key});

  @override
  State<DonorsAnalytics> createState() => _DonorsAnalyticsState();
}

class _DonorsAnalyticsState extends State<DonorsAnalytics> {
  // Sample weekly data (in PHP)
  final List<double> _weekData = const [
    4200,
    3800,
    7000,
    3000,
    6200,
    4100,
    5900,
  ];

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF0F2D50);
    const lightNavy = Color(0xFF173A63);
    const subtitle = Color(0xFF6E7B8A);

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
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        children: [
          // Chart card
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionTitle(''),
                AspectRatio(
                  aspectRatio: 1.6,
                  child: CustomPaint(
                    painter: _GridChartPainter(
                      data: _weekData,
                      gridColor: Colors.grey.shade300,
                      lineColor: lightNavy,
                    ),
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
                const SizedBox(height: 4),
                // Y-axis captions
                Row(
                  children: const [
                    _YTick('₱0'),
                    Spacer(),
                    _YTick('₱15,000'),
                    Spacer(),
                    _YTick('₱30,000'),
                    Spacer(),
                    _YTick('₱50,000'),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // KPI 3-up
          _Card(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              children: const [
                _KpiTile(
                  titleTop: 'Total Donation',
                  titleBottom: 'This Month',
                  value: 'PHP 1,500.00',
                ),
                _VerticalDivider(),
                _KpiTile(
                  titleTop: 'Top',
                  titleBottom: 'Donor',
                  value: 'John De Guzman',
                ),
                _VerticalDivider(),
                _KpiTile(
                  titleTop: 'Average',
                  titleBottom: 'Donation',
                  value: 'PHP 25.00',
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Donation Frequency
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                _SectionTitle('Donation Frequency'),
                SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: _PillStat(
                        headline: 'Frequent\nDonors',
                        percent: '45%',
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: _PillStat(
                        headline: 'Occasional\nDonors',
                        percent: '30%',
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: _PillStat(
                        headline: 'One time\nDonors',
                        percent: '25%',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

/// Reusable card container
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
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: child,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFF0F2D50),
        fontSize: 20,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

/// KPI Column
class _KpiTile extends StatelessWidget {
  final String titleTop;
  final String titleBottom;
  final String value;

  const _KpiTile({
    required this.titleTop,
    required this.titleBottom,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final subtle = Colors.grey.shade600;
    return Expanded(
      child: Column(
        children: [
          Text(
            '$titleTop\n$titleBottom',
            textAlign: TextAlign.center,
            style: TextStyle(color: subtle, fontSize: 12, height: 1.2),
          ),
          const SizedBox(height: 8),
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

class _VerticalDivider extends StatelessWidget {
  const _VerticalDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 52,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: Colors.grey.shade200,
    );
  }
}

class _PillStat extends StatelessWidget {
  final String headline;
  final String percent;

  const _PillStat({required this.headline, required this.percent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F2D50),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.08),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            headline,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              height: 1.1,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              percent,
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

class _YTick extends StatelessWidget {
  final String label;
  const _YTick(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
    );
  }
}

/// Simple grid + polyline painter for the chart
class _GridChartPainter extends CustomPainter {
  final List<double> data;
  final Color gridColor;
  final Color lineColor;

  _GridChartPainter({
    required this.data,
    required this.gridColor,
    required this.lineColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;

    // Draw grid (5 horizontal, 5 vertical)
    const rows = 5;
    const cols = 5;

    for (int r = 0; r <= rows; r++) {
      final dy = size.height / rows * r;
      canvas.drawLine(Offset(0, dy), Offset(size.width, dy), gridPaint);
    }
    for (int c = 0; c <= cols; c++) {
      final dx = size.width / cols * c;
      canvas.drawLine(Offset(dx, 0), Offset(dx, size.height), gridPaint);
    }

    if (data.isEmpty) return;

    // Normalize data to the canvas height (assume max 50k)
    const maxValue = 50000.0;
    final line = Paint()
      ..color = lineColor
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();

    for (int i = 0; i < data.length; i++) {
      final x = (size.width / (data.length - 1)) * i;
      final y =
          size.height - (data[i].clamp(0, maxValue) / maxValue) * size.height;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        // smooth-ish curve
        final prevX = (size.width / (data.length - 1)) * (i - 1);
        final prevY =
            size.height -
            (data[i - 1].clamp(0, maxValue) / maxValue) * size.height;
        final controlX = (prevX + x) / 2;
        path.cubicTo(controlX, prevY, controlX, y, x, y);
      }
    }

    // Shadow under the line
    final shadow = Paint()
      ..color = lineColor.withOpacity(0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    canvas.drawPath(path, shadow);
    canvas.drawPath(path, line);
  }

  @override
  bool shouldRepaint(covariant _GridChartPainter oldDelegate) {
    return oldDelegate.data != data ||
        oldDelegate.gridColor != gridColor ||
        oldDelegate.lineColor != lineColor;
  }
}
