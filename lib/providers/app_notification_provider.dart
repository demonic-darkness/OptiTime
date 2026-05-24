// lib/providers/app_notification_provider.dart

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/app_notification.dart';
import '../models/task_model.dart';
import '../providers/settings_provider.dart';
import '../services/phone_notification_service.dart';

class AppNotificationProvider extends ChangeNotifier {
  static const String _notificationsKey = 'app_notifications';
  static const String _sentKeysKey = 'app_notification_sent_keys';

  final List<AppNotification> _notifications = [];
  final Set<String> _sentKeys = {};
  Timer? _timer;

  List<AppNotification> get notifications => List.unmodifiable(_notifications);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final rawNotifications = prefs.getStringList(_notificationsKey) ?? [];
    final rawSentKeys = prefs.getStringList(_sentKeysKey) ?? [];

    _notifications
      ..clear()
      ..addAll(rawNotifications.map((raw) {
        return AppNotification.fromMap(jsonDecode(raw));
      }));
    _sentKeys
      ..clear()
      ..addAll(rawSentKeys);
  }

  void startAutoSync({
    required List<Task> Function() tasks,
    required SettingsProvider Function() settings,
  }) {
    _timer?.cancel();
    syncTasks(tasks(), settings());
    _timer = Timer.periodic(const Duration(minutes: 15), (_) {
      syncTasks(tasks(), settings());
    });
  }

  Future<void> syncTasks(List<Task> tasks, SettingsProvider settings) async {
    final now = DateTime.now();
    for (final task in tasks) {
      if (!task.reminder || task.dueDate == null || !task.dueDate!.isAfter(now)) {
        continue;
      }

      await _notifyColorState(task, settings, now);
      await _notifyDueToday(task, now);
    }
  }

  Future<void> remove(String id) async {
    _notifications.removeWhere((n) => n.id == id);
    notifyListeners();
    await _saveNotifications();
  }

  Future<void> _notifyColorState(
    Task task,
    SettingsProvider settings,
    DateTime now,
  ) async {
    final key = '${task.id}:color:${_colorState(task, settings, now)}';
    if (_sentKeys.contains(key)) return;

    await _addNotification(task, key);
  }

  Future<void> _notifyDueToday(Task task, DateTime now) async {
    if (!_isSameDay(task.dueDate!, now)) return;

    final firstMoment = DateTime(now.year, now.month, now.day, 9);
    final secondMoment = DateTime(now.year, now.month, now.day, 15);

    if (!now.isBefore(firstMoment)) {
      await _addNotification(task, '${task.id}:today:first');
    }
    if (!now.isBefore(secondMoment)) {
      await _addNotification(task, '${task.id}:today:second');
    }
  }

  Future<void> _addNotification(Task task, String sentKey) async {
    if (_sentKeys.contains(sentKey)) return;

    final notification = AppNotification(
      id: const Uuid().v4(),
      taskId: task.id,
      taskTitle: task.title,
      message: _messageFor(task),
      createdAt: DateTime.now(),
    );

    _sentKeys.add(sentKey);
    _notifications.insert(0, notification);
    if (_notifications.length > 100) {
      _notifications.removeRange(100, _notifications.length);
    }

    notifyListeners();
    await _saveSentKeys();
    await _saveNotifications();
    await PhoneNotificationService.show(
      id: notification.id.hashCode & 0x7fffffff,
      title: 'OptiTime',
      body: notification.message,
    );
  }

  String _messageFor(Task task) {
    final due = task.dueDate!;
    if (_isSameDay(due, DateTime.now())) {
      return 'La tarea ${task.title} vence a las ${_timeText(due)}';
    }
    return 'La tarea ${task.title} vence ${_dateText(due)}';
  }

  String _colorState(Task task, SettingsProvider settings, DateTime now) {
    if (task.importance != -1) return 'manual-${task.importance}';
    final daysLeft = task.dueDate!.difference(now).inDays;
    return settings.colorForDaysLeft(daysLeft).value.toRadixString(16);
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _dateText(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  String _timeText(DateTime date) {
    final hour = date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
    final min = date.minute.toString().padLeft(2, '0');
    final amPm = date.hour >= 12 ? 'p.m.' : 'a.m.';
    return '$hour:$min $amPm';
  }

  Future<void> _saveNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _notificationsKey,
      _notifications.map((n) => jsonEncode(n.toMap())).toList(),
    );
  }

  Future<void> _saveSentKeys() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_sentKeysKey, _sentKeys.toList());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
