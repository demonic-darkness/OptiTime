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

// Punto de entrada de la aplicación.
// Se inicializa el binding de Flutter, se cargan los proveedores necesarios
// y se arranca la aplicación con un MultiProvider para que el estado
// esté disponible en toda la app.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Proveedores que necesitan cargar datos antes de renderizar la UI.
  final settings = SettingsProvider();
  final taskTypes = TaskTypeProvider();
  final notifications = AppNotificationProvider();

  // Cargar ajustes, tipos de tarea y notificaciones desde almacenamiento.
  await settings.load();
  await taskTypes.load();
  await notifications.load();

  // Asegura que el widget se construya en el siguiente frame.
  await Future.delayed(Duration.zero);

  runApp(
    MultiProvider(
      providers: [
        // Crea el proveedor de tareas y carga las tareas al inicio.
        ChangeNotifierProvider(create: (_) => TaskProvider()..loadTasks()),
        // Se usa ChangeNotifierProvider.value aquí porque ya creamos la instancia antes.
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

  // Color principal de la aplicación.
  static const Color _primary = Color(0xFF4F46E5);

  @override
  Widget build(BuildContext context) {
    // Observa el estado de darkMode para elegir el tema adecuado.
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

// Widget principal que controla la navegación entre las pantallas.
class MainNavigator extends StatefulWidget {
  const MainNavigator({super.key});

  @override
  State<MainNavigator> createState() => _MainNavigatorState();
}

class _MainNavigatorState extends State<MainNavigator> {
  int _selectedIndex = 2; // Inicia en la pestaña "Inicio".
  bool _startedNotificationSync = false; // Controla arranque único.
  bool _notificationSyncQueued = false; // Evita sincronizaciones duplicadas.

  // ── Colores usados en la barra de navegación ──────────────────────────────
  static const Color _primary = Color(0xFF4F46E5);
  static const Color _navInactive = Color(0xFFBDBDBD);

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    // Lista de pantallas que se muestran según el índice seleccionado.
    _screens = [
      const Placeholder(), // 0 - Calendario (por implementar)
      const TasksScreen(), // 1 - Tareas
      HomeScreen(
        onOpenTasks: () => setState(() => _selectedIndex = 1),
        onOpenNotifications: () => setState(() => _selectedIndex = 3),
      ), // 2 - Inicio
      const NotificationsScreen(), // 3 - Notificaciones
      const SettingsScreen(), // 4 - Ajustes
    ];
  }

  @override
  Widget build(BuildContext context) {
    final tasks = context.watch<TaskProvider>().tasks;
    final settings = context.watch<SettingsProvider>();

    // Inicia la sincronización automática de notificaciones una sola vez.
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

    // Agenda una sincronización de notificaciones después de cada build,
    // pero evita que se ejecute varias veces simultáneamente.
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
    final labels = ['Calendario', 'Tareas', 'Inicio', 'Notificaciones', 'Ajustes'];

    return Container(
      height: 78,
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
          return Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => setState(() => _selectedIndex = i),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 38,
                      height: 32,
                      decoration: isSelected
                          ? BoxDecoration(
                              color: selectedBackground,
                              borderRadius: BorderRadius.circular(18),
                            )
                          : null,
                      child: Icon(
                        icons[i],
                        color: isSelected ? selectedColor : inactiveColor,
                        size: isSelected ? 25 : 23,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      labels[i],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: isSelected ? selectedColor : inactiveColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
