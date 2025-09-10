import 'package:flutter/material.dart';

class PetPage extends StatelessWidget {
  const PetPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
        title: const Text(
          "Pets",
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.pets, size: 20, color: Color(0xFF1F2C47)),
                  SizedBox(width: 6),
                  Text(
                    "Dog Categories",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2C47),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: "Search",
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      filled: true,
                      fillColor: Colors.grey.shade200,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: const [
                      Text(
                        "Filter",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_drop_down, color: Colors.black),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            SizedBox(
              height: 370,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildPetCard(
                    context,
                    imagePath: "assets/images/donors/peter.png",
                    name: "Peter",
                    healthStatus: "Healthy",
                    careNeeds: "Regular",
                    adoptionStatus: "Available",
                  ),
                  _buildPetCard(
                    context,
                    imagePath: "assets/images/donors/max.png",
                    name: "Max",
                    healthStatus: "Healthy",
                    careNeeds: "Regular",
                    adoptionStatus: "Available",
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Pet Card Widget
  Widget _buildPetCard(
    BuildContext context, {
    required String imagePath,
    required String name,
    required String healthStatus,
    required String careNeeds,
    required String adoptionStatus,
  }) {
    return Container(
      width: 250,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(16),
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
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
            child: Image.asset(
              imagePath,
              height: 190,
              width: 250,
              fit: BoxFit.cover,
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                _buildStatusRow("Health Status", healthStatus),
                _buildStatusRow("Care Needs", careNeeds),
                _buildStatusRow("Adoption Status", adoptionStatus),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1F2C47),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PetDetailsPage(
                            name: name,
                            imagePath: imagePath,
                            description:
                                "$name is a gentle rescue dog who was found alone but never lost hope. Now ready for a second chance at love",
                            tags: ["1y", "NEEDS MEDICAL CARE", "Aspin"],
                          ),
                        ),
                      );
                    },
                    child: const Text(
                      "View",
                      style: TextStyle(
                        fontSize: 20,
                        color: Color.fromARGB(255, 219, 221, 225),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 15, color: Color(0xFF1F2C47)),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

class PetDetailsPage extends StatelessWidget {
  final String name;
  final String imagePath;
  final String description;
  final List<String> tags;

  const PetDetailsPage({
    super.key,
    required this.name,
    required this.imagePath,
    required this.description,
    required this.tags,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
        centerTitle: true,
        title: Text(
          name,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2C47),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                imagePath,
                width: double.infinity,
                height: 220,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 12),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    description,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF1F2C47),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.star_border, color: Color(0xFF1F2C47)),
                  onPressed: () {},
                ),
              ],
            ),
            const SizedBox(height: 12),

            Wrap(
              spacing: 8,
              children: tags.map((tag) {
                return Chip(
                  label: Text(
                    tag,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: tag == "NEEDS MEDICAL CARE"
                          ? Colors.red
                          : const Color(0xFF1F2C47),
                    ),
                  ),
                  backgroundColor: tag == "NEEDS MEDICAL CARE"
                      ? Colors.red.shade50
                      : Colors.grey.shade200,
                );
              }).toList(),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 45,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1F2C47),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Donate",
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),
            TextButton(
              onPressed: () {},
              child: const Text(
                "View More",
                style: TextStyle(fontSize: 14, color: Color(0xFF1F2C47)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
