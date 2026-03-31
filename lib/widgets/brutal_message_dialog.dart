import 'package:flutter/material.dart';

class BrutalMessageDialog extends StatelessWidget {
  final String message;
  final bool isPositive;

  const BrutalMessageDialog({
    super.key,
    required this.message,
    required this.isPositive,
  });

  static Future<void> show(BuildContext context, String message, {bool isPositive = false}) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => BrutalMessageDialog(message: message, isPositive: isPositive),
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = isPositive ? const Color(0xFF16A34A) : const Color(0xFFDC2626);
    return AlertDialog(
      backgroundColor: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            isPositive ? '💪' : '😤',
            style: const TextStyle(fontSize: 48),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'ENTENDIDO',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
