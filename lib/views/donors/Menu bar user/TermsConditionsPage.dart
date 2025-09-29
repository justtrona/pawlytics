import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TermsConditionsPage extends StatefulWidget {
  const TermsConditionsPage({super.key});

  @override
  State<TermsConditionsPage> createState() => _TermsConditionsPageState();
}

class _TermsConditionsPageState extends State<TermsConditionsPage> {
  bool isChecked = false;

  @override
  void initState() {
    super.initState();
    _loadAgreement();
  }

  Future<void> _loadAgreement() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isChecked = prefs.getBool('termsAgreed') ?? false;
    });
  }

  Future<void> _saveAgreement(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('termsAgreed', value);
  }

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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.pets, size: 50, color: Color(0xFF1F2C47)),
            const SizedBox(height: 8),

            const Text(
              "Terms & Conditions",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2C47),
              ),
            ),
            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Welcome to Pawlytics! Please read these Terms and Conditions carefully before using our app.\n\n",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                      height: 1.5,
                    ),
                  ),
                  RichText(
                    text: const TextSpan(
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                        height: 1.5,
                      ),
                      children: [
                        TextSpan(
                          text: "1. Use of the App\n",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Color(0xFF1F2C47),
                          ),
                        ),
                        TextSpan(
                          text:
                              "By using Pawlytics, you agree to act responsibly and respectfully within the app. You must be 13 years old or older to use our services.\n\n",
                        ),
                        TextSpan(
                          text: "2. User Responsibilities\n",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Color(0xFF1F2C47),
                          ),
                        ),
                        TextSpan(
                          text:
                              "You are responsible for the information you provide. You agree not to upload false, harmful, or misleading content.\n\n",
                        ),
                        TextSpan(
                          text: "3. Privacy and Data\n",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Color(0xFF1F2C47),
                          ),
                        ),
                        TextSpan(
                          text:
                              "We respect your privacy. Your personal data, including donation history and pet preferences, will only be used to improve your experience. Read our full Privacy Policy for details.\n\n",
                        ),
                        TextSpan(
                          text: "4. Donations and Transactions\n",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Color(0xFF1F2C47),
                          ),
                        ),
                        TextSpan(
                          text:
                              "All donations are final and non-refundable unless explicitly stated. Transaction histories are securely stored and accessible within your profile.\n",
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(left: 8),
                    child: Text.rich(
                      TextSpan(
                        text: "I Agree with the ",
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                        children: [
                          TextSpan(
                            text: "Terms and Conditions",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1F2C47),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Checkbox(
                  value: isChecked,
                  activeColor: const Color(0xFF1F2C47),
                  onChanged: (val) {
                    setState(() {
                      isChecked = val ?? false;
                      _saveAgreement(isChecked);
                    });
                  },
                ),
              ],
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isChecked
                      ? const Color(0xFF1F2C47)
                      : Colors.grey,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                onPressed: isChecked
                    ? () async {
                        // Save agreement
                        await _saveAgreement(true);

                        // Show confirmation dialog
                        showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              title: const Text(
                                "Agreement Accepted",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              content: const Text(
                                "Thank you for accepting the Terms & Conditions.",
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context); // close dialog
                                    Navigator.pop(
                                      context,
                                      true,
                                    ); // go back to prev page
                                  },
                                  child: const Text("Close"),
                                ),
                              ],
                            );
                          },
                        );
                      }
                    : null,
                child: const Text(
                  "I Agree",
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
