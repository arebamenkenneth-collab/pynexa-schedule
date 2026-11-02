class Habit {
  final String id;
  String name;
  String category;
  String description;
  List<String> completedDates;
  Map<String, int> dailyCompletions;
  int dailyTarget;

  Habit({
    required this.id,
    required this.name,
    this.category = 'Personal',
    this.description = '',
    this.dailyTarget = 1,
    List<String>? completedDates,
    Map<String, int>? dailyCompletions,
  })  : completedDates = completedDates ?? [],
        dailyCompletions = dailyCompletions ?? {};

  int completionsOn(String date) {
    if (dailyCompletions.containsKey(date)) {
      return dailyCompletions[date]!;
    }

    return completedDates.contains(date) ? 1 : 0;
  }

  bool isCompletedOn(String date) {
    return completionsOn(date) >= dailyTarget;
  }

  double progressOn(String date) {
    if (dailyTarget <= 0) return 0;

    return (completionsOn(date) / dailyTarget)
        .clamp(0.0, 1.0);
  }

  void addCompletion(String date) {
    final current = completionsOn(date);

    if (current < dailyTarget) {
      dailyCompletions[date] = current + 1;
    }

    _syncCompletedDates(date);
  }

  void removeCompletion(String date) {
    final current = completionsOn(date);

    if (current > 0) {
      dailyCompletions[date] = current - 1;
    }

    _syncCompletedDates(date);
  }

  void toggleDate(String date) {
    if (isCompletedOn(date)) {
      dailyCompletions.remove(date);
      completedDates.remove(date);
    } else {
      dailyCompletions[date] = dailyTarget;
      _syncCompletedDates(date);
    }
  }

  void _syncCompletedDates(String date) {
    if (isCompletedOn(date)) {
      if (!completedDates.contains(date)) {
        completedDates.add(date);
      }
    } else {
      completedDates.remove(date);
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category,
        'description': description,
        'dailyTarget': dailyTarget,
        'completedDates': completedDates,
        'dailyCompletions': dailyCompletions,
      };

  factory Habit.fromJson(Map<String, dynamic> json) {
    final rawCompletions = json['dailyCompletions'];

    final completions = <String, int>{};

    if (rawCompletions is Map) {
      rawCompletions.forEach((key, value) {
        if (value is num) {
          completions[key.toString()] = value.toInt();
        }
      });
    }

    return Habit(
      id: json['id']?.toString() ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      name: json['name']?.toString() ?? 'Untitled habit',
      category: json['category']?.toString() ?? 'Personal',
      description: json['description']?.toString() ?? '',
      dailyTarget: (json['dailyTarget'] as num?)?.toInt() ?? 1,
      completedDates: json['completedDates'] is List
          ? (json['completedDates'] as List)
              .map((date) => date.toString())
              .toList()
          : [],
      dailyCompletions: completions,
    );
  }
}
