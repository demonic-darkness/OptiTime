// lib/screens/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:optitime/providers/settings_provider.dart';
import 'package:optitime/models/color_threshold.dart';

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
    final settings = context.watch<SettingsProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Configuracion de colores',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A2E),
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Define cuántos días faltantes corresponde a cada color.\nPuedes deshabilitar hasta 2 colores.',
          style: TextStyle(fontSize: 12, color: Color(0xFF9E9E9E), height: 1.5),
        ),
        const SizedBox(height: 16),

        // Grid de colores — 3 columnas
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 0.85,
          ),
          itemCount: settings.thresholds.length,
          itemBuilder: (context, i) =>
              _buildColorTile(context, settings, i),
        ),
      ],
    );
  }

  Widget _buildColorTile(
      BuildContext context, SettingsProvider settings, int index) {
    final t = settings.thresholds[index];
    final isEnabled = t.enabled;
    final canDisable = settings.canDisable(index);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Círculo de color
        GestureDetector(
          onTap: () {
            if (!canDisable && isEnabled) {
              // Ya hay 2 deshabilitados, mostrar aviso
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Solo puedes deshabilitar 2 colores'),
                  duration: Duration(seconds: 2),
                ),
              );
              return;
            }
            context.read<SettingsProvider>().toggleThreshold(index);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: isEnabled ? t.color : Colors.grey.shade400,
              shape: BoxShape.circle,
              boxShadow: isEnabled
                  ? [
                      BoxShadow(
                        color: t.color.withOpacity(0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ]
                  : [],
            ),
            child: isEnabled
                ? null
                : const Icon(Icons.block, color: Colors.white54, size: 28),
          ),
        ),

        const SizedBox(height: 8),

        // Campo de días o chip "Deshabilitado"
        isEnabled
            ? _buildDaysField(context, index, t)
            : _buildDisabledChip(context, index),

        const SizedBox(height: 4),

        Text(
          'Días faltantes',
          style: TextStyle(
            fontSize: 11,
            color: isEnabled ? const Color(0xFF424242) : Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildDaysField(
      BuildContext context, int index, ColorThreshold t) {
    return SizedBox(
      width: 80,
      height: 32,
      child: TextFormField(
        initialValue: t.days.toString(),
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(3),
        ],
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide:
                const BorderSide(color: Color(0xFF3A3A9F), width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        onChanged: (v) {
          final parsed = int.tryParse(v);
          if (parsed != null) {
            context.read<SettingsProvider>().setThresholdDays(index, parsed);
          }
        },
      ),
    );
  }

  Widget _buildDisabledChip(BuildContext context, int index) {
    return GestureDetector(
      onTap: () => context.read<SettingsProvider>().toggleThreshold(index),
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade400),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Deshabilitado',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.arrow_drop_down,
                size: 16, color: Colors.grey.shade600),
          ],
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