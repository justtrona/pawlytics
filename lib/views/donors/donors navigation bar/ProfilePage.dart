import 'package:flutter/material.dart';
import 'package:pawlytics/views/donors/donors%20navigation%20bar/connections/ProfileEdit.dart';
// ⬅️ import your ProfileEdit file

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

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
              title: "Payment Method",
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
            ),
            buildMenuButton(
              context,
              icon: Icons.receipt_long,
              title: "Manual Donation",
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
            ),
            buildMenuButton(
              context,
              icon: Icons.update,
              title: "Shelter Updates",
            ),
            buildMenuButton(
              context,
              icon: Icons.bar_chart,
              title: "Campaign Outcomes",
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
            ),
            buildMenuButton(
              context,
              icon: Icons.description,
              title: "Terms and Condition",
            ),
            buildMenuButton(
              context,
              icon: Icons.notifications,
              title: "Notification Preferences",
            ),
            buildMenuButton(context, icon: Icons.mail, title: "Contact Us"),
            buildMenuButton(context, icon: Icons.logout, title: "Logout"),
          ],
        ),
      ),
    );
  }
}
