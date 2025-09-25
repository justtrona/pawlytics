import 'package:flutter/material.dart';
import 'package:pawlytics/views/donors/HomeScreenButtons/DonatePage.dart';

class PetDetailPage extends StatefulWidget {
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
  State<PetDetailPage> createState() => _PetDetailPageState();
}

class _PetDetailPageState extends State<PetDetailPage> {
  bool isFavorite = false;

  @override
  Widget build(BuildContext context) {
    final petInfo = {"Age": "Senior", "Breed": widget.breed, "Gender": "Male"};

    final statusTags = [
      {"label": "For Adoption", "icon": Icons.home},
      {"label": "Vaccinated", "icon": Icons.vaccines},
      {"label": "Surgery", "icon": Icons.healing},
      {"label": "Needs Treatment", "icon": Icons.favorite},
      {"label": "Spay/Neuter", "icon": Icons.pets},
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 25),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: Image.asset(
                        widget.image,
                        height: 280,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 25,
                    ), // 👈 same as image
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            widget.name,
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1F2C47),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            isFavorite ? Icons.star : Icons.star_border,
                            size: 30,
                            color: Color(0xFF1F2C47),
                          ),
                          onPressed: () {
                            setState(() {
                              isFavorite = !isFavorite;
                            });
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: petInfo.entries.map((entry) {
                      return _buildMainTag(entry.key, entry.value);
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: statusTags.map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1F2C47),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              tag["icon"] as IconData,
                              size: 16,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              tag["label"] as String,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  Text(
                    "${widget.name} is a lovely ${widget.breed} ${widget.type} looking for a forever home!\n\n"
                    "He was rescued in the Philippines after being abandoned. "
                    "Despite his hardships, he remains gentle and full of love. "
                    "Adopting ${widget.name} means giving him a second chance "
                    "to live in a safe and happy environment. He loves people, "
                    "is friendly with kids, and enjoys quiet afternoons. "
                    "Help us give ${widget.name} the life he deserves.",
                    textAlign: TextAlign.start,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.5,
                      color: Color(0xFF1F2C47),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
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
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const DonatePage(allowInKind: false),
                        ),
                      );
                    },

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
                const SizedBox(height: 16),

                Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: 3500 / 10000,
                        minHeight: 12,
                        backgroundColor: Colors.grey[300],
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF1F2C47),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "₱3,500 raised of ₱10,000 goal",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F2C47),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainTag(String label, String value) {
    return Container(
      width: 150,
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2C47),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
