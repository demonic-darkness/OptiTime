// lib/screens/home_screen.dart

import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  // ── Tareas de ejemplo ──────────────────────────────────────────────────────
final List<Map<String, dynamic>> _todayTasks = [
  {'title': 'Hacer ejercicio',       'status': 'done'},
  {'title': 'Terminar proyecto',     'status': 'warning'},
  {'title': 'Revisar informes',      'status': 'urgent'},
  {'title': 'Estudiar para examen',  'status': 'warning'},  // +
  {'title': 'Leer capítulo 5',       'status': 'urgent'},   // +
];

  // ── Paleta: Enfoque Índigo ─────────────────────────────────────────────────
  static const Color _primary   = Color(0xFF4F46E5);
  static const Color _info      = Color(0xFF06B6D4);
  static const Color _bgPage    = Color(0xFFF1F5F9);
  static const Color _textDark  = Color(0xFF0F172A);
  static const Color _textMuted = Color(0xFF64748B);
  static const Color _success   = Color(0xFF22C55E);
  static const Color _warning   = Color(0xFFFACC15);
  static const Color _danger    = Color(0xFFEF4444);

  // ── Helpers ────────────────────────────────────────────────────────────────
  Color _statusColor(String status) {
    switch (status) {
      case 'done':    return _success;
      case 'warning': return _warning;
      case 'urgent':  return _danger;
      default:        return Colors.grey;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'done':    return Icons.check_circle;
      case 'warning': return Icons.warning_amber_rounded;
      case 'urgent':  return Icons.cancel;
      default:        return Icons.circle_outlined;
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    _buildGreeting(),
                    const SizedBox(height: 20),
                    _buildNextTaskHero(),
                    const SizedBox(height: 16),
                    _buildSummaryRow(),
                    const SizedBox(height: 20),
                    _buildTodayTasks(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: add new task
        },
        backgroundColor: _primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  // ── AppBar con fecha discreta ──────────────────────────────────────────────
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

  // ── Saludo + notificación ──────────────────────────────────────────────────
  Widget _buildGreeting() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text(
          '¡BUENOS DÍAS!',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            fontStyle: FontStyle.italic,
            color: _textDark,
          ),
        ),
        Stack(
          children: [
            const Icon(Icons.notifications_outlined, color: _primary, size: 28),
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: _danger,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text('1',
                      style: TextStyle(fontSize: 6, color: Colors.white)),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Hero: próxima tarea urgente ────────────────────────────────────────────
  Widget _buildNextTaskHero() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF818CF8), _primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: _primary.withOpacity(0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Etiquetas superior
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.bolt_rounded, color: Colors.white, size: 14),
                    SizedBox(width: 4),
                    Text(
                      'PRÓXIMA TAREA',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _danger.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'URGENTE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Nombre de la tarea
          const Text(
            'Entregar documentación\nde matemáticas',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.25,
            ),
          ),

          const SizedBox(height: 12),

          // Metadata + botón
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.menu_book_rounded,
                    color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Académico · Matemáticas',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  Text(
                    'Vence a las 5:00 PM',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () {
                  // TODO: navigate to detail
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: _primary,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Detalles',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Fila de resumen rápido ─────────────────────────────────────────────────
  Widget _buildSummaryRow() {
    final items = [
      {'label': 'Pendientes',  'count': '3', 'color': _primary,  'bg': const Color(0xFFEDE9FE)},
      {'label': 'En progreso', 'count': '1', 'color': _info,     'bg': const Color(0xFFE0F2FE)},
      {'label': 'Completadas', 'count': '2', 'color': _success,  'bg': const Color(0xFFDCFCE7)},
    ];

    return Row(
      children: List.generate(items.length, (i) {
        final item = items[i];
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: i < items.length - 1 ? 10 : 0),
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: item['bg'] as Color,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Text(
                  item['count'] as String,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: item['color'] as Color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item['label'] as String,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: (item['color'] as Color).withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  // ── Tareas de hoy (colapsable, máx 3 visibles) ────────────────────────────
  static const int _taskPreviewLimit = 3;

  Widget _buildTodayTasks() {
    final pending = _todayTasks.where((t) => t['status'] != 'done').toList();
    final visible = pending.take(_taskPreviewLimit).toList();
    final extra   = pending.length - _taskPreviewLimit;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Encabezado ────────────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tareas de Hoy',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _textDark,
                ),
              ),
              if (pending.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDE9FE),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${pending.length} pendiente${pending.length > 1 ? 's' : ''}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _primary,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 14),

          // ── Estado vacío ──────────────────────────────────────────────────
          if (pending.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.celebration_rounded,
                        color: _success, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '¡Sin pendientes por hoy!',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: _textDark,
                        ),
                      ),
                      Text(
                        'Disfruta tu tiempo libre 🎉',
                        style: TextStyle(fontSize: 12, color: _textMuted),
                      ),
                    ],
                  ),
                ],
              ),
            ),

          // ── Lista (máx 3) ─────────────────────────────────────────────────
          ...visible.map((task) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Icon(
                      _statusIcon(task['status']),
                      color: _statusColor(task['status']),
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        task['title'],
                        style: const TextStyle(
                          fontSize: 14,
                          color: _textDark,
                        ),
                      ),
                    ),
                    if (task['status'] == 'warning')
                      const Icon(Icons.warning_amber_rounded,
                          color: _warning, size: 18),
                    if (task['status'] == 'urgent')
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFE4E4),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'Urgente',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _danger,
                          ),
                        ),
                      ),
                  ],
                ),
              )),

          // ── Botón "Ver todas" si hay más de 3 ────────────────────────────
          if (extra > 0) ...[
            const Divider(height: 20, thickness: 0.8),
            GestureDetector(
              onTap: () {
                // TODO: navegar a pestaña de tareas
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Ver $extra tarea${extra > 1 ? 's' : ''} más',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _primary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_forward_rounded,
                      color: _primary, size: 16),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}