// lib/models/task_model.dart

class Task {
  final String id;
  final String title;
  final DateTime? dueDate;   // null si el usuario activa "No definir"
  final String type;         // 'Academica', 'Personal', 'Trabajo', etc.
  final String details;
  final List<String> imagePaths; // rutas locales de imágenes adjuntas
  final int importance;      // -1 = predeterminado, 0-5 = nivel elegido
  final bool reminder;       // true = enviar recordatorios
  final DateTime createdAt;
  final bool completed;

  Task({
    required this.id,
    required this.title,
    this.dueDate,
    required this.type,
    this.details = '',
    this.imagePaths = const [],
    this.importance = -1,
    this.reminder = false,
    required this.createdAt,
    this.completed = false,
  });

  // ── Convierte Task a Map para guardar en SQLite ───────────────────────────
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'dueDate': dueDate?.toIso8601String(),
      'type': type,
      'details': details,
      'imagePaths': imagePaths.join('|'), // guardamos como texto separado por |
      'importance': importance,
      'reminder': reminder ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
      'completed': completed ? 1 : 0,
    };
  }

  // ── Crea un Task desde un Map de SQLite ───────────────────────────────────
  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'],
      title: map['title'],
      dueDate: map['dueDate'] != null ? DateTime.parse(map['dueDate']) : null,
      type: map['type'],
      details: map['details'] ?? '',
      imagePaths: map['imagePaths'] != null && map['imagePaths'].isNotEmpty
          ? (map['imagePaths'] as String).split('|')
          : [],
      importance: map['importance'] ?? -1,
      reminder: map['reminder'] == 1,
      createdAt: DateTime.parse(map['createdAt']),
      completed: map['completed'] == 1,
    );
  }

  // ── Copia con cambios (útil para editar) ──────────────────────────────────
  Task copyWith({
    String? title,
    DateTime? dueDate,
    bool clearDueDate = false,
    String? type,
    String? details,
    List<String>? imagePaths,
    int? importance,
    bool? reminder,
    bool? completed,
  }) {
    return Task(
      id: id,
      title: title ?? this.title,
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
      type: type ?? this.type,
      details: details ?? this.details,
      imagePaths: imagePaths ?? this.imagePaths,
      importance: importance ?? this.importance,
      reminder: reminder ?? this.reminder,
      createdAt: createdAt,
      completed: completed ?? this.completed,
    );
  }
}