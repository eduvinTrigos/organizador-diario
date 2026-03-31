import 'dart:math';
import 'package:flutter/material.dart';
import '../models/challenge.dart';
import '../models/progress_entry.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';
import '../data/messages.dart';
import '../utils/date_utils.dart';
import '../widgets/challenge_card.dart';
import '../widgets/progress_bar.dart';
import '../widgets/brutal_message_dialog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

// Representa una fila en el listado: un reto en un horario concreto.
class _ChallengeSlot {
  final Challenge challenge;
  final String time;        // "HH:MM"
  final String progressKey; // challenge.id  o  challenge.id:HH:MM
  final bool isRecurring;

  const _ChallengeSlot({
    required this.challenge,
    required this.time,
    required this.progressKey,
    required this.isRecurring,
  });
}

class _HomeScreenState extends State<HomeScreen> {
  final _storage = StorageService();
  final _notifications = NotificationService();

  List<Challenge> _challenges = [];
  Map<String, ProgressEntry> _todayProgress = {};
  Map<String, Map<String, ProgressEntry>> _allProgress = {};
  int _streak = 0;
  bool _loading = true;

  static const _weekLetters = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final challenges = await _storage.getChallenges();
    final progress = await _storage.getTodayProgress();
    final allProgress = await _storage.getAllProgress();
    final streak = await _storage.getStreak();
    setState(() {
      _challenges = challenges.where((c) => c.active).toList();
      _todayProgress = progress;
      _allProgress = allProgress;
      _streak = streak;
      _loading = false;
    });
  }

  // Genera la lista plana de slots ordenada por hora.
  List<_ChallengeSlot> get _slots {
    final slots = <_ChallengeSlot>[];
    for (final c in _challenges) {
      if (c.intervalHours <= 0) {
        slots.add(_ChallengeSlot(
          challenge: c,
          time: c.reminderTime,
          progressKey: c.id,
          isRecurring: false,
        ));
      } else {
        final parts = c.reminderTime.split(':');
        int hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);
        while (hour < 24) {
          final t = '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
          slots.add(_ChallengeSlot(
            challenge: c,
            time: t,
            progressKey: '${c.id}:$t',
            isRecurring: true,
          ));
          hour += c.intervalHours;
        }
      }
    }
    slots.sort((a, b) => a.time.compareTo(b.time));
    return slots;
  }

  Future<void> _complete(Challenge challenge, String progressKey) async {
    final entry = _todayProgress[progressKey] ?? ProgressEntry(completed: false, postponedCount: 0);
    if (entry.completed) return;

    entry.completed = true;
    entry.completedAt = AppDateUtils.currentTime();
    await _storage.saveEntryForToday(progressKey, entry);

    await _storage.recalculateStreak(_challenges);
    final newStreak = await _storage.getStreak();

    final category = challenge.title.toLowerCase().contains('agua')
        ? MessageCategory.brutalWater
        : MessageCategory.brutalPositive;
    final msg = getRandomMessage(category);

    setState(() {
      _todayProgress[progressKey] = entry;
      _allProgress[AppDateUtils.todayKey()] = Map.from(_todayProgress);
      _streak = newStreak;
    });

    if (mounted) {
      await BrutalMessageDialog.show(context, msg, isPositive: true);
    }
  }

  Future<void> _postpone(Challenge challenge, String progressKey) async {
    final entry = _todayProgress[progressKey] ?? ProgressEntry(completed: false, postponedCount: 0);
    if (entry.completed) return;

    entry.postponedCount++;
    await _storage.saveEntryForToday(progressKey, entry);
    await _notifications.schedulePostponeNotification(challenge);

    final msg = getPostponeMessage(entry.postponedCount);

    setState(() {
      _todayProgress[progressKey] = entry;
    });

    if (mounted) {
      await BrutalMessageDialog.show(context, msg, isPositive: false);
    }
  }

  // ── Métricas ─────────────────────────────────────────────────────────────

  bool get _allCompleted {
    final s = _slots;
    if (s.isEmpty) return false;
    return s.every((sl) => _todayProgress[sl.progressKey]?.completed == true);
  }

  int get _totalSlots => _slots.length;
  int get _completedSlots =>
      _slots.where((sl) => _todayProgress[sl.progressKey]?.completed == true).length;

  double get _completionRatio =>
      _totalSlots == 0 ? 0 : _completedSlots / _totalSlots;

  // ── Semana ────────────────────────────────────────────────────────────────

  List<bool?> get _weekDayStatuses {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    return List.generate(7, (i) {
      final day = monday.add(Duration(days: i));
      if (day.isAfter(DateTime(now.year, now.month, now.day))) return null;
      final key = AppDateUtils.dateKey(day);
      final dayProgress = _allProgress[key];
      if (dayProgress == null || _challenges.isEmpty) return null;
      final allDone = _challenges.every((c) {
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
      return allDone;
    });
  }

  int get _weekCompletedDays =>
      _weekDayStatuses.where((s) => s == true).length;

  int get _weekDaysSoFar => DateTime.now().weekday;

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final months = ['Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
        'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'];
    final todayStr = '${now.day} de ${months[now.month - 1]}';
    final slots = _slots;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : RefreshIndicator(
              onRefresh: _load,
              child: CustomScrollView(
                slivers: [
                  SliverAppBar(
                    backgroundColor: const Color(0xFF0F0F0F),
                    expandedHeight: 120,
                    pinned: true,
                    flexibleSpace: FlexibleSpaceBar(
                      background: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 50, 20, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(todayStr,
                                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                                if (_streak > 0)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.orange[900],
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text('🔥 $_streak días',
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            AppProgressBar(value: _completionRatio),
                          ],
                        ),
                      ),
                    ),
                  ),

                  if (_allCompleted)
                    SliverToBoxAdapter(
                      child: Container(
                        margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.green[900],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green[700]!),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('✅', style: TextStyle(fontSize: 24)),
                            SizedBox(width: 8),
                            Text('¡Todo listo por hoy!',
                                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),

                  // ── Sección Semana ────────────────────────────────────
                  if (_challenges.isNotEmpty)
                    SliverToBoxAdapter(
                      child: _SectionCard(
                        title: 'Semana',
                        child: Row(
                          children: [
                            _DonutChart(
                              completed: _weekCompletedDays,
                              total: _weekDaysSoFar,
                              color: const Color(0xFF16A34A),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('$_weekCompletedDays de $_weekDaysSoFar días completados',
                                      style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: List.generate(7, (i) => _DayBubble(
                                      label: _weekLetters[i],
                                      status: _weekDayStatuses[i],
                                    )),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // ── Sección Hoy ───────────────────────────────────────
                  if (_challenges.isNotEmpty)
                    SliverToBoxAdapter(
                      child: _SectionCard(
                        title: 'Hoy',
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _DonutChart(
                              completed: _completedSlots,
                              total: _totalSlots,
                              color: const Color(0xFF3B82F6),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('$_completedSlots de $_totalSlots completados',
                                      style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                                  const SizedBox(height: 12),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: slots.map((sl) {
                                      final done = _todayProgress[sl.progressKey]?.completed == true;
                                      return _ChallengeBubble(
                                        challenge: sl.challenge,
                                        completed: done,
                                        slotTime: sl.isRecurring ? sl.time : null,
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // ── Sin retos ─────────────────────────────────────────
                  if (_challenges.isEmpty)
                    SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('😴', style: TextStyle(fontSize: 48)),
                            const SizedBox(height: 16),
                            const Text('No tenés retos activos.', style: TextStyle(color: Colors.white, fontSize: 18)),
                            const SizedBox(height: 8),
                            Text('Andá a la pestaña Retos y creá uno.',
                                style: TextStyle(color: Colors.grey[500])),
                          ],
                        ),
                      ),
                    )
                  else ...[
                    // ── Lista de slots ordenada por hora ─────────────────
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                        child: Text('Retos del día',
                            style: TextStyle(color: Colors.grey[500], fontSize: 13, fontWeight: FontWeight.w600)),
                      ),
                    ),
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, i) {
                          final sl = slots[i];
                          return ChallengeCard(
                            challenge: sl.challenge,
                            entry: _todayProgress[sl.progressKey],
                            slotTime: sl.isRecurring ? sl.time : null,
                            onComplete: () => _complete(sl.challenge, sl.progressKey),
                            onPostpone: () => _postpone(sl.challenge, sl.progressKey),
                          );
                        },
                        childCount: slots.length,
                      ),
                    ),
                  ],

                  const SliverToBoxAdapter(child: SizedBox(height: 20)),
                ],
              ),
            ),
    );
  }
}

// ── Widgets privados ─────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _DayBubble extends StatelessWidget {
  final String label;
  final bool? status;
  const _DayBubble({required this.label, required this.status});

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Widget icon;
    if (status == null) {
      bg = Colors.grey[850]!;
      icon = Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold));
    } else if (status!) {
      bg = Colors.green[700]!;
      icon = const Icon(Icons.check, color: Colors.white, size: 14);
    } else {
      bg = Colors.red[900]!;
      icon = const Icon(Icons.close, color: Colors.white, size: 14);
    }
    return Column(
      children: [
        Container(
          width: 30, height: 30,
          decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
          child: Center(child: icon),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 10)),
      ],
    );
  }
}

class _ChallengeBubble extends StatelessWidget {
  final Challenge challenge;
  final bool completed;
  final String? slotTime;
  const _ChallengeBubble({required this.challenge, required this.completed, this.slotTime});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 38, height: 38,
          decoration: BoxDecoration(
            color: completed ? Colors.green[700] : Colors.grey[850],
            shape: BoxShape.circle,
            border: Border.all(
              color: completed ? Colors.green[500]! : Color(challenge.colorValue).withOpacity(0.5),
              width: 1.5,
            ),
          ),
          child: Center(
            child: completed
                ? const Icon(Icons.check, color: Colors.white, size: 16)
                : Text(challenge.emoji, style: const TextStyle(fontSize: 18)),
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          width: 38,
          child: Text(
            slotTime ?? challenge.title.split(' ').first,
            style: TextStyle(color: Colors.grey[500], fontSize: 9),
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}

class _DonutChart extends StatelessWidget {
  final int completed;
  final int total;
  final Color color;
  const _DonutChart({required this.completed, required this.total, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 80, height: 80,
      child: CustomPaint(painter: _DonutPainter(completed: completed, total: total, color: color)),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final int completed;
  final int total;
  final Color color;
  _DonutPainter({required this.completed, required this.total, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 3;
    canvas.drawCircle(center, radius,
        Paint()..color = Colors.grey[800]!..style = PaintingStyle.fill);
    if (total > 0 && completed > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -pi / 2,
        2 * pi * (completed / total),
        true,
        Paint()..color = color..style = PaintingStyle.fill,
      );
    }
    canvas.drawCircle(center, radius * 0.58,
        Paint()..color = const Color(0xFF1A1A1A)..style = PaintingStyle.fill);
    final text = total == 0 ? '-' : '$completed/$total';
    final tp = TextPainter(
      text: TextSpan(
          text: text,
          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(center.dx - tp.width / 2, center.dy - tp.height / 2));
  }

  @override
  bool shouldRepaint(_DonutPainter old) => old.completed != completed || old.total != total;
}
