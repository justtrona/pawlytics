import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pawlytics/views/donors/donors navigation bar/connections/ProfileSettings.dart';

class ProfileEdit extends StatelessWidget {
  const ProfileEdit({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text("Profile"),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black87,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: const _ProfileBody(),
    );
  }
}

class _ProfileBody extends StatelessWidget {
  const _ProfileBody({Key? key}) : super(key: key);

  Future<_UserView> _loadUser() async {
    final sb = Supabase.instance.client;
    final user = sb.auth.currentUser;

    String fullName = 'User';
    String? email = user?.email;
    String? avatar;
    double totalCash = 0;
    int inKindCount = 0;
    int totalCampaigns = 0;
    int totalAdoptions = 0;

    if (user != null) {
      final md = user.userMetadata ?? {};
      final metaName =
          (md['fullName'] as String?) ??
          (md['full_name'] as String?) ??
          (md['name'] as String?);
      final metaAvatar =
          (md['avatar_url'] as String?) ??
          (md['picture'] as String?) ??
          (md['photo_url'] as String?);

      if (metaName != null && metaName.trim().isNotEmpty) {
        fullName = metaName.trim();
      } else if ((email ?? '').contains('@')) {
        fullName = email!.split('@').first;
      }

      if (metaAvatar != null && metaAvatar.trim().isNotEmpty) {
        avatar = metaAvatar.trim();
      }

      try {
        final donations = await sb
            .from('donations')
            .select()
            .eq('user_id', user.id);

        for (final d in donations) {
          final amount = _parseAmount(d['amount']);
          final typeA = (d['donation_type'] ?? '').toString().toLowerCase();
          final typeB = (d['donation_typ'] ?? '').toString().toLowerCase();
          final byType = typeA.contains('kind') || typeB.contains('kind');
          final item = (d['item'] ?? '').toString().trim();
          final qty = d['quantity'];
          final hasGoods = item.isNotEmpty || (qty is num && qty > 0);
          final isInKind = byType || ((amount == 0) && hasGoods);

          if (isInKind) {
            inKindCount++;
          } else {
            totalCash += amount;
          }
        }
        totalCampaigns = donations.length;
      } catch (_) {}

      try {
        final adoptions = await sb
            .from('adoptions')
            .select('id')
            .eq('donor_id', user.id);
        totalAdoptions = (adoptions as List).length;
      } catch (_) {}
    }

    // Tier logic
    String level = "Bronze Supporter";
    Color levelColor = Colors.orange;
    double nextGoal = 10000;
    if (totalCash >= 10000 && totalCash < 50000) {
      level = "Silver Supporter";
      levelColor = Colors.grey;
      nextGoal = 50000;
    } else if (totalCash >= 50000 && totalCash < 100000) {
      level = "Gold Supporter";
      levelColor = Colors.amber.shade700;
      nextGoal = 100000;
    } else if (totalCash >= 100000) {
      level = "Platinum Supporter";
      levelColor = Colors.blueAccent;
      nextGoal = totalCash;
    }

    double progress = totalCash / nextGoal;
    if (progress > 1) progress = 1;

    bool isNetwork = avatar != null && avatar!.startsWith('http');
    return _UserView(
      name: fullName,
      email: email ?? '',
      avatarUrl: avatar,
      isNetworkAvatar: isNetwork,
      totalCash: totalCash,
      inKindCount: inKindCount,
      totalCampaigns: totalCampaigns,
      totalAdoptions: totalAdoptions,
      level: level,
      levelColor: levelColor,
      progress: progress,
      nextGoal: nextGoal,
    );
  }

  double _parseAmount(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v.replaceAll(',', '')) ?? 0;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final php = NumberFormat.currency(locale: 'en_PH', symbol: '₱');

    return FutureBuilder<_UserView>(
      future: _loadUser(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final user = snap.data!;

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // -------- Compact Header --------
              Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF2F3C7E), Color(0xFF1F2A56)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(25),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 8,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                padding: const EdgeInsets.only(top: 35, bottom: 25),
                child: Column(
                  children: [
                    // Avatar
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 95,
                          height: 95,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.white.withOpacity(0.25),
                                blurRadius: 12,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                        CircleAvatar(
                          radius: 45,
                          backgroundColor: Colors.white,
                          child: CircleAvatar(
                            radius: 42,
                            backgroundImage: user.avatarUrl == null
                                ? const AssetImage(
                                        "assets/images/donors/dog3.png",
                                      )
                                      as ImageProvider
                                : (user.isNetworkAvatar
                                          ? NetworkImage(user.avatarUrl!)
                                          : AssetImage(user.avatarUrl!))
                                      as ImageProvider,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      user.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      user.email,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ProfileSettings(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.edit_rounded, size: 16),
                      label: const Text("Edit Profile"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF1F2A56),
                        elevation: 3,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // -------- Smaller Tier Card --------
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: user.levelColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: user.levelColor.withOpacity(0.15),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.emoji_events_rounded,
                      color: user.levelColor,
                      size: 38,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      user.level,
                      style: TextStyle(
                        color: user.levelColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Total Cash Donated: ${php.format(user.totalCash)}",
                      style: const TextStyle(fontSize: 14),
                    ),
                    Text(
                      "In-kind Donations: ${user.inKindCount}",
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: LinearProgressIndicator(
                        value: user.progress,
                        minHeight: 10,
                        backgroundColor: Colors.grey.shade300,
                        color: user.levelColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      user.progress < 1
                          ? "Donate ₱${(user.nextGoal - user.totalCash).toStringAsFixed(0)} more to reach the next level!"
                          : "You’ve reached the top tier!",
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                        fontSize: 13,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
              const Divider(thickness: 1, color: Colors.black26),
              const SizedBox(height: 12),

              // -------- Stats Section --------
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _statCard(
                    Icons.campaign,
                    "Campaigns Supported",
                    user.totalCampaigns.toString(),
                    Colors.indigo,
                  ),
                  _statCard(
                    Icons.volunteer_activism_rounded,
                    "Cash Donations",
                    php.format(user.totalCash),
                    Colors.green,
                  ),
                  _statCard(
                    Icons.card_giftcard_rounded,
                    "In-kind Donations",
                    "${user.inKindCount}",
                    Colors.deepOrange,
                  ),
                  _statCard(
                    Icons.pets_rounded,
                    "Adoptions",
                    user.totalAdoptions.toString(),
                    Colors.purple,
                  ),
                ],
              ),

              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _statCard(IconData icon, String label, String value, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black12.withOpacity(0.08),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/* ------------------------------- DTO/View -------------------------------- */
class _UserView {
  final String name;
  final String email;
  final String? avatarUrl;
  final bool isNetworkAvatar;
  final double totalCash;
  final int inKindCount;
  final int totalCampaigns;
  final int totalAdoptions;
  final String level;
  final Color levelColor;
  final double progress;
  final double nextGoal;

  _UserView({
    required this.name,
    required this.email,
    required this.avatarUrl,
    required this.isNetworkAvatar,
    required this.totalCash,
    required this.inKindCount,
    required this.totalCampaigns,
    required this.totalAdoptions,
    required this.level,
    required this.levelColor,
    required this.progress,
    required this.nextGoal,
  });
}
