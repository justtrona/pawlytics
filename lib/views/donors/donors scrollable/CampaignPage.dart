import 'package:flutter/material.dart';
import 'package:pawlytics/views/donors/donors%20scrollable/connections/CampaignDetailsPage.dart';

class CampaignPage extends StatefulWidget {
  const CampaignPage({super.key});

  @override
  State<CampaignPage> createState() => _CampaignPageState();
}

class _CampaignPageState extends State<CampaignPage> {
  String selectedFilter = "All";

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
            Navigator.pop(context);
          },
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    
                    padding: const EdgeInsets.all(4),
                    // child: ToggleButtons(
                    //   borderRadius: BorderRadius.circular(30),
                    //   borderColor: Colors.transparent,
                    //   selectedBorderColor: Colors.transparent,
                    //   fillColor: Colors.transparent,
                    //   selectedColor: Colors.black,
                    //   color: Colors.grey,
                    //   isSelected: [
                    //     selectedFilter == "All",
                    //     selectedFilter == "Pets",
                    //     selectedFilter == "Campaigns",
                    //   ],
                    //   onPressed: (index) {
                    //     setState(() {
                    //       if (index == 0) selectedFilter = "All";
                    //       if (index == 1) selectedFilter = "Pets";
                    //       if (index == 2) selectedFilter = "Campaigns";
                    //     });
                    //   },
                    //   children: const [
                    //     Padding(
                    //       padding: EdgeInsets.symmetric(
                    //         horizontal: 16,
                    //         vertical: 8,
                    //       ),
                    //       child: Text(
                    //         "All",
                    //         style: TextStyle(
                    //           fontSize: 16,
                    //           fontWeight: FontWeight.bold,
                    //           color: Color(0xFF23344E),
                    //         ),
                    //       ),
                    //     ),
                    //     Padding(
                    //       padding: EdgeInsets.symmetric(
                    //         horizontal: 16,
                    //         vertical: 8,
                    //       ),
                    //       child: Text(
                    //         "Pets",
                    //         style: TextStyle(
                    //           fontSize: 16,
                    //           fontWeight: FontWeight.bold,
                    //           color: Color(0xFF23344E),
                    //         ),
                    //       ),
                    //     ),
                    //     Padding(
                    //       padding: EdgeInsets.symmetric(
                    //         horizontal: 16,
                    //         vertical: 8,
                    //       ),
                    //       child: Text(
                    //         "Campaigns",
                    //         style: TextStyle(
                    //           fontSize: 16,
                    //           fontWeight: FontWeight.bold,
                    //           color: Color(0xFF23344E),
                    //         ),
                    //       ),
                    //     ),
                    //   ],
                    // ),
                  ),
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: "All Campaigns",
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
                        value: "Last 30 Days",
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

                TextField(
                  decoration: InputDecoration(
                    hintText: "Search Campaign",
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.grey.shade300,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 0),

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: 3,
              itemBuilder: (context, index) {
                final List<List<String>> allTags = [
                  ["Medical Supplies", "Dogs", "Urgent", "Food"],
                  ["Honorarium", "Weekly Funds", "Urgent", "Shelter"],
                  ["Medical Supplies", "Dogs", "Urgent", "Food"],
                ];

                final List<String> allImages = [
                  "assets/images/donors/virus.png",
                  "assets/images/donors/rescue.png",
                  "assets/images/donors/virus.png",
                ];

                final List<String> allDescriptions = [
                  "We are raising fund for dog food. Your help can save our shelter dogs...",
                  "We are gathering weekly funds to support vet honorarium and shelter needs...",
                  "We are raising fund for CDV test kits once again. CDV test kits give us peace of mind...",
                ];

                return CampaignCard(
                  description: allDescriptions[index],
                  tags: allTags[index],
                  image: allImages[index],
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
      color: const Color.fromARGB(255, 195, 216, 231),
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: const Color.fromARGB(255, 20, 11, 11),
                      width: 1,
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

            Text(
              description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Color(0xFF23344E)),
            ),

            const SizedBox(height: 12),

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
