import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/challenge.dart';
import '../models/progress_entry.dart';
import '../utils/date_utils.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  static const _keyChallenges = 'challenges';
  static const _keyProgress = 'progress';
  static const _keySettings = 'settings';

  // ── Challenges ──────────────────────────────────────────────

  Future<List<Challenge>> getChallenges() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyChallenges);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list.map((e) => Challenge.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> saveChallenges(List<Challenge> challenges) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyChallenges, jsonEncode(challenges.map((c) => c.toJson()).toList()));
  }

  Future<void> addChallenge(Challenge challenge) async {
    final challenges = await getChallenges();
    challenges.add(challenge);
    await saveChallenges(challenges);
  }

  Future<void> updateChallenge(Challenge updated) async {
    final challenges = await getChallenges();
    final idx = challenges.indexWhere((c) => c.id == updated.id);
    if (idx != -1) {
      challenges[idx] = updated;
      await saveChallenges(challenges);
    }
  }

  Future<void> deleteChallenge(String id) async {
    final challenges = await getChallenges();
    challenges.removeWhere((c) => c.id == id);
    await saveChallenges(challenges);
  }

  // ── Progress ─────────────────────────────────────────────────

  Future<Map<String, Map<String, ProgressEntry>>> getAllProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyProgress);
    if (raw == null) return {};
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return decoded.map((date, dayData) {
      final dayMap = (dayData as Map<String, dynamic>).map(
        (id, entryData) => MapEntry(
          id,
          ProgressEntry.fromJson(entryData as Map<String, dynamic>),
        ),
      );
      return MapEntry(date, dayMap);
    });
  }

  Future<Map<String, ProgressEntry>> getTodayProgress() async {
    final all = await getAllProgress();
    return all[AppDateUtils.todayKey()] ?? {};
  }

  Future<Map<String, ProgressEntry>> getProgressForDate(String dateKey) async {
    final all = await getAllProgress();
    return all[dateKey] ?? {};
  }

  Future<void> saveEntryForToday(String challengeId, ProgressEntry entry) async {
    final all = await getAllProgress();
    final todayKey = AppDateUtils.todayKey();
    all[todayKey] ??= {};
    all[todayKey]![challengeId] = entry;
    await _saveAllProgress(all);
  }

  Future<void> _saveAllProgress(Map<String, Map<String, ProgressEntry>> all) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = all.map((date, dayMap) {
      return MapEntry(date, dayMap.map((id, entry) => MapEntry(id, entry.toJson())));
    });
    await prefs.setString(_keyProgress, jsonEncode(encoded));
  }

  Future<void> resetTodayProgress() async {
    final all = await getAllProgress();
    all.remove(AppDateUtils.todayKey());
    await _saveAllProgress(all);
  }

  // ── Settings ─────────────────────────────────────────────────

  Future<Map<String, dynamic>> getSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keySettings);
    if (raw == null) {
      return {'notificationsEnabled': true, 'streakDays': 0};
    }
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<void> saveSettings(Map<String, dynamic> settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keySettings, jsonEncode(settings));
  }

  Future<int> getStreak() async {
    final s = await getSettings();
    return (s['streakDays'] as int?) ?? 0;
  }

  Future<void> recalculateStreak(List<Challenge> activeChallenges) async {
    if (activeChallenges.isEmpty) return;
    final all = await getAllProgress();
    int streak = 0;
    DateTime day = DateTime.now();

    while (true) {
      final key = AppDateUtils.dateKey(day);
      final dayProgress = all[key];
      if (dayProgress == null) break;

      final allCompleted = activeChallenges.every((c) {
        if (c.intervalHours <= 0) {
          return dayProgress[c.id]?.completed == true;
        }
        // Para recurrentes: al menos un slot completado ese día
        final parts = c.reminderTime.split(':');
        int hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);
        while (hour < 24) {
          final t = '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
          if (dayProgress['${c.id}:$t']?.completed == true) return true;
          hour += c.intervalHours;
        }
        return false;
      });

      if (!allCompleted) break;
      streak++;
      day = day.subtract(const Duration(days: 1));
    }

    final settings = await getSettings();
    settings['streakDays'] = streak;
    await saveSettings(settings);
  }
}
