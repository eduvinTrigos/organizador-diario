import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import '../models/challenge.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  // Each challenge can have up to this many notification slots (for recurring)
  static const _maxSlots = 15;

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

    final baseId = _idFromChallengeId(challenge.id);

    if (challenge.intervalHours <= 0) {
      await _scheduleSlot(challenge, baseId, hour, minute);
    } else {
      int slot = 0;
      int h = hour;
      while (h < 24) {
        await _scheduleSlot(challenge, baseId + slot, h, minute);
        slot++;
        h += challenge.intervalHours;
      }
    }
  }

  Future<void> _scheduleSlot(Challenge challenge, int notifId, int hour, int minute) async {
    final now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      notifId,
      '${challenge.emoji} ${challenge.title}',
      '¿Lo vas a hacer o seguís siendo el mismo de siempre?',
      scheduled,
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
    final postponeId = _idFromChallengeId(challenge.id) + 50000;
    await _plugin.cancel(postponeId);

    final scheduled = tz.TZDateTime.now(tz.local).add(const Duration(hours: 2));

    await _plugin.zonedSchedule(
      postponeId,
      '${challenge.emoji} Todavía está pendiente...',
      'Lo postergaste. Seguís igual. ${challenge.title}.',
      scheduled,
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
    final baseId = _idFromChallengeId(challengeId);
    for (int i = 0; i < _maxSlots; i++) {
      await _plugin.cancel(baseId + i);
    }
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  int _idFromChallengeId(String id) {
    return id.hashCode.abs() % 10000;
  }
}
