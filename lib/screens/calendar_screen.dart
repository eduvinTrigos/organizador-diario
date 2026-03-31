import 'package:flutter/material.dart';
import '../models/challenge.dart';
import '../models/progress_entry.dart';
import '../services/storage_service.dart';
import '../widgets/calendar_grid.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final _storage = StorageService();

  Map<String, Map<String, ProgressEntry>> _allProgress = {};
  List<Challenge> _challenges = [];
  bool _loading = true;
  late int _year;
  late int _month;

  final _monthNames = ['Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio', 'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _year = now.year;
    _month = now.month;
    _load();
  }

  Future<void> _load() async {
    final progress = await _storage.getAllProgress();
    final challenges = await _storage.getChallenges();
    setState(() {
      _allProgress = progress;
      _challenges = challenges;
      _loading = false;
    });
  }

  void _prevMonth() {
    setState(() {
      if (_month == 1) { _month = 12; _year--; }
      else { _month--; }
    });
  }

  void _nextMonth() {
    setState(() {
      if (_month == 12) { _month = 1; _year++; }
      else { _month++; }
    });
  }

  void _onDayTap(String dateKey, Map<String, ProgressEntry> dayProgress) {
    final activeChallenges = _challenges.where((c) => c.active).toList();
    if (activeChallenges.isEmpty) return;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: Text(dateKey, style: const TextStyle(color: Colors.white, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: activeChallenges.map((c) {
            final entry = dayProgress[c.id];
            final done = entry?.completed ?? false;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(
                    done ? Icons.check_circle : Icons.cancel,
                    color: done ? Colors.green[400] : Colors.red[400],
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text('${c.emoji} ${c.title}', style: const TextStyle(color: Colors.white)),
                ],
              ),
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CERRAR', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F0F),
        title: const Text('Progreso', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Navegación mes
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: _prevMonth,
                        icon: const Icon(Icons.chevron_left, color: Colors.white),
                      ),
                      Text(
                        '${_monthNames[_month - 1]} $_year',
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        onPressed: _nextMonth,
                        icon: const Icon(Icons.chevron_right, color: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  CalendarGrid(
                    year: _year,
                    month: _month,
                    allProgress: _allProgress,
                    challenges: _challenges,
                    onDayTap: _onDayTap,
                  ),
                  const SizedBox(height: 24),
                  // Leyenda
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      _legend(Colors.green[800]!, '100%'),
                      _legend(Colors.green[300]!, '50–99%'),
                      _legend(Colors.yellow[700]!, '1–49%'),
                      _legend(Colors.red[400]!, '0%'),
                      _legend(Colors.grey[800]!, 'Sin datos'),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  Widget _legend(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 14, height: 14, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(color: Colors.grey[400], fontSize: 12)),
      ],
    );
  }
}
