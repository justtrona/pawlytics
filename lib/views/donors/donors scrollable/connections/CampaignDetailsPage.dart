import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pawlytics/views/donors/HomeScreenButtons/DonatePage.dart';

class CampaignDetailsPage extends StatelessWidget {
  // NEW: we need this to attach donations to the correct campaign
  final int campaignId;

  final String title;
  final String image;
  final String raised;
  final String goal;
  final double progress;
  final String description;

  const CampaignDetailsPage({
    super.key,
    required this.campaignId, // <-- add this
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
        backgroundColor: Colors.white,
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
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: const Color.fromARGB(255, 18, 13, 13),
                  width: 1,
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

            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2C47),
              ),
            ),

            Row(
              children: [
                Text(
                  "$raised of $goal",
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF1F2C47),
                  ),
                ),
                const Spacer(), // nicer than a hard-coded width
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
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

      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0F2D50), Color(0xFFEC8C69)],
            ),
            borderRadius: BorderRadius.circular(36),
            boxShadow: const [
              BoxShadow(
                blurRadius: 14,
                offset: Offset(0, 8),
                color: Colors.black26,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(36),
            child: FloatingActionButton.extended(
              heroTag: 'donateFab',
              tooltip: 'Support the animals',
              onPressed: () async {
                HapticFeedback.lightImpact();
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DonatePage(
                      campaignId: campaignId, // <-- pass the id
                      campaignTitle:
                          title, // optional, nice for the DonatePage header
                      // allowInKind: true,     // optional: set if you want to restrict tabs
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.volunteer_activism_rounded),
              label: const Text(
                'Donate Now',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
          ),
        ),
      ),
    );
  }
}
