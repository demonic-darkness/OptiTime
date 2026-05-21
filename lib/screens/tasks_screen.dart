// lib/screens/tasks_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:optitime/providers/task_provider.dart';
import 'package:optitime/models/task_model.dart';
import 'create_task_screen.dart';
import 'package:optitime/providers/settings_provider.dart';

enum _TaskFilterKind {
  none,
  type,
  exactDate,
  untilDate,
  color,
  overdue,
}

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _showFilters = false;
  _TaskFilterKind _activeFilter = _TaskFilterKind.none;
  String? _selectedTypeFilter;
  DateTime? _selectedDateFilter;
  int? _selectedImportanceFilter;

  final List<String> _taskTypes = const [
    'Academica',
    'Personal',
    'Trabajo',
    'Salud',
    'Otro',
  ];

  final List<Map<String, dynamic>> _colorFilters = const [
    {'label': 'Azul', 'color': Color(0xFF5B8DEF), 'value': 0},
    {'label': 'Verde', 'color': Color(0xFF66BB6A), 'value': 1},
    {'label': 'Amarillo', 'color': Color(0xFFFFEE58), 'value': 2},
    {'label': 'Naranja', 'color': Color(0xFFFFA726), 'value': 3},
    {'label': 'Rojo', 'color': Color(0xFFEF5350), 'value': 4},
    {'label': 'Vino', 'color': Color(0xFF6D1F1F), 'value': 5},
  ];

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

  // ── Paleta: Enfoque Índigo ─────────────────────────────────────────────────
  static const Color _primary   = Color(0xFF4F46E5);
  static const Color _accent    = Color(0xFF7C3AED);
  static const Color _info      = Color(0xFF06B6D4);
  static const Color _bgPage    = Color(0xFFF1F5F9);
  static const Color _textDark  = Color(0xFF0F172A);
  static const Color _textMuted = Color(0xFF64748B);
  static const Color _success   = Color(0xFF22C55E);
  static const Color _warning   = Color(0xFFFACC15);
  static const Color _danger    = Color(0xFFEF4444);

  // ── Determina la sección de una tarea según su fecha ──────────────────────
  String _getSection(Task task) {
    if (task.dueDate == null) return 'Sin fecha';
    final now = DateTime.now();
    final due = task.dueDate!;
    final today = DateTime(now.year, now.month, now.day);
    final taskDay = DateTime(due.year, due.month, due.day);
    final diff = taskDay.difference(today).inDays;

    if (_isOverdue(task)) return 'Vencidas';
    if (diff == 0) return 'Hoy';
    if (diff == 1) return 'Mañana';
    if (diff > 1 && diff <= 7) return 'Esta semana';
    return 'Próximamente';
  }

  bool _isOverdue(Task task) {
    if (task.dueDate == null) return false;
    return task.dueDate!.isBefore(DateTime.now());
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  // ── Color de tarjeta según importancia ────────────────────────────────────
  Color _taskColor(Task task) {
    if (task.importance == -1) {
      if (task.dueDate == null) return _textMuted;
      final daysLeft = task.dueDate!.difference(DateTime.now()).inDays;
      return context.read<SettingsProvider>().colorForDaysLeft(daysLeft);
    }
    switch (task.importance) {
      case 0: return _primary;
      case 1: return _success;
      case 2: return _warning;
      case 3: return const Color(0xFFF97316); // naranja
      case 4: return _danger;
      case 5: return const Color(0xFF7F1D1D); // rojo oscuro
      default: return _danger;
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

  // ── Tareas filtradas por búsqueda y filtro activo ────────────────────────
  List<Task> _filteredTasks(List<Task> all) {
    final query = _searchQuery.toLowerCase();
    return all.where((task) {
      final matchesSearch =
          query.isEmpty || task.title.toLowerCase().contains(query);

      if (!matchesSearch) return false;

      final overdue = _isOverdue(task);
      if (_activeFilter != _TaskFilterKind.overdue && overdue) return false;

      switch (_activeFilter) {
        case _TaskFilterKind.none:
          return true;
        case _TaskFilterKind.type:
          return task.type == _selectedTypeFilter;
        case _TaskFilterKind.exactDate:
          return task.dueDate != null &&
              _selectedDateFilter != null &&
              _isSameDay(task.dueDate!, _selectedDateFilter!);
        case _TaskFilterKind.untilDate:
          if (task.dueDate == null || _selectedDateFilter == null) {
            return false;
          }
          final today = _dateOnly(DateTime.now());
          final taskDay = _dateOnly(task.dueDate!);
          final limit = _dateOnly(_selectedDateFilter!);
          return !taskDay.isBefore(today) && !taskDay.isAfter(limit);
        case _TaskFilterKind.color:
          final selectedColor = _colorFilters.firstWhere(
            (c) => c['value'] == _selectedImportanceFilter,
            orElse: () => {'color': null},
          )['color'];
          return selectedColor is Color && _taskColor(task) == selectedColor;
        case _TaskFilterKind.overdue:
          return overdue;
      }
    }).toList();
  }

  // ── Secciones en orden ────────────────────────────────────────────────────
  List<String> _sections(List<Task> tasks) {
    const order = ['Vencidas', 'Hoy', 'Mañana', 'Esta semana', 'Próximamente', 'Sin fecha'];
    final present = tasks.map((t) => _getSection(t)).toSet();
    return order.where((s) => present.contains(s)).toList();
  }

  String get _filterLabel {
    switch (_activeFilter) {
      case _TaskFilterKind.none:
        return 'Filtrar';
      case _TaskFilterKind.type:
        return _selectedTypeFilter ?? 'Tipo';
      case _TaskFilterKind.exactDate:
        return _selectedDateFilter == null
            ? 'Fecha'
            : 'Fecha ${_formatDate(_selectedDateFilter!)}';
      case _TaskFilterKind.untilDate:
        return _selectedDateFilter == null
            ? 'Hasta fecha'
            : 'Hasta ${_formatDate(_selectedDateFilter!)}';
      case _TaskFilterKind.color:
        final color = _colorFilters.firstWhere(
          (c) => c['value'] == _selectedImportanceFilter,
          orElse: () => {'label': 'Color'},
        );
        return color['label'] as String;
      case _TaskFilterKind.overdue:
        return 'Vencidas';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  Future<void> _pickFilterDate(_TaskFilterKind kind) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final initialDate =
        kind == _TaskFilterKind.untilDate &&
                _selectedDateFilter != null &&
                _selectedDateFilter!.isBefore(today)
            ? today
            : (_selectedDateFilter ?? today);
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: kind == _TaskFilterKind.untilDate
          ? today
          : DateTime(today.year - 5),
      lastDate: DateTime(today.year + 5),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF3A3A9F),
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );

    if (picked == null) return;
    setState(() {
      _activeFilter = kind;
      _selectedDateFilter = picked;
      _selectedTypeFilter = null;
      _selectedImportanceFilter = null;
      _showFilters = false;
    });
  }

  void _clearFilter() {
    setState(() {
      _activeFilter = _TaskFilterKind.none;
      _selectedTypeFilter = null;
      _selectedDateFilter = null;
      _selectedImportanceFilter = null;
    });
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final allTasks = context.watch<TaskProvider>().tasks;
    final tasks = _filteredTasks(allTasks);

    return Scaffold(
      backgroundColor: _bgPage,
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
        backgroundColor: _primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  // ── Widgets ────────────────────────────────────────────────────────────────

  Widget _buildAppBar() {
    final now = DateTime.now();
    final days = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    final months = [
      'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
    ];
    final dateStr = '${days[now.weekday - 1]} ${now.day}, ${months[now.month - 1]}';

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFE0E7FF),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'OptiTime',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: _primary,
              letterSpacing: 1.2,
            ),
          ),
          Text(
            dateStr,
            style: const TextStyle(
              fontSize: 13,
              color: _textMuted,
              fontWeight: FontWeight.w500,
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
          colors: [Color(0xFF818CF8), _primary],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: [
          BoxShadow(
            color: _primary.withOpacity(0.3),
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
    final hasFilter = _activeFilter != _TaskFilterKind.none;
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
                  color: _primary.withOpacity(0.12),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(
              Icons.assignment_outlined,
              size: 56,
              color: Color(0xFFC7D2FE), // índigo 200
            ),
          ),
          const SizedBox(height: 24),
          Text(
            hasFilter ? 'Sin resultados' : 'Sin tareas por ahora',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hasFilter
                ? 'No hay tareas que coincidan\ncon este filtro'
                : 'Presiona el botón + para agregar\ntu primera tarea',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: _textMuted,
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
                  color: _textMuted,
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
              foregroundColor: _primary,
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
