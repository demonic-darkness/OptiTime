import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:optitime/providers/task_provider.dart';
import 'home_screen.dart';
import 'tasks_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Future.delayed(Duration.zero);
  runApp(
    ChangeNotifierProvider(
      create: (_) => TaskProvider()..loadTasks(),
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
        scaffoldBackgroundColor: const Color(0xFFF0F4FF),
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

  // Agrega aquí las pantallas en el mismo orden que los íconos del nav
  final List<Widget> _screens = [
    const Placeholder(), // 0 - Calendario (próximamente)
    const TasksScreen(), // 1 - Tareas
    const HomeScreen(),  // 2 - Inicio
    const Placeholder(), // 3 - Notificaciones (próximamente)
    const Placeholder(), // 4 - Configuración (próximamente)
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // IndexedStack mantiene el estado de cada pantalla al cambiar de tab
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
                      color: const Color(0xFF5B8DEF).withOpacity(0.12),
                      shape: BoxShape.circle,
                    )
                  : null,
              child: Icon(
                icons[i],
                color: isSelected
                    ? const Color(0xFF3A3A9F)
                    : const Color(0xFFBDBDBD),
                size: isSelected ? 28 : 24,
              ),
            ),
          );
        }),
      ),
    );
  }
}