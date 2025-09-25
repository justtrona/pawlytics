import 'package:flutter/material.dart';

class AboutUsPage extends StatelessWidget {
  const AboutUsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            
            const Icon(Icons.home, size: 60, color: Color(0xFF1A2C50)),

            const SizedBox(height: 12),

            
            const Text(
              "Mission & Vision",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A2C50),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              "Our mission is to rescue abused and abandoned pets, provide "
              "them with proper care, and help them find loving homes.\n\n"
              "A community where every pet is safe, loved and cared for.",
              style: TextStyle(
                fontSize: 15,
                color: Colors.black87,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 25),

            
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Our Story",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Founded by passionate volunteers in 2010, we began rescuing pets "
              "from the streets of Davao City. Today, with the help of your "
              "growing community, we continue to fight for every animal’s right "
              "to live with dignity",
              style: TextStyle(
                fontSize: 15,
                color: Colors.black87,
                height: 1.5,
              ),
              textAlign: TextAlign.start,
            ),

            const SizedBox(height: 25),

            
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "What We Do",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: 12),

            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                buildAction(Icons.pets, "Rescue", "Saving abandoned pets"),
                buildAction(Icons.favorite, "Adopt", "Finding loving homes"),
              ],
            ),
            const SizedBox(height: 16),

            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                buildAction(
                  Icons.health_and_safety,
                  "Care",
                  "Providing medical treatment",
                ),
                buildAction(
                  Icons.campaign,
                  "Awareness",
                  "Promoting pet welfare",
                ),
              ],
            ),

            const SizedBox(height: 25),
            Divider(thickness: 1),

            const SizedBox(height: 25),

            
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  
                  Container(
                    height: 80,
                    width: 100,
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.map, color: Colors.green, size: 40),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Brgy. Malagamot,\nDavao city",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          "+63 913 323 4591",
                          style: TextStyle(fontSize: 15, color: Colors.black87),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),
          ],
        ),
      ),
    );
  }

  
  Widget buildAction(IconData icon, String title, String subtitle) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        margin: const EdgeInsets.symmetric(horizontal: 5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, size: 28, color: const Color(0xFF1A2C50)),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 13, color: Colors.black54),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
