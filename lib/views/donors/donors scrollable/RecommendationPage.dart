import 'package:flutter/material.dart';
import 'package:pawlytics/views/donors/donors%20scrollable/connections/PetDetailsPage.dart';

class RecommendationPage extends StatelessWidget {
  final List<Map<String, String>> recommendedPets = [
    {
      "name": "Max",
      "breed": "Aspin",
      "type": "Dog",
      "image": "assets/images/donors/max.png",
    },
    {
      "name": "Mingming",
      "breed": "Puspin",
      "type": "Cat",
      "image": "assets/images/donors/luna.png",
    },
    {
      "name": "Buddy",
      "breed": "Shih Tzu",
      "type": "Dog",
      "image": "assets/images/donors/peter.png",
    },
    {
      "name": "Kuting",
      "breed": "Puspin",
      "type": "Cat",
      "image": "assets/images/donors/max.png",
    },
    {
      "name": "Chowee",
      "breed": "Puspin",
      "type": "Cat",
      "image": "assets/images/donors/luna.png",
    },
    {
      "name": "Princess",
      "breed": "Aspins",
      "type": "Dog",
      "image": "assets/images/donors/peter.png",
    },
    {
      "name": "Luna",
      "breed": "Persian Mix",
      "type": "Cat",
      "image": "assets/images/donors/max.png",
    },
    {
      "name": "Bantay",
      "breed": "Puspin",
      "type": "Cat",
      "image": "assets/images/donors/luna.png",
    },
    {
      "name": "Snow",
      "breed": "Aspin",
      "type": "Dog",
      "image": "assets/images/donors/peter.png",
    },
  ];

  RecommendationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
        title: const Text(
          "Recommended Pets",
          style: TextStyle(
            color: Color(0xFF1F2C47),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true, // 👈 keeps title centered between back + actions
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        children: [
          // Description
          const Text(
            "Matched with your interest in small breeds\nand recent donation activity.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF1F2C47), fontSize: 14),
          ),
          const SizedBox(height: 14),

          // Preferences Row
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

          // Pet List
          ...recommendedPets.map((pet) {
            return Container(
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(10),
                      topRight: Radius.circular(10),
                    ),
                    child: Image.asset(
                      pet["image"]!,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: const BoxDecoration(
                      color: Color(0xFF1F2C47),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(10),
                        bottomRight: Radius.circular(10),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "${pet["breed"]} • ${pet["type"]}",
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.white70,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              pet["name"]!,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),

                        IconButton(
                          icon: const Icon(
                            Icons.info_outline,
                            color: Colors.white,
                            size: 26,
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PetDetailPage(
                                  name: pet["name"]!,
                                  image: pet["image"]!,
                                  breed: pet["breed"]!,
                                  type: pet["type"]!,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}
