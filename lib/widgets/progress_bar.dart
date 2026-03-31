import 'package:flutter/material.dart';

class AppProgressBar extends StatelessWidget {
  final double value; // 0.0 a 1.0
  final Color color;
  final double height;

  const AppProgressBar({
    super.key,
    required this.value,
    this.color = const Color(0xFF16A34A),
    this.height = 8,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: LinearProgressIndicator(
        value: value.clamp(0.0, 1.0),
        backgroundColor: const Color(0xFF2D2D2D),
        valueColor: AlwaysStoppedAnimation<Color>(color),
        minHeight: height,
      ),
    );
  }
}
