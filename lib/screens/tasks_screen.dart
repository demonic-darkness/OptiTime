// lib/screens/tasks_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:optitime/providers/task_provider.dart';
import 'package:optitime/models/task_model.dart';
import 'create_task_screen.dart';
import 'package:optitime/providers/settings_provider.dart';
import 'package:optitime/providers/task_type_provider.dart';

enum _TaskFilterKind { none, type, exactDate, untilDate, color, overdue }

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

  // ── Paleta: Azul claro, estilo iOS ────────────────────────────────────────
  static const Color _primary = Color(0xFF3B82F6);
  static const Color _bgPage = Color(0xFFF2F6FF);
  static const Color _textDark = Color(0xFF1C1C1E);
  static const Color _textMuted = Color(0xFF8E8E93);
  static const Color _success = Color(0xFF34C759);
  static const Color _warning = Color(0xFFFF9F0A);
  static const Color _danger = Color(0xFFFF3B30);
  static const Color _cardBg = Color(0xFFFFFFFF);
  static const String _font = '.SF Pro Text';

  bool get _isDark => context.read<SettingsProvider>().darkMode;
  Color get _pageBg => _isDark ? const Color(0xFF0F172A) : _bgPage;
  Color get _surface => _isDark ? const Color(0xFF1E293B) : _cardBg;
  Color get _surfaceAlt => _isDark ? const Color(0xFF111827) : _bgPage;
  Color get _heading => _isDark ? const Color(0xFFE5E7EB) : _textDark;
  Color get _muted => _isDark ? const Color(0xFF94A3B8) : _textMuted;
  Color get _accent => _isDark ? const Color(0xFF60A5FA) : _primary;
  Color get _softBorder =>
      _isDark ? Colors.white.withValues(alpha: 0.08) : Colors.transparent;
  Color get _shadow => Colors.black.withValues(alpha: _isDark ? 0.28 : 0.05);

  final List<Map<String, dynamic>> _colorFilters = const [
    {'label': 'Azul', 'color': Color(0xFF3B82F6), 'value': 0},
    {'label': 'Verde', 'color': Color(0xFF34C759), 'value': 1},
    {'label': 'Amarillo', 'color': Color(0xFFFF9F0A), 'value': 2},
    {'label': 'Naranja', 'color': Color(0xFFF97316), 'value': 3},
    {'label': 'Rojo', 'color': Color(0xFFFF3B30), 'value': 4},
    {'label': 'Vino', 'color': Color(0xFF7F1D1D), 'value': 5},
  ];

  // ── Timer para el reloj ────────────────────────────────────────────────────
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

  // ── Helpers de fecha/sección ───────────────────────────────────────────────
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

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/'
      '${date.year}';

  // ── Color de tarjeta ───────────────────────────────────────────────────────
  Color _taskColor(Task task) {
    if (task.importance == -1) {
      if (task.dueDate == null) return _muted;
      final daysLeft = task.dueDate!.difference(DateTime.now()).inDays;
      return context.read<SettingsProvider>().colorForDaysLeft(daysLeft);
    }
    switch (task.importance) {
      case 0:
        return _accent;
      case 1:
        return _success;
      case 2:
        return _warning;
      case 3:
        return const Color(0xFFF97316);
      case 4:
        return _danger;
      case 5:
        return const Color(0xFF7F1D1D);
      default:
        return _danger;
    }
  }

  // ── Texto de vencimiento ───────────────────────────────────────────────────
  String _dueText(Task task) {
    if (task.dueDate == null) return 'Sin fecha límite';
    final d = task.dueDate!;
    final hour = d.hour > 12 ? d.hour - 12 : (d.hour == 0 ? 12 : d.hour);
    final amPm = d.hour >= 12 ? 'p.m.' : 'a.m.';
    final min = d.minute.toString().padLeft(2, '0');
    return '$hour:$min $amPm';
  }

  String _dueDisplayText(Task task) {
    if (task.dueDate == null) return 'Sin fecha límite';
    final due = task.dueDate!;
    if (_isSameDay(due, DateTime.now())) return 'Vence a las ${_dueText(task)}';
    return 'Vence el ${_formatDate(due)}';
  }

  // ── Filtrado ───────────────────────────────────────────────────────────────
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
          if (task.dueDate == null || _selectedDateFilter == null) return false;
          final today = _dateOnly(DateTime.now());
          final taskDay = _dateOnly(task.dueDate!);
          final limit = _dateOnly(_selectedDateFilter!);
          return !taskDay.isBefore(today) && !taskDay.isAfter(limit);
        case _TaskFilterKind.color:
          return _matchesColorFilter(task);
        case _TaskFilterKind.overdue:
          return overdue;
      }
    }).toList();
  }

  List<String> _sections(List<Task> tasks) {
    const order = [
      'Vencidas',
      'Hoy',
      'Mañana',
      'Esta semana',
      'Próximamente',
      'Sin fecha',
    ];
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
            : _formatDate(_selectedDateFilter!);
      case _TaskFilterKind.untilDate:
        return _selectedDateFilter == null
            ? 'Hasta fecha'
            : 'Hasta ${_formatDate(_selectedDateFilter!)}';
      case _TaskFilterKind.color:
        final c = _colorFilters.firstWhere(
          (c) => c['value'] == _selectedImportanceFilter,
          orElse: () => {'label': 'Color'},
        );
        return c['label'] as String;
      case _TaskFilterKind.overdue:
        return 'Vencidas';
    }
  }

  Future<void> _pickFilterDate(_TaskFilterKind kind) async {
    final isDark = context.read<SettingsProvider>().darkMode;
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
          colorScheme: isDark
              ? ColorScheme.dark(primary: _accent, onPrimary: Colors.white)
              : ColorScheme.light(primary: _accent, onPrimary: Colors.white),
          dialogTheme: DialogThemeData(
            backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
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

  void _clearFilter() => setState(() {
    _activeFilter = _TaskFilterKind.none;
    _selectedTypeFilter = null;
    _selectedDateFilter = null;
    _selectedImportanceFilter = null;
  });

  bool _matchesColorFilter(Task task) {
    final selected = _selectedImportanceFilter;
    if (selected == null) return false;
    if (task.importance == selected) return true;
    if (task.importance != -1) return false;
    final taskColor = _taskColor(task);
    final accepted = switch (selected) {
      0 => const [Color(0xFF3B82F6), Color(0xFF5B8DEF), Color(0xFF90CAF9)],
      1 => const [Color(0xFF34C759), Color(0xFF66BB6A), Color(0xFF4CAF50)],
      2 => const [Color(0xFFFF9F0A), Color(0xFFFACC15), Color(0xFFFFEE58)],
      3 => const [Color(0xFFF97316), Color(0xFFFFA726)],
      4 => const [Color(0xFFFF3B30), Color(0xFFEF5350)],
      5 => const [Color(0xFF7F1D1D), Color(0xFF6D1F1F)],
      _ => const <Color>[],
    };
    return accepted.contains(taskColor);
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    context.watch<SettingsProvider>().darkMode;
    final allTasks = context.watch<TaskProvider>().tasks;
    final tasks = _filteredTasks(allTasks);

    return Scaffold(
      backgroundColor: _pageBg,
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
                    tasks.isEmpty ? _buildEmptyState() : _buildTaskList(tasks),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CreateTaskScreen()),
        ),
        backgroundColor: _accent,
        elevation: 2,
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }

  // ── AppBar ─────────────────────────────────────────────────────────────────
  Widget _buildAppBar() {
    final now = DateTime.now();
    final days = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    final months = [
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic',
    ];
    final dateStr =
        '${days[now.weekday - 1]} ${now.day} ${months[now.month - 1]}';

    return Container(
      color: _pageBg,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'OptiTime',
            style: TextStyle(
              fontFamily: _font,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: _accent,
              letterSpacing: -0.3,
            ),
          ),
          Text(
            dateStr,
            style: TextStyle(
              fontFamily: _font,
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: _muted,
            ),
          ),
        ],
      ),
    );
  }

  // ── Búsqueda y filtros ─────────────────────────────────────────────────────
  Widget _buildSearchAndFilter() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: _surface,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: _softBorder),
                  boxShadow: [
                    BoxShadow(
                      color: _shadow,
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _searchQuery = v),
                  style: TextStyle(
                    fontFamily: _font,
                    fontSize: 15,
                    color: _heading,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Buscar tarea...',
                    hintStyle: TextStyle(
                      fontFamily: _font,
                      color: _muted,
                      fontSize: 15,
                    ),
                    prefixIcon: Icon(Icons.search, color: _muted, size: 20),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: () => setState(() => _showFilters = !_showFilters),
              child: Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: _activeFilter != _TaskFilterKind.none
                      ? _accent
                      : _surface,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: _softBorder),
                  boxShadow: [
                    BoxShadow(
                      color: _shadow,
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.filter_alt_outlined,
                      color: _activeFilter != _TaskFilterKind.none
                          ? Colors.white
                          : _accent,
                      size: 18,
                    ),
                    const SizedBox(width: 4),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 80),
                      child: Text(
                        _filterLabel,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: _font,
                          color: _activeFilter != _TaskFilterKind.none
                              ? Colors.white
                              : _accent,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    Icon(
                      _showFilters
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: _activeFilter != _TaskFilterKind.none
                          ? Colors.white
                          : _accent,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox(width: double.infinity),
          secondChild: _buildFilterMenu(),
          crossFadeState: _showFilters
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 180),
        ),
      ],
    );
  }

  Widget _buildFilterMenu() {
    final taskTypeProvider = context.watch<TaskTypeProvider>();
    final allTasks = context.watch<TaskProvider>().tasks;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _softBorder),
        boxShadow: [
          BoxShadow(color: _shadow, blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'FILTRAR POR',
            style: TextStyle(
              fontFamily: _font,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: _muted,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ...taskTypeProvider.allTypes.map(
                (type) => _buildFilterChip(
                  label: type,
                  icon: _typeIcon(type),
                  selected:
                      _activeFilter == _TaskFilterKind.type &&
                      _selectedTypeFilter == type,
                  onTap: () => setState(() {
                    _activeFilter = _TaskFilterKind.type;
                    _selectedTypeFilter = type;
                    _selectedDateFilter = null;
                    _selectedImportanceFilter = null;
                    _showFilters = false;
                  }),
                  onLongPress: taskTypeProvider.isCustomType(type)
                      ? () => _deleteCustomType(type, allTasks)
                      : null,
                ),
              ),
              _buildFilterChip(
                label: 'Nuevo tipo',
                icon: Icons.add,
                selected: false,
                onTap: _showAddCustomTypeDialog,
              ),
              _buildFilterChip(
                label: 'Fecha exacta',
                icon: Icons.event_outlined,
                selected: _activeFilter == _TaskFilterKind.exactDate,
                onTap: () => _pickFilterDate(_TaskFilterKind.exactDate),
              ),
              _buildFilterChip(
                label: 'Hasta fecha',
                icon: Icons.date_range_outlined,
                selected: _activeFilter == _TaskFilterKind.untilDate,
                onTap: () => _pickFilterDate(_TaskFilterKind.untilDate),
              ),
              _buildFilterChip(
                label: 'Vencidas',
                icon: Icons.warning_amber_rounded,
                selected: _activeFilter == _TaskFilterKind.overdue,
                onTap: () => setState(() {
                  _activeFilter = _TaskFilterKind.overdue;
                  _selectedTypeFilter = null;
                  _selectedDateFilter = null;
                  _selectedImportanceFilter = null;
                  _showFilters = false;
                }),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'POR COLOR',
            style: TextStyle(
              fontFamily: _font,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: _muted,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _colorFilters.map((cf) {
              final value = cf['value'] as int;
              final color = cf['color'] as Color;
              final selected =
                  _activeFilter == _TaskFilterKind.color &&
                  _selectedImportanceFilter == value;
              return GestureDetector(
                onTap: () => setState(() {
                  _activeFilter = _TaskFilterKind.color;
                  _selectedImportanceFilter = value;
                  _selectedTypeFilter = null;
                  _selectedDateFilter = null;
                  _showFilters = false;
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected
                          ? _heading
                          : (_isDark
                                ? Colors.white.withValues(alpha: 0.22)
                                : Colors.white),
                      width: selected ? 2.5 : 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: selected
                      ? const Icon(Icons.check, color: Colors.white, size: 16)
                      : null,
                ),
              );
            }).toList(),
          ),
          if (_activeFilter != _TaskFilterKind.none) ...[
            const SizedBox(height: 12),
            Divider(
              height: 1,
              thickness: 0.5,
              color: _isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.07),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _clearFilter,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.close_rounded, size: 15, color: _danger),
                  const SizedBox(width: 4),
                  Text(
                    'Quitar filtro',
                    style: TextStyle(
                      fontFamily: _font,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _danger,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    IconData? icon,
    VoidCallback? onLongPress,
  }) {
    return GestureDetector(
      onLongPress: onLongPress,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: selected ? _accent : _surfaceAlt,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: selected ? _accent : _softBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 14, color: selected ? Colors.white : _muted),
                const SizedBox(width: 5),
              ],
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 120),
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: _font,
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    color: selected ? Colors.white : _heading,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Reloj banner ───────────────────────────────────────────────────────────
  Widget _buildClockBanner() {
    final now = DateTime.now();
    final hour = now.hour > 12
        ? now.hour - 12
        : (now.hour == 0 ? 12 : now.hour);
    final amPm = now.hour >= 12 ? 'PM' : 'AM';
    final timeStr =
        '${hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
      decoration: BoxDecoration(
        color: _accent,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _accent.withValues(alpha: 0.25),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            timeStr,
            style: TextStyle(
              fontFamily: _font,
              fontSize: 44,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: -1,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 7, left: 6),
            child: Text(
              amPm,
              style: TextStyle(
                fontFamily: _font,
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Estado vacío ───────────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    final hasFilter = _activeFilter != _TaskFilterKind.none;
    return Padding(
      padding: const EdgeInsets.only(top: 60),
      child: Column(
        children: [
          Text(hasFilter ? '🔍' : '📋', style: const TextStyle(fontSize: 52)),
          const SizedBox(height: 16),
          Text(
            hasFilter ? 'Sin resultados' : 'Sin tareas por ahora',
            style: TextStyle(
              fontFamily: _font,
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: _heading,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            hasFilter
                ? 'No hay tareas que coincidan\ncon este filtro'
                : 'Presiona el botón + para agregar\ntu primera tarea',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: _font,
              fontSize: 14,
              color: _muted,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ── Lista de tareas ────────────────────────────────────────────────────────
  Widget _buildTaskList(List<Task> tasks) {
    final sections = _sections(tasks);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: sections.map((section) {
        final sectionTasks = tasks
            .where((t) => _getSection(t) == section)
            .toList();
        final isOverdueSection = section == 'Vencidas';
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  if (isOverdueSection) ...[
                    Icon(Icons.warning_amber_rounded, color: _danger, size: 15),
                    const SizedBox(width: 5),
                  ],
                  Text(
                    section.toUpperCase(),
                    style: TextStyle(
                      fontFamily: _font,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isOverdueSection ? _danger : _muted,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
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
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: _isDark ? 0.34 : 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(_typeIcon(task.type), color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: _font,
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      color: Colors.white.withValues(alpha: 0.7),
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _dueDisplayText(task),
                      style: TextStyle(
                        fontFamily: _font,
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => CreateTaskScreen(task: task)),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Ver',
                style: TextStyle(
                  fontFamily: _font,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Dialogs ────────────────────────────────────────────────────────────────
  Future<void> _showAddCustomTypeDialog() async {
    final controller = TextEditingController();
    final type = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _surface,
        title: Text(
          'Nuevo tipo de tarea',
          style: TextStyle(
            fontFamily: _font,
            fontWeight: FontWeight.w600,
            color: _heading,
          ),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          style: TextStyle(fontFamily: _font, color: _heading),
          decoration: InputDecoration(
            hintText: 'Ej. Proyecto, Familia...',
            hintStyle: TextStyle(fontFamily: _font, color: _muted),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancelar',
              style: TextStyle(fontFamily: _font, color: _muted),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: Text(
              'Guardar',
              style: TextStyle(
                fontFamily: _font,
                color: _accent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    final cleanType = type?.trim();
    WidgetsBinding.instance.addPostFrameCallback((_) => controller.dispose());
    if (cleanType == null || cleanType.isEmpty || !mounted) return;

    await Future<void>.delayed(Duration.zero);
    if (!mounted) return;

    final added = await context.read<TaskTypeProvider>().addCustomType(
      cleanType,
    );
    if (!mounted) return;

    if (!added) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ese tipo de tarea ya existe')),
      );
      return;
    }

    setState(() {
      _activeFilter = _TaskFilterKind.type;
      _selectedTypeFilter = cleanType;
      _selectedDateFilter = null;
      _selectedImportanceFilter = null;
      _showFilters = false;
    });
  }

  Future<void> _deleteCustomType(String type, List<Task> allTasks) async {
    final hasActiveTasks = allTasks.any(
      (task) => task.type == type && !_isOverdue(task),
    );

    if (hasActiveTasks) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No se puede eliminar "$type" porque tiene tareas activas',
          ),
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _surface,
        title: Text(
          'Eliminar tipo',
          style: TextStyle(
            fontFamily: _font,
            fontWeight: FontWeight.w600,
            color: _heading,
          ),
        ),
        content: Text(
          '¿Eliminar "$type" de tus tipos personalizados?',
          style: TextStyle(fontFamily: _font, color: _heading),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancelar',
              style: TextStyle(fontFamily: _font, color: _muted),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Eliminar',
              style: TextStyle(
                fontFamily: _font,
                color: _danger,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;
    await context.read<TaskTypeProvider>().removeCustomType(type);
    if (!mounted) return;

    if (_activeFilter == _TaskFilterKind.type && _selectedTypeFilter == type) {
      _clearFilter();
    }
  }

  IconData _typeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'academica':
        return Icons.school_outlined;
      case 'personal':
        return Icons.person_outline;
      case 'trabajo':
        return Icons.work_outline;
      case 'salud':
        return Icons.favorite_border;
      case 'otro':
        return Icons.category_outlined;
      default:
        return Icons.label_outline;
    }
  }
}
