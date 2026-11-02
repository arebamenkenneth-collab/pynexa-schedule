class ScheduleTask {
  final String id;
  String title;
  String notes;
  String category;
  String priority;
  DateTime dueDate;
  DateTime? startTime;
  bool completed;
  String recurrence;
  List<int> repeatDays;
  List<String> subtasks;
  List<bool> subtaskDone;

  ScheduleTask({
    required this.id,
    required this.title,
    this.notes = '',
    this.category = 'Personal',
    this.priority = 'Medium',
    required this.dueDate,
    this.startTime,
    this.completed = false,
    this.recurrence = 'Never',
    List<int>? repeatDays,
    List<String>? subtasks,
    List<bool>? subtaskDone,
  })  : repeatDays = repeatDays ?? [],
        subtasks = subtasks ?? [],
        subtaskDone = subtaskDone ?? [];

  int get completedSubtasks =>
      subtaskDone.where((done) => done).length;

  double get subtaskProgress {
    if (subtasks.isEmpty) return 0;
    return completedSubtasks / subtasks.length;
  }

  void addSubtask(String title) {
    final value = title.trim();
    if (value.isEmpty) return;

    subtasks.add(value);
    subtaskDone.add(false);
  }

  void toggleSubtask(int index) {
    if (index < 0 || index >= subtasks.length) return;

    while (subtaskDone.length < subtasks.length) {
      subtaskDone.add(false);
    }

    subtaskDone[index] = !subtaskDone[index];
  }

  void removeSubtask(int index) {
    if (index < 0 || index >= subtasks.length) return;

    subtasks.removeAt(index);

    if (index < subtaskDone.length) {
      subtaskDone.removeAt(index);
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'notes': notes,
        'category': category,
        'priority': priority,
        'dueDate': dueDate.toIso8601String(),
        'startTime': startTime?.toIso8601String(),
        'completed': completed,
        'recurrence': recurrence,
        'repeatDays': repeatDays,
        'subtasks': subtasks,
        'subtaskDone': subtaskDone,
      };

  factory ScheduleTask.fromJson(Map<String, dynamic> json) {
    final rawSubtasks = json['subtasks'];
    final rawDone = json['subtaskDone'];

    final subtasks = rawSubtasks is List
        ? rawSubtasks.map((item) => item.toString()).toList()
        : <String>[];

    final subtaskDone = rawDone is List
        ? rawDone.map((item) => item == true).toList()
        : <bool>[];

    while (subtaskDone.length < subtasks.length) {
      subtaskDone.add(false);
    }

    if (subtaskDone.length > subtasks.length) {
      subtaskDone.removeRange(subtasks.length, subtaskDone.length);
    }

    return ScheduleTask(
      id: json['id']?.toString() ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      title: json['title']?.toString() ?? '',
      notes: json['notes']?.toString() ?? '',
      category: json['category']?.toString() ?? 'Personal',
      priority: json['priority']?.toString() ?? 'Medium',
      dueDate: DateTime.tryParse(
            json['dueDate']?.toString() ?? '',
          ) ??
          DateTime.now(),
      startTime: DateTime.tryParse(
        json['startTime']?.toString() ?? '',
      ),
      completed: json['completed'] == true,
      recurrence: json['recurrence']?.toString() ?? 'Never',
      repeatDays: json['repeatDays'] is List
          ? (json['repeatDays'] as List)
              .whereType<num>()
              .map((day) => day.toInt())
              .toList()
          : [],
      subtasks: subtasks,
      subtaskDone: subtaskDone,
    );
  }
}
