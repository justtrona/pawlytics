import 'package:flutter/material.dart';

class TransactionsPage extends StatelessWidget {
  const TransactionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          "History",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2C47),
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildHistoryCard(
              Icons.volunteer_activism,
              "Donated to Local Shelter",
              "Amount ₱1,050",
              "June 10",
            ),
            const SizedBox(height: 20),
            _buildHistoryCard(Icons.pets, "Adopted Mittens", "Cat", "May 16"),
            const SizedBox(height: 20),
            _buildHistoryCard(
              Icons.home,
              "Adopted to Local Shelter",
              "Dog",
              "May 11",
            ),
            const SizedBox(height: 20),
            _buildHistoryCard(
              Icons.volunteer_activism,
              "Donated to Local Shelter",
              "Amount ₱500",
              "April 30",
            ),
            const SizedBox(height: 20),
            _buildHistoryCard(
              Icons.home,
              "Adopted to Local Shelter",
              "Dog",
              "March 10",
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryCard(
    IconData icon,
    String title,
    String subtitle,
    String date,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 40, color: Colors.black87),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    height: 1.3,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          Text(
            date,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black87,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
