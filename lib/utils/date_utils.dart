class AppDateUtils {
  static String todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  static String dateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  static String currentTime() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }

  static List<DateTime> daysInMonth(int year, int month) {
    final lastDay = DateTime(year, month + 1, 0);
    return List.generate(
      lastDay.day,
      (i) => DateTime(year, month, i + 1),
    );
  }

  static int firstWeekdayOfMonth(int year, int month) {
    // Monday = 0, Sunday = 6
    return (DateTime(year, month, 1).weekday - 1) % 7;
  }
}
