import 'package:flutter/material.dart';
import 'dart:math';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: CampaignOutcomesPage(),
    );
  }
}

class CampaignOutcomesPage extends StatelessWidget {
  const CampaignOutcomesPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "Campaign Outcomes",
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const TextField(
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: "All Campaign...",
                  ),
                ),
              ),
              const SizedBox(height: 15),

              campaignCard(
                "Campaign A",
                "Active",
                "Jan 1 - Jan 22",
                trailing: statusButton(
                  "Successful",
                  const Color(0xFF1F2C47),
                  fontSize: 15,
                  padding: const EdgeInsets.all(10),
                ),
                alignWithStatus: true,
              ),
              const Divider(),

              campaignCard(
                "Campaign B",
                "Completed",
                "Dec 1 - Dec 22",
                trailing: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    statusButton(
                      "Implemented",
                      const Color(0xFF1F2C47),
                      fontSize: 15,
                      padding: const EdgeInsets.all(10),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Needs Improvement",
                      style: TextStyle(fontSize: 12, color: Color(0xFF1F2C47)),
                    ),
                  ],
                ),
                alignWithStatus: true,
              ),
              const Divider(),

              campaignCard(
                "Campaign C",
                "Active",
                "Jan 1 - Jan 22",
                trailing: const Text(
                  "12,341 people",
                  style: TextStyle(fontSize: 12, color: Color(0xFF1F2C47)),
                ),
                alignWithDate: true,
              ),
              const Divider(),

              const SizedBox(height: 15),
              const Text(
                "Campaign Outcomes",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text("Click-Through Rate   3.5%"),
                        Text("Conversion Rate       1.2%"),
                        Text("Donation Received   \$1,200"),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: SizedBox(
                      width: 150,
                      height: 150,
                      child: CustomPaint(
                        painter: PieChartPainter(
                          [20, 30, 50],
                          [Colors.grey, Colors.grey, Colors.grey],
                        ),
                      ),
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

  Widget campaignCard(
    String title,
    String status,
    String date, {
    Widget? trailing,
    bool alignWithStatus = false,
    bool alignWithDate = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(status),
              if (trailing != null && alignWithStatus) trailing,
            ],
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(date),
              if (trailing != null && alignWithDate) trailing,
            ],
          ),
        ],
      ),
    );
  }

  Widget statusButton(
    String text,
    Color color, {
    double fontSize = 12,
    EdgeInsets padding = const EdgeInsets.all(6),
  }) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: padding,
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      onPressed: () {},
      child: Text(
        text,
        style: TextStyle(color: Colors.white, fontSize: fontSize),
      ),
    );
  }
}

class PieChartPainter extends CustomPainter {
  final List<double> values;
  final List<Color> colors;

  PieChartPainter(this.values, this.colors);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2;
    double startAngle = -pi / 3;
    final total = values.fold(0.0, (t, v) => t + v);

    for (int i = 0; i < values.length; i++) {
      final sweepAngle = (values[i] / total) * 2 * pi;
      paint.color = colors[i % colors.length];

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );

      final midAngle = startAngle + sweepAngle / 2;
      final labelRadius = radius * 0.6;
      final labelX = center.dx + cos(midAngle) * labelRadius;
      final labelY = center.dy + sin(midAngle) * labelRadius;

      final label = '${values[i].toInt()}%';
      final textColor = paint.color.computeLuminance() > 0.6
          ? Colors.black
          : Colors.white;

      final tp = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(fontSize: 12, color: textColor),
        ),
        textDirection: TextDirection.ltr,
      );
      tp.layout();
      tp.paint(canvas, Offset(labelX - tp.width / 2, labelY - tp.height / 2));

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant PieChartPainter oldDelegate) {
    return oldDelegate.values != values || oldDelegate.colors != colors;
  }
}
