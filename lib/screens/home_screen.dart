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
  int _streak = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final challenges = await _storage.getChallenges();
    final progress = await _storage.getTodayProgress();
    final streak = await _storage.getStreak();
    setState(() {
      _challenges = challenges.where((c) => c.active).toList();
      _todayProgress = progress;
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

    // Elegir categoría según el reto
    final category = challenge.title.toLowerCase().contains('agua')
        ? MessageCategory.brutalWater
        : MessageCategory.brutalPositive;
    final msg = getRandomMessage(category);

    setState(() {
      _todayProgress[challenge.id] = entry;
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

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final months = ['Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio', 'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'];
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
                        margin: const EdgeInsets.all(16),
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
