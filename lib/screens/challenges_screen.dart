import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/challenge.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';

class ChallengesScreen extends StatefulWidget {
  const ChallengesScreen({super.key});

  @override
  State<ChallengesScreen> createState() => _ChallengesScreenState();
}

class _ChallengesScreenState extends State<ChallengesScreen> {
  final _storage = StorageService();
  final _notifications = NotificationService();
  List<Challenge> _challenges = [];
  bool _loading = true;

  final _emojis = ['💧', '🏃', '🥗', '😴', '📚', '🧘', '🚴', '💪', '🥤', '🍎', '🚶', '🧹'];
  final _colors = [
    const Color(0xFF3B82F6),
    const Color(0xFF10B981),
    const Color(0xFFF59E0B),
    const Color(0xFFEF4444),
    const Color(0xFF8B5CF6),
    const Color(0xFFEC4899),
    const Color(0xFF14B8A6),
    const Color(0xFFF97316),
  ];

  static const _intervalOptions = [
    (label: 'Sin repetición', hours: 0),
    (label: 'Cada 2 horas', hours: 2),
    (label: 'Cada 4 horas', hours: 4),
    (label: 'Cada 6 horas', hours: 6),
    (label: 'Cada 8 horas', hours: 8),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final challenges = await _storage.getChallenges();
    setState(() { _challenges = challenges; _loading = false; });
  }

  Future<void> _toggleActive(Challenge challenge) async {
    challenge.active = !challenge.active;
    await _storage.updateChallenge(challenge);
    if (challenge.active) {
      await _notifications.scheduleDailyNotification(challenge);
    } else {
      await _notifications.cancelNotification(challenge.id);
    }
    setState(() {});
  }

  Future<void> _delete(Challenge challenge) async {
    await _storage.deleteChallenge(challenge.id);
    await _notifications.cancelNotification(challenge.id);
    setState(() { _challenges.removeWhere((c) => c.id == challenge.id); });
  }

  String _intervalLabel(int hours) {
    if (hours <= 0) return '';
    return ' · cada ${hours}h';
  }

  Future<void> _openForm({Challenge? existing}) async {
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    String selectedEmoji = existing?.emoji ?? '💧';
    Color selectedColor = existing != null ? Color(existing.colorValue) : _colors[0];
    TimeOfDay selectedTime = existing != null
        ? TimeOfDay(
            hour: int.parse(existing.reminderTime.split(':')[0]),
            minute: int.parse(existing.reminderTime.split(':')[1]),
          )
        : const TimeOfDay(hour: 8, minute: 0);
    int selectedInterval = existing?.intervalHours ?? 0;
    bool saving = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20, right: 20, top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  existing == null ? 'Nuevo reto' : 'Editar reto',
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: titleCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Nombre del reto',
                    labelStyle: TextStyle(color: Colors.grey[500]),
                    enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey[700]!)),
                    focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Emoji', style: TextStyle(color: Colors.grey, fontSize: 13)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _emojis.map((e) => GestureDetector(
                    onTap: () => setModalState(() => selectedEmoji = e),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: selectedEmoji == e ? Colors.white24 : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: selectedEmoji == e ? Border.all(color: Colors.white) : null,
                      ),
                      child: Text(e, style: const TextStyle(fontSize: 24)),
                    ),
                  )).toList(),
                ),
                const SizedBox(height: 16),
                const Text('Color', style: TextStyle(color: Colors.grey, fontSize: 13)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _colors.map((c) => GestureDetector(
                    onTap: () => setModalState(() => selectedColor = c),
                    child: Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: selectedColor == c ? Border.all(color: Colors.white, width: 3) : null,
                      ),
                    ),
                  )).toList(),
                ),
                const SizedBox(height: 16),
                const Text('Recordatorio', style: TextStyle(color: Colors.grey, fontSize: 13)),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: ctx,
                      initialTime: selectedTime,
                      builder: (context, child) => Theme(
                        data: ThemeData.dark(),
                        child: child!,
                      ),
                    );
                    if (picked != null) setModalState(() => selectedTime = picked);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[700]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.access_time, color: Colors.white),
                        const SizedBox(width: 8),
                        Text(
                          '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}',
                          style: const TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Repetir recordatorio', style: TextStyle(color: Colors.grey, fontSize: 13)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[700]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: selectedInterval,
                      isExpanded: true,
                      dropdownColor: const Color(0xFF1A1A1A),
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      onChanged: (val) {
                        if (val != null) setModalState(() => selectedInterval = val);
                      },
                      items: _intervalOptions.map((opt) => DropdownMenuItem(
                        value: opt.hours,
                        child: Text(opt.label),
                      )).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF16A34A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: saving ? null : () async {
                      if (titleCtrl.text.trim().isEmpty) return;
                      setModalState(() => saving = true);
                      final timeStr = '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}';

                      try {
                        if (existing == null) {
                          final challenge = Challenge(
                            id: const Uuid().v4(),
                            title: titleCtrl.text.trim(),
                            emoji: selectedEmoji,
                            colorValue: selectedColor.value,
                            reminderTime: timeStr,
                            intervalHours: selectedInterval,
                            active: true,
                            createdAt: DateTime.now().toIso8601String().split('T')[0],
                          );
                          await _storage.addChallenge(challenge);
                          try {
                            await _notifications.scheduleDailyNotification(challenge);
                          } catch (_) {}
                        } else {
                          existing.title = titleCtrl.text.trim();
                          existing.emoji = selectedEmoji;
                          existing.colorValue = selectedColor.value;
                          existing.reminderTime = timeStr;
                          existing.intervalHours = selectedInterval;
                          await _storage.updateChallenge(existing);
                          if (existing.active) {
                            try {
                              await _notifications.scheduleDailyNotification(existing);
                            } catch (_) {}
                          }
                        }

                        await _load();
                        if (ctx.mounted) Navigator.pop(ctx);
                      } catch (_) {
                        setModalState(() => saving = false);
                      }
                    },
                    child: saving
                        ? const SizedBox(
                            height: 20, width: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : Text(existing == null ? 'CREAR RETO' : 'GUARDAR CAMBIOS',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F0F),
        title: const Text('Mis Retos', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(),
        backgroundColor: const Color(0xFF16A34A),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : _challenges.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('🎯', style: TextStyle(fontSize: 48)),
                      const SizedBox(height: 16),
                      const Text('No tenés retos todavía.', style: TextStyle(color: Colors.white, fontSize: 18)),
                      const SizedBox(height: 8),
                      Text('Tocá el + para crear uno.', style: TextStyle(color: Colors.grey[500])),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _challenges.length,
                  itemBuilder: (context, i) {
                    final c = _challenges[i];
                    return Dismissible(
                      key: Key(c.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        decoration: BoxDecoration(
                          color: Colors.red[800],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      confirmDismiss: (_) async {
                        return await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            backgroundColor: const Color(0xFF1A1A1A),
                            title: const Text('Eliminar reto', style: TextStyle(color: Colors.white)),
                            content: Text('¿Seguro que querés eliminar "${c.title}"?', style: const TextStyle(color: Colors.grey)),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCELAR')),
                              TextButton(onPressed: () => Navigator.pop(context, true), child: Text('ELIMINAR', style: TextStyle(color: Colors.red[400]))),
                            ],
                          ),
                        ) ?? false;
                      },
                      onDismissed: (_) => _delete(c),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: Color(c.colorValue).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Color(c.colorValue).withOpacity(0.4)),
                        ),
                        child: ListTile(
                          leading: Text(c.emoji, style: const TextStyle(fontSize: 28)),
                          title: Text(c.title, style: TextStyle(color: c.active ? Colors.white : Colors.grey[500])),
                          subtitle: Text(
                            '⏰ ${c.reminderTime}${_intervalLabel(c.intervalHours)}',
                            style: TextStyle(color: Colors.grey[600], fontSize: 12),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, color: Colors.grey, size: 20),
                                onPressed: () => _openForm(existing: c),
                              ),
                              IconButton(
                                icon: Icon(Icons.delete_outline, color: Colors.red[400], size: 20),
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (_) => AlertDialog(
                                      backgroundColor: const Color(0xFF1A1A1A),
                                      title: const Text('Eliminar reto', style: TextStyle(color: Colors.white)),
                                      content: Text('¿Seguro que querés eliminar "${c.title}"?', style: const TextStyle(color: Colors.grey)),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCELAR')),
                                        TextButton(onPressed: () => Navigator.pop(context, true), child: Text('ELIMINAR', style: TextStyle(color: Colors.red[400]))),
                                      ],
                                    ),
                                  ) ?? false;
                                  if (confirm) _delete(c);
                                },
                              ),
                              Switch(
                                value: c.active,
                                onChanged: (_) => _toggleActive(c),
                                activeColor: const Color(0xFF16A34A),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
