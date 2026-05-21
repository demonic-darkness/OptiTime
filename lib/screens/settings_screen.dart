// lib/screens/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:optitime/providers/settings_provider.dart';
// import 'package:optitime/models/color_threshold.dart';
import 'package:optitime/screens/color_settings_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTitle(),
                    const SizedBox(height: 20),
                    _buildColorSection(context),
                    const SizedBox(height: 28),
                    _buildSwitchSection(context),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Widgets ───────────────────────────────────────────────────────────────

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

  Widget _buildTitle() {
    return const Text(
      'Configuracion',
      style: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w900,
        color: Color(0xFF1A1A2E),
      ),
    );
  }

  Widget _buildColorSection(BuildContext context) {
    // Reemplazamos la sección completa por una fila que navega a la pantalla
    // específica de configuración de colores.
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          title: const Text(
            'Configuración de colores',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ColorSettingsScreen()),
            );
          },
        ),
      ),
    );
  }

  

  Widget _buildSwitchSection(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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
        children: [
          // Modo oscuro
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Modo oscuro / claro',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              Switch(
                value: settings.darkMode,
                activeColor: const Color(0xFF3A3A9F),
                onChanged: (v) =>
                    context.read<SettingsProvider>().setDarkMode(v),
              ),
            ],
          ),

          Divider(color: Colors.grey.shade200),

          // Recordatorios globales
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recordatorios',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              Switch(
                value: settings.reminders,
                activeColor: const Color(0xFF3A3A9F),
                onChanged: (v) =>
                    context.read<SettingsProvider>().setReminders(v),
              ),
            ],
          ),
        ],
      ),
    );
  }
}