import 'package:flutter/material.dart';

class RecommendationPage extends StatelessWidget {
  const RecommendationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
        title: const Text(
          "Recommendation",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2C47),
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              "Matched with your interest in small breeds\nand recent donation activity.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF1F2C47), fontSize: 14),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.pets, size: 25, color: Color(0xFF1F2C47)),
                SizedBox(width: 8),
                Text(
                  "Your Preferences",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2C47),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildPetCard(
              context,
              imagePath: "assets/images/donors/peter.png",
              name: "Peter",
              description: "Shy but sweet",
              tags: const ["Healthy", "Small Breed"],
            ),
            _buildPetCard(
              context,
              imagePath: "assets/images/donors/max.png",
              name: "Max",
              description: "Energetic and playful",
              tags: const ["Healthy", "Senior"],
            ),
            _buildPetCard(
              context,
              imagePath: "assets/images/donors/luna.png",
              name: "Luna",
              description: "Gentle",
              tags: const ["Healthy", "Juvenile"],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPetCard(
    BuildContext context, {
    required String imagePath,
    required String name,
    required String description,
    required List<String> tags,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey.shade200,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            spreadRadius: 2,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              bottomLeft: Radius.circular(12),
            ),
            child: Image.asset(
              imagePath,
              width: 200,
              height: 200,
              fit: BoxFit.cover,
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Icon(Icons.star_border, color: Color(0xFF1F2C47)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2C47),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 30,
                    runSpacing: 4,
                    children: tags
                        .map(
                          (tag) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 1,
                              vertical: 4,
                            ),
                            child: Text(
                              tag,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1F2C47),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 88,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {},
                      child: const Text(
                        "View",
                        style: TextStyle(
                          fontSize: 20,
                          color: Color.fromARGB(255, 209, 211, 214),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
