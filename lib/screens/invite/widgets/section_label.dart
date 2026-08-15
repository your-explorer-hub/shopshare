import 'package:flutter/material.dart';

class InviteSectionLabel extends StatelessWidget {
  final String label;
  const InviteSectionLabel({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
    );
  }
}
