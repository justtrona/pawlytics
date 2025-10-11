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

class _ProfileBody extends StatelessWidget {
  const _ProfileBody({Key? key}) : super(key: key);

  Future<_UserView> _loadUser() async {
    final sb = Supabase.instance.client;
    final user = sb.auth.currentUser;

    // Defaults
    String fullName = 'User';
    String? email = user?.email;
    String? avatar;

    if (user != null) {
      final md = user.userMetadata ?? {};
      final metaName =
          (md['fullName'] as String?) ??
          (md['full_name'] as String?) ??
          (md['name'] as String?) ??
          (md['username'] as String?) ??
          (md['display_name'] as String?);
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

      // ---------------- Check registrations table ----------------
      try {
        Map<String, dynamic>? reg = await sb
            .from('registrations')
            .select('fullName, email')
            .eq('auth_user_id', user.id)
            .maybeSingle();

        if (reg == null && (user.email ?? '').isNotEmpty) {
          reg = await sb
              .from('registrations')
              .select('fullName, email')
              .eq('email', user.email!)
              .maybeSingle();
        }

        if (reg != null) {
          final rName = (reg['fullName'] as String?);
          if (rName != null && rName.trim().isNotEmpty) {
            fullName = rName.trim();
          }
        }
      } catch (_) {
        // ignore if table or RLS missing
      }

      // ---------------- Check profiles table ----------------
      try {
        final Map<String, dynamic>? res = await sb
            .from('profiles')
            .select('full_name, avatar_url')
            .eq('id', user.id)
            .maybeSingle();

        if (res != null) {
          final pName = (res['full_name'] as String?);
          final pAvatar = (res['avatar_url'] as String?);

          if (pName != null && pName.trim().isNotEmpty) {
            fullName = pName.trim();
          }
          if (pAvatar != null && pAvatar.trim().isNotEmpty) {
            avatar = pAvatar.trim();
          }
        }
      } catch (_) {
        // ignore if missing
      }
    }

    bool isNetwork = avatar != null && avatar!.startsWith('http');
    return _UserView(
      name: fullName,
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
              /* ----------------------- Cover + Avatar ----------------------- */
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

              /* ----------------------- Full Name Display ----------------------- */
              Text(
                user.name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 4),
              if (user.email.isNotEmpty)
                Text(
                  user.email,
                  style: const TextStyle(fontSize: 14, color: Colors.black54),
                ),

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

              /* ----------------------- Donor Section ----------------------- */
              const Center(
                child: Text(
                  "Here is your impact so far...",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(height: 12),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Image.asset(
                      "assets/images/donors/bronze.png",
                      height: 80,
                      width: 80,
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

              /* ----------------------- Progress Bar ----------------------- */
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const ClipRRect(
                  borderRadius: BorderRadius.all(Radius.circular(20)),
                  child: LinearProgressIndicator(
                    value: 0.3,
                    color: Color(0xFF23344E),
                    backgroundColor: Colors.transparent,
                    minHeight: 16,
                  ),
                ),
              ),

              const SizedBox(height: 8),
              const Text(
                "Support Php 9,100 more campaigns to reach Silver!",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF23344E),
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 30),
              const Divider(thickness: 1, color: Colors.black26),

              /* ----------------------- Stats ----------------------- */
              const SizedBox(height: 20),
              _statCard(Icons.emoji_events, "Campaigns Supported", "10"),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _statCard(
                      Icons.volunteer_activism,
                      "Total Donations",
                      "Php 150",
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: _statCard(Icons.pets, "Adoptions", "69")),
                ],
              ),
              const SizedBox(height: 12),
              _statCard(Icons.home, "Animals You Helped", "4"),
            ],
          ),
        );
      },
    );
  }

  Widget _statCard(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, size: 50),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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

  _UserView({
    required this.name,
    required this.email,
    required this.avatarUrl,
    required this.isNetworkAvatar,
  });
}
