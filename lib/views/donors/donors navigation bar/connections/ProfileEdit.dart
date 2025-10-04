import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pawlytics/views/donors/donors navigation bar/connections/ProfileSettings.dart';

class ProfileEdit extends StatelessWidget {
  const ProfileEdit({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
        centerTitle: true,
        elevation: 0,
        foregroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: const _ProfileBody(),
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                               Body (dynamic)                               */
/* -------------------------------------------------------------------------- */

class _ProfileBody extends StatelessWidget {
  const _ProfileBody({Key? key}) : super(key: key);

  Future<_UserView> _loadUser() async {
    final sb = Supabase.instance.client;
    final user = sb.auth.currentUser;

    // Defaults
    String name = 'there';
    String? email = user?.email;
    String? avatar;

    // 1) From auth metadata
    if (user != null) {
      final md = user.userMetadata ?? {};
      final metaName =
          (md['full_name'] as String?) ??
          (md['name'] as String?) ??
          (md['username'] as String?) ??
          (md['display_name'] as String?);
      final metaAvatar =
          (md['avatar_url'] as String?) ??
          (md['picture'] as String?) ??
          (md['photo_url'] as String?);

      if (metaName != null && metaName.trim().isNotEmpty) {
        name = metaName.trim();
      } else if ((email ?? '').contains('@')) {
        name = email!.split('@').first;
      }

      if (metaAvatar != null && metaAvatar.trim().isNotEmpty) {
        avatar = metaAvatar.trim();
      }
    }

    // 2) From profiles table (optional)
    try {
      if (user != null) {
        final Map<String, dynamic>? res = await sb
            .from('profiles')
            .select('full_name, name, username, avatar_url, photo_url')
            .eq('id', user.id)
            .maybeSingle();

        if (res != null) {
          final pName =
              (res['full_name'] as String?) ??
              (res['name'] as String?) ??
              (res['username'] as String?);
          final pAvatar =
              (res['avatar_url'] as String?) ?? (res['photo_url'] as String?);

          if (pName != null && pName.trim().isNotEmpty) name = pName.trim();
          if (pAvatar != null && pAvatar.trim().isNotEmpty) {
            avatar = pAvatar.trim();
          }
        }
      }
    } catch (_) {
      // profiles table might not exist; ignore
    }

    // Sanitize avatar: allow http(s) only; otherwise treat as asset path
    bool isNetwork = avatar != null && avatar!.startsWith('http');
    return _UserView(
      name: name,
      email: email ?? '',
      avatarUrl: avatar,
      isNetworkAvatar: isNetwork,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_UserView>(
      future: _loadUser(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final user = snap.data!;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Header with cover + avatar
              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Container(
                    height: 130,
                    decoration: BoxDecoration(
                      color: Colors.blueGrey.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  Positioned(
                    bottom: -50,
                    child: CircleAvatar(
                      radius: 50,
                      backgroundImage: user.avatarUrl == null
                          ? const AssetImage("assets/images/donors/dog3.png")
                                as ImageProvider
                          : (user.isNetworkAvatar
                                    ? NetworkImage(user.avatarUrl!)
                                    : AssetImage(user.avatarUrl!))
                                as ImageProvider,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 70),

              // Name + email + Edit Profile
              Text(
                user.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (user.email.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  user.email,
                  style: const TextStyle(color: Colors.black54, fontSize: 13),
                ),
              ],
              TextButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProfileSettings(),
                    ),
                  );
                },
                icon: const Icon(Icons.edit, size: 16),
                label: const Text("Edit Profile"),
              ),

              const SizedBox(height: 30),

              // Impact section (kept from your design)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(
                    child: Text(
                      "Here is your impact so far...",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Donor level card (static demo — wire to your levels later)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Image.asset(
                          "assets/images/donors/bronze.png",
                          height: 80,
                          width: 80,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: 8),
                        RichText(
                          text: TextSpan(
                            style: TextStyle(fontSize: 16, color: Colors.black),
                            children: [
                              TextSpan(
                                text: "Donor Level: ",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              TextSpan(
                                text: "Bronze Supporter",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Progress to next tier
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 6,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: const LinearProgressIndicator(
                        value: 0.3,
                        color: Color(0xFF23344E),
                        backgroundColor: Colors.transparent,
                        minHeight: 16,
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Center(
                    child: Text(
                      "Support Php 9,100 more campaigns to reach Silver!",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF23344E),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  const SizedBox(height: 12),

                  const Divider(
                    thickness: 1,
                    color: Colors.black26,
                    indent: 8,
                    endIndent: 8,
                  ),

                  const SizedBox(height: 20),

                  // Time filter chip (UI only for now)
                  Align(
                    alignment: Alignment.center,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: TextButton(
                        onPressed: () {},
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          foregroundColor: Colors.black,
                          backgroundColor: Colors.transparent,
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "Filter Last 30 Days",
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.3,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_drop_down, size: 18),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Stat cards (your existing demo numbers)
                  Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: const [
                            Icon(Icons.emoji_events, size: 50),
                            SizedBox(height: 6, width: 500),
                            Text(
                              "Campaigns Supported",
                              style: TextStyle(fontSize: 20),
                            ),
                            SizedBox(height: 4),
                            Text(
                              "10",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                children: const [
                                  Icon(Icons.volunteer_activism, size: 50),
                                  SizedBox(height: 6),
                                  Text(
                                    "Total Donations",
                                    style: TextStyle(fontSize: 20),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    "Php 150",
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                children: const [
                                  Icon(Icons.pets, size: 50),
                                  SizedBox(height: 6),
                                  Text(
                                    "Adoptions",
                                    style: TextStyle(fontSize: 20),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    "69",
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: const [
                            Icon(Icons.home, size: 50),
                            SizedBox(height: 6),
                            Text(
                              "Animals You Helped",
                              style: TextStyle(fontSize: 20),
                            ),
                            SizedBox(height: 4, width: 500),
                            Text(
                              "4",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

/* ------------------------------- DTO/View -------------------------------- */

class _UserView {
  final String name;
  final String email;
  final String? avatarUrl;
  final bool isNetworkAvatar;

  _UserView({
    required this.name,
    required this.email,
    required this.avatarUrl,
    required this.isNetworkAvatar,
  });
}
