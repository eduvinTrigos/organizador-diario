class ProgressEntry {
  bool completed;
  String? completedAt;
  int postponedCount;

  ProgressEntry({
    required this.completed,
    this.completedAt,
    required this.postponedCount,
  });

  Map<String, dynamic> toJson() => {
        'completed': completed,
        'completedAt': completedAt,
        'postponedCount': postponedCount,
      };

  factory ProgressEntry.fromJson(Map<String, dynamic> json) => ProgressEntry(
        completed: json['completed'] as bool,
        completedAt: json['completedAt'] as String?,
        postponedCount: json['postponedCount'] as int,
      );
}
