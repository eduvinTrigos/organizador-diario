import 'package:flutter/material.dart';
import '../models/challenge.dart';
import '../models/progress_entry.dart';
import '../utils/date_utils.dart';

class CalendarGrid extends StatelessWidget {
  final int year;
  final int month;
  final Map<String, Map<String, ProgressEntry>> allProgress;
  final List<Challenge> challenges;
  final void Function(String dateKey, Map<String, ProgressEntry> dayProgress) onDayTap;

  const CalendarGrid({
    super.key,
    required this.year,
    required this.month,
    required this.allProgress,
    required this.challenges,
    required this.onDayTap,
  });

  Color _colorForDay(String dateKey) {
    final dayProgress = allProgress[dateKey];
    final activeChallenges = challenges.where((c) => c.active).toList();
    if (activeChallenges.isEmpty || dayProgress == null) return Colors.grey[800]!;

    final completed = activeChallenges.where((c) {
      final entry = dayProgress[c.id];
      return entry != null && entry.completed;
    }).length;

    final ratio = completed / activeChallenges.length;
    if (ratio == 1.0) return Colors.green[800]!;
    if (ratio >= 0.5) return Colors.green[300]!;
    if (ratio > 0) return Colors.yellow[700]!;
    return Colors.red[400]!;
  }

  @override
  Widget build(BuildContext context) {
    final days = AppDateUtils.daysInMonth(year, month);
    final firstWeekday = AppDateUtils.firstWeekdayOfMonth(year, month);
    final todayKey = AppDateUtils.todayKey();
    final weekDays = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];

    return Column(
      children: [
        // Cabecera días semana
        Row(
          children: weekDays
              .map((d) => Expanded(
                    child: Center(
                      child: Text(
                        d,
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 8),
        // Grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
          ),
          itemCount: days.length + firstWeekday,
          itemBuilder: (context, index) {
            if (index < firstWeekday) return const SizedBox.shrink();
            final day = days[index - firstWeekday];
            final dateKey = AppDateUtils.dateKey(day);
            final isToday = dateKey == todayKey;
            final color = _colorForDay(dateKey);
            final dayProgress = allProgress[dateKey] ?? {};

            return GestureDetector(
              onTap: () => onDayTap(dateKey, dayProgress),
              child: Container(
                decoration: BoxDecoration(
                  color: color.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(6),
                  border: isToday
                      ? Border.all(color: Colors.white, width: 2)
                      : Border.all(color: color.withOpacity(0.5), width: 1),
                ),
                child: Center(
                  child: Text(
                    '${day.day}',
                    style: TextStyle(
                      color: isToday ? Colors.white : Colors.grey[300],
                      fontSize: 13,
                      fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
