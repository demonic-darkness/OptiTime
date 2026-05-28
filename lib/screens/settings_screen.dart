// lib/screens/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:optitime/providers/settings_provider.dart';
import 'package:optitime/screens/color_settings_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const Color _lightPage = Color(0xFFF0F4FF);
  static const Color _darkPage = Color(0xFF0F172A);
  static const Color _lightCard = Colors.white;
  static const Color _darkCard = Color(0xFF1E293B);
  static const Color _lightPrimary = Color(0xFF3A3A9F);
  static const Color _darkPrimary = Color(0xFF93C5FD);
  static const Color _lightText = Color(0xFF1A1A2E);
  static const Color _darkText = Color(0xFFE5E7EB);
  static const Color _darkMuted = Color(0xFF94A3B8);

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final isDark = settings.darkMode;

    return Scaffold(
      backgroundColor: isDark ? _darkPage : _lightPage,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(isDark),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTitle(isDark),
                    const SizedBox(height: 20),
                    _buildColorSection(context, isDark),
                    const SizedBox(height: 28),
                    _buildSwitchSection(context, settings, isDark),
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

  Widget _buildAppBar(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'OptiTime',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isDark ? _darkPrimary : _lightPrimary,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitle(bool isDark) {
    return Text(
      'Configuracion',
      style: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w900,
        color: isDark ? _darkText : _lightText,
      ),
    );
  }

  Widget _buildColorSection(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Card(
        color: isDark ? _darkCard : _lightCard,
        elevation: isDark ? 0 : 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          title: Text(
            'Configuración de colores',
            style: TextStyle(
              color: isDark ? _darkText : _lightText,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          trailing: Icon(
            Icons.chevron_right,
            color: isDark ? _darkMuted : Colors.black54,
          ),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ColorSettingsScreen()),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSwitchSection(
    BuildContext context,
    SettingsProvider settings,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? _darkCard : _lightCard,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.06),
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
              Text(
                'Modo oscuro / claro',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: isDark ? _darkText : _lightText,
                ),
              ),
              Switch(
                value: settings.darkMode,
                activeThumbColor: isDark ? _darkPrimary : _lightPrimary,
                onChanged: (v) =>
                    context.read<SettingsProvider>().setDarkMode(v),
              ),
            ],
          ),

          Divider(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.grey.shade200,
          ),

          // Recordatorios globales
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recordatorios',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: isDark ? _darkText : _lightText,
                ),
              ),
              Switch(
                value: settings.reminders,
                activeThumbColor: isDark ? _darkPrimary : _lightPrimary,
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
