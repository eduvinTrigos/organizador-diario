import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _storage = StorageService();
  final _notifications = NotificationService();

  bool _notificationsEnabled = true;
  int _streak = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final settings = await _storage.getSettings();
    setState(() {
      _notificationsEnabled = settings['notificationsEnabled'] as bool? ?? true;
      _streak = settings['streakDays'] as int? ?? 0;
      _loading = false;
    });
  }

  Future<void> _toggleNotifications(bool value) async {
    setState(() => _notificationsEnabled = value);
    final settings = await _storage.getSettings();
    settings['notificationsEnabled'] = value;
    await _storage.saveSettings(settings);

    if (!value) {
      await _notifications.cancelAll();
    } else {
      final challenges = await _storage.getChallenges();
      for (final c in challenges.where((c) => c.active)) {
        await _notifications.scheduleDailyNotification(c);
      }
    }
  }

  Future<void> _resetToday() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Resetear progreso de hoy', style: TextStyle(color: Colors.white)),
        content: const Text(
          '¿Seguro? Se borra todo el progreso de hoy. No hay vuelta atrás.',
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCELAR')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('RESETEAR', style: TextStyle(color: Colors.red[400])),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _storage.resetTodayProgress();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Progreso de hoy reseteado.'), backgroundColor: Colors.grey),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F0F),
        title: const Text('Configuración', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Streak
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.orange[900]!.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange[800]!),
                  ),
                  child: Row(
                    children: [
                      const Text('🔥', style: TextStyle(fontSize: 36)),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Racha actual', style: TextStyle(color: Colors.grey, fontSize: 13)),
                          Text(
                            '$_streak ${_streak == 1 ? 'día' : 'días'} consecutivos',
                            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Notificaciones
                _settingsTile(
                  icon: Icons.notifications_outlined,
                  title: 'Notificaciones',
                  subtitle: 'Recordatorios diarios de tus retos',
                  trailing: Switch(
                    value: _notificationsEnabled,
                    onChanged: _toggleNotifications,
                    activeColor: const Color(0xFF16A34A),
                  ),
                ),
                const SizedBox(height: 12),
                // Reset hoy
                _settingsTile(
                  icon: Icons.refresh,
                  title: 'Resetear progreso de hoy',
                  subtitle: 'Borra el avance de todos los retos de hoy',
                  trailing: IconButton(
                    icon: Icon(Icons.arrow_forward_ios, color: Colors.grey[600], size: 18),
                    onPressed: _resetToday,
                  ),
                  onTap: _resetToday,
                ),
                const SizedBox(height: 32),
                Center(
                  child: Text(
                    'Motivador Personal v1.0\nSolo para Android • Todo offline',
                    style: TextStyle(color: Colors.grey[700], fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _settingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.grey[400], size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontSize: 15)),
                  Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                ],
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }
}
