import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:optitime/models/task_model.dart';
import 'package:optitime/providers/task_provider.dart';
import 'package:optitime/providers/settings_provider.dart';
import 'package:optitime/providers/task_type_provider.dart';
import 'package:optitime/providers/app_notification_provider.dart';
import 'screens/home_screen.dart';
import 'screens/tasks_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settings = SettingsProvider();
  final taskTypes = TaskTypeProvider();
  final notifications = AppNotificationProvider();
  await settings.load();
  await taskTypes.load();
  await notifications.load();
  await Future.delayed(Duration.zero);
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TaskProvider()..loadTasks()),
        ChangeNotifierProvider.value(value: settings),
        ChangeNotifierProvider.value(value: taskTypes),
        ChangeNotifierProvider.value(value: notifications),
      ],
      child: const OptiTimeApp(),
    ),
  );
}

class OptiTimeApp extends StatelessWidget {
  const OptiTimeApp({super.key});

  static const Color _primary = Color(0xFF4F46E5);

  @override
  Widget build(BuildContext context) {
    final darkMode = context.watch<SettingsProvider>().darkMode;

    return MaterialApp(
      title: 'OptiTime',
      debugShowCheckedModeBanner: false,
      themeMode: darkMode ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _primary,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF1F5F9),
        cardColor: Colors.white,
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith((states) {
            return states.contains(WidgetState.selected) ? _primary : null;
          }),
          trackColor: WidgetStateProperty.resolveWith((states) {
            return states.contains(WidgetState.selected)
                ? _primary.withValues(alpha: 0.28)
                : null;
          }),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _primary,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        cardColor: const Color(0xFF1E293B),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith((states) {
            return states.contains(WidgetState.selected)
                ? const Color(0xFF93C5FD)
                : null;
          }),
          trackColor: WidgetStateProperty.resolveWith((states) {
            return states.contains(WidgetState.selected)
                ? const Color(0xFF60A5FA).withValues(alpha: 0.36)
                : null;
          }),
        ),
      ),
      home: const MainNavigator(),
    );
  }
}

class MainNavigator extends StatefulWidget {
  const MainNavigator({super.key});

  @override
  State<MainNavigator> createState() => _MainNavigatorState();
}

class _MainNavigatorState extends State<MainNavigator> {
  int _selectedIndex = 2; // Inicia en Home (posición 2)
  bool _startedNotificationSync = false;
  bool _notificationSyncQueued = false;

  // ── Paleta: Enfoque Índigo ─────────────────────────────────────────────────
  static const Color _primary = Color(0xFF4F46E5);
  static const Color _navInactive = Color(0xFFBDBDBD);

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      const Placeholder(), // 0 - Calendario (próximamente)
      const TasksScreen(), // 1 - Tareas
      HomeScreen(
        onOpenTasks: () => setState(() => _selectedIndex = 1),
        onOpenNotifications: () => setState(() => _selectedIndex = 3),
      ), // 2 - Inicio
      const NotificationsScreen(), // 3 - Notificaciones
      const SettingsScreen(), // 4 - Configuración
    ];
  }

  @override
  Widget build(BuildContext context) {
    final tasks = context.watch<TaskProvider>().tasks;
    final settings = context.watch<SettingsProvider>();

    if (!_startedNotificationSync) {
      _startedNotificationSync = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<AppNotificationProvider>().startAutoSync(
          tasks: () => context.read<TaskProvider>().tasks,
          settings: () => context.read<SettingsProvider>(),
        );
      });
    }
    _queueNotificationSync(tasks, settings);

    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  void _queueNotificationSync(List<Task> tasks, SettingsProvider settings) {
    if (_notificationSyncQueued) return;
    _notificationSyncQueued = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await context.read<AppNotificationProvider>().syncTasks(tasks, settings);
      _notificationSyncQueued = false;
    });
  }

  Widget _buildBottomNav() {
    final darkMode = context.watch<SettingsProvider>().darkMode;
    final navBackground = darkMode
        ? const Color(0xFF111827)
        : const Color(0xFFFFFFFF);
    final selectedBackground = darkMode
        ? const Color(0xFF60A5FA).withValues(alpha: 0.18)
        : _primary.withValues(alpha: 0.12);
    final selectedColor = darkMode ? const Color(0xFF93C5FD) : _primary;
    final inactiveColor = darkMode ? const Color(0xFF64748B) : _navInactive;

    final icons = [
      Icons.calendar_today_outlined,
      Icons.check_circle_outline,
      Icons.home_rounded,
      Icons.notifications_outlined,
      Icons.settings_outlined,
    ];

    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: navBackground,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: darkMode ? 0.28 : 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(icons.length, (i) {
          final isSelected = i == _selectedIndex;
          return GestureDetector(
            onTap: () => setState(() => _selectedIndex = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(10),
              decoration: isSelected
                  ? BoxDecoration(
                      color: selectedBackground,
                      shape: BoxShape.circle,
                    )
                  : null,
              child: Icon(
                icons[i],
                color: isSelected ? selectedColor : inactiveColor,
                size: isSelected ? 28 : 24,
              ),
            ),
          );
        }),
      ),
    );
  }
}
