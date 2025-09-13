import 'package:flutter/material.dart';

class ViewMorePage extends StatelessWidget {
  const ViewMorePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
          "Shelter Update",
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                filterButton("Weekly", true),
                const SizedBox(width: 8),
                filterButton("Monthly", false),
                const SizedBox(width: 8),
                filterButton("Yearly", false),
              ],
            ),
            const SizedBox(height: 16),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              decoration: BoxDecoration(
                color: Color(0xFF1F2C47),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.volunteer_activism, color: Colors.white, size: 50),
                  SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Total Donations",
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                      SizedBox(height: 4),
                      Text(
                        "PHP 2,500.00",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            Expanded(
              child: ListView(
                children: [
                  donationCard(
                    petName: "Peter",
                    purpose: "Vaccination",
                    fundType: "PHP 1,500.00",
                    date: "July 29, 2025",
                    time: "9:00 AM",
                  ),
                  const SizedBox(height: 12),
                  donationCard(
                    petName: "Max",
                    purpose: "1x Deworming Kit",
                    fundType: "In-Kind",
                    date: "July 25, 2025",
                    time: "8:00 AM",
                  ),
                  const SizedBox(height: 12),
                  donationCard(
                    petName: "Luna",
                    purpose: "Vaccination",
                    fundType: "Antibiotics",
                    date: "July 22, 2025",
                    time: "3:00 PM",
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget filterButton(String label, bool isSelected) {
    return Expanded(
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? Color(0xFF1F2C47) : Colors.grey[200],
          foregroundColor: isSelected ? Colors.white : Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        onPressed: () {},
        child: Text(label),
      ),
    );
  }

  static Widget donationCard({
    required String petName,
    required String purpose,
    required String fundType,
    required String date,
    required String time,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            spreadRadius: 1,
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          infoRow("Pet Name", petName),
          const SizedBox(height: 4),
          infoRow("Fund Purpose", purpose),
          const SizedBox(height: 4),
          infoRow("Fund Type", fundType),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.bottomRight,
            child: Text(
              "$date\n$time",
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 13, color: Color(0xFF1F2C47)),
            ),
          ),
        ],
      ),
    );
  }

  static Widget infoRow(String label, String value) {
    return RichText(
      text: TextSpan(
        text: "$label: ",
        style: const TextStyle(fontSize: 14, color: Color(0xFF1F2C47)),
        children: [
          TextSpan(
            text: value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2C47),
            ),
          ),
        ],
      ),
    );
  }
}
