import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/timezone.dart' as tz_lib;
import 'services/notification_service.dart';
import 'screens/home_screen.dart';
import 'screens/calendar_screen.dart';
import 'screens/challenges_screen.dart';
import 'screens/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();
  try {
    final String timeZone = await FlutterTimezone.getLocalTimezone();
    tz_lib.setLocalLocation(tz_lib.getLocation(timeZone));
  } catch (_) {}
  await NotificationService().init();
  await NotificationService().requestPermissions();
  runApp(const MotivadorApp());
}

final _router = GoRouter(
  initialLocation: '/',
  routes: [
    ShellRoute(
      builder: (context, state, child) => MainShell(child: child),
      routes: [
        GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
        GoRoute(path: '/calendar', builder: (_, __) => const CalendarScreen()),
        GoRoute(path: '/challenges', builder: (_, __) => const ChallengesScreen()),
        GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
      ],
    ),
  ],
);

class MotivadorApp extends StatelessWidget {
  const MotivadorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Motivador Personal',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F0F0F),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF16A34A),
          surface: Color(0xFF1A1A1A),
        ),
      ),
      routerConfig: _router,
    );
  }
}

class MainShell extends StatefulWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final _tabs = ['/', '/calendar', '/challenges', '/settings'];

  void _onTap(int index) {
    setState(() => _currentIndex = index);
    context.go(_tabs[index]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTap,
        backgroundColor: const Color(0xFF1A1A1A),
        selectedItemColor: const Color(0xFF16A34A),
        unselectedItemColor: Colors.grey[600],
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.today), label: 'Hoy'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: 'Calendario'),
          BottomNavigationBarItem(icon: Icon(Icons.flag_outlined), label: 'Retos'),
          BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), label: 'Config'),
        ],
      ),
    );
  }
}
