import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pawlytics/views/admin/admin_widgets/stats-grid.dart';
import 'package:pawlytics/route/route.dart' as route;

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  static const brandColor = Color(0xA627374D);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 90),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: brandColor,
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
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Admin12345",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              "Staff - Admin",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Image.asset(
                          "assets/images/small_logo.png",
                          width: 50,
                          height: 50,
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
                    const Center(
                      child: Text(
                        "PHP 1,500.00",
                        style: TextStyle(
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
                        children: const [
                          _KeyValueSmall(title: "Today", value: "PHP 100.00"),
                          _KeyValueSmall(
                            title: "This Month",
                            value: "PHP 12,500.00",
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Center(
                      child: SizedBox(
                        width: 200,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xff27374d),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          onPressed: () => Navigator.pushNamed(
                            context,
                            route.donationReports,
                          ),
                          child: const Text(
                            "Manage Donations",
                            style: TextStyle(
                              fontSize: 17,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Container(
                height: 200,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.grey.shade100,
                ),
                padding: const EdgeInsets.all(12),
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(show: true),
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, _) {
                            const days = [
                              "Mon",
                              "Tue",
                              "Wed",
                              "Thu",
                              "Fri",
                              "Sat",
                              "Sun",
                            ];
                            return Text(days[value.toInt() % 7]);
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        isCurved: true,
                        spots: const [
                          FlSpot(0, 20),
                          FlSpot(1, 40),
                          FlSpot(2, 25),
                          FlSpot(3, 60),
                          FlSpot(4, 80),
                          FlSpot(5, 50),
                          FlSpot(6, 70),
                        ],
                        barWidth: 3,
                        color: brandColor,
                        dotData: FlDotData(show: false),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const StatsGrid(),
              const SizedBox(height: 12),
              _CardListSection(
                title: "Latest Donations",
                items: const [
                  _Item("Francis M.", "PHP 25.00"),
                  _Item("John D.", "PHP 50.00"),
                  _Item("Mary A.", "PHP 10.00"),
                  _Item("Lucas C.", "PHP 500.00"),
                  _Item("Luke M.", "PHP 150.00"),
                  _Item("Maine Q.", "PHP 50.00"),
                ],
              ),
              const SizedBox(height: 12),
              _CardListSection(
                title: "Top Campaigns",
                items: const [
                  _Item("Honey's Medical Bills", "PHP 1000.00"),
                  _Item("Utilities", "PHP 500.00"),
                  _Item("Stray Dogs Meals", "PHP 500.00"),
                  _Item("Shelters’ Food & Water", "PHP 5500.00"),
                  _Item("Honorarium", "PHP 3120.00"),
                  _Item("Emergency Medical Fund", "PHP 4890.00"),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// methods below

class _KeyValueSmall extends StatefulWidget {
  final String title;
  final String value;
  const _KeyValueSmall({required this.title, required this.value});

  @override
  State<_KeyValueSmall> createState() => _KeyValueSmallState();
}

class _KeyValueSmallState extends State<_KeyValueSmall> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.title,
          style: const TextStyle(fontSize: 15, color: Colors.white70),
        ),
        Text(
          widget.value,
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
                        item.right,
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
