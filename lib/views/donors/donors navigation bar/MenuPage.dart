import 'package:flutter/material.dart';
import 'package:pawlytics/route/route.dart' as route; // <-- use named routes
import 'package:pawlytics/views/donors/Menu%20bar%20user/AnimalsYouHelpedPage.dart';
import 'package:pawlytics/views/donors/Menu%20bar%20user/CampaignOutcomesPage.dart';
import 'package:pawlytics/views/donors/Menu%20bar%20user/CertificatesPage.dart';
import 'package:pawlytics/views/donors/Menu%20bar%20user/ContactUsPage.dart';
import 'package:pawlytics/views/donors/Menu%20bar%20user/MyDonationPage.dart';
import 'package:pawlytics/views/donors/Menu%20bar%20user/NotificationPreferencePage.dart';
import 'package:pawlytics/views/donors/Menu%20bar%20user/PaymentMethodPage.dart';
import 'package:pawlytics/views/donors/Menu%20bar%20user/PrivacySettingsPage.dart';
import 'package:pawlytics/views/donors/Menu%20bar%20user/ShelterUpdatesPage.dart';
import 'package:pawlytics/views/donors/Menu%20bar%20user/TermsConditionsPage.dart';
import 'package:pawlytics/views/donors/donors%20navigation%20bar/connections/ProfileEdit.dart';
import 'package:pawlytics/views/get_start/get_started_main.dart';
import 'package:pawlytics/views/get_start/login_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _signingOut = false;

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
      await Supabase.instance.client.auth.signOut();
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Signed out successfully')));

      // Option A: go to app root that shows AuthGate
      // Navigator.of(context, rootNavigator: true)
      //     .pushNamedAndRemoveUntil('/', (_) => false);

      // Option B: go directly to your named login page
      Navigator.of(
        context,
        rootNavigator: true,
      ).pushNamedAndRemoveUntil(route.login, (_) => false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Logout failed: $e')));
    } finally {
      _signingOut = false;
    }
  }

  Widget buildMenuButton(
    BuildContext context, {
    required IconData icon,
    required String title,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 16.0),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF5E6B7F),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(top: 16, bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                "Profile",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Color(0xFF1F2C47),
                ),
              ),
            ),
            buildMenuButton(
              context,
              icon: Icons.person,
              title: "User TenTen",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfileEdit()),
                );
              },
            ),
            buildMenuButton(context, icon: Icons.star, title: "Favorites"),
            buildMenuButton(
              context,
              icon: Icons.payment,
              title: "Payment method",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PaymentMethodPage(),
                  ),
                );
              },
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                "Manage Donations",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Color(0xFF1F2C47),
                ),
              ),
            ),
            buildMenuButton(
              context,
              icon: Icons.monetization_on,
              title: "My Donations",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MyDonationPage(),
                  ),
                );
              },
            ),
            buildMenuButton(
              context,
              icon: Icons.campaign,
              title: "Campaign Contributions",
            ),
            buildMenuButton(
              context,
              icon: Icons.workspace_premium,
              title: "Certificates",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CertificatesPage(),
                  ),
                );
              },
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                "Tracking",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Color(0xFF1F2C47),
                ),
              ),
            ),
            buildMenuButton(
              context,
              icon: Icons.show_chart,
              title: "Your Impact",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AnimalsYouHelpedPage(),
                  ),
                );
              },
            ),
            buildMenuButton(
              context,
              icon: Icons.update,
              title: "Shelter Updates",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ShelterUpdatesPage(),
                  ),
                );
              },
            ),
            buildMenuButton(
              context,
              icon: Icons.bar_chart,
              title: "Campaign Outcomes",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CampaignOutcomesPage(),
                  ),
                );
              },
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                "Settings",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Color(0xFF1F2C47),
                ),
              ),
            ),
            buildMenuButton(
              context,
              icon: Icons.lock,
              title: "Privacy Settings",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PrivacySettingsPage(),
                  ),
                );
              },
            ),
            buildMenuButton(
              context,
              icon: Icons.description,
              title: "Terms and Condition",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TermsConditionsPage(),
                  ),
                );
              },
            ),
            buildMenuButton(
              context,
              icon: Icons.notifications,
              title: "Notification Preferences",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NotificationPreferencePage(),
                  ),
                );
              },
            ),
            buildMenuButton(
              context,
              icon: Icons.mail,
              title: "Contact Us",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ContactUsPage(),
                  ),
                );
              },
            ),
            buildMenuButton(
              context,
              icon: Icons.logout,
              title: "Logout",
              onTap: () async {
                try {
                  await Supabase.instance.client.auth.signOut(
                    scope: SignOutScope.global,
                  ); // stronger, revokes on server too
                  if (!context.mounted) return;

                  // Optional: quick sanity print
                  // debugPrint('After signOut, session: ${Supabase.instance.client.auth.currentSession}');

                  // Go straight to the LoginPage and clear the entire stack.
                  Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const GetStartedMain()),
                    (_) => false,
                  );
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Logout failed: $e')));
                }
              },
              // <-- same logic as Admin menuBar
            ),
          ],
        ),
      ),
    );
  }
}
