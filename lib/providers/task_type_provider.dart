// lib/providers/task_type_provider.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TaskTypeProvider extends ChangeNotifier {
  static const List<String> defaultTypes = [
    'Academica',
    'Personal',
    'Trabajo',
    'Salud',
    'Otro',
  ];

  static const String _customTypesKey = 'custom_task_types';

  List<String> _customTypes = [];

  List<String> get customTypes => List.unmodifiable(_customTypes);
  List<String> get allTypes => [...defaultTypes, ..._customTypes];

  bool isCustomType(String type) => _customTypes.contains(type);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _customTypes = prefs.getStringList(_customTypesKey) ?? [];
    notifyListeners();
  }

  Future<bool> addCustomType(String rawType) async {
    final type = rawType.trim();
    if (type.isEmpty) return false;

    final exists = allTypes.any(
      (existing) => existing.toLowerCase() == type.toLowerCase(),
    );
    if (exists) return false;

    _customTypes.add(type);
    await _save();
    notifyListeners();
    return true;
  }

  Future<void> removeCustomType(String type) async {
    _customTypes.remove(type);
    await _save();
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_customTypesKey, _customTypes);
  }
}
