// lib/screens/color_settings_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:optitime/models/color_threshold.dart';
import 'package:optitime/providers/settings_provider.dart';
import 'package:optitime/widgets/app_top_bar.dart';

class ColorSettingsScreen extends StatelessWidget {
  const ColorSettingsScreen({super.key});

  static const Color _lightPage = Color(0xFFF2F6FF);
  static const Color _darkPage = Color(0xFF0F172A);
  static const Color _lightCard = Colors.white;
  static const Color _darkCard = Color(0xFF1E293B);
  static const Color _lightAlt = Color(0xFFEFF6FF);
  static const Color _darkAlt = Color(0xFF111827);
  static const Color _lightPrimary = Color(0xFF3B82F6);
  static const Color _darkPrimary = Color(0xFF60A5FA);
  static const Color _lightText = Color(0xFF1C1C1E);
  static const Color _darkText = Color(0xFFE5E7EB);
  static const Color _lightMuted = Color(0xFF8E8E93);
  static const Color _darkMuted = Color(0xFF94A3B8);
  static const String _font = '.SF Pro Text';

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final isDark = settings.darkMode;

    final page = isDark ? _darkPage : _lightPage;
    final primary = isDark ? _darkPrimary : _lightPrimary;
    final muted = isDark ? _darkMuted : _lightMuted;

    return Scaffold(
      backgroundColor: page,
      body: SafeArea(
        child: Column(
          children: [
            AppTopBar(
              backgroundColor: page,
              primaryColor: primary,
              mutedColor: muted,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(context, isDark),
                    const SizedBox(height: 18),
                    _buildInfoCard(isDark),
                    const SizedBox(height: 16),
                    ...List.generate(
                      settings.thresholds.length,
                      (index) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildColorRow(context, settings, index, isDark),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    final primary = isDark ? _darkPrimary : _lightPrimary;
    final text = isDark ? _darkText : _lightText;
    final muted = isDark ? _darkMuted : _lightMuted;
    final card = isDark ? _darkCard : _lightCard;
    final border = _borderColor(isDark);

    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          color: primary,
          style: IconButton.styleFrom(
            backgroundColor: card,
            side: BorderSide(color: border),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Colores de tareas',
                style: TextStyle(
                  fontFamily: _font,
                  color: text,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Ajusta los días faltantes para cada color',
                style: TextStyle(
                  fontFamily: _font,
                  color: muted,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(bool isDark) {
    final primary = isDark ? _darkPrimary : _lightPrimary;
    final muted = isDark ? _darkMuted : _lightMuted;
    final text = isDark ? _darkText : _lightText;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(isDark),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.info_outline_rounded, color: primary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reglas de color',
                  style: TextStyle(
                    fontFamily: _font,
                    color: text,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Puedes deshabilitar hasta 2 colores. Las tareas con importancia automática tomarán estos valores.',
                  style: TextStyle(
                    fontFamily: _font,
                    color: muted,
                    fontSize: 12,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorRow(
    BuildContext context,
    SettingsProvider settings,
    int index,
    bool isDark,
  ) {
    final threshold = settings.thresholds[index];
    final isEnabled = threshold.enabled;
    final canDisable = settings.canDisable(index);
    final primary = isDark ? _darkPrimary : _lightPrimary;
    final text = isDark ? _darkText : _lightText;
    final muted = isDark ? _darkMuted : _lightMuted;
    final alt = isDark ? _darkAlt : _lightAlt;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(isDark),
      child: Row(
        children: [
          GestureDetector(
            onTap: () =>
                _toggleColor(context, settings, index, canDisable, isEnabled),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: isEnabled
                    ? threshold.color
                    : muted.withValues(alpha: 0.35),
                shape: BoxShape.circle,
                boxShadow: isEnabled
                    ? [
                        BoxShadow(
                          color: threshold.color.withValues(alpha: 0.32),
                          blurRadius: 9,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : [],
              ),
              child: isEnabled
                  ? null
                  : Icon(Icons.block_rounded, color: muted, size: 24),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  threshold.label,
                  style: TextStyle(
                    fontFamily: _font,
                    color: isEnabled ? text : muted,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isEnabled
                      ? 'Aplicar desde este número de días'
                      : 'Color deshabilitado',
                  style: TextStyle(
                    fontFamily: _font,
                    color: muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          isEnabled
              ? _buildDaysField(context, index, threshold, isDark)
              : GestureDetector(
                  onTap: () =>
                      context.read<SettingsProvider>().toggleThreshold(index),
                  child: Container(
                    height: 38,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: alt,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _borderColor(isDark)),
                    ),
                    child: Center(
                      child: Text(
                        'Activar',
                        style: TextStyle(
                          fontFamily: _font,
                          color: primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildDaysField(
    BuildContext context,
    int index,
    ColorThreshold threshold,
    bool isDark,
  ) {
    final primary = isDark ? _darkPrimary : _lightPrimary;
    final text = isDark ? _darkText : _lightText;
    final muted = isDark ? _darkMuted : _lightMuted;
    final alt = isDark ? _darkAlt : _lightAlt;

    return SizedBox(
      width: 74,
      height: 42,
      child: TextFormField(
        key: ValueKey('${threshold.label}-${threshold.days}'),
        initialValue: threshold.days.toString(),
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(3),
        ],
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: _font,
          color: text,
          fontSize: 15,
          fontWeight: FontWeight.w800,
        ),
        decoration: InputDecoration(
          hintText: '0',
          hintStyle: TextStyle(color: muted),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 8,
          ),
          filled: true,
          fillColor: alt,
          border: _inputBorder(_borderColor(isDark)),
          enabledBorder: _inputBorder(_borderColor(isDark)),
          focusedBorder: _inputBorder(primary, width: 1.6),
        ),
        onChanged: (value) {
          final parsed = int.tryParse(value);
          if (parsed != null) {
            context.read<SettingsProvider>().setThresholdDays(index, parsed);
          }
        },
      ),
    );
  }

  void _toggleColor(
    BuildContext context,
    SettingsProvider settings,
    int index,
    bool canDisable,
    bool isEnabled,
  ) {
    if (!canDisable && isEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Solo puedes deshabilitar 2 colores'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    settings.toggleThreshold(index);
  }

  BoxDecoration _cardDecoration(bool isDark) {
    return BoxDecoration(
      color: isDark ? _darkCard : _lightCard,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: _borderColor(isDark)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.05),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  Color _borderColor(bool isDark) {
    return isDark
        ? Colors.white.withValues(alpha: 0.08)
        : const Color(0xFFE2E8F0);
  }

  OutlineInputBorder _inputBorder(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}
