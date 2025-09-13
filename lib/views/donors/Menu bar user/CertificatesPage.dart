import 'package:flutter/material.dart';

class CertificatesPage extends StatelessWidget {
  const CertificatesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text(
          "Certificates",
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        automaticallyImplyLeading: true, // ✅ show back button
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context); // ✅ goes back to previous screen
          },
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildCertCard(
            asset: "assets/images/donors/bronze.png",
            title: "Bronze Certificate",
            subtitle: "Earned on March 12, 2026",
            background: const Color(0xFFFFF3E0),
            buttons: [
              _buildActionButton(
                "Preview",
                Colors.white,
                const Color(0xFF1F2C47),
              ),
              _buildActionButton(
                "Download",
                const Color(0xFF1F2C47),
                Colors.white,
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildCertCard(
            asset: "assets/images/donors/silver.png",
            title: "Silver Certificate",
            subtitle: "₱900 out of ₱10,000",
            background: const Color(0xFFE0E0E0),
            progress: 0.09,
            extraText:
                "You're Almost There! Just Add ₱9100 to unlock this achievement.",
          ),
          const SizedBox(height: 20),
          _buildCertCard(
            asset: "assets/images/donors/gold.png",
            title: "Gold Certificate",
            subtitle: "₱11,000 to Unlock This Achievement",
            background: const Color(0xFFFFF9C4),
          ),
          const SizedBox(height: 20),
          _buildCertCard(
            asset: "assets/images/donors/silver.png",
            title: "Platinum Certificate",
            subtitle: "₱20,000 to Unlock This Achievement",
            background: const Color(0xFFEDE7F6),
          ),
          const SizedBox(height: 20),
          _buildCertCard(
            asset: "assets/images/donors/diamond.png",
            title: "Diamond Certificate",
            subtitle: "₱40,000 to Unlock This Achievement",
            background: const Color(0xFFE0F7FA),
          ),
        ],
      ),
    );
  }

  static Widget _buildCertCard({
    required String asset,
    required String title,
    required String subtitle,
    required Color background,
    double? progress,
    String? extraText,
    List<Widget>? buttons,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      height: 150,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.asset(asset, width: 100, height: 100, fit: BoxFit.contain),
          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 6),
                if (progress != null) ...[
                  LinearProgressIndicator(
                    value: progress,
                    color: const Color(0xFF1F2C47),
                    backgroundColor: Colors.white,
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  const SizedBox(height: 6),
                ],
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (extraText != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    extraText,
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ],
                if (buttons != null) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: buttons
                        .map(
                          (btn) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: btn,
                          ),
                        )
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildActionButton(
    String text,
    Color bgColor,
    Color textColor,
  ) {
    return ElevatedButton.icon(
      icon: Icon(
        text == "Preview" ? Icons.visibility : Icons.download,
        size: 16,
        color: textColor,
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: bgColor,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: textColor, width: 1),
        ),
        elevation: 0,
      ),
      onPressed: () {},
      label: Text(text, style: TextStyle(color: textColor, fontSize: 12)),
    );
  }
}
