import 'package:flutter/material.dart';

class HomeHeaderSection extends StatelessWidget {
  final String greeting;
  final Color accentColor;

  const HomeHeaderSection({
    super.key,
    required this.greeting,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            greeting,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: accentColor,
            ),
          ),
          Icon(
            Icons.notifications_none,
            color: accentColor,
            size: 28,
          ),
        ],
      ),
    );
  }
}
