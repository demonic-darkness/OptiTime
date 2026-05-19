// lib/providers/settings_provider.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/color_threshold.dart';

class SettingsProvider extends ChangeNotifier {
  bool _darkMode = false;
  bool _reminders = true;

  // ── 5 colores fijos en orden de más días a menos ──────────────────────────
  late List<ColorThreshold> _thresholds;

  bool get darkMode => _darkMode;
  bool get reminders => _reminders;
  List<ColorThreshold> get thresholds => _thresholds;

  // Cuántos están deshabilitados actualmente
  int get _disabledCount => _thresholds.where((t) => !t.enabled).length;

  // Si un threshold puede deshabilitarse (máx 2 deshabilitados = mín 3 activos)
  bool canDisable(int index) {
    if (!_thresholds[index].enabled) return true; // ya está deshabilitado, puede re-habilitarse
    return _disabledCount < 2;
  }

  // ── Carga desde SharedPreferences ────────────────────────────────────────
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();

    _darkMode = prefs.getBool('darkMode') ?? false;
    _reminders = prefs.getBool('reminders') ?? true;

    // Valores por defecto: verde=10, amarillo=5, naranja=3, rojo=1, rojo oscuro=0
    _thresholds = [
      ColorThreshold(
        color: const Color(0xFF4CAF50),
        label: 'Verde',
        days: prefs.getInt('threshold_days_0') ?? 10,
        enabled: prefs.getBool('threshold_enabled_0') ?? true,
      ),
      ColorThreshold(
        color: const Color(0xFFFFEE58),
        label: 'Amarillo',
        days: prefs.getInt('threshold_days_1') ?? 5,
        enabled: prefs.getBool('threshold_enabled_1') ?? true,
      ),
      ColorThreshold(
        color: const Color(0xFFFFA726),
        label: 'Naranja',
        days: prefs.getInt('threshold_days_2') ?? 3,
        enabled: prefs.getBool('threshold_enabled_2') ?? true,
      ),
      ColorThreshold(
        color: const Color(0xFFEF5350),
        label: 'Rojo',
        days: prefs.getInt('threshold_days_3') ?? 1,
        enabled: prefs.getBool('threshold_enabled_3') ?? true,
      ),
      ColorThreshold(
        color: const Color(0xFF6D1F1F),
        label: 'Rojo oscuro',
        days: prefs.getInt('threshold_days_4') ?? 0,
        enabled: prefs.getBool('threshold_enabled_4') ?? true,
      ),
    ];

    notifyListeners();
  }

  // ── Guardar todo ──────────────────────────────────────────────────────────
  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkMode', _darkMode);
    await prefs.setBool('reminders', _reminders);
    for (int i = 0; i < _thresholds.length; i++) {
      await prefs.setInt('threshold_days_$i', _thresholds[i].days);
      await prefs.setBool('threshold_enabled_$i', _thresholds[i].enabled);
    }
  }

  // ── Métodos públicos ──────────────────────────────────────────────────────

  Future<void> setDarkMode(bool value) async {
    _darkMode = value;
    notifyListeners();
    await _save();
  }

  Future<void> setReminders(bool value) async {
    _reminders = value;
    notifyListeners();
    await _save();
  }

  Future<void> setThresholdDays(int index, int days) async {
    _thresholds[index].days = days;
    notifyListeners();
    await _save();
  }

  Future<void> toggleThreshold(int index) async {
    final t = _thresholds[index];
    if (t.enabled && _disabledCount >= 2) return; // no se puede deshabilitar más
    t.enabled = !t.enabled;
    notifyListeners();
    await _save();
  }

  // ── Lógica principal: color de tarea según días faltantes ─────────────────
  // Solo se usa cuando la importancia es -1 (predeterminado)
  Color colorForDaysLeft(int daysLeft) {
    // Recorre los thresholds habilitados de menor a mayor días
    // y retorna el color del primero que aplique
    final active = _thresholds.where((t) => t.enabled).toList();

    // Ordenar de mayor a menor días para comparar correctamente
    active.sort((a, b) => b.days.compareTo(a.days));

    for (final t in active) {
      if (daysLeft >= t.days) return t.color;
    }

    // Si faltan menos días que el mínimo configurado, usa el último color activo
    return active.last.color;
  }
}