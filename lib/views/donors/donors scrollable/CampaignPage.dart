import 'package:flutter/material.dart';
import 'package:pawlytics/views/donors/donors%20scrollable/connections/CampaignDetailsPage.dart';

class CampaignPage extends StatefulWidget {
  const CampaignPage({super.key});

  @override
  State<CampaignPage> createState() => _CampaignPageState();
}

class _CampaignPageState extends State<CampaignPage> {
  String selectedFilter = "All"; // ✅ Track selected filter

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
        title: const Text(
          "Campaign",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2C47),
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context); // ✅ This returns to Home
          },
        ),
      ),
      body: Column(
        children: [
          // ✅ Top Filters Section
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ✅ ToggleButtons for All, Pets, Campaigns
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
                      fillColor: Colors.transparent, // Active tab background
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
                          padding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: Text(
                            "All",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF23344E),
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: Text(
                            "Pets",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF23344E),
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: Text(
                            "Campaigns",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF23344E),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // ✅ Dropdowns
                // ✅ Dropdowns
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: "All Campaigns", // ✅ default value
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.grey.shade300,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        dropdownColor: Colors.white,
                        items: ["All Campaigns", "Ongoing", "Completed"]
                            .map(
                              (e) => DropdownMenuItem(value: e, child: Text(e)),
                            )
                            .toList(),
                        onChanged: (_) {},
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: "Last 30 Days", // ✅ default value
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.grey.shade300,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        dropdownColor: Colors.white,
                        items: ["Last 30 Days", "This Month", "This Year"]
                            .map(
                              (e) => DropdownMenuItem(value: e, child: Text(e)),
                            )
                            .toList(),
                        onChanged: (_) {},
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // ✅ Search bar
                TextField(
                  decoration: InputDecoration(
                    hintText: "Search Campaign",
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.grey.shade300, // ✅ plain box background
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        12,
                      ), // ✅ rounded corners
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 0),

          // ✅ Scrollable Campaign List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: 3, // number of campaigns
              itemBuilder: (context, index) {
                // ✅ Different tags per campaign
                final List<List<String>> allTags = [
                  ["Medical Supplies", "Dogs", "Urgent", "Food"],
                  ["Honorarium", "Weekly Funds", "Urgent", "Shelter"],
                  ["Medical Supplies", "Dogs", "Urgent", "Food"],
                ];

                // ✅ Different images per campaign
                final List<String> allImages = [
                  "assets/virus.png",
                  "assets/rescue.png",
                  "assets/virus.png",
                ];

                // ✅ Different descriptions (optional)
                final List<String> allDescriptions = [
                  "We are raising fund for dog food. Your help can save our shelter dogs...",
                  "We are gathering weekly funds to support vet honorarium and shelter needs...",
                  "We are raising fund for CDV test kits once again. CDV test kits give us peace of mind...",
                ];

                return CampaignCard(
                  description: allDescriptions[index],
                  tags: allTags[index],
                  image: allImages[index], // ✅ pick different image
                  progress: 0.4,
                  raised: "₱10,750.00",
                  goal: "₱15,000.00",
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ✅ Reusable Campaign Card (title removed)
// ✅ Reusable Campaign Card (title removed)
class CampaignCard extends StatelessWidget {
  final String description;
  final List<String> tags;
  final String image;
  final double progress;
  final String raised;
  final String goal;

  const CampaignCard({
    super.key,
    required this.description,
    required this.tags,
    required this.image,
    required this.progress,
    required this.raised,
    required this.goal,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color.fromARGB(
        255,
        195,
        216,
        231,
      ), // ✅ background for the big box (adjust as you like)
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image + Star (with stroke/border)
            Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: const Color.fromARGB(
                        255,
                        20,
                        11,
                        11,
                      ), // ✅ stroke color
                      width: 1, // ✅ stroke thickness
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      image,
                      height: 160,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: IconButton(
                    icon: const Icon(
                      Icons.star_border,
                      size: 35,
                      color: Color(0xFF1F2C47),
                    ),
                    onPressed: () {},
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Tags
            Wrap(
              spacing: 6,
              children: tags
                  .map(
                    (t) => Chip(
                      label: Text(t),
                      backgroundColor: const Color.fromARGB(255, 218, 215, 215),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 6),

            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                color: const Color(0xFF23344E),
                backgroundColor: Colors.grey.shade300,
              ),
            ),
            const SizedBox(height: 6),

            // Raised / Goal
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Raised: $raised",
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "Goal: $goal",
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 2, 5, 10),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 6),

            // ✅ Description
            Text(
              description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Color(0xFF23344E)),
            ),

            const SizedBox(height: 12),

            // ✅ Donate Button (navigates to details page)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CampaignDetailsPage(
                        title: "We Don’t Have Dog Food Anymore",
                        image: image,
                        raised: raised,
                        goal: goal,
                        progress: progress,
                        description:
                            "Lorem Ipsum is simply dummy text of the printing and typesetting industry...",
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF23344E),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  "Donate",
                  style: TextStyle(color: Color.fromARGB(255, 215, 217, 220)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
