import 'package:flutter/material.dart';

class ViewMore extends StatelessWidget {
  const ViewMore({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
        title: const Text(
          "Donation Usage",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2C47),
          ),
        ),
        centerTitle: true,
      ),
    );
  }
}
