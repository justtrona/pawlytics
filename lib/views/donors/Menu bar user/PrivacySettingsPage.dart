import 'package:flutter/material.dart';
import 'package:pawlytics/views/donors/Menu%20bar%20user/Additional%20function/ChangePasswordPage.dart';

class PrivacySettingsPage extends StatefulWidget {
  const PrivacySettingsPage({super.key});

  @override
  State<PrivacySettingsPage> createState() => _PrivacySettingsPageState();
}

class _PrivacySettingsPageState extends State<PrivacySettingsPage> {
  bool activityStatus = true;
  bool donationAnonymity = false;
  bool petPreferencesConfidentiality = true;
  bool allowRecommendations = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Icon(Icons.pets, size: 50, color: Color(0xFF1F2C47)),
            const SizedBox(height: 8),

            const Text(
              "Privacy Settings",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2C47),
              ),
            ),
            const SizedBox(height: 20),

            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _buildSettingTile(
                    title: "Profile Visibly",
                    subtitle:
                        "Choose who can see your profile and pet interactions.",
                  ),
                  const Divider(),
                  _buildSwitchTile(
                    title: "Activity Status",
                    subtitle: "Show when I’m active",
                    value: activityStatus,
                    onChanged: (val) {
                      setState(() {
                        activityStatus = val;
                      });
                    },
                  ),
                  const Divider(),
                  _buildSwitchTile(
                    title: "Donation Anonymity",
                    subtitle: "Display my name on donation list",
                    value: donationAnonymity,
                    onChanged: (val) {
                      setState(() {
                        donationAnonymity = val;
                      });
                    },
                  ),
                  const Divider(),
                  _buildSwitchTile(
                    title: "Pet Preferences Confidentiality",
                    subtitle: "Hide my liked pets from public",
                    value: petPreferencesConfidentiality,
                    onChanged: (val) {
                      setState(() {
                        petPreferencesConfidentiality = val;
                      });
                    },
                  ),
                  const Divider(),
                  _buildSwitchTile(
                    title: "Allow Recommendations",
                    subtitle: "Allow personalized pet suggestions",
                    value: allowRecommendations,
                    onChanged: (val) {
                      setState(() {
                        allowRecommendations = val;
                      });
                    },
                  ),
                  const Divider(),
                  ListTile(
                    title: const Text(
                      "Two-Factor Authentication",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2C47),
                      ),
                    ),
                    subtitle: const Text("Enable 2FA"),
                    trailing: TextButton(
                      onPressed: () {},
                      child: const Text(
                        "Enable 2FA",
                        style: TextStyle(color: Color(0xFF1F2C47)),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1F2C47),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ChangePasswordPage(),
                        ),
                      );
                    },
                    child: const Text(
                      "Change Password",
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {},
                    child: const Text(
                      "Request My Data",
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingTile({required String title, required String subtitle}) {
    return ListTile(
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Color(0xFF1F2C47),
        ),
      ),
      subtitle: Text(subtitle),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return SwitchListTile(
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Color(0xFF1F2C47),
        ),
      ),
      subtitle: Text(subtitle),
      value: value,
      activeColor: const Color(0xFF1F2C47),
      onChanged: onChanged,
    );
  }
}
