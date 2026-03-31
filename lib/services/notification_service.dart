import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/challenge.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await _plugin.initialize(initSettings);
  }

  Future<void> requestPermissions() async {
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.requestNotificationsPermission();
  }

  Future<void> scheduleDailyNotification(Challenge challenge) async {
    await cancelNotification(challenge.id);

    final parts = challenge.reminderTime.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);

    final now = DateTime.now();
    DateTime scheduledDate = DateTime(now.year, now.month, now.day, hour, minute);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    final notifId = _idFromChallengeId(challenge.id);

    await _plugin.zonedSchedule(
      notifId,
      '${challenge.emoji} ${challenge.title}',
      '¿Lo vas a hacer o seguís siendo el mismo de siempre?',
      _toTZDateTime(scheduledDate),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_challenges',
          'Retos Diarios',
          channelDescription: 'Recordatorios de tus retos',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> schedulePostponeNotification(Challenge challenge) async {
    final postponeId = _idFromChallengeId(challenge.id) + 10000;
    await _plugin.cancel(postponeId);

    final scheduledDate = DateTime.now().add(const Duration(hours: 2));

    await _plugin.zonedSchedule(
      postponeId,
      '${challenge.emoji} Todavía está pendiente...',
      'Lo postergaste. Seguís igual. ${challenge.title}.',
      _toTZDateTime(scheduledDate),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'postpone_reminders',
          'Recordatorios de Postergación',
          channelDescription: 'Te avisa cuando postergaste un reto',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancelNotification(String challengeId) async {
    await _plugin.cancel(_idFromChallengeId(challengeId));
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  int _idFromChallengeId(String id) {
    return id.hashCode.abs() % 100000;
  }

  // ignore: deprecated_member_use
  dynamic _toTZDateTime(DateTime dt) => dt;
}
