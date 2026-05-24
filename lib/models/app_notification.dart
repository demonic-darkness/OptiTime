// lib/models/app_notification.dart

class AppNotification {
  final String id;
  final String taskId;
  final String taskTitle;
  final String message;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.taskId,
    required this.taskTitle,
    required this.message,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'taskId': taskId,
      'taskTitle': taskTitle,
      'message': message,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory AppNotification.fromMap(Map<String, dynamic> map) {
    return AppNotification(
      id: map['id'],
      taskId: map['taskId'],
      taskTitle: map['taskTitle'],
      message: map['message'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}
