import 'package:flutter/material.dart';

class GoalPage extends StatefulWidget {
  const GoalPage({super.key});

  @override
  State<GoalPage> createState() => _GoalPageState();
}

class _GoalPageState extends State<GoalPage> {
  final TextEditingController _searchController = TextEditingController();

  // Example breakdown data
  final List<Map<String, dynamic>> _utilities = [
    {
      "icon": Icons.water_drop_outlined,
      "title": "Water",
      "status": "Low Stock",
      "deadline": "July 23, 2025",
      "total": 3500,
      "raised": 800,
    },
    {
      "icon": Icons.flash_on_outlined,
      "title": "Electricity",
      "status": "Low Stock",
      "deadline": "July 31, 2025",
      "total": 5000,
      "raised": 1000,
    },
    {
      "icon": Icons.local_drink_outlined,
      "title": "Drinking Water",
      "status": "Low Stock",
      "deadline": "July 31, 2025",
      "total": 2000,
      "raised": 1000,
    },
  ];

  String _searchQuery = "";

  @override
  Widget build(BuildContext context) {
    // Filter utilities based on search query
    final filteredUtilities = _utilities.where((item) {
      final title = (item["title"] as String).toLowerCase();
      return title.contains(_searchQuery.toLowerCase());
    }).toList();

    // Calculate total goal and raised from filtered list
    final int totalGoal = filteredUtilities.fold(
      0,
      (sum, item) => sum + (item["total"] as int),
    );
    final int totalRaised = filteredUtilities.fold(
      0,
      (sum, item) => sum + (item["raised"] as int),
    );

    final double overallProgress = totalGoal > 0
        ? totalRaised / totalGoal
        : 0.0;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          "Goals",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2C47),
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Search bar
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Search Utility Needs",
                hintStyle: const TextStyle(color: Colors.grey),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.grey.shade200,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 0,
                  horizontal: 16,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
            const SizedBox(height: 20),

            // Overall progress goal (for filtered list)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Overall Goal",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2C47),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      "Php $totalRaised of Php $totalGoal",
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: overallProgress,
                      backgroundColor: Colors.grey.shade300,
                      color: const Color(0xFF1F2C47),
                      minHeight: 12,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Breakdown list (filtered by search)
            Expanded(
              child: filteredUtilities.isEmpty
                  ? const Center(
                      child: Text(
                        "No utilities found",
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: filteredUtilities.length,
                      itemBuilder: (context, index) {
                        final item = filteredUtilities[index];
                        return _buildBreakdownCard(
                          icon: item["icon"],
                          title: item["title"],
                          status: item["status"],
                          deadline: item["deadline"],
                          total: item["total"],
                          raised: item["raised"],
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBreakdownCard({
    required IconData icon,
    required String title,
    required String status,
    required String deadline,
    required int total,
    required int raised,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title + Deadline
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, size: 28, color: const Color(0xFF1F2C47)),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        status,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Text(
                "Needed by $deadline",
                style: const TextStyle(fontSize: 12, color: Color(0xFF1F2C47)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            "Est. Php $total needed",
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 6),
          Text(
            "Php $raised of Php $total",
            style: const TextStyle(fontSize: 12, color: Color(0xFF1F2C47)),
          ),
        ],
      ),
    );
  }
}
