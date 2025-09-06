import 'package:flutter/material.dart';

class UtilitiesPage extends StatelessWidget {
  const UtilitiesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
        title: const Text(
          "Utilities",
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
            TextField(
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
            ),
            const SizedBox(height: 20),

            Expanded(
              child: ListView(
                children: [
                  _buildUtilityCard(
                    icon: Icons.water_drop_outlined,
                    title: "Water",
                    status: "Low Stock",
                    deadline: "July 23, 2025",
                    total: 3500,
                    raised: 800,
                  ),
                  _buildUtilityCard(
                    icon: Icons.flash_on_outlined,
                    title: "Electricity",
                    status: "Low Stock",
                    deadline: "July 31, 2025",
                    total: 5000,
                    raised: 1000,
                  ),
                  _buildUtilityCard(
                    icon: Icons.local_drink_outlined,
                    title: "Drinking Water",
                    status: "Low Stock",
                    deadline: "July 31, 2025",
                    total: 2000,
                    raised: 1000,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUtilityCard({
    required IconData icon,
    required String title,
    required String status,
    required String deadline,
    required int total,
    required int raised,
  }) {
    double progress = raised / total;

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, size: 30, color: const Color(0xFF1F2C47)),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        status,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF1F2C47),
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

          const SizedBox(height: 12),

          // Estimated needs
          Center(
            child: Text(
              "Est. PHP $total needed",
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),

          const SizedBox(height: 6),

          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey.shade300,
              color: const Color(0xFF1F2C47),
              minHeight: 8,
            ),
          ),

          const SizedBox(height: 6),

          Center(
            child: Text(
              "Php $raised of Php $total",
              style: const TextStyle(fontSize: 12, color: Color(0xFF1F2C47)),
            ),
          ),

          const SizedBox(height: 12),

          Center(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1F2C47),
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {},
              child: const Text(
                "DONATE",
                style: TextStyle(
                  fontSize: 14,
                  color: Color.fromARGB(255, 229, 230, 232),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
