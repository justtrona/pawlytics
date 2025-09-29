import 'package:flutter/material.dart';

class AnimalsYouHelpedPage extends StatefulWidget {
  const AnimalsYouHelpedPage({super.key});

  @override
  State<AnimalsYouHelpedPage> createState() => _AnimalsYouHelpedPageState();
}

class _AnimalsYouHelpedPageState extends State<AnimalsYouHelpedPage> {
  final List<Map<String, String>> animals = [
    {
      "name": "Peter",
      "status": "Donated May. 15",
      "image": "assets/images/donors/peter.png",
    },
    {
      "name": "Max",
      "status": "Adopted May. 15",
      "image": "assets/images/donors/max.png",
    },
    {
      "name": "Luna",
      "status": "Adopted May. 15",
      "image": "assets/images/donors/luna.png",
    },
    {
      "name": "Buboy",
      "status": "Donated May. 15",
      "image": "assets/images/donors/peter.png",
    },
  ];

  String searchQuery = "";

  @override
  Widget build(BuildContext context) {
    final filteredAnimals = animals.where((animal) {
      return animal["name"]!.toLowerCase().contains(searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Animals You Helped",
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              "You’ve supported ${animals.length} animals so far.\nThank you for making a difference!",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, color: Colors.black87),
            ),
            const SizedBox(height: 20),

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
                      hintText: "Search pets by name",
                      hintStyle: TextStyle(
                        color: Colors.black54.withOpacity(0.4),
                        fontSize: 14,
                      ),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Colors.black54,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(35),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            Expanded(
              child: GridView.builder(
                itemCount: filteredAnimals.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.75,
                ),
                itemBuilder: (context, index) {
                  final animal = filteredAnimals[index];
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 55,
                          backgroundImage: AssetImage(animal["image"]!),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          animal["name"]!,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            color: Color(0xFF1F2C47),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          animal["status"]!,
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 15,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
