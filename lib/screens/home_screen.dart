// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:optitime/models/task_model.dart';
import 'package:optitime/providers/settings_provider.dart';
import 'package:optitime/providers/task_provider.dart';
import 'create_task_screen.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onOpenTasks;
  final VoidCallback? onOpenNotifications;

  const HomeScreen({super.key, this.onOpenTasks, this.onOpenNotifications});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // ── Paleta: Azul claro, estilo iOS ────────────────────────────────────────
  static const Color _primary = Color(0xFF3B82F6); // azul claro principal
  static const Color _bgPage = Color(0xFFF2F6FF); // fondo muy suave
  static const Color _textDark = Color(0xFF1C1C1E); // casi negro, estilo iOS
  static const Color _textMuted = Color(0xFF8E8E93); // gris iOS
  static const Color _success = Color(0xFF34C759); // verde iOS
  static const Color _warning = Color(0xFFFF9F0A); // naranja/ámbar iOS
  static const Color _danger = Color(0xFFFF3B30); // rojo iOS
  static const Color _cardBg = Color(0xFFFFFFFF); // cards blancas

  // ── Fuente estilo iOS (SF Pro → usa el sistema en iOS, fallback sans en Android)
  static const String _font = '.SF Pro Text';

  bool get _darkMode => context.watch<SettingsProvider>().darkMode;
  Color get _pageBg => _darkMode ? const Color(0xFF0F172A) : _bgPage;
  Color get _surface => _darkMode ? const Color(0xFF1E293B) : _cardBg;
  Color get _heading => _darkMode ? const Color(0xFFE5E7EB) : _textDark;
  Color get _muted => _darkMode ? const Color(0xFF94A3B8) : _textMuted;
  Color get _homePrimary => _darkMode ? const Color(0xFF60A5FA) : _primary;

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    _buildGreeting(),
                    const SizedBox(height: 24),
                    _buildNextTaskCard(),
                    const SizedBox(height: 24),
                    _buildTodayTasks(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openCreateTask,
        backgroundColor: _homePrimary,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
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
              color: _homePrimary,
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

  // ── Saludo ─────────────────────────────────────────────────────────────────
  Widget _buildGreeting() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _greeting(),
              style: TextStyle(
                fontFamily: _font,
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: _heading,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 2),
          ],
        ),
        GestureDetector(
          onTap: widget.onOpenNotifications,
          child: Stack(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _surface,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: _darkMode ? 0.22 : 0.06,
                      ),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.notifications_outlined,
                  color: _heading,
                  size: 20,
                ),
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: _danger,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Hero: próxima tarea ────────────────────────────────────────────────────
  Widget _buildNextTaskCard() {
    final nextTask = context.watch<TaskProvider>().nextTask;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PRÓXIMA TAREA',
          style: TextStyle(
            fontFamily: _font,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: _muted,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 10),
        if (nextTask == null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: _darkMode ? 0.22 : 0.04,
                  ),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              'No hay tareas próximas',
              style: TextStyle(
                fontFamily: _font,
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: _muted,
              ),
            ),
          )
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _homePrimary,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: _homePrimary.withValues(alpha: 0.25),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Chip urgente
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _taskStatusLabel(nextTask),
                    style: TextStyle(
                      fontFamily: _font,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // Título
                Text(
                  nextTask.title,
                  style: TextStyle(
                    fontFamily: _font,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.3,
                    letterSpacing: -0.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 16),

                // Footer
                Row(
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      color: Colors.white.withValues(alpha: 0.75),
                      size: 15,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      _dueText(nextTask),
                      style: TextStyle(
                        fontFamily: _font,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => _openTask(nextTask),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
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
                            color: _homePrimary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }

  // ── Tareas de hoy ──────────────────────────────────────────────────────────
  static const int _taskPreviewLimit = 3;

  void _openTask(Task task) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CreateTaskScreen(task: task)),
    );
  }

  void _openCreateTask() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateTaskScreen()),
    );
  }

  List<Task> _pendingTasks(List<Task> tasks) {
    final pending = tasks.where((task) => !task.completed).toList();
    pending.sort((a, b) {
      final aDate = a.dueDate;
      final bDate = b.dueDate;
      if (aDate == null && bDate == null) {
        return b.createdAt.compareTo(a.createdAt);
      }
      if (aDate == null) return 1;
      if (bDate == null) return -1;
      return aDate.compareTo(bDate);
    });
    return pending;
  }

  bool _isOverdue(Task task) {
    final dueDate = task.dueDate;
    return dueDate != null && dueDate.isBefore(DateTime.now());
  }

  bool _isDueSoon(Task task) {
    final dueDate = task.dueDate;
    if (dueDate == null || _isOverdue(task)) return false;
    return dueDate.difference(DateTime.now()).inHours <= 24;
  }

  Color _taskColor(Task task) {
    if (task.completed) return _success;
    if (task.importance == -1) {
      final dueDate = task.dueDate;
      if (dueDate == null) return _muted;
      final daysLeft = dueDate.difference(DateTime.now()).inDays;
      return context.read<SettingsProvider>().colorForDaysLeft(daysLeft);
    }

    switch (task.importance) {
      case 0:
        return _homePrimary;
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

  IconData _taskIcon(Task task) {
    if (task.completed) return Icons.check_circle;
    if (_isOverdue(task) || _isDueSoon(task)) return Icons.access_time_rounded;
    return Icons.radio_button_unchecked;
  }

  String _taskStatusLabel(Task task) {
    if (task.completed) return 'Hecha';
    if (_isOverdue(task)) return 'Vencida';
    if (_isDueSoon(task)) return 'Urgente';
    return 'Pendiente';
  }

  String _dueText(Task task) {
    final dueDate = task.dueDate;
    if (dueDate == null) return 'Sin fecha limite';

    final hour = dueDate.hour > 12
        ? dueDate.hour - 12
        : (dueDate.hour == 0 ? 12 : dueDate.hour);
    final amPm = dueDate.hour >= 12 ? 'p.m.' : 'a.m.';
    final min = dueDate.minute.toString().padLeft(2, '0');

    if (_isSameDay(dueDate, DateTime.now())) {
      return 'Vence a las $hour:$min $amPm';
    }
    return 'Vence el ${dueDate.day.toString().padLeft(2, '0')}/'
        '${dueDate.month.toString().padLeft(2, '0')}/${dueDate.year}';
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return '¡Buenos días!';
    if (hour >= 12 && hour < 19) return '¡Buenas tardes!';
    return '¡Buenas noches!';
  }

  Widget _buildTodayTasks() {
    final pending = _pendingTasks(context.watch<TaskProvider>().tasks);
    final visible = pending.take(_taskPreviewLimit).toList();
    final extra = pending.length - _taskPreviewLimit;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Encabezado
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'PENDIENTES',
              style: TextStyle(
                fontFamily: _font,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _muted,
                letterSpacing: 0.8,
              ),
            ),
            if (pending.isNotEmpty)
              Text(
                '${pending.length} pendiente${pending.length > 1 ? 's' : ''}',
                style: TextStyle(
                  fontFamily: _font,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: _homePrimary,
                ),
              ),
          ],
        ),

        const SizedBox(height: 10),

        // Estado vacío
        if (pending.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Text('🎉', style: TextStyle(fontSize: 28)),
                const SizedBox(height: 8),
                Text(
                  '¡Sin tareas pendientes!',
                  style: TextStyle(
                    fontFamily: _font,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _heading,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Disfruta tu tiempo libre',
                  style: TextStyle(
                    fontFamily: _font,
                    fontSize: 13,
                    color: _muted,
                  ),
                ),
              ],
            ),
          ),

        // Lista de tareas
        if (pending.isNotEmpty)
          Container(
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: _darkMode ? 0.22 : 0.04,
                  ),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                ...List.generate(visible.length, (i) {
                  final task = visible[i];
                  final isLast = i == visible.length - 1;
                  return Column(
                    children: [
                      InkWell(
                        onTap: () => _openTask(task),
                        borderRadius: BorderRadius.vertical(
                          top: i == 0 ? const Radius.circular(16) : Radius.zero,
                          bottom: isLast
                              ? const Radius.circular(16)
                              : Radius.zero,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _taskIcon(task),
                                color: _taskColor(task),
                                size: 18,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  task.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFamily: _font,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    color: _heading,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 9,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: _taskColor(
                                    task,
                                  ).withValues(alpha: 0.10),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  _taskStatusLabel(task),
                                  style: TextStyle(
                                    fontFamily: _font,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: _taskColor(task),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (!isLast)
                        Divider(
                          height: 1,
                          thickness: 0.5,
                          indent: 46,
                          color: Colors.black.withValues(
                            alpha: _darkMode ? 0.16 : 0.06,
                          ),
                        ),
                    ],
                  );
                }),

                // Botón "Ver más"
                if (extra > 0) ...[
                  Divider(
                    height: 1,
                    thickness: 0.5,
                    color: Colors.black.withValues(
                      alpha: _darkMode ? 0.16 : 0.06,
                    ),
                  ),
                  GestureDetector(
                    onTap: widget.onOpenTasks,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Ver $extra tarea${extra > 1 ? 's' : ''} más',
                            style: TextStyle(
                              fontFamily: _font,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _homePrimary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: _homePrimary,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}
