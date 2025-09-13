import 'package:flutter/material.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final TextEditingController currentPasswordController =
      TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  bool showCurrent = false;
  bool showNew = false;
  bool showConfirm = false;

  @override
  Widget build(BuildContext context) {
    final newPassword = newPasswordController.text;

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
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.lock, size: 32, color: Color(0xFF1F2C47)),
                    SizedBox(width: 8),
                    Text(
                      "Change Password",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2C47),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  "Update Password for enhanced account security.",
                  style: TextStyle(fontSize: 14, color: Color(0xFF1F2C47)),
                  textAlign: TextAlign.center,
                ),
              ],
            ),

            const Divider(height: 30),
            const SizedBox(height: 20),

            _buildPasswordField(
              controller: currentPasswordController,
              label: "Current Password",
              obscureText: !showCurrent,
              onToggle: () => setState(() => showCurrent = !showCurrent),
            ),
            const SizedBox(height: 16),

            _buildPasswordField(
              controller: newPasswordController,
              label: "New Password",
              obscureText: !showNew,
              onToggle: () => setState(() => showNew = !showNew),
              onChanged: (val) => setState(() {}),
            ),
            const SizedBox(height: 16),

            _buildPasswordField(
              controller: confirmPasswordController,
              label: "Confirm New Password",
              obscureText: !showConfirm,
              onToggle: () => setState(() => showConfirm = !showConfirm),
            ),
            const SizedBox(height: 20),

            _buildPasswordRules(newPassword),

            const Spacer(),

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
                    onPressed: () {},
                    child: const Text(
                      "Apply Changes",
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
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text(
                      "Discard",
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

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool obscureText,
    required VoidCallback onToggle,
    ValueChanged<String>? onChanged,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          fontSize: 14,
          color: Colors.black87,
          fontWeight: FontWeight.w500,
        ),
        filled: true,
        fillColor: Colors.grey.shade200,
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () => controller.clear(),
            ),
            IconButton(
              icon: Icon(obscureText ? Icons.visibility : Icons.visibility_off),
              onPressed: onToggle,
            ),
          ],
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildPasswordRules(String password) {
    bool hasUpper = password.contains(RegExp(r'[A-Z]'));
    bool hasNumber = password.contains(RegExp(r'[0-9]'));
    bool hasLength = password.length >= 8;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildRule("At least 1 uppercase", hasUpper),
        _buildRule("At least 1 number", hasNumber),
        _buildRule("At least 8 characters", hasLength),
      ],
    );
  }

  Widget _buildRule(String text, bool passed) {
    return Row(
      children: [
        Icon(
          passed ? Icons.check_circle : Icons.cancel,
          size: 18,
          color: passed ? Colors.green : Colors.grey,
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            fontSize: 14,
            color: passed ? Colors.green : Colors.black87,
          ),
        ),
      ],
    );
  }
}
