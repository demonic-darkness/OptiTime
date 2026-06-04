// lib/screens/notifications_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:optitime/models/app_notification.dart';
import 'package:optitime/models/task_model.dart';
import 'package:optitime/providers/app_notification_provider.dart';
import 'package:optitime/providers/settings_provider.dart';
import 'package:optitime/providers/task_provider.dart';
import 'package:optitime/widgets/app_top_bar.dart';
import 'create_task_screen.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  static const Color _primary = Color(0xFF3B82F6);
  static const Color _bgPage = Color(0xFFF1F5F9);
  static const Color _textDark = Color(0xFF0F172A);
  static const Color _textMuted = Color(0xFF64748B);
  static const Color _darkPage = Color(0xFF0F172A);
  static const Color _darkCard = Color(0xFF1E293B);
  static const Color _darkText = Color(0xFFE5E7EB);
  static const Color _darkMuted = Color(0xFF94A3B8);
  static const Color _darkPrimary = Color(0xFF60A5FA);

  @override
  Widget build(BuildContext context) {
    final notifications = context
        .watch<AppNotificationProvider>()
        .notifications;
    final tasks = context.watch<TaskProvider>().tasks;
    final isDark = context.watch<SettingsProvider>().darkMode;

    return Scaffold(
      backgroundColor: isDark ? _darkPage : _bgPage,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(isDark),
            Expanded(
              child: notifications.isEmpty
                  ? _buildEmptyState(isDark)
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 92),
                      itemCount: notifications.length,
                      separatorBuilder: (_, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final notification = notifications[index];
                        final task = _taskFor(notification, tasks);
                        return _buildNotificationCard(
                          context,
                          notification,
                          task,
                          isDark,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(bool isDark) {
    return AppTopBar(
      backgroundColor: isDark ? _darkPage : _bgPage,
      primaryColor: isDark ? _darkPrimary : _primary,
      mutedColor: isDark ? _darkMuted : _textMuted,
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: isDark ? _darkCard : Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: (isDark ? _darkPrimary : _primary).withValues(
                      alpha: isDark ? 0.18 : 0.12,
                    ),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Icon(
                Icons.notifications_none_outlined,
                size: 56,
                color: isDark ? _darkPrimary : const Color(0xFFC7D2FE),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Sin notificaciones',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? _darkPrimary : _primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Aqui apareceran los recordatorios enviados',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? _darkMuted : _textMuted,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationCard(
    BuildContext context,
    AppNotification notification,
    Task? task,
    bool isDark,
  ) {
    final isExpired = task == null || _isOverdue(task);
    final primary = isDark ? _darkPrimary : _primary;
    final muted = isDark ? _darkMuted : _textMuted;
    final text = isDark ? _darkText : _textDark;

    return Material(
      color: isExpired
          ? (isDark ? const Color(0xFF273449) : const Color(0xFFE2E8F0))
          : (isDark ? _darkCard : Colors.white),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: task == null
            ? null
            : () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CreateTaskScreen(task: task),
                  ),
                );
              },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: isExpired
                      ? const Color(0xFF94A3B8)
                      : primary.withValues(alpha: isDark ? 0.18 : 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isExpired
                      ? Icons.notifications_paused_outlined
                      : Icons.notifications_active_outlined,
                  color: isExpired ? Colors.white : primary,
                  size: 21,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.message,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isExpired ? muted : text,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _dateTimeText(notification.createdAt),
                      style: TextStyle(
                        color: muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () {
                  context.read<AppNotificationProvider>().remove(
                    notification.id,
                  );
                },
                icon: const Icon(Icons.delete_outline),
                color: muted,
                tooltip: 'Eliminar',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Task? _taskFor(AppNotification notification, List<Task> tasks) {
    for (final task in tasks) {
      if (task.id == notification.taskId) return task;
    }
    return null;
  }

  bool _isOverdue(Task task) {
    if (task.dueDate == null) return false;
    return task.dueDate!.isBefore(DateTime.now());
  }

  String _dateTimeText(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day/$month/${date.year} $hour:$minute';
  }
}
