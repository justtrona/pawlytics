import 'package:flutter/material.dart';
import 'package:pawlytics/views/donors/controller/campaign-controller.dart';
import 'package:pawlytics/views/donors/donors%20scrollable/connections/CampaignDetailsPage.dart';
import 'package:pawlytics/views/donors/model/campaign-card-model.dart';

class CampaignPage extends StatefulWidget {
  const CampaignPage({super.key});

  @override
  State<CampaignPage> createState() => _CampaignPageState();
}

class _CampaignPageState extends State<CampaignPage> {
  final controller = CampaignsController();
  late Future<List<CampaignCardModel>> _campaigns;

  @override
  void initState() {
    super.initState();
    _campaigns = controller.fetchCampaigns(
      useView: true,
    ); // reads campaigns_with_totals
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
          // Filters & search (UI only)
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
                        items: const ["All Campaigns", "Ongoing", "Completed"]
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
                        items: const ["Last 30 Days", "This Month", "This Year"]
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

          // Campaign list
          Expanded(
            child: FutureBuilder<List<CampaignCardModel>>(
              future: _campaigns,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }
                final campaigns = snapshot.data;
                if (campaigns == null || campaigns.isEmpty) {
                  return const Center(child: Text("No campaigns found"));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: campaigns.length,
                  itemBuilder: (context, index) {
                    final c = campaigns[index];
                    return CampaignCard(
                      model: c,
                      onDonate: () {
                        // Pass the campaignId so DonatePage will record it
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CampaignDetailsPage(
                              campaignId: c.id,
                              title: c.title,
                              image: c.image,
                              raised: "₱${c.raised.toStringAsFixed(2)}",
                              goal: "₱${c.goal.toStringAsFixed(2)}",
                              progress: c.progress,
                              description: c.description,
                            ),
                          ),
                        );
                      },
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
  final CampaignCardModel model;
  final VoidCallback onDonate;

  const CampaignCard({super.key, required this.model, required this.onDonate});

  // ---------- Status helpers (accept enum or string and render nice chip) ----------
  String _statusKey(dynamic status) {
    try {
      final n = (status as dynamic).name; // enum.name on Dart >= 2.15
      if (n is String && n.isNotEmpty) return n.toLowerCase();
    } catch (_) {}
    var s = status?.toString() ?? '';
    final dot = s.lastIndexOf('.');
    if (dot != -1) s = s.substring(dot + 1);
    return s.trim().toLowerCase();
  }

  String _statusLabel(dynamic status) {
    switch (_statusKey(status)) {
      case 'active':
        return 'ACTIVE';
      case 'inactive':
        return 'INACTIVE';
      case 'due':
        return 'DUE';
      default:
        final k = _statusKey(status);
        return k.isEmpty ? '' : k.toUpperCase();
    }
  }

  Color _statusBorder(dynamic status) {
    switch (_statusKey(status)) {
      case 'active':
        return const Color(0xFF23344E);
      case 'due':
        return const Color(0xFFB45309); // amber
      case 'inactive':
        return Colors.blueGrey.shade300;
      default:
        return Colors.blueGrey.shade300;
    }
  }

  Color _statusText(dynamic status) {
    switch (_statusKey(status)) {
      case 'active':
        return const Color(0xFF23344E);
      case 'due':
        return const Color(0xFF92400E);
      case 'inactive':
        return Colors.blueGrey.shade600;
      default:
        return Colors.blueGrey.shade600;
    }
  }
  // -------------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final status = model.status; // make sure your model exposes this

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
                    child: model.image.startsWith('http')
                        ? Image.network(
                            model.image,
                            height: 160,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          )
                        : Image.asset(
                            model.image,
                            height: 160,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                  ),
                ),

                // Status chip (top-right)
                if (status != null && _statusKey(status).isNotEmpty)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: _statusBorder(status),
                          width: 1.2,
                        ),
                      ),
                      child: Text(
                        _statusLabel(status),
                        style: TextStyle(
                          color: _statusText(status),
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                          letterSpacing: .2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              model.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF23344E),
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              children: model.tags
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
                value: model.progress,
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
                  "Raised: ₱${model.raised.toStringAsFixed(2)}",
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "Goal: ₱${model.goal.toStringAsFixed(2)}",
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
              model.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Color(0xFF23344E)),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onDonate,
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
