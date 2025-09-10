import 'package:flutter/material.dart';

class ShelterPage extends StatelessWidget {
  const ShelterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
        title: const Text(
          "Shelter",
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
