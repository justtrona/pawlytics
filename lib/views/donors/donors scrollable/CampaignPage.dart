import 'package:flutter/material.dart';
import 'package:pawlytics/views/donors/donors%20scrollable/connections/CampaignDetailsPage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CampaignPage extends StatefulWidget {
  const CampaignPage({super.key});

  @override
  State<CampaignPage> createState() => _CampaignPageState();
}

class _CampaignPageState extends State<CampaignPage> {
  String selectedFilter = "All";
  final supabase = Supabase.instance.client;
  late Future<List<Map<String, dynamic>>> _campaigns;

  @override
  void initState() {
    super.initState();
    _campaigns = fetchCampaigns();
  }

  Future<List<Map<String, dynamic>>> fetchCampaigns() async {
    final response = await supabase
        .from('campaigns')
        .select()
        .order('created_at', ascending: false);
    return (response as List).cast<Map<String, dynamic>>();
  }

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
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Filters and search (unchanged UI)
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(padding: const EdgeInsets.all(4))),
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

          // Campaign list loaded from Supabase
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _campaigns,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text("No campaigns found"));
                }

                final campaigns = snapshot.data!;
                return ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: campaigns.length,
                  itemBuilder: (context, index) {
                    final c = campaigns[index];

                    // --- Robust tags handling (FIX) ---
                    // Possible shapes:
                    // - c['tags'] as List<dynamic> -> convert to List<String>
                    // - c['tags'] as String -> comma separated
                    // - no tags field -> fallback to category or ["General"]
                    final dynamic tagsRaw = c['tags'] ?? c['category'] ?? null;
                    List<String> tagsList = [];

                    if (tagsRaw == null) {
                      tagsList = [c['category']?.toString() ?? 'General'];
                    } else if (tagsRaw is List) {
                      tagsList = tagsRaw
                          .map((e) => e == null ? '' : e.toString().trim())
                          .where((s) => s.isNotEmpty)
                          .toList();
                    } else if (tagsRaw is String) {
                      // Support comma-separated string like "Dogs, Urgent"
                      tagsList = tagsRaw
                          .split(',')
                          .map((s) => s.trim())
                          .where((s) => s.isNotEmpty)
                          .toList();
                      if (tagsList.isEmpty) {
                        tagsList = [tagsRaw];
                      }
                    } else {
                      // single value of other type -> toString
                      tagsList = [tagsRaw.toString()];
                    }
                    // If still empty, provide fallback
                    if (tagsList.isEmpty) {
                      tagsList = [c['category']?.toString() ?? 'General'];
                    }
                    // --- end tags handling ---

                    final title =
                        c['program']?.toString() ?? "Untitled Campaign";
                    final description =
                        c['description']?.toString() ??
                        "No description available";

                    // parse fundraising_goal and raised safely
                    final double goalVal =
                        double.tryParse(
                          c['fundraising_goal']?.toString() ?? '',
                        ) ??
                        0.0;
                    final double raisedVal =
                        double.tryParse(c['raised']?.toString() ?? '') ?? 0.0;

                    final double progress = goalVal > 0
                        ? ((raisedVal / goalVal).clamp(0.0, 1.0) as double)
                        : 0.0;

                    // image fallback (you can replace with URL from DB and use Image.network)
                    final String image =
                        c['image_url']?.toString() ??
                        "assets/images/donors/rescue.png";

                    return CampaignCard(
                      title: title,
                      description: description,
                      tags: tagsList,
                      image: image,
                      progress: progress,
                      raised: "₱${raisedVal.toStringAsFixed(2)}",
                      goal: "₱${goalVal.toStringAsFixed(2)}",
                    );
                  },
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
  final String title;
  final String description;
  final List<String> tags;
  final String image;
  final double progress;
  final String raised;
  final String goal;

  const CampaignCard({
    super.key,
    required this.title,
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
                    child: image.startsWith('http')
                        ? Image.network(
                            image,
                            height: 160,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          )
                        : Image.asset(
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
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF23344E),
              ),
            ),
            const SizedBox(height: 6),
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
                    color: Color(0xFF02050A),
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
                        title: title,
                        image: image,
                        raised: raised,
                        goal: goal,
                        progress: progress,
                        description: description,
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
