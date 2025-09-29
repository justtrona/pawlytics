import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MyDonationPage(),
    );
  }
}

class MyDonationPage extends StatefulWidget {
  const MyDonationPage({super.key});

  @override
  State<MyDonationPage> createState() => _MyDonationPageState();
}

class _MyDonationPageState extends State<MyDonationPage> {
  String selectedFilter = "Weekly";

  final List<Map<String, String>> donations = [
    {"type": "Cash", "amount": "2000.00", "date": "06/22/25"},
    {"type": "Cash", "amount": "500.00", "date": "06/03/25"},
    {"type": "Cash", "amount": "1000.00", "date": "05/15/25"},
    {"type": "Cash", "amount": "1500.00", "date": "01/10/25"},
  ];

  List<Map<String, String>> get filteredDonations {
    if (selectedFilter == "Weekly") {
      return donations.where((d) => d["date"]!.startsWith("06/22")).toList();
    } else if (selectedFilter == "Monthly") {
      return donations.where((d) => d["date"]!.startsWith("06/")).toList();
    } else if (selectedFilter == "Yearly") {
      return donations.where((d) => d["date"]!.endsWith("/25")).toList();
    }
    return donations;
  }

  double get totalBalance {
    return filteredDonations.fold(
      0.0,
      (sum, d) => sum + double.parse(d["amount"]!),
    );
  }

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
          "Donation History",
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                filterButton("Weekly"),
                const SizedBox(width: 8),
                filterButton("Monthly"),
                const SizedBox(width: 8),
                filterButton("Yearly"),
              ],
            ),
            const SizedBox(height: 16),

            // Total Balance
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: const Color(0xFF1F2C47),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  const Text(
                    "Total Balance",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "PHP ${totalBalance.toStringAsFixed(2)}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Donations List
            Expanded(
              child: filteredDonations.isEmpty
                  ? const Center(child: Text("No donations found."))
                  : ListView.separated(
                      itemCount: filteredDonations.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final donation = filteredDonations[index];
                        return donationCard(
                          donation["type"]!,
                          "PHP ${donation["amount"]!}",
                          donation["date"]!,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget filterButton(String label) {
    final bool isSelected = selectedFilter == label;
    return Expanded(
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected
              ? const Color(0xFF1F2C47)
              : Colors.grey[200],
          foregroundColor: isSelected ? Colors.white : Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        onPressed: () {
          setState(() {
            selectedFilter = label;
          });
        },
        child: Text(label),
      ),
    );
  }

  Widget donationCard(String type, String amount, String date) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          rowText("Donation Type", type),
          const SizedBox(height: 4),
          rowText("Amount Donated", amount),
          const SizedBox(height: 4),
          rowText("Date Donated", date),
        ],
      ),
    );
  }

  Widget rowText(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: Colors.black54),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
