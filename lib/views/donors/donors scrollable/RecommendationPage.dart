import 'package:flutter/material.dart';
import 'package:pawlytics/views/donors/donors%20scrollable/connections/PetDetailsPage.dart';

class RecommendationPage extends StatelessWidget {
  RecommendationPage({super.key});

  /// If you don’t have per-pet campaigns yet, map to an “All Campaigns” id.
  static const int defaultCampaignId = 26; // TODO: replace with your real id

  // Use dynamic to allow an int for campaignId
  final List<Map<String, dynamic>> recommendedPets = [
    {
      "id": 1, // Add ID
      "name": "Max",
      "breed": "Aspin",
      "type": "Dog",
      "image": "assets/images/donors/max.png",
      "campaignId": defaultCampaignId,
    },
    {
      "id": 2, // Add ID
      "name": "Mingming",
      "breed": "Puspin",
      "type": "Cat",
      "image": "assets/images/donors/luna.png",
      "campaignId": defaultCampaignId,
    },
    {
      "id": 3, // Add ID
      "name": "Buddy",
      "breed": "Shih Tzu",
      "type": "Dog",
      "image": "assets/images/donors/peter.png",
      "campaignId": defaultCampaignId,
    },
    {
      "id": 4, // Add ID
      "name": "Kuting",
      "breed": "Puspin",
      "type": "Cat",
      "image": "assets/images/donors/max.png",
      "campaignId": defaultCampaignId,
    },
    {
      "id": 5, // Add ID
      "name": "Chowee",
      "breed": "Puspin",
      "type": "Cat",
      "image": "assets/images/donors/luna.png",
      "campaignId": defaultCampaignId,
    },
    {
      "id": 6, // Add ID
      "name": "Princess",
      "breed": "Aspins",
      "type": "Dog",
      "image": "assets/images/donors/peter.png",
      "campaignId": defaultCampaignId,
    },
    {
      "id": 7, // Add ID
      "name": "Luna",
      "breed": "Persian Mix",
      "type": "Cat",
      "image": "assets/images/donors/max.png",
      "campaignId": defaultCampaignId,
    },
    {
      "id": 8, // Add ID
      "name": "Bantay",
      "breed": "Puspin",
      "type": "Cat",
      "image": "assets/images/donors/luna.png",
      "campaignId": defaultCampaignId,
    },
    {
      "id": 9, // Add ID
      "name": "Snow",
      "breed": "Aspin",
      "type": "Dog",
      "image": "assets/images/donors/peter.png",
      "campaignId": defaultCampaignId,
    },
  ];

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
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        children: [
          const Text(
            "Matched with your interest in small breeds\nand recent donation activity.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF1F2C47), fontSize: 14),
          ),
          const SizedBox(height: 14),

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
                      pet["image"] as String,
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
                              pet["name"] as String,
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
                                builder: (_) => PetDetailPage(
                                  // campaignId: pet["campaignId"],
                                  petId: pet["id"], // Passing the id
                                  name: pet['name'] as String,
                                  image: pet['image'] as String,
                                  breed: pet['breed'] as String,
                                  type: pet['type'] as String,
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
