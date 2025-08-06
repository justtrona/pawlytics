import 'package:flutter/material.dart';

class ColoredContainer extends StatelessWidget {
  final Color color;

  const ColoredContainer({super.key, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200, // Height of the colored container
      width: 200, // Add this
      margin: const EdgeInsets.only(left: 16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }
}
