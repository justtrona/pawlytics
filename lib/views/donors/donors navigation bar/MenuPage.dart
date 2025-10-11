import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pawlytics/views/donors/Menu%20bar%20user/FavoritePage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pawlytics/route/route.dart' as route;
import 'package:pawlytics/views/donors/Menu%20bar%20user/myimpact.dart';
import 'package:pawlytics/views/donors/Menu%20bar%20user/CampaignOutcomesPage.dart';
import 'package:pawlytics/views/donors/Menu%20bar%20user/CertificatesPage.dart';
import 'package:pawlytics/views/donors/Menu%20bar%20user/ContactUsPage.dart';
import 'package:pawlytics/views/donors/Menu%20bar%20user/MyDonationPage.dart';
import 'package:pawlytics/views/donors/Menu%20bar%20user/NotificationPreferencePage.dart';
import 'package:pawlytics/views/donors/Menu%20bar%20user/PaymentMethodPage.dart';
import 'package:pawlytics/views/donors/Menu%20bar%20user/PrivacySettingsPage.dart';
import 'package:pawlytics/views/donors/donors%20navigation%20bar/ShelterUpdatesPage.dart';
import 'package:pawlytics/views/donors/Menu%20bar%20user/TermsConditionsPage.dart';
import 'package:pawlytics/views/donors/donors%20navigation%20bar/connections/ProfileEdit.dart';
import 'package:pawlytics/views/get_start/get_started_main.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  static const brand = Color(0xFF1F2C47);
  static const ink = Color(0xFF0F2D50);

  bool _signingOut = false;
  bool _loading = true;
  String? _fullName;

  User? get _user => Supabase.instance.client.auth.currentUser;
  String get _email => _user?.email ?? '';

  @override
  void initState() {
    super.initState();
    _loadFullName();
  }

  Future<void> _loadFullName() async {
    final sb = Supabase.instance.client;
    final user = _user;

    if (user == null) {
      setState(() => _loading = false);
      return;
    }

    String? fullName;

    try {
      // 1️⃣ Check user metadata
      final md = user.userMetadata ?? {};
      fullName =
          (md['fullName'] as String?) ??
          (md['full_name'] as String?) ??
          (md['name'] as String?) ??
          (md['display_name'] as String?);

      // 2️⃣ Check registrations table
      if (fullName == null || fullName.isEmpty) {
        Map<String, dynamic>? reg = await sb
            .from('registrations')
            .select('fullName')
            .eq('auth_user_id', user.id)
            .maybeSingle();

        if (reg == null && (user.email ?? '').isNotEmpty) {
          reg = await sb
              .from('registrations')
              .select('fullName')
              .eq('email', user.email!)
              .maybeSingle();
        }

        if (reg != null && reg['fullName'] != null) {
          fullName = reg['fullName'] as String;
        }
      }

      // 3️⃣ Check profiles table
      if (fullName == null || fullName.isEmpty) {
        final Map<String, dynamic>? profile = await sb
            .from('profiles')
            .select('full_name')
            .eq('id', user.id)
            .maybeSingle();

        if (profile != null && profile['full_name'] != null) {
          fullName = profile['full_name'] as String;
        }
      }
    } catch (e) {
      debugPrint('Error fetching full name: $e');
    }

    setState(() {
      _fullName = fullName?.trim().isNotEmpty == true
          ? fullName!.trim()
          : _email.split('@').first;
      _loading = false;
    });
  }

  String get initials {
    final parts = (_fullName ?? _email).trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return 'U';
    if (parts.length == 1) {
      return parts.first.isEmpty
          ? 'U'
          : parts.first.characters.first.toUpperCase();
    }
    return '${parts.first.characters.first.toUpperCase()}${parts.last.characters.first.toUpperCase()}';
  }

  Future<void> _confirmAndLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
    if (confirm != true || _signingOut) return;

    _signingOut = true;
    try {
      await Supabase.instance.client.auth.signOut(scope: SignOutScope.global);
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const GetStartedMain()),
        (_) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Logout failed: $e')));
    } finally {
      _signingOut = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final displayName = _fullName ?? _email.split('@').first;
    final subLine = _email.isNotEmpty ? _email : '';

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ————— Header —————
          SliverAppBar(
            automaticallyImplyLeading: false,
            pinned: true,
            backgroundColor: ink,
            expandedHeight: 136,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0F2D50), Color(0xFF2F4973)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                    child: Row(
                      children: [
                        _RingAvatar(initials: initials),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                displayName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 3),
                              GestureDetector(
                                onLongPress: () {
                                  if (subLine.trim().isEmpty) return;
                                  Clipboard.setData(
                                    ClipboardData(text: subLine),
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Email copied'),
                                      duration: Duration(seconds: 1),
                                    ),
                                  );
                                },
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.alternate_email,
                                      size: 14,
                                      color: Colors.white70,
                                    ),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        subLine,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        TextButton.icon(
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            backgroundColor: Colors.white.withOpacity(.12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                              side: BorderSide(
                                color: Colors.white.withOpacity(.22),
                              ),
                            ),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ProfileEdit(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.edit, size: 16),
                          label: const Text(
                            'Edit',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ————— Menu Section —————
          SliverList(
            delegate: SliverChildListDelegate([
              const SizedBox(height: 10),
              const _SectionHeader('Profile'),
              _MenuTile(
                icon: Icons.person,
                title: displayName,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileEdit()),
                ),
              ),
              _MenuTile(
                icon: Icons.payment,
                title: 'Payment method',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PaymentMethodPage()),
                ),
              ),

              const _SectionHeader('Manage Donations'),
              _MenuTile(
                icon: Icons.monetization_on,
                title: 'My Donations',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const DonationHistoryPage(),
                  ),
                ),
              ),
              _MenuTile(
                icon: Icons.workspace_premium,
                title: 'Certificates',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => CertificatesPage()),
                ),
              ),
              const _SectionHeader('Tracking'),
              _MenuTile(
                icon: Icons.show_chart,
                title: 'Your Impact',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ImpactPage()),
                ),
              ),
              _MenuTile(
                icon: Icons.star,
                title: 'Favorites',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const FavoritesPage()),
                ),
              ),
              const _SectionHeader('Settings'),
              _MenuTile(
                icon: Icons.lock,
                title: 'Privacy Settings',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PrivacySettingsPage(),
                  ),
                ),
              ),
              _MenuTile(
                icon: Icons.description,
                title: 'Terms and Conditions',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const TermsConditionsPage(),
                  ),
                ),
              ),
              _MenuTile(
                icon: Icons.notifications,
                title: 'Notification Preferences',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const NotificationPreferencePage(),
                  ),
                ),
              ),
              _MenuTile(
                icon: Icons.mail,
                title: 'Contact Us',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ContactUsPage()),
                ),
              ),
              _MenuTile(
                icon: Icons.logout,
                title: 'Logout',
                danger: true,
                onTap: _confirmAndLogout,
              ),
              const SizedBox(height: 24),
            ]),
          ),
        ],
      ),
    );
  }
}

/* ================== Reusable Widgets (unchanged) ================== */

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Row(
        children: [
          Text(
            text,
            style: const TextStyle(
              color: Color(0xFF1F2C47),
              fontWeight: FontWeight.w900,
              fontSize: 15,
            ),
          ),
          const Spacer(),
          Container(height: 1, width: 140, color: Colors.black12),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final brand = _ProfilePageState.brand;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: Colors.grey.shade300),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: danger
                        ? const Color(0xFFFFE9E7)
                        : brand.withOpacity(.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: danger
                          ? const Color(0xFFFFC7C1)
                          : brand.withOpacity(.20),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    icon,
                    size: 20,
                    color: danger ? const Color(0xFFCC3A2B) : brand,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: danger ? const Color(0xFFCC3A2B) : Colors.black87,
                      fontSize: 15,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.black38),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RingAvatar extends StatelessWidget {
  const _RingAvatar({required this.initials});
  final String initials;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 46,
      height: 46,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Color(0xFFFFB89C), Color(0xFFEC8C69)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Color(0xFF17314F),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              initials,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
