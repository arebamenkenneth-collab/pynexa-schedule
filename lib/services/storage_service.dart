import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/task.dart';
import '../models/habit.dart';
import '../models/goal.dart';

class StorageService {
  static const String _tasksKey = 'pynexa_schedule_tasks_v1';
  static const String _habitsKey = 'pynexa_schedule_habits_v1';
  static const String _goalsKey = 'pynexa_schedule_goals_v1';

  Future<List<ScheduleTask>> loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_tasksKey);

    if (raw == null || raw.isEmpty) return [];

    try {
      final List<dynamic> decoded = jsonDecode(raw);
      return decoded
          .map((item) => ScheduleTask.fromJson(
                Map<String, dynamic>.from(item),
              ))
          .toList();
    } catch (error) {
      throw FormatException('Could not load saved tasks: $error');
    }
  }

  Future<List<Habit>> loadHabits() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_habitsKey);

    if (raw == null || raw.isEmpty) return [];

    try {
      final List<dynamic> decoded = jsonDecode(raw);
      return decoded
          .map((item) => Habit.fromJson(
                Map<String, dynamic>.from(item),
              ))
          .toList();
    } catch (error) {
      throw FormatException('Could not load saved habits: $error');
    }
  }

  Future<List<PlannerGoal>> loadGoals() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_goalsKey);

    if (raw == null || raw.isEmpty) return [];

    try {
      final List<dynamic> decoded = jsonDecode(raw);
      return decoded
          .map((item) => PlannerGoal.fromJson(
                Map<String, dynamic>.from(item),
              ))
          .toList();
    } catch (error) {
      throw FormatException('Could not load saved goals: $error');
    }
  }

  Future<void> saveTasks(List<ScheduleTask> tasks) async {
    final prefs = await SharedPreferences.getInstance();
    final data = tasks.map((task) => task.toJson()).toList();
    await prefs.setString(_tasksKey, jsonEncode(data));
  }

  Future<void> saveHabits(List<Habit> habits) async {
    final prefs = await SharedPreferences.getInstance();
    final data = habits.map((habit) => habit.toJson()).toList();
    await prefs.setString(_habitsKey, jsonEncode(data));
  }

  Future<void> saveGoals(List<PlannerGoal> goals) async {
    final prefs = await SharedPreferences.getInstance();
    final data = goals.map((goal) => goal.toJson()).toList();
    await prefs.setString(_goalsKey, jsonEncode(data));
  }

  Future<String> createBackup() async {
    final tasks = await loadTasks();
    final habits = await loadHabits();
    final goals = await loadGoals();

    final backup = {
      'app': 'PyNexa Schedule',
      'version': 1,
      'createdAt': DateTime.now().toIso8601String(),
      'tasks': tasks.map((item) => item.toJson()).toList(),
      'habits': habits.map((item) => item.toJson()).toList(),
      'goals': goals.map((item) => item.toJson()).toList(),
    };

    return const JsonEncoder.withIndent('  ').convert(backup);
  }

  Future<void> restoreBackup(String backupJson) async {
    final decoded = jsonDecode(backupJson);

    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Invalid backup file.');
    }

    if (decoded['app'] != 'PyNexa Schedule') {
      throw const FormatException('This backup is not from PyNexa Schedule.');
    }

    final tasksData = decoded['tasks'];
    final habitsData = decoded['habits'];
    final goalsData = decoded['goals'];

    if (tasksData is! List ||
        habitsData is! List ||
        goalsData is! List) {
      throw const FormatException('Backup data is incomplete.');
    }

    final tasks = tasksData
        .map((item) => ScheduleTask.fromJson(
              Map<String, dynamic>.from(item),
            ))
        .toList();

    final habits = habitsData
        .map((item) => Habit.fromJson(
              Map<String, dynamic>.from(item),
            ))
        .toList();

    final goals = goalsData
        .map((item) => PlannerGoal.fromJson(
              Map<String, dynamic>.from(item),
            ))
        .toList();

    await saveTasks(tasks);
    await saveHabits(habits);
    await saveGoals(goals);
  }
}
