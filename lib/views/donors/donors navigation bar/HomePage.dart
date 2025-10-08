import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

import 'package:pawlytics/views/donors/HomeScreenButtons/DonatePage.dart';
import 'package:pawlytics/views/donors/HomeScreenButtons/ViewMore.dart';
import 'package:pawlytics/views/donors/donors navigation bar/connections/AboutUsPage.dart';
import 'package:pawlytics/views/donors/donors scrollable/CampaignPage.dart';
import 'package:pawlytics/views/donors/donors scrollable/GoalPage.dart';
import 'package:pawlytics/views/donors/donors scrollable/PetPage.dart';
import 'package:pawlytics/views/donors/donors scrollable/RecommendationPage.dart';
import 'package:pawlytics/views/donors/donors scrollable/connections/PetDetailsPage.dart';

// Monthly goal/expenses controller/model
import 'package:pawlytics/views/donors/controller/goal-opex-controller.dart';

/// ---- tiny color helper
Color darker(Color c, [double amount = .12]) {
  final double t = amount.clamp(0.0, 1.0) as double;
  return Color.lerp(c, Colors.black, t)!;
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  /// Use your real “All Campaigns / General Fund” id here
  static const int defaultCampaignId = 26; // TODO: replace with your actual id

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],

      appBar: AppBar(
        automaticallyImplyLeading: false,
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
            Center(child: _UserGreeting()),
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
                    child: buildCircleIcon(Icons.flag, "Expenses"),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 15),
            const Divider(thickness: 2, indent: 10, endIndent: 10),

            // ===== Monthly Expenses (Summary) ABOVE recommendations =====
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: _MonthlyGoalHeader(),
            ),
            const SizedBox(height: 16),

            // Recommended carousel
            sectionHeader(context, "Recommended"),
            const SizedBox(height: 230, child: _RecommendedPetsRow()),

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
                      campaignId: defaultCampaignId,
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
          child: const Icon(
            Icons.campaign,
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
}

/* -------------------------------------------------------------------------- */
/*                          USER GREETING WIDGET                              */
/* -------------------------------------------------------------------------- */

class _UserGreeting extends StatelessWidget {
  const _UserGreeting({Key? key}) : super(key: key);

  Future<String> _fetchName() async {
    final sb = Supabase.instance.client;
    final user = sb.auth.currentUser;

    // 1) Try auth metadata
    if (user != null) {
      final md = user.userMetadata ?? {};
      final metaName =
          (md['full_name'] as String?) ??
          (md['name'] as String?) ??
          (md['username'] as String?) ??
          (md['display_name'] as String?);
      if (metaName != null && metaName.trim().isNotEmpty) {
        return metaName.trim();
      }
    }

    // 2) Try profiles table
    try {
      if (user != null) {
        final Map<String, dynamic>? res = await sb
            .from('profiles')
            .select('full_name, name, username')
            .eq('id', user.id)
            .maybeSingle();

        if (res != null) {
          final nameFromProfile =
              (res['full_name'] as String?) ??
              (res['name'] as String?) ??
              (res['username'] as String?);
          if (nameFromProfile != null && nameFromProfile.trim().isNotEmpty) {
            return nameFromProfile.trim();
          }
        }
      }
    } catch (_) {
      // safely ignore
    }

    // 3) Fallback to email local part or "there"
    final email = user?.email ?? '';
    if (email.contains('@')) return email.split('@').first;
    return 'there';
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _fetchName(),
      builder: (context, snap) {
        final name = snap.data ?? 'there';
        return Text(
          'Hello, $name!',
          style: const TextStyle(fontSize: 18, color: Colors.white),
        );
      },
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                     MONTHLY EXPENSES HEADER (SUMMARY)                      */
/* -------------------------------------------------------------------------- */

class _MonthlyGoalHeader extends StatefulWidget {
  const _MonthlyGoalHeader({Key? key}) : super(key: key);

  @override
  State<_MonthlyGoalHeader> createState() => _MonthlyGoalHeaderState();
}

class _MonthlyGoalHeaderState extends State<_MonthlyGoalHeader> {
  final _controller = OpexAllocationsController();
  final _php = NumberFormat.currency(
    locale: 'en_PH',
    symbol: '₱',
    decimalDigits: 0,
  );
  final _dateFmt = DateFormat('MMM d, yyyy');

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChange);
    _controller.loadAllocations();
  }

  void _onChange() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onChange);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const brand = Color(0xFF1F2C47);
    final border = BorderSide(color: Colors.grey.shade300);

    if (_controller.loading) {
      return Container(
        height: 112,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.fromBorderSide(border),
        ),
        padding: const EdgeInsets.all(16),
        child: const Align(
          alignment: Alignment.centerLeft,
          child: SizedBox(
            width: 160,
            child: LinearProgressIndicator(minHeight: 10),
          ),
        ),
      );
    }

    // TOTAL EXPENSES = manual amounts + tracked entries
    final items = _controller.items;
    final totalThisMonth = items.fold<double>(
      0,
      (s, e) => s + (e.amount + e.raised),
    );

    final isClosed = _controller.isClosed;
    final dueStr = _controller.monthEnd == null
        ? '—'
        : _dateFmt.format(_controller.monthEnd!);

    return _SummaryExpensesCard(
      brand: brand,
      border: border,
      title: "This Month’s Expenses",
      amountLabel: _php.format(totalThisMonth),
      statusChip: _StatusChip(
        label: isClosed ? 'Closed' : 'Active',
        color: isClosed ? Colors.grey : brand,
      ),
      periodText: 'As of: $dueStr',
      showClosedNote: isClosed,
    );
  }
}

/* ---------- Shared UI pieces for expenses summary ---------- */

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(.25)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: color,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _SummaryExpensesCard extends StatelessWidget {
  const _SummaryExpensesCard({
    required this.brand,
    required this.border,
    required this.title,
    required this.amountLabel,
    required this.statusChip,
    required this.periodText,
    required this.showClosedNote,
  });

  final Color brand;
  final BorderSide border;
  final String title;
  final String amountLabel;
  final Widget statusChip;
  final String periodText;
  final bool showClosedNote;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.fromBorderSide(border),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // title + status
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: brand,
                  ),
                ),
              ),
              statusChip,
            ],
          ),
          const SizedBox(height: 6),
          Text(
            periodText,
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
          const SizedBox(height: 10),
          Center(
            child: Text(
              amountLabel,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 26,
                color: brand,
                letterSpacing: .2,
              ),
            ),
          ),
          if (showClosedNote) ...[
            const SizedBox(height: 8),
            const Text(
              'This month is closed.',
              style: TextStyle(fontSize: 12, color: Colors.redAccent),
            ),
          ],
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

// import 'package:flutter/services.dart';
// import 'package:flutter/material.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
// import 'package:intl/intl.dart';

// import 'package:pawlytics/views/donors/HomeScreenButtons/DonatePage.dart';
// import 'package:pawlytics/views/donors/HomeScreenButtons/ViewMore.dart';
// import 'package:pawlytics/views/donors/donors navigation bar/connections/AboutUsPage.dart';
// import 'package:pawlytics/views/donors/donors scrollable/CampaignPage.dart';
// import 'package:pawlytics/views/donors/donors scrollable/GoalPage.dart';
// import 'package:pawlytics/views/donors/donors scrollable/PetPage.dart';
// import 'package:pawlytics/views/donors/donors scrollable/RecommendationPage.dart';
// import 'package:pawlytics/views/donors/donors scrollable/connections/PetDetailsPage.dart';

// // Monthly goal controller/model
// import 'package:pawlytics/views/donors/controller/goal-opex-controller.dart';

// /// ---- tiny color helper to avoid withOpacity deprecation and extension clashes
// Color darker(Color c, [double amount = .12]) {
//   final double t = amount.clamp(0.0, 1.0) as double;
//   return Color.lerp(c, Colors.black, t)!;
// }

// class HomePage extends StatelessWidget {
//   const HomePage({super.key});

//   /// Use your real “All Campaigns / General Fund” id here
//   static const int defaultCampaignId = 26; // TODO: replace with your actual id

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.grey[100],

//       appBar: AppBar(
//         automaticallyImplyLeading: false,

//         backgroundColor: const Color(0xFF1A2C50),
//         elevation: 0,
//         shape: const RoundedRectangleBorder(
//           borderRadius: BorderRadius.only(
//             bottomLeft: Radius.circular(25),
//             bottomRight: Radius.circular(25),
//           ),
//         ),
//         title: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Center(
//               child: Text(
//                 "Welcome to PAWLYTICS",
//                 style: TextStyle(fontSize: 14, color: Colors.white70),
//               ),
//             ),
//             const SizedBox(height: 2),
//             // 👇 dynamic user name
//             const Center(child: _UserGreeting()),
//           ],
//         ),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.help_outline, color: Colors.white),
//             onPressed: () {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(builder: (context) => const AboutUsPage()),
//               );
//             },
//           ),
//         ],
//       ),

//       body: SingleChildScrollView(
//         padding: const EdgeInsets.only(bottom: 120),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Featured banner
//             Container(
//               margin: const EdgeInsets.all(16),
//               decoration: BoxDecoration(
//                 borderRadius: BorderRadius.circular(15),
//                 image: const DecorationImage(
//                   image: AssetImage("assets/images/donors/peter.png"),
//                   fit: BoxFit.cover,
//                 ),
//               ),
//               height: 180,
//               width: double.infinity,
//               child: Container(
//                 padding: const EdgeInsets.all(12),
//                 decoration: BoxDecoration(
//                   borderRadius: BorderRadius.circular(15),
//                   color: Colors.black26,
//                 ),
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.end,
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     const Text(
//                       "Featured Pet of the Week",
//                       style: TextStyle(
//                         color: Colors.white,
//                         fontSize: 18,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                     const SizedBox(height: 8),
//                     ElevatedButton(
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: const Color(0xFF1A2C50),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                       ),
//                       onPressed: () {
//                         Navigator.push(
//                           context,
//                           MaterialPageRoute(
//                             builder: (_) => const PetDetailPage(
//                               petId: 'featured-buddy-1',
//                               name: "Buddy",
//                               image: "assets/images/donors/peter.png",
//                               breed: "Aspin",
//                               type: "Dog",
//                             ),
//                           ),
//                         );
//                       },
//                       child: const Text(
//                         "Meet Me",
//                         style: TextStyle(
//                           fontSize: 14,
//                           fontWeight: FontWeight.bold,
//                           color: Color.fromARGB(255, 210, 212, 216),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),

//             // Quick nav
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 16),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                 children: [
//                   GestureDetector(
//                     onTap: () {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(builder: (_) => const CampaignPage()),
//                       );
//                     },
//                     child: buildCircleIcon(Icons.campaign, "Campaigns"),
//                   ),
//                   GestureDetector(
//                     onTap: () {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(builder: (_) => const PetPage()),
//                       );
//                     },
//                     child: buildCircleIcon(Icons.pets, "Pets"),
//                   ),
//                   GestureDetector(
//                     onTap: () {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(builder: (_) => const GoalPage()),
//                       );
//                     },
//                     child: buildCircleIcon(Icons.flag, "Goals"),
//                   ),
//                 ],
//               ),
//             ),

//             const SizedBox(height: 15),
//             const Divider(thickness: 2, indent: 10, endIndent: 10),

//             // ===== Monthly Goal (Summary) ABOVE recommendations =====
//             const Padding(
//               padding: EdgeInsets.symmetric(horizontal: 16),
//               child: _MonthlyGoalHeader(),
//             ),
//             const SizedBox(height: 16),

//             // Recommended carousel (now pulls the same pets shown in PetPage)
//             sectionHeader(context, "Recommended"),
//             const SizedBox(height: 230, child: _RecommendedPetsRow()),

//             const SizedBox(height: 20),
//           ],
//         ),
//       ),

//       // Global donate button → donate to general fund (defaultCampaignId)
//       floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
//       floatingActionButton: SafeArea(
//         minimum: const EdgeInsets.all(16),
//         child: DecoratedBox(
//           decoration: BoxDecoration(
//             gradient: const LinearGradient(
//               begin: Alignment.topLeft,
//               end: Alignment.bottomRight,
//               colors: [Color(0xFF0F2D50), Color(0xFFEC8C69)],
//             ),
//             borderRadius: BorderRadius.circular(36),
//             boxShadow: const [
//               BoxShadow(
//                 blurRadius: 14,
//                 offset: Offset(0, 8),
//                 color: Colors.black26,
//               ),
//             ],
//           ),
//           child: ClipRRect(
//             borderRadius: BorderRadius.circular(36),
//             child: FloatingActionButton.extended(
//               heroTag: 'donateFab',
//               tooltip: 'Support the animals',
//               onPressed: () async {
//                 HapticFeedback.lightImpact();
//                 await Navigator.push(
//                   context,
//                   MaterialPageRoute(
//                     builder: (_) => const DonatePage(
//                       campaignId: defaultCampaignId, // 👈 general fund
//                       campaignTitle: 'General Fund',
//                     ),
//                   ),
//                 );
//               },
//               icon: const Icon(Icons.volunteer_activism_rounded),
//               label: const Text(
//                 'Donate Now',
//                 style: TextStyle(fontWeight: FontWeight.w700),
//               ),
//               backgroundColor: Colors.transparent,
//               foregroundColor: Colors.white,
//               elevation: 0,
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   // ---------------- Helpers ----------------

//   Widget buildCircleIcon(IconData icon, String label) {
//     return Column(
//       children: [
//         Container(
//           padding: const EdgeInsets.all(10),
//           decoration: const BoxDecoration(
//             color: Color(0xFF1A2C50),
//             shape: BoxShape.circle,
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.black12,
//                 blurRadius: 6,
//                 offset: Offset(0, 3),
//               ),
//             ],
//           ),
//           child: Icon(
//             icon,
//             size: 30,
//             color: Color.fromARGB(255, 248, 248, 248),
//           ),
//         ),
//         const SizedBox(height: 6),
//         Text(
//           label,
//           style: const TextStyle(
//             fontSize: 12,
//             fontWeight: FontWeight.w600,
//             color: Color(0xFF1A2C50),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget sectionHeader(BuildContext context, String title) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 4),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Text(
//             title,
//             style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//           ),
//           GestureDetector(
//             onTap: () {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(builder: (_) => RecommendationPage()),
//               );
//             },
//             child: const Text(
//               "View More",
//               style: TextStyle(
//                 fontSize: 14,
//                 fontWeight: FontWeight.w500,
//                 color: Colors.blue,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// /* -------------------------------------------------------------------------- */
// /*                          USER GREETING WIDGET                              */
// /* -------------------------------------------------------------------------- */

// class _UserGreeting extends StatelessWidget {
//   const _UserGreeting({Key? key}) : super(key: key);

//   Future<String> _fetchName() async {
//     final sb = Supabase.instance.client;
//     final user = sb.auth.currentUser;

//     // 1) Try auth metadata
//     if (user != null) {
//       final md = user.userMetadata ?? {};
//       final metaName =
//           (md['full_name'] as String?) ??
//           (md['name'] as String?) ??
//           (md['username'] as String?) ??
//           (md['display_name'] as String?);
//       if (metaName != null && metaName.trim().isNotEmpty) {
//         return metaName.trim();
//       }
//     }

//     // 2) Try profiles table (nullable result from maybeSingle)
//     try {
//       if (user != null) {
//         final Map<String, dynamic>? res = await sb
//             .from('profiles')
//             .select('full_name, name, username')
//             .eq('id', user.id)
//             .maybeSingle();

//         if (res != null) {
//           final nameFromProfile =
//               (res['full_name'] as String?) ??
//               (res['name'] as String?) ??
//               (res['username'] as String?);
//           if (nameFromProfile != null && nameFromProfile.trim().isNotEmpty) {
//             return nameFromProfile.trim();
//           }
//         }
//       }
//     } catch (_) {
//       // table/columns might not exist — safely ignore
//     }

//     // 3) Fallback to email local part or "there"
//     final email = user?.email ?? '';
//     if (email.contains('@')) return email.split('@').first;
//     return 'there';
//   }

//   @override
//   Widget build(BuildContext context) {
//     return FutureBuilder<String>(
//       future: _fetchName(),
//       builder: (context, snap) {
//         final name = snap.data ?? 'there';
//         return Text(
//           'Hello, $name!',
//           style: const TextStyle(fontSize: 18, color: Colors.white),
//         );
//       },
//     );
//   }
// }

// /* -------------------------------------------------------------------------- */
// /*                        MONTHLY GOAL HEADER (SUMMARY)                       */
// /* -------------------------------------------------------------------------- */

// class _MonthlyGoalHeader extends StatefulWidget {
//   const _MonthlyGoalHeader({Key? key}) : super(key: key);

//   @override
//   State<_MonthlyGoalHeader> createState() => _MonthlyGoalHeaderState();
// }

// class _MonthlyGoalHeaderState extends State<_MonthlyGoalHeader> {
//   final _controller = OpexAllocationsController();
//   final _php = NumberFormat.currency(
//     locale: 'en_PH',
//     symbol: '₱',
//     decimalDigits: 0,
//   );
//   final _dateFmt = DateFormat('MMM d, yyyy');

//   @override
//   void initState() {
//     super.initState();
//     _controller.addListener(_onChange);
//     _controller.loadAllocations();
//   }

//   void _onChange() {
//     if (mounted) setState(() {});
//   }

//   @override
//   void dispose() {
//     _controller.removeListener(_onChange);
//     _controller.dispose();
//     super.dispose();
//   }

//   String _percent(double v) => '${(v * 100).clamp(0, 100).toStringAsFixed(0)}%';

//   @override
//   Widget build(BuildContext context) {
//     const brand = Color(0xFF1F2C47);
//     const peach = Color(0xFFEC8C69);
//     final border = BorderSide(color: Colors.grey.shade300);

//     if (_controller.loading) {
//       return Container(
//         height: 112,
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(16),
//           border: Border.fromBorderSide(border),
//         ),
//         padding: const EdgeInsets.all(16),
//         child: const Align(
//           alignment: Alignment.centerLeft,
//           child: SizedBox(
//             width: 160,
//             child: LinearProgressIndicator(minHeight: 10),
//           ),
//         ),
//       );
//     }

//     final items = _controller.items;
//     final goal = items.fold<double>(0, (s, e) => s + e.amount);
//     final raised = items.fold<double>(0, (s, e) => s + e.raised);
//     final prog = goal > 0 ? (raised / goal).clamp(0.0, 1.0) : 0.0;

//     final isClosed = _controller.isClosed;
//     final dueStr = _controller.monthEnd == null
//         ? '—'
//         : _dateFmt.format(_controller.monthEnd!);

//     return _SummaryCard(
//       brand: brand,
//       peach: peach,
//       border: border,
//       title: "This Month’s Goal",
//       raisedLabel: _php.format(raised),
//       goalLabel: _php.format(goal),
//       progress: prog,
//       percentText: _percent(prog),
//       statusChip: _StatusChip(
//         label: isClosed ? 'Closed' : 'Active',
//         color: isClosed ? Colors.grey : brand,
//       ),
//       dueText: 'Due: $dueStr',
//       showClosedNote: isClosed,
//     );
//   }
// }

// /* ---------- Shared UI pieces for goal summary ---------- */

// class _StatusChip extends StatelessWidget {
//   const _StatusChip({required this.label, required this.color});
//   final String label;
//   final Color color;

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
//       decoration: BoxDecoration(
//         color: color.withValues(alpha: .08),
//         borderRadius: BorderRadius.circular(999),
//         border: Border.all(color: color.withValues(alpha: .25)),
//       ),
//       child: Text(
//         label,
//         style: TextStyle(
//           fontWeight: FontWeight.w700,
//           color: color,
//           fontSize: 12,
//         ),
//       ),
//     );
//   }
// }

// class _SummaryCard extends StatelessWidget {
//   const _SummaryCard({
//     required this.brand,
//     required this.peach,
//     required this.border,
//     required this.title,
//     required this.raisedLabel,
//     required this.goalLabel,
//     required this.progress,
//     required this.percentText,
//     required this.statusChip,
//     required this.dueText,
//     required this.showClosedNote,
//   });

//   final Color brand;
//   final Color peach;
//   final BorderSide border;
//   final String title;
//   final String raisedLabel;
//   final String goalLabel;
//   final double progress;
//   final String percentText;
//   final Widget statusChip;
//   final String dueText;
//   final bool showClosedNote;

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         border: Border.fromBorderSide(border),
//         boxShadow: const [
//           BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3)),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // title + status
//           Row(
//             children: [
//               Expanded(
//                 child: Text(
//                   title,
//                   style: TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.w800,
//                     color: brand,
//                   ),
//                 ),
//               ),
//               statusChip,
//             ],
//           ),
//           const SizedBox(height: 6),
//           Text(
//             dueText,
//             style: const TextStyle(fontSize: 12, color: Colors.black54),
//           ),
//           const SizedBox(height: 12),
//           Row(
//             children: [
//               Expanded(
//                 child: Column(
//                   children: [
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         Text(
//                           raisedLabel,
//                           style: const TextStyle(
//                             fontWeight: FontWeight.w800,
//                             fontSize: 16,
//                           ),
//                         ),
//                         const SizedBox(width: 6),
//                         const Text(
//                           'raised',
//                           style: TextStyle(color: Colors.grey),
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 2),
//                     Text(
//                       'of $goalLabel',
//                       style: const TextStyle(
//                         fontSize: 13,
//                         color: Colors.black54,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               Container(
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 10,
//                   vertical: 6,
//                 ),
//                 decoration: BoxDecoration(
//                   color: peach.withValues(alpha: .12),
//                   borderRadius: BorderRadius.circular(999),
//                   border: Border.all(color: peach.withValues(alpha: .35)),
//                 ),
//                 child: Text(
//                   percentText,
//                   style: TextStyle(
//                     fontWeight: FontWeight.w700,
//                     color: darker(peach, 0.12),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 12),
//           ClipRRect(
//             borderRadius: BorderRadius.circular(10),
//             child: LinearProgressIndicator(
//               value: progress,
//               minHeight: 12,
//               backgroundColor: Colors.grey.shade200,
//               valueColor: AlwaysStoppedAnimation(brand),
//             ),
//           ),
//           if (showClosedNote) ...[
//             const SizedBox(height: 8),
//             const Text(
//               'This month is closed. New donations are not accepted.',
//               style: TextStyle(fontSize: 12, color: Colors.redAccent),
//             ),
//           ],
//         ],
//       ),
//     );
//   }
// }

// /* -------------------------------------------------------------------------- */
// /*                   Recommended pets row (reads pet_profiles)                */
// /* -------------------------------------------------------------------------- */

// class _RecommendedPetsRow extends StatelessWidget {
//   const _RecommendedPetsRow({Key? key}) : super(key: key);

//   Future<List<_MiniPet>> _fetch() async {
//     final sb = Supabase.instance.client;
//     final res = await sb
//         .from('pet_profiles')
//         .select('id, name, species, age_group, status, image, created_at')
//         .order('created_at', ascending: false)
//         .limit(12);

//     final rows = (res as List).cast<Map<String, dynamic>>();
//     return rows.map(_MiniPet.fromMap).toList();
//   }

//   String? _resolveImageUrl(String? raw) {
//     if (raw == null || raw.isEmpty) return null;
//     if (raw.startsWith('http')) return raw;
//     // If you store Supabase Storage paths, convert to public URL here:
//     // return Supabase.instance.client.storage.from('your-bucket').getPublicUrl(raw);
//     return null;
//   }

//   @override
//   Widget build(BuildContext context) {
//     return FutureBuilder<List<_MiniPet>>(
//       future: _fetch(),
//       builder: (context, snap) {
//         if (snap.connectionState == ConnectionState.waiting) {
//           // skeletons
//           return ListView.separated(
//             scrollDirection: Axis.horizontal,
//             padding: const EdgeInsets.symmetric(horizontal: 16),
//             itemCount: 4,
//             separatorBuilder: (_, __) => const SizedBox(width: 10),
//             itemBuilder: (_, __) => const _SkeletonCard(),
//           );
//         }

//         if (snap.hasError) {
//           return Center(
//             child: Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 16),
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   const Icon(Icons.error_outline, color: Colors.red),
//                   const SizedBox(height: 8),
//                   Text(
//                     snap.error.toString(),
//                     textAlign: TextAlign.center,
//                     style: const TextStyle(color: Colors.red),
//                   ),
//                 ],
//               ),
//             ),
//           );
//         }

//         final pets = snap.data ?? const <_MiniPet>[];
//         if (pets.isEmpty) {
//           return const Center(child: Text('No pets yet'));
//         }

//         return ListView.separated(
//           scrollDirection: Axis.horizontal,
//           padding: const EdgeInsets.only(left: 16, right: 10),
//           itemCount: pets.length,
//           separatorBuilder: (_, __) => const SizedBox(width: 10),
//           itemBuilder: (context, i) {
//             final p = pets[i];
//             final url = _resolveImageUrl(p.imageUrl);

//             // Same visual design as your homepage cards
//             return _RecommendedCard(
//               petId: p.id,
//               name: p.name,
//               breed: p.ageGroup.isEmpty ? '—' : p.ageGroup,
//               type: p.species,
//               imageUrl: url,
//             );
//           },
//         );
//       },
//     );
//   }
// }

// class _SkeletonCard extends StatelessWidget {
//   const _SkeletonCard({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       width: 160,
//       margin: const EdgeInsets.only(right: 6),
//       child: Column(
//         children: [
//           ClipRRect(
//             borderRadius: BorderRadius.circular(12),
//             child: Container(height: 140, width: 180, color: Colors.black12),
//           ),
//           const SizedBox(height: 6),
//           Container(height: 16, width: 100, color: Colors.black12),
//           const SizedBox(height: 4),
//           Container(height: 12, width: 80, color: Colors.black12),
//         ],
//       ),
//     );
//   }
// }

// class _RecommendedCard extends StatelessWidget {
//   const _RecommendedCard({
//     required this.petId,
//     required this.name,
//     required this.breed,
//     required this.type,
//     required this.imageUrl,
//   });

//   final String petId;
//   final String name;
//   final String breed;
//   final String type;
//   final String? imageUrl;

//   @override
//   Widget build(BuildContext context) {
//     Widget img;
//     if (imageUrl == null) {
//       img = Image.asset(
//         "assets/images/donors/peter.png",
//         height: 140,
//         width: 180,
//         fit: BoxFit.cover,
//       );
//     } else if (imageUrl!.startsWith('http')) {
//       img = Image.network(
//         imageUrl!,
//         height: 140,
//         width: 180,
//         fit: BoxFit.cover,
//         errorBuilder: (_, __, ___) => Image.asset(
//           "assets/images/donors/peter.png",
//           height: 140,
//           width: 180,
//           fit: BoxFit.cover,
//         ),
//       );
//     } else {
//       img = Image.asset(imageUrl!, height: 140, width: 180, fit: BoxFit.cover);
//     }

//     return Container(
//       width: 160,
//       margin: const EdgeInsets.only(right: 6),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.center,
//         children: [
//           Stack(
//             children: [
//               ClipRRect(borderRadius: BorderRadius.circular(12), child: img),
//               Positioned(
//                 bottom: 8,
//                 right: 8,
//                 child: ElevatedButton.icon(
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.white,
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 12,
//                       vertical: 8,
//                     ),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(20),
//                     ),
//                     elevation: 2,
//                   ),
//                   onPressed: () {
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                         builder: (_) => PetDetailPage(
//                           petId: petId,
//                           name: name,
//                           image: imageUrl ?? '',
//                           breed: breed,
//                           type: type,
//                         ),
//                       ),
//                     );
//                   },
//                   icon: const Icon(
//                     Icons.info,
//                     size: 25,
//                     color: Color(0xFF1A2C50),
//                   ),
//                   label: const Text(
//                     "View Details",
//                     style: TextStyle(
//                       fontSize: 15,
//                       fontWeight: FontWeight.w600,
//                       color: Color(0xFF1A2C50),
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 6),
//           Text(
//             name,
//             maxLines: 1,
//             overflow: TextOverflow.ellipsis,
//             style: const TextStyle(
//               fontWeight: FontWeight.w600,
//               fontSize: 20,
//               color: Color(0xFF1A2C50),
//             ),
//           ),
//           Text(
//             "$breed • $type",
//             maxLines: 1,
//             overflow: TextOverflow.ellipsis,
//             style: const TextStyle(fontSize: 15, color: Color(0xFF1A2C50)),
//           ),
//         ],
//       ),
//     );
//   }
// }

// /* ------------------------------ tiny DTO class ---------------------------- */

// class _MiniPet {
//   final String id;
//   final String name;
//   final String species;
//   final String ageGroup;
//   final String status;
//   final String? imageUrl;
//   final DateTime? createdAt;

//   _MiniPet({
//     required this.id,
//     required this.name,
//     required this.species,
//     required this.ageGroup,
//     required this.status,
//     required this.imageUrl,
//     required this.createdAt,
//   });

//   static DateTime? _toDate(dynamic v) {
//     if (v == null) return null;
//     try {
//       return DateTime.parse('$v');
//     } catch (_) {
//       return null;
//     }
//   }

//   factory _MiniPet.fromMap(Map<String, dynamic> m) => _MiniPet(
//     id: (m['id'] ?? '').toString(),
//     name: (m['name'] ?? 'Unnamed').toString(),
//     species: (m['species'] ?? '').toString(),
//     ageGroup: (m['age_group'] ?? '').toString(),
//     status: (m['status'] ?? '').toString(),
//     imageUrl: (m['image']?.toString().isEmpty ?? true)
//         ? null
//         : m['image'].toString(),
//     createdAt: _toDate(m['created_at']),
//   );
// }
