// lib/screens/home_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  // ── Timer para el reloj en tiempo real ────────────────────────────────────
  late Timer _timer;

  // ── Tareas de ejemplo ──────────────────────────────────────────────────────
  final List<Map<String, dynamic>> _todayTasks = [
    {'title': 'Hacer ejercicio', 'status': 'done'},
    {'title': 'Terminar proyecto', 'status': 'warning'},
    {'title': 'Revisar informes', 'status': 'urgent'},
  ];

  // ── Ciclo de vida ──────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    // Actualiza la pantalla cada segundo para que el reloj sea en tiempo real
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _timer.cancel(); // Cancela el timer al salir para evitar fugas de memoria
    super.dispose();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  Color _statusColor(String status) {
    switch (status) {
      case 'done':
        return const Color(0xFF4CAF50);
      case 'warning':
        return const Color(0xFFFFC107);
      case 'urgent':
        return const Color(0xFFE53935);
      default:
        return Colors.grey;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'done':
        return Icons.check_circle;
      case 'warning':
        return Icons.warning_amber_rounded;
      case 'urgent':
        return Icons.cancel;
      default:
        return Icons.circle_outlined;
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
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
                    const SizedBox(height: 12),
                    _buildGreeting(),
                    const SizedBox(height: 16),
                    _buildClockCard(),
                    const SizedBox(height: 20),
                    _buildTodayTasks(),
                    const SizedBox(height: 20),
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
        backgroundColor: const Color(0xFF5B8DEF),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  // ── Widgets ────────────────────────────────────────────────────────────────

  Widget _buildAppBar() {
    return Container(
      decoration: const BoxDecoration(
        color: Color.fromARGB(255, 151, 217, 238),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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

  Widget _buildGreeting() {
    final now = DateTime.now();
    final days = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
    final months = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    final dateStr = '${days[now.weekday - 1]}, ${now.day} de ${months[now.month - 1]}';

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
            color: Color(0xFF1A1A2E),
          ),
        ),
        Row(
          children: [
            Text(
              dateStr,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF9E9E9E),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 6),
            Stack(
              children: [
                const Icon(Icons.notifications_outlined,
                    color: Color(0xFF3A3A9F), size: 26),
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE53935),
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
        ),
      ],
    );
  }

  Widget _buildClockCard() {
    final now = DateTime.now();
    final hour = now.hour > 12 ? now.hour - 12 : (now.hour == 0 ? 12 : now.hour);
    final amPm = now.hour >= 12 ? 'PM' : 'AM';
    final timeStr =
        '${hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF7B9FFF), Color(0xFF3A3A9F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5B8DEF).withOpacity(0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  timeStr,
                  style: const TextStyle(
                    fontSize: 52,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    amPm,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white70,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: const BoxDecoration(
              color: Color(0xFFCC1F1F),
            ),
            child: const Column(
              children: [
                Text(
                  'Proxima tarea:',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  'Tarea importante',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),

          Container(
            decoration: const BoxDecoration(
              color: Color(0xFFCC1F1F),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Tipo: academico',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        // TODO: navigate to detail
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF3A3A9F),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Detalles',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F0FE),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.menu_book_rounded,
                            color: Color(0xFF3A3A9F), size: 22),
                      ),
                      const SizedBox(width: 10),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Entregar documentación de\nmatemáticas',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF424242),
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Vence a las 5:00 PM',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF3A3A9F),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayTasks() {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'Tareas de Hoy',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              Icon(Icons.more_horiz, color: Colors.grey),
            ],
          ),
          const SizedBox(height: 14),
          ..._todayTasks.map((task) => Padding(
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
                        style: TextStyle(
                          fontSize: 14,
                          color: task['status'] == 'done'
                              ? Colors.grey
                              : const Color(0xFF1A1A2E),
                          decoration: task['status'] == 'done'
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                        ),
                      ),
                    ),
                    if (task['status'] == 'warning')
                      const Icon(Icons.warning_amber_rounded,
                          color: Color(0xFFFFC107), size: 18),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}