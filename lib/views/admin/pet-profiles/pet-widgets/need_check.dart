import 'package:flutter/material.dart';

const brand = Color(0xFF27374D);

class NeedCheck extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const NeedCheck({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      value: value,
      onChanged: (v) => onChanged(v ?? false),
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: const EdgeInsets.only(right: 12),
      dense: true,
      checkboxShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
      ),
      activeColor: brand,
      checkColor: Colors.white,
      title: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF212C36),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
