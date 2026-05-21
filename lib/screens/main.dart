import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:optitime/providers/task_provider.dart';
import 'package:optitime/providers/settings_provider.dart';
import 'home_screen.dart';
import 'tasks_screen.dart';
import 'settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settings = SettingsProvider();
  await settings.load();
  await Future.delayed(Duration.zero);
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TaskProvider()..loadTasks()),
        ChangeNotifierProvider.value(value: settings),
      ],
      child: const OptiTimeApp(),
    ),
  );
}

class OptiTimeApp extends StatelessWidget {
  const OptiTimeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OptiTime',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF1F5F9), // igual que _bgPage en home_screen
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

  // ── Paleta: Enfoque Índigo ─────────────────────────────────────────────────
  static const Color _primary     = Color(0xFF4F46E5);
  static const Color _navInactive = Color(0xFFBDBDBD);

  final List<Widget> _screens = [
    const Placeholder(),    // 0 - Calendario (próximamente)
    const TasksScreen(),    // 1 - Tareas
    const HomeScreen(),     // 2 - Inicio
    const Placeholder(),    // 3 - Notificaciones (próximamente)
    const SettingsScreen(), // 4 - Configuración
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
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
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
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
                      color: _primary.withOpacity(0.12),
                      shape: BoxShape.circle,
                    )
                  : null,
              child: Icon(
                icons[i],
                color: isSelected ? _primary : _navInactive,
                size: isSelected ? 28 : 24,
              ),
            ),
          );
        }),
      ),
    );
  }
}