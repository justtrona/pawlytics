import 'package:flutter/material.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  String selectedFilter = "All";

  final List<Map<String, String>> items = [
    {
      "image": "assets/dogfood.png",
      "category": "Campaigns",
      "title": "Dog Food",
      "description": "We are out of dog food anymore!",
    },
    {
      "image": "assets/mishi.png",
      "category": "Pets",
      "title": "Mishi",
      "description": "5 years old | For Adoption | Rescue Dog",
    },
    {
      "image": "assets/mrshocks.png",
      "category": "Pets",
      "title": "Mr. Shocks",
      "description": "3 years old | Under Medication | Rescue Dog",
    },
    {
      "image": "assets/shelter.png",
      "category": "Campaigns",
      "title": "Shelter needs food supplies",
      "description":
          "Shelter experiencing crisis in foods and other utilities...",
    },
  ];

  @override
  Widget build(BuildContext context) {
    final filteredItems = selectedFilter == "All"
        ? items
        : items.where((item) => item["category"] == selectedFilter).toList();

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          "Favorites",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2C47),
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(30),
                ),
                padding: const EdgeInsets.all(4),
                child: ToggleButtons(
                  borderRadius: BorderRadius.circular(30),
                  borderColor: Colors.transparent,
                  selectedBorderColor: Colors.transparent,
                  fillColor: Colors.grey.shade200,
                  selectedColor: Colors.black,
                  color: Colors.grey,
                  isSelected: [
                    selectedFilter == "All",
                    selectedFilter == "Pets",
                    selectedFilter == "Campaigns",
                  ],
                  onPressed: (index) {
                    setState(() {
                      if (index == 0) selectedFilter = "All";
                      if (index == 1) selectedFilter = "Pets";
                      if (index == 2) selectedFilter = "Campaigns";
                    });
                  },
                  children: const [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        "All",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        "Pets",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        "Campaigns",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: filteredItems.length,
                itemBuilder: (context, index) {
                  final item = filteredItems[index];
                  return _favoriteItem(
                    item["image"]!,
                    item["category"]!,
                    item["title"]!,
                    item["description"]!,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _favoriteItem(
    String image,
    String category,
    String title,
    String description,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
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
              image,
              width: double.infinity,
              height: 180,
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF1F2C47),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2C47),
                      ),
                    ),
                    const Icon(Icons.star, color: Color(0xFF1F2C47)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF1F2C47),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
