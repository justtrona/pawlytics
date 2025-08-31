import 'package:flutter/material.dart';

class RewardsCertification extends StatefulWidget {
  const RewardsCertification({super.key});

  @override
  State<RewardsCertification> createState() => _RewardsCertificationState();
}

class _RewardsCertificationState extends State<RewardsCertification> {
  String selectedDonor = "John De Guzman";

  final List<String> donors = [
    "John De Guzman",
    "Maria Santos",
    "Pedro Dela Cruz",
  ];

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF0F2D50);
    const subtitle = Color(0xFF6E7B8A);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () => Navigator.pop(context),
          color: Colors.black87,
        ),
        title: const Text(
          "Rewards & Certification",
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        children: [
          // Dropdown for donor selection
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(10),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedDonor,
                icon: const Icon(Icons.arrow_drop_down),
                isExpanded: true,
                items: donors.map((String donor) {
                  return DropdownMenuItem<String>(
                    value: donor,
                    child: Text(
                      donor,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    selectedDonor = newValue!;
                  });
                },
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Donor Progress Title
          const Text(
            "Donor Progress",
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: navy,
            ),
          ),

          const SizedBox(height: 10),

          // Donor Progress Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                const Icon(Icons.emoji_events, size: 50, color: navy),
                const SizedBox(height: 8),
                const Text(
                  "Silver Certificate",
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: navy,
                  ),
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: 0.09,
                    minHeight: 14,
                    color: navy,
                    backgroundColor: Colors.grey.shade300,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "₱900 out of ₱10,000",
                  style: TextStyle(
                    fontSize: 14,
                    color: subtitle,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Donor Achievements Title
          const Text(
            "Donor Achievements",
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: navy,
            ),
          ),

          const SizedBox(height: 12),

          // Achievements Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: const [
                AchievementCard(
                  title: "Bronze Certificate",
                  subtitle: "Earned on March 12, 2026",
                  color: Colors.brown,
                  status: "earned",
                ),
                SizedBox(width: 12),
                AchievementCard(
                  title: "Silver Certificate",
                  subtitle: "Unlocked",
                  color: Colors.grey,
                  status: "unlocked",
                ),
                SizedBox(width: 12),
                AchievementCard(
                  title: "Gold Certificate",
                  subtitle: "Locked",
                  color: Colors.amber,
                  status: "locked",
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Achievement Card Widget
class AchievementCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color color;
  final String status;

  const AchievementCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    bool isUnlocked = status == "unlocked" || status == "earned";

    return Container(
      width: 140,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(Icons.emoji_events, size: 45, color: color),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: Color(0xFF0F2D50),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isUnlocked
                  ? Colors.green.withOpacity(0.1)
                  : Colors.grey.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isUnlocked ? Colors.green : Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
