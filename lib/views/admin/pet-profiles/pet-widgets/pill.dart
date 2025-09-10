import 'package:flutter/material.dart';

const brand = Color(0xFF27374D);

class Pill extends StatelessWidget {
  final String label;
  final bool selected;
  final bool outlineOnly;
  final VoidCallback onTap;

  const Pill({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.outlineOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    final bg = selected && !outlineOnly ? brand : Colors.white;
    final fg = selected && !outlineOnly ? Colors.white : brand;
    final side = BorderSide(color: brand, width: 1.3);

    return SizedBox(
      height: 44,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          side: side,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
        child: Text(label),
      ),
    );
  }
}
