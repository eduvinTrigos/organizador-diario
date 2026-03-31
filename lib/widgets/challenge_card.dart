import 'package:flutter/material.dart';
import '../models/challenge.dart';
import '../models/progress_entry.dart';

class ChallengeCard extends StatelessWidget {
  final Challenge challenge;
  final ProgressEntry? entry;
  final String? slotTime; // HH:MM para retos recurrentes
  final VoidCallback onComplete;
  final VoidCallback onPostpone;

  const ChallengeCard({
    super.key,
    required this.challenge,
    required this.entry,
    this.slotTime,
    required this.onComplete,
    required this.onPostpone,
  });

  @override
  Widget build(BuildContext context) {
    final isCompleted = entry?.completed ?? false;
    final postponedCount = entry?.postponedCount ?? 0;
    final cardColor = Color(challenge.colorValue).withOpacity(0.15);
    final borderColor = isCompleted ? const Color(0xFF16A34A) : Color(challenge.colorValue);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(challenge.emoji, style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (slotTime != null)
                        Text(
                          slotTime!,
                          style: TextStyle(
                            color: isCompleted ? Colors.grey[600] : Colors.grey[400],
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      Text(
                        challenge.title,
                        style: TextStyle(
                          color: isCompleted ? Colors.grey[400] : Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          decoration: isCompleted ? TextDecoration.lineThrough : null,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isCompleted)
                  const Icon(Icons.check_circle, color: Color(0xFF16A34A), size: 28),
              ],
            ),
            if (postponedCount > 0 && !isCompleted) ...[
              const SizedBox(height: 6),
              Text(
                'Postergado $postponedCount ${postponedCount == 1 ? 'vez' : 'veces'} hoy',
                style: TextStyle(
                  color: postponedCount >= 3 ? Colors.red[400] : Colors.orange[400],
                  fontSize: 12,
                ),
              ),
            ],
            if (!isCompleted) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onComplete,
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('COMPLETAR'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF16A34A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onPostpone,
                      icon: const Icon(Icons.schedule, size: 18),
                      label: const Text('POSTERGAR'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.orange[400],
                        side: BorderSide(color: Colors.orange[400]!),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
