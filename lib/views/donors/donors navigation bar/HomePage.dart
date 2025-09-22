import 'package:flutter/material.dart';
import 'package:pawlytics/views/donors/HomeScreenButtons/DonatePage.dart';
import 'package:pawlytics/views/donors/HomeScreenButtons/ViewMore.dart';
import 'package:pawlytics/views/donors/donors%20navigation%20bar/connections/AboutUsPage.dart';
import 'package:pawlytics/views/donors/donors%20scrollable/CampaignPage.dart';
import 'package:pawlytics/views/donors/donors%20scrollable/GoalPage.dart';
import 'package:pawlytics/views/donors/donors%20scrollable/PetPage.dart';
import 'package:pawlytics/views/donors/donors%20scrollable/RecommendationPage.dart';
import 'package:pawlytics/views/donors/donors%20scrollable/connections/PetDetailsPage.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key, required String title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A2C50),
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(25),
            bottomRight: Radius.circular(25),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Center(
              child: Text(
                "Welcome to PAWLYTICS",
                style: TextStyle(fontSize: 14, color: Colors.white70),
              ),
            ),
            SizedBox(height: 2),
            Center(
              child: Text(
                "Hello, User1010!",
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AboutUsPage()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Featured Pet of the Week
            Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                image: const DecorationImage(
                  image: AssetImage("assets/images/donors/peter.png"),
                  fit: BoxFit.cover,
                ),
              ),
              height: 180,
              width: double.infinity,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  color: Colors.black26,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Featured Pet of the Week",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A2C50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {},
                      child: const Text(
                        "❤️ Meet Me",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color.fromARGB(255, 210, 212, 216),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Quick Action Icons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const RecommendationPage(),
                        ),
                      );
                    },
                    child: buildCircleIcon(Icons.thumb_up, "Recommended"),
                  ),
                  const SizedBox(width: 50),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CampaignPage(),
                        ),
                      );
                    },
                    child: buildCircleIcon(Icons.campaign, "Campaigns"),
                  ),
                  const SizedBox(width: 70),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PetPage(),
                        ),
                      );
                    },
                    child: buildCircleIcon(Icons.pets, "Pets"),
                  ),
                  const SizedBox(width: 70),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const GoalPage(),
                        ),
                      );
                    },
                    child: buildCircleIcon(Icons.flag, "Goals"),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
            const Divider(thickness: 2, indent: 20, endIndent: 20),

            // Recommended Section
            sectionHeader(context, "Recommended"),
            SizedBox(
              height: 230,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  petCard(
                    context,
                    "Peter",
                    "Golden Retriever",
                    "Dog",
                    "assets/images/donors/peter.png",
                  ),
                  petCard(
                    context,
                    "Max",
                    "German Shepherd",
                    "Dog",
                    "assets/images/donors/dog3.png",
                  ),
                  petCard(
                    context,
                    "Luna",
                    "Shih Tzu",
                    "Dog",
                    "assets/images/donors/dog3.png",
                  ),
                  petCard(
                    context,
                    "Rocky",
                    "Beagle",
                    "Dog",
                    "assets/images/donors/luna.png",
                  ),
                ],
              ),
            ),

            const SizedBox(height: 1),

            // Donation Usage Card
            _buildDonationCard(
              context,
              total: 15000,
              raised: 12500,
              deadline: "Sept 30, 2025",
            ),

            // Donate Button
            Container(
              alignment: Alignment.center,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A2C50),
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 60,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 4,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const DonatePage()),
                  );
                },
                child: const Text(
                  "DONATE",
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // Circle Icon
  Widget buildCircleIcon(IconData icon, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Icon(icon, size: 28, color: const Color(0xFF1A2C50)),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  // Section Header (with navigation)
  Widget sectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const RecommendationPage(),
                ),
              );
            },
            child: const Text(
              "View More",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.blue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Pet Card
  Widget petCard(
    BuildContext context,
    String name,
    String breed,
    String type,
    String imagePath,
  ) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(left: 16, right: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  imagePath,
                  height: 140,
                  width: 180,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                bottom: 8,
                right: 8,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 2,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PetDetailPage(
                          name: name,
                          image: imagePath,
                          breed: breed,
                          type: type,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.info,
                    size: 14,
                    color: Color(0xFF1A2C50),
                  ),
                  label: const Text(
                    "View Details",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A2C50),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            name,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: Colors.black87,
            ),
          ),
          Text(
            "$breed • $type",
            style: const TextStyle(fontSize: 13, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  // Donation Usage Card
  Widget _buildDonationCard(
    BuildContext context, {
    required int total,
    required int raised,
    required String deadline,
  }) {
    double progress = raised / total;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
          // Title + View More
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Donation Usage",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ViewMorePage(),
                    ),
                  );
                },
                child: const Text(
                  "View More",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.blue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey.shade300,
              color: const Color(0xFF1A2C50),
              minHeight: 10,
            ),
          ),

          const SizedBox(height: 8),

          // Raised vs total
          Center(
            child: Text(
              "Php $raised of Php $total",
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
