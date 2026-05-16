// lib/providers/task_provider.dart

import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../database/database_helper.dart';

class TaskProvider extends ChangeNotifier {
  List<Task> _tasks = [];

  List<Task> get tasks => _tasks;

  // ── Tareas de hoy ─────────────────────────────────────────────────────────
  List<Task> get todayTasks {
    final now = DateTime.now();
    return _tasks.where((t) {
      if (t.dueDate == null) return false;
      return t.dueDate!.year == now.year &&
          t.dueDate!.month == now.month &&
          t.dueDate!.day == now.day;
    }).toList();
  }

  // ── Tareas de mañana ──────────────────────────────────────────────────────
  List<Task> get tomorrowTasks {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return _tasks.where((t) {
      if (t.dueDate == null) return false;
      return t.dueDate!.year == tomorrow.year &&
          t.dueDate!.month == tomorrow.month &&
          t.dueDate!.day == tomorrow.day;
    }).toList();
  }

  // ── Próxima tarea (la más cercana sin completar) ──────────────────────────
  Task? get nextTask {
    final pending = _tasks.where((t) => !t.completed && t.dueDate != null);
    if (pending.isEmpty) return null;
    return pending.reduce((a, b) => a.dueDate!.isBefore(b.dueDate!) ? a : b);
  }

  // ── Carga inicial desde SQLite ────────────────────────────────────────────
  Future<void> loadTasks() async {
    _tasks = await DatabaseHelper.instance.getAllTasks();
    notifyListeners();
  }

  // ── Agregar ───────────────────────────────────────────────────────────────
  Future<void> addTask(Task task) async {
    await DatabaseHelper.instance.insertTask(task);
    _tasks.insert(0, task);
    notifyListeners();
  }

  // ── Editar ────────────────────────────────────────────────────────────────
  Future<void> updateTask(Task task) async {
    await DatabaseHelper.instance.updateTask(task);
    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      _tasks[index] = task;
      notifyListeners();
    }
  }

  // ── Eliminar ──────────────────────────────────────────────────────────────
  Future<void> deleteTask(String id) async {
    await DatabaseHelper.instance.deleteTask(id);
    _tasks.removeWhere((t) => t.id == id);
    notifyListeners();
  }

  // ── Marcar como completada ────────────────────────────────────────────────
  Future<void> toggleComplete(String id) async {
    final index = _tasks.indexWhere((t) => t.id == id);
    if (index == -1) return;
    final updated = _tasks[index].copyWith(
      completed: !_tasks[index].completed,
    );
    await updateTask(updated);
  }
}