import 'package:flutter/material.dart';

class CampaignDetailsPage extends StatelessWidget {
  final String title;
  final String image;
  final String raised;
  final String goal;
  final double progress;
  final String description;

  const CampaignDetailsPage({
    super.key,
    required this.title,
    required this.image,
    required this.raised,
    required this.goal,
    required this.progress,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
        title: const Text(
          "Campaigns",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2C47),
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ✅ Campaign Image with border stroke
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: const Color.fromARGB(255, 18, 13, 13), // stroke color
                  width: 1, // stroke thickness
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  image,
                  width: double.infinity,
                  height: 180,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ✅ Title
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2C47),
              ),
            ),

            // ✅ Raised / Goal + Star (side by side)
            Row(
              children: [
                Text(
                  "$raised of $goal",
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF1F2C47),
                  ),
                ),
                const SizedBox(width: 230), // spacing between text and star
                IconButton(
                  padding: EdgeInsets.zero, // remove default padding
                  constraints: const BoxConstraints(), // shrink tap area
                  icon: const Icon(
                    Icons.star_border,
                    size: 35,
                    color: Color(0xFF1F2C47),
                  ),
                  onPressed: () {},
                ),
              ],
            ),
            const SizedBox(height: 10),

            // ✅ Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 10,
                color: const Color(0xFF23344E),
                backgroundColor: Colors.grey.shade300,
              ),
            ),

            const SizedBox(height: 20),

            // ✅ Description
            const Text(
              "Description",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2C47),
              ),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF1F2C47),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),

      // ✅ Donate Button at bottom, slightly lifted
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(
          16,
          0,
          16,
          32,
        ), // bottom = 32 for spacing
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF23344E),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              "Donate Now",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
