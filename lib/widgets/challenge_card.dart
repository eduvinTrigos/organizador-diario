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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Text(challenge.emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 10),
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
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      decoration: isCompleted ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  if (postponedCount > 0 && !isCompleted)
                    Text(
                      'Postergado $postponedCount ${postponedCount == 1 ? 'vez' : 'veces'}',
                      style: TextStyle(
                        color: postponedCount >= 3 ? Colors.red[400] : Colors.orange[400],
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
            ),
            if (isCompleted)
              const Icon(Icons.check_circle, color: Color(0xFF16A34A), size: 26)
            else ...[
              IconButton(
                onPressed: onComplete,
                icon: const Icon(Icons.check_circle_outline, color: Color(0xFF16A34A), size: 28),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                tooltip: 'Completar',
              ),
              IconButton(
                onPressed: onPostpone,
                icon: Icon(Icons.schedule, color: Colors.orange[400], size: 26),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                tooltip: 'Postergar',
              ),
            ],
          ],
        ),
      ),
    );
  }
}
