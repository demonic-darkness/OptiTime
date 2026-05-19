// lib/screens/tasks_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:optitime/providers/task_provider.dart';
import 'package:optitime/models/task_model.dart';
import 'create_task_screen.dart';
import 'package:optitime/providers/settings_provider.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // ── Timer para el reloj en tiempo real ────────────────────────────────────
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _searchController.dispose();
    super.dispose();
  }

  // ── Determina la sección de una tarea según su fecha ──────────────────────
  String _getSection(Task task) {
    if (task.dueDate == null) return 'Sin fecha';
    final now = DateTime.now();
    final due = task.dueDate!;
    final today = DateTime(now.year, now.month, now.day);
    final taskDay = DateTime(due.year, due.month, due.day);
    final diff = taskDay.difference(today).inDays;

    if (diff == 0) return 'Hoy';
    if (diff == 1) return 'Mañana';
    if (diff > 1 && diff <= 7) return 'Esta semana';
    return 'Próximamente';
  }

  // ── Color de tarjeta según importancia ────────────────────────────────────
  Color _taskColor(Task task) {
     if (task.importance == -1) {
        // Usa la configuración de colores por días faltantes
        if (task.dueDate == null) return const Color(0xFF9E9E9E);
        final daysLeft = task.dueDate!.difference(DateTime.now()).inDays;
        return context.read<SettingsProvider>().colorForDaysLeft(daysLeft);
      }
    switch (task.importance) {
      case 0: return const Color(0xFF5B8DEF);
      case 1: return const Color(0xFF66BB6A);
      case 2: return const Color(0xFFFFEE58);
      case 3: return const Color(0xFFFFA726);
      case 4: return const Color(0xFFEF5350);
      case 5: return const Color(0xFF6D1F1F);
      default: return const Color(0xFFE53935);
    }
  }

  // ── Texto de vencimiento ──────────────────────────────────────────────────
  String _dueText(Task task) {
    if (task.dueDate == null) return 'Sin fecha límite';
    final d = task.dueDate!;
    final hour = d.hour > 12 ? d.hour - 12 : (d.hour == 0 ? 12 : d.hour);
    final amPm = d.hour >= 12 ? 'p.m.' : 'a.m.';
    final min = d.minute.toString().padLeft(2, '0');
    return '$hour:$min $amPm';
  }

  // ── Tareas filtradas por búsqueda ─────────────────────────────────────────
  List<Task> _filteredTasks(List<Task> all) {
    if (_searchQuery.isEmpty) return all;
    return all
        .where((t) => t.title.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  // ── Secciones en orden ────────────────────────────────────────────────────
  List<String> _sections(List<Task> tasks) {
    const order = ['Hoy', 'Mañana', 'Esta semana', 'Próximamente', 'Sin fecha'];
    final present = tasks.map((t) => _getSection(t)).toSet();
    return order.where((s) => present.contains(s)).toList();
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final allTasks = context.watch<TaskProvider>().tasks;
    final tasks = _filteredTasks(allTasks);

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    _buildSearchAndFilter(),
                    const SizedBox(height: 14),
                    _buildClockBanner(),
                    const SizedBox(height: 18),
                    tasks.isEmpty
                        ? _buildEmptyState()
                        : _buildTaskList(tasks),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateTaskScreen()),
          );
        },
        backgroundColor: const Color(0xFF5B8DEF),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  // ── Widgets ────────────────────────────────────────────────────────────────

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Text(
            'OptiTime',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF3A3A9F),
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: const InputDecoration(
                hintText: 'Buscar',
                hintStyle: TextStyle(color: Color(0xFFBDBDBD), fontSize: 14),
                prefixIcon: Icon(Icons.search, color: Color(0xFFBDBDBD), size: 20),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: () {
            // TODO: mostrar opciones de filtro
          },
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: const [
                Icon(Icons.filter_alt_outlined, color: Color(0xFF3A3A9F), size: 18),
                SizedBox(width: 4),
                Text(
                  'Filtrar',
                  style: TextStyle(
                    color: Color(0xFF3A3A9F),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildClockBanner() {
    final now = DateTime.now();
    final hour = now.hour > 12 ? now.hour - 12 : (now.hour == 0 ? 12 : now.hour);
    final amPm = now.hour >= 12 ? 'PM' : 'AM';
    final timeStr =
        '${hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [Color(0xFF7B9FFF), Color(0xFF3A3A9F)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5B8DEF).withOpacity(0.3),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            timeStr,
            style: const TextStyle(
              fontSize: 42,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 2,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              amPm,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white70,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.only(top: 50),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF5B8DEF).withOpacity(0.12),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(
              Icons.assignment_outlined,
              size: 56,
              color: Color(0xFFB0BEFF),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Sin tareas por ahora',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF3A3A9F),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Presiona el botón + para agregar\ntu primera tarea',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF9E9E9E),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskList(List<Task> tasks) {
    final sections = _sections(tasks);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: sections.map((section) {
        final sectionTasks =
            tasks.where((t) => _getSection(t) == section).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                section,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF757575),
                ),
              ),
            ),
            ...sectionTasks.map((task) => _buildTaskCard(task)),
            const SizedBox(height: 16),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildTaskCard(Task task) {
    final color = _taskColor(task);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Vence a las ${_dueText(task)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CreateTaskScreen(task: task),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF3A3A9F),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Ver',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}