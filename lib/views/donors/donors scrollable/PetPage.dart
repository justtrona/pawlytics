import 'package:flutter/material.dart';
import 'package:pawlytics/views/donors/donors%20scrollable/connections/PetDetailsPage.dart';

class PetPage extends StatefulWidget {
  const PetPage({super.key});

  @override
  State<PetPage> createState() => _PetPageState();
}

class _PetPageState extends State<PetPage> {
  String searchQuery = "";
  String selectedFilter = "All"; // All, Dog, Cat

  // Sample pet data
  final List<Map<String, String>> pets = [
    {
      "name": "Peter",
      "breed": "Aspin",
      "type": "Dog",
      "image": "assets/images/donors/peter.png",
    },
    {
      "name": "Max",
      "breed": "Aspin",
      "type": "Dog",
      "image": "assets/images/donors/max.png",
    },
    {
      "name": "Luna",
      "breed": "Persian",
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
      "name": "Milo",
      "breed": "Siamese",
      "type": "Cat",
      "image": "assets/images/donors/luna.png",
    },
    {
      "name": "Rocky",
      "breed": "Bulldog",
      "type": "Dog",
      "image": "assets/images/donors/max.png",
    },
    {
      "name": "Cleo",
      "breed": "Maine Coon",
      "type": "Cat",
      "image": "assets/images/donors/luna.png",
    },
    {
      "name": "Charlie",
      "breed": "Beagle",
      "type": "Dog",
      "image": "assets/images/donors/peter.png",
    },
  ];

  @override
  Widget build(BuildContext context) {
    // Filter + search pets
    List<Map<String, String>> filteredPets = pets.where((pet) {
      final matchesSearch = pet["name"]!.toLowerCase().contains(
        searchQuery.toLowerCase(),
      );
      final matchesFilter =
          selectedFilter == "All" || pet["type"] == selectedFilter;
      return matchesSearch && matchesFilter;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context); // 👈 this makes the back button work
          },
        ),
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
            // Dog Categories title
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.pets, size: 20, color: Color(0xFF1F2C47)),
                  SizedBox(width: 6),
                  Text(
                    "Dog & Cat Categories",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2C47),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // Search + Filter Row
            Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: "Search pets",
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
                GestureDetector(
                  onTap: () {
                    _showFilterDialog();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Text(
                          selectedFilter,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_drop_down, color: Colors.black),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // GridView for pet cards
            Expanded(
              child: GridView.builder(
                padding: EdgeInsets.zero,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, // 2 per row
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1,
                ),
                itemCount: filteredPets.length,
                itemBuilder: (context, index) {
                  final pet = filteredPets[index];
                  return _buildPetCard(
                    pet["image"]!,
                    pet["name"]!,
                    pet["breed"]!,
                    pet["type"]!,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Build Pet Card
  Widget _buildPetCard(
    String imagePath,
    String name,
    String breed,
    String type,
  ) {
    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          // Pet Image
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(10),
              topRight: Radius.circular(10),
            ),
            child: Image.asset(
              imagePath,
              height: 110,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),

          // Blue Info Section
          Container(
            width: double.infinity,
            height: 90,
            decoration: const BoxDecoration(
              color: Color(0xFF1F2C47),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(10),
                bottomRight: Radius.circular(10),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Breed + Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          "$breed ($type)",
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Color(0xFF1F2C47),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          textStyle: const TextStyle(fontSize: 13),
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
                        child: const Text("View Details"),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Pet Name
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
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

  // Filter Dialog
  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Filter by"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text("All"),
                onTap: () {
                  setState(() {
                    selectedFilter = "All";
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text("Dog"),
                onTap: () {
                  setState(() {
                    selectedFilter = "Dog";
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text("Cat"),
                onTap: () {
                  setState(() {
                    selectedFilter = "Cat";
                  });
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
