import 'package:flutter/material.dart';

class NotificationPreferencePage extends StatefulWidget {
  const NotificationPreferencePage({super.key});

  @override
  State<NotificationPreferencePage> createState() =>
      _NotificationPreferencePageState();
}

class _NotificationPreferencePageState
    extends State<NotificationPreferencePage> {
  bool emailNotification = true;
  bool smsAlert = false;
  bool dailySummary = true;

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
      body: Column(
        children: [
          const Icon(Icons.pets, size: 50, color: Color(0xFF1F2C47)),
          const SizedBox(height: 5),
          const Text(
            "Notification Preference",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2C47),
            ),
          ),
          const SizedBox(height: 15),

          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(
                    child: Text(
                      "Enable notifications to stay informed\nabout important updates",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  _buildSwitchTile(
                    title: "Email Notification",
                    description:
                        "Turn on email notifications to receive updates about your donations, reports, and payments. Stay informed and never miss a thing!",
                    value: emailNotification,
                    onChanged: (val) {
                      setState(() => emailNotification = val);
                    },
                  ),

                  Divider(color: Colors.grey.shade400),

                  _buildSwitchTile(
                    title: "SMS Alert",
                    description:
                        "Get real-time updates on your donations and reports straight to your phone with SMS alerts.",
                    value: smsAlert,
                    onChanged: (val) {
                      setState(() => smsAlert = val);
                    },
                  ),

                  Divider(color: Colors.grey.shade400),

                  _buildSwitchTile(
                    title: "Daily Summary",
                    description:
                        "Get a quick overview of your daily activity, reports, and updates with our Daily Summary.",
                    value: dailySummary,
                    onChanged: (val) {
                      setState(() => dailySummary = val);
                    },
                  ),
                  const Spacer(),

                  Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1F2C47),
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          onPressed: () {},
                          child: const Text(
                            "Save",
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey.shade400,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          onPressed: () {},
                          child: const Text(
                            "Not now",
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String description,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F2C47),
                ),
              ),
            ),
            Switch(
              value: value,
              activeColor: Colors.white,
              activeTrackColor: const Color(0xFF1F2C47),
              onChanged: onChanged,
            ),
          ],
        ),
        const SizedBox(height: 5),
        Text(
          description,
          style: const TextStyle(fontSize: 13, color: Colors.black54),
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}
