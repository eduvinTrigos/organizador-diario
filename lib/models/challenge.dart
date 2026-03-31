class Challenge {
  final String id;
  String title;
  String emoji;
  int colorValue;
  String reminderTime;
  bool active;
  String createdAt;

  Challenge({
    required this.id,
    required this.title,
    required this.emoji,
    required this.colorValue,
    required this.reminderTime,
    required this.active,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'emoji': emoji,
        'colorValue': colorValue,
        'reminderTime': reminderTime,
        'active': active,
        'createdAt': createdAt,
      };

  factory Challenge.fromJson(Map<String, dynamic> json) => Challenge(
        id: json['id'] as String,
        title: json['title'] as String,
        emoji: json['emoji'] as String,
        colorValue: json['colorValue'] as int,
        reminderTime: json['reminderTime'] as String,
        active: json['active'] as bool,
        createdAt: json['createdAt'] as String,
      );
}
