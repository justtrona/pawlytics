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
      "breed": "Puspin",
      "type": "Cat",
      "image": "assets/images/donors/luna.png",
    },
    {
      "name": "Rocky",
      "breed": "Labrador Retriever",
      "type": "Dog",
      "image": "assets/images/donors/max.png",
    },
    {
      "name": "Cleo",
      "breed": "Puspin",
      "type": "Cat",
      "image": "assets/images/donors/luna.png",
    },
    {
      "name": "Charlie",
      "breed": "Aspin",
      "type": "Dog",
      "image": "assets/images/donors/peter.png",
    },
  ];

  @override
  Widget build(BuildContext context) {
    List<Map<String, String>> filteredPets = pets.where((pet) {
      final matchesSearch = pet["breed"]!.toLowerCase().contains(
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
            Navigator.pop(context);
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
                      hintText: "Search breed",
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

            Expanded(
              child: GridView.builder(
                padding: EdgeInsets.zero,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 8,
                  childAspectRatio: 0.9,
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
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(10),
              topRight: Radius.circular(10),
            ),
            child: Image.asset(
              imagePath,
              height: 150,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),

          Container(
            width: double.infinity,
            height: 70,
            decoration: const BoxDecoration(
              color: Color(0xFF1F2C47),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(10),
                bottomRight: Radius.circular(10),
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 6,
                  right: 6,
                  child: IconButton(
                    icon: const Icon(Icons.info_outline, color: Colors.white),
                    iconSize: 20,
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
                  ),
                ),

                Positioned(
                  left: 8,
                  bottom: 6,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "$breed • $type",
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

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
