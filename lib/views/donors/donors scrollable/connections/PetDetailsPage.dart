import 'package:flutter/material.dart';

class PetDetailPage extends StatelessWidget {
  final String name;
  final String image;
  final String breed;
  final String type;

  const PetDetailPage({
    super.key,
    required this.name,
    required this.image,
    required this.breed,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    // Example dynamic data (later can come from backend/db)
    final petInfo = {"ageGroup": "Senior", "species": type, "gender": "Male"};

    final statusTags = [
      {"label": "For Adoption", "icon": Icons.home},
      {"label": "Vaccination", "icon": Icons.vaccines},
      {"label": "Surgery", "icon": Icons.healing},
      {"label": "Needs Treatment", "icon": Icons.favorite},
      {"label": "Spay/Neuter", "icon": Icons.pets},
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Pet image
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                image,
                height: 220,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 16),

            // Pet name + Favorite
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2C47),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.star_border, size: 28),
                  color: const Color(0xFF1F2C47),
                  onPressed: () {},
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Basic info
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 3,
              children: [
                _buildMainTag(petInfo["ageGroup"]!),
                _buildMainTag(petInfo["species"]!),
                _buildMainTag(petInfo["gender"]!),
              ],
            ),
            const SizedBox(height: 12),

            // Status tags
            Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: statusTags.map((tag) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        tag["icon"] as IconData,
                        size: 16,
                        color: Colors.black,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        tag["label"] as String,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Pet description (could be dynamic too)
            Text(
              "$name is a lovely $breed $type looking for a forever home!",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Color(0xFF1F2C47)),
            ),
            const SizedBox(height: 20),

            // Donate button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1F2C47),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () {},
                child: const Text(
                  "Donate Me",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Progress bar with text
            Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: 3500 / 10000,
                    minHeight: 10,
                    backgroundColor: Colors.grey[300],
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF1F2C47),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "₱ 3,500 raised of ₱10,000",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1F2C47),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainTag(String text, {IconData? icon}) {
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
    );
  }
}
