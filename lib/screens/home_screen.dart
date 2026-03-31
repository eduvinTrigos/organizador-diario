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

  Future<void> _complete(Challenge challenge) async {
    final entry = _todayProgress[challenge.id] ?? ProgressEntry(completed: false, postponedCount: 0);
    if (entry.completed) return;

    entry.completed = true;
    entry.completedAt = AppDateUtils.currentTime();
    await _storage.saveEntryForToday(challenge.id, entry);

    final activeChallenges = _challenges;
    await _storage.recalculateStreak(activeChallenges);
    final newStreak = await _storage.getStreak();

    final category = challenge.title.toLowerCase().contains('agua')
        ? MessageCategory.brutalWater
        : MessageCategory.brutalPositive;
    final msg = getRandomMessage(category);

    setState(() {
      _todayProgress[challenge.id] = entry;
      _allProgress[AppDateUtils.todayKey()] = Map.from(_todayProgress);
      _streak = newStreak;
    });

    if (mounted) {
      await BrutalMessageDialog.show(context, msg, isPositive: true);
    }
  }

  Future<void> _postpone(Challenge challenge) async {
    final entry = _todayProgress[challenge.id] ?? ProgressEntry(completed: false, postponedCount: 0);
    if (entry.completed) return;

    entry.postponedCount++;
    await _storage.saveEntryForToday(challenge.id, entry);
    await _notifications.schedulePostponeNotification(challenge);

    final msg = getPostponeMessage(entry.postponedCount);

    setState(() {
      _todayProgress[challenge.id] = entry;
    });

    if (mounted) {
      await BrutalMessageDialog.show(context, msg, isPositive: false);
    }
  }

  bool get _allCompleted {
    if (_challenges.isEmpty) return false;
    return _challenges.every((c) => _todayProgress[c.id]?.completed == true);
  }

  double get _completionRatio {
    if (_challenges.isEmpty) return 0;
    final done = _challenges.where((c) => _todayProgress[c.id]?.completed == true).length;
    return done / _challenges.length;
  }

  int get _todayCompleted =>
      _challenges.where((c) => _todayProgress[c.id]?.completed == true).length;

  // Returns bool? per weekday: true=all done, false=partial/none, null=no data/future
  List<bool?> get _weekDayStatuses {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    return List.generate(7, (i) {
      final day = monday.add(Duration(days: i));
      if (day.isAfter(DateTime(now.year, now.month, now.day))) return null;
      final key = AppDateUtils.dateKey(day);
      final dayProgress = _allProgress[key];
      if (dayProgress == null || _challenges.isEmpty) return null;
      final allDone = _challenges.every((c) => dayProgress[c.id]?.completed == true);
      return allDone;
    });
  }

  int get _weekCompletedDays =>
      _weekDayStatuses.where((s) => s == true).length;

  int get _weekDaysSoFar {
    final now = DateTime.now();
    return now.weekday; // 1=Mon .. 7=Sun
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final months = ['Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
        'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'];
    final todayStr = '${now.day} de ${months[now.month - 1]}';

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
                                Text(
                                  todayStr,
                                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                                ),
                                if (_streak > 0)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.orange[900],
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      '🔥 $_streak días',
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                    ),
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
                            Text(
                              '¡Todo listo por hoy!',
                              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // ── Sección Semana ──────────────────────────────
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
                                  Text(
                                    '$_weekCompletedDays de $_weekDaysSoFar días completados',
                                    style: TextStyle(color: Colors.grey[400], fontSize: 12),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: List.generate(7, (i) {
                                      final status = _weekDayStatuses[i];
                                      return _DayBubble(
                                        label: _weekLetters[i],
                                        status: status,
                                      );
                                    }),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // ── Sección Hoy ─────────────────────────────────
                  if (_challenges.isNotEmpty)
                    SliverToBoxAdapter(
                      child: _SectionCard(
                        title: 'Hoy',
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _DonutChart(
                              completed: _todayCompleted,
                              total: _challenges.length,
                              color: const Color(0xFF3B82F6),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '$_todayCompleted de ${_challenges.length} retos completados',
                                    style: TextStyle(color: Colors.grey[400], fontSize: 12),
                                  ),
                                  const SizedBox(height: 12),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: _challenges.map((c) {
                                      final done = _todayProgress[c.id]?.completed == true;
                                      return _ChallengeBubble(
                                        challenge: c,
                                        completed: done,
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
                            Text('Andá a la pestaña Retos y creá uno.', style: TextStyle(color: Colors.grey[500])),
                          ],
                        ),
                      ),
                    )
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, i) {
                          final challenge = _challenges[i];
                          return ChallengeCard(
                            challenge: challenge,
                            entry: _todayProgress[challenge.id],
                            onComplete: () => _complete(challenge),
                            onPostpone: () => _postpone(challenge),
                          );
                        },
                        childCount: _challenges.length,
                      ),
                    ),

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
          Text(
            title,
            style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _DayBubble extends StatelessWidget {
  final String label;
  final bool? status; // true=done, false=missed, null=no data

  const _DayBubble({required this.label, required this.status});

  @override
  Widget build(BuildContext context) {
    final Color bgColor;
    final Widget icon;

    if (status == null) {
      bgColor = Colors.grey[850]!;
      icon = Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold));
    } else if (status!) {
      bgColor = Colors.green[700]!;
      icon = const Icon(Icons.check, color: Colors.white, size: 14);
    } else {
      bgColor = Colors.red[900]!;
      icon = const Icon(Icons.close, color: Colors.white, size: 14);
    }

    return Column(
      children: [
        Container(
          width: 30, height: 30,
          decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
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

  const _ChallengeBubble({required this.challenge, required this.completed});

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
            challenge.title.split(' ').first,
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
      child: CustomPaint(
        painter: _DonutPainter(completed: completed, total: total, color: color),
      ),
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
    const innerRatio = 0.58;

    // Background ring
    final bgPaint = Paint()
      ..color = Colors.grey[800]!
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, bgPaint);

    // Completed arc
    if (total > 0 && completed > 0) {
      final fillPaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;
      final sweepAngle = 2 * pi * (completed / (total == 0 ? 1 : total));
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -pi / 2,
        sweepAngle,
        true,
        fillPaint,
      );
    }

    // Inner cutout (donut hole)
    final holePaint = Paint()
      ..color = const Color(0xFF1A1A1A)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * innerRatio, holePaint);

    // Center text
    final text = total == 0 ? '-' : '$completed/$total';
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(center.dx - tp.width / 2, center.dy - tp.height / 2));
  }

  @override
  bool shouldRepaint(_DonutPainter old) =>
      old.completed != completed || old.total != total;
}
