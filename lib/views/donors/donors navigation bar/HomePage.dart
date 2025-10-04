import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:pawlytics/views/donors/HomeScreenButtons/DonatePage.dart';
import 'package:pawlytics/views/donors/HomeScreenButtons/ViewMore.dart';
import 'package:pawlytics/views/donors/donors navigation bar/connections/AboutUsPage.dart';
import 'package:pawlytics/views/donors/donors scrollable/CampaignPage.dart';
import 'package:pawlytics/views/donors/donors scrollable/GoalPage.dart';
import 'package:pawlytics/views/donors/donors scrollable/PetPage.dart';
import 'package:pawlytics/views/donors/donors scrollable/RecommendationPage.dart';
import 'package:pawlytics/views/donors/donors scrollable/connections/PetDetailsPage.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  /// Use your real “All Campaigns / General Fund” id here
  static const int defaultCampaignId = 26; // TODO: replace with your actual id

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A2C50),
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(25),
            bottomRight: Radius.circular(25),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Center(
              child: Text(
                "Welcome to PAWLYTICS",
                style: TextStyle(fontSize: 14, color: Colors.white70),
              ),
            ),
            SizedBox(height: 2),
            Center(
              child: Text(
                "Hello, User1010!",
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AboutUsPage()),
              );
            },
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Featured banner
            Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                image: const DecorationImage(
                  image: AssetImage("assets/images/donors/peter.png"),
                  fit: BoxFit.cover,
                ),
              ),
              height: 180,
              width: double.infinity,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  color: Colors.black26,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Featured Pet of the Week",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A2C50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {
                        // ✅ Pass a real petId string (replace with real id when wired to DB)
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const PetDetailPage(
                              petId: 'featured-buddy-1',
                              name: "Buddy",
                              image: "assets/images/donors/peter.png",
                              breed: "Aspin",
                              type: "Dog",
                            ),
                          ),
                        );
                      },
                      child: const Text(
                        "Meet Me",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color.fromARGB(255, 210, 212, 216),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Quick nav
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CampaignPage()),
                      );
                    },
                    child: buildCircleIcon(Icons.campaign, "Campaigns"),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const PetPage()),
                      );
                    },
                    child: buildCircleIcon(Icons.pets, "Pets"),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const GoalPage()),
                      );
                    },
                    child: buildCircleIcon(Icons.flag, "Goals"),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 15),
            const Divider(thickness: 2, indent: 10, endIndent: 10),

            // Recommended carousel (now pulls the same pets shown in PetPage)
            sectionHeader(context, "Recommended"),
            const SizedBox(height: 230, child: _RecommendedPetsRow()),

            const SizedBox(height: 1),

            _buildDonationCard(
              context,
              total: 15000,
              raised: 12500,
              deadline: "Sept 30, 2025",
            ),
            const SizedBox(height: 15),
            const SizedBox(height: 20),
          ],
        ),
      ),

      // Global donate button → donate to general fund (defaultCampaignId)
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
                    builder: (_) => const DonatePage(
                      campaignId: defaultCampaignId, // 👈 general fund
                      campaignTitle: 'General Fund',
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

  // ---------------- Helpers ----------------

  Widget buildCircleIcon(IconData icon, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: const BoxDecoration(
            color: Color(0xFF1A2C50),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 6,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Icon(
            icon,
            size: 30,
            color: Color.fromARGB(255, 248, 248, 248),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A2C50),
          ),
        ),
      ],
    );
  }

  Widget sectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => RecommendationPage()),
              );
            },
            child: const Text(
              "View More",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.blue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget petCard(
    BuildContext context, {
    required String petId, // ✅ NEW
    required String name,
    required String breed,
    required String type,
    required String imagePath,
    required int campaignId, // (you can remove later if unused)
  }) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(left: 16, right: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  imagePath,
                  height: 140,
                  width: 180,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                bottom: 8,
                right: 8,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 2,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PetDetailPage(
                          petId: petId, // ✅ pass the id we received
                          name: name,
                          image: imagePath,
                          breed: breed,
                          type: type,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.info,
                    size: 25,
                    color: Color(0xFF1A2C50),
                  ),
                  label: const Text(
                    "View Details",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A2C50),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            name,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 20,
              color: Color(0xFF1A2C50),
            ),
          ),
          Text(
            "$breed • $type",
            style: const TextStyle(fontSize: 15, color: Color(0xFF1A2C50)),
          ),
        ],
      ),
    );
  }

  Widget _buildDonationCard(
    BuildContext context, {
    required int total,
    required int raised,
    required String deadline,
  }) {
    final double progress = raised / total;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 1),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Donation Usage",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ViewMorePage()),
                ),
                child: const Text(
                  "View More",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.blue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey.shade300,
              color: const Color(0xFF1A2C50),
              minHeight: 10,
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              "Php $raised of Php $total",
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                   Recommended pets row (reads pet_profiles)                */
/* -------------------------------------------------------------------------- */

class _RecommendedPetsRow extends StatelessWidget {
  const _RecommendedPetsRow({Key? key}) : super(key: key);

  Future<List<_MiniPet>> _fetch() async {
    final sb = Supabase.instance.client;
    final res = await sb
        .from('pet_profiles')
        .select('id, name, species, age_group, status, image, created_at')
        .order('created_at', ascending: false)
        .limit(12);

    final rows = (res as List).cast<Map<String, dynamic>>();
    return rows.map(_MiniPet.fromMap).toList();
  }

  String? _resolveImageUrl(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    if (raw.startsWith('http')) return raw;
    // If you store Supabase Storage paths, convert to public URL here:
    // return Supabase.instance.client.storage.from('your-bucket').getPublicUrl(raw);
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<_MiniPet>>(
      future: _fetch(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          // skeletons
          return ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: 4,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, __) => const _SkeletonCard(),
          );
        }

        if (snap.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red),
                  const SizedBox(height: 8),
                  Text(
                    snap.error.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                ],
              ),
            ),
          );
        }

        final pets = snap.data ?? const <_MiniPet>[];
        if (pets.isEmpty) {
          return const Center(child: Text('No pets yet'));
        }

        return ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.only(left: 16, right: 10),
          itemCount: pets.length,
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (context, i) {
            final p = pets[i];
            final url = _resolveImageUrl(p.imageUrl);

            // Same visual design as your homepage cards
            return _RecommendedCard(
              petId: p.id,
              name: p.name,
              breed: p.ageGroup.isEmpty ? '—' : p.ageGroup,
              type: p.species,
              imageUrl: url,
            );
          },
        );
      },
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 6),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(height: 140, width: 180, color: Colors.black12),
          ),
          const SizedBox(height: 6),
          Container(height: 16, width: 100, color: Colors.black12),
          const SizedBox(height: 4),
          Container(height: 12, width: 80, color: Colors.black12),
        ],
      ),
    );
  }
}

class _RecommendedCard extends StatelessWidget {
  const _RecommendedCard({
    required this.petId,
    required this.name,
    required this.breed,
    required this.type,
    required this.imageUrl,
  });

  final String petId;
  final String name;
  final String breed;
  final String type;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    Widget img;
    if (imageUrl == null) {
      img = Image.asset(
        "assets/images/donors/peter.png",
        height: 140,
        width: 180,
        fit: BoxFit.cover,
      );
    } else if (imageUrl!.startsWith('http')) {
      img = Image.network(
        imageUrl!,
        height: 140,
        width: 180,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Image.asset(
          "assets/images/donors/peter.png",
          height: 140,
          width: 180,
          fit: BoxFit.cover,
        ),
      );
    } else {
      img = Image.asset(imageUrl!, height: 140, width: 180, fit: BoxFit.cover);
    }

    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Stack(
            children: [
              ClipRRect(borderRadius: BorderRadius.circular(12), child: img),
              Positioned(
                bottom: 8,
                right: 8,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 2,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PetDetailPage(
                          petId: petId,
                          name: name,
                          image: imageUrl ?? '',
                          breed: breed,
                          type: type,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.info,
                    size: 25,
                    color: Color(0xFF1A2C50),
                  ),
                  label: const Text(
                    "View Details",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A2C50),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 20,
              color: Color(0xFF1A2C50),
            ),
          ),
          Text(
            "$breed • $type",
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 15, color: Color(0xFF1A2C50)),
          ),
        ],
      ),
    );
  }
}

/* ------------------------------ tiny DTO class ---------------------------- */

class _MiniPet {
  final String id;
  final String name;
  final String species;
  final String ageGroup;
  final String status;
  final String? imageUrl;
  final DateTime? createdAt;

  _MiniPet({
    required this.id,
    required this.name,
    required this.species,
    required this.ageGroup,
    required this.status,
    required this.imageUrl,
    required this.createdAt,
  });

  static DateTime? _toDate(dynamic v) {
    if (v == null) return null;
    try {
      return DateTime.parse('$v');
    } catch (_) {
      return null;
    }
  }

  factory _MiniPet.fromMap(Map<String, dynamic> m) => _MiniPet(
    id: (m['id'] ?? '').toString(),
    name: (m['name'] ?? 'Unnamed').toString(),
    species: (m['species'] ?? '').toString(),
    ageGroup: (m['age_group'] ?? '').toString(),
    status: (m['status'] ?? '').toString(),
    imageUrl: (m['image']?.toString().isEmpty ?? true)
        ? null
        : m['image'].toString(),
    createdAt: _toDate(m['created_at']),
  );
}
