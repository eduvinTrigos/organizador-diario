class Challenge {
  final String id;
  String title;
  String emoji;
  int colorValue;
  String reminderTime;
  int intervalHours; // 0 = single daily, 2/4/6/8 = repeat every N hours
  bool active;
  String createdAt;

  Challenge({
    required this.id,
    required this.title,
    required this.emoji,
    required this.colorValue,
    required this.reminderTime,
    this.intervalHours = 0,
    required this.active,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'emoji': emoji,
        'colorValue': colorValue,
        'reminderTime': reminderTime,
        'intervalHours': intervalHours,
        'active': active,
        'createdAt': createdAt,
      };

  factory Challenge.fromJson(Map<String, dynamic> json) => Challenge(
        id: json['id'] as String,
        title: json['title'] as String,
        emoji: json['emoji'] as String,
        colorValue: json['colorValue'] as int,
        reminderTime: json['reminderTime'] as String,
        intervalHours: (json['intervalHours'] as int?) ?? 0,
        active: json['active'] as bool,
        createdAt: json['createdAt'] as String,
      );
}
