import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PyNexaScheduleApp());
}

const Color brandPurple = Color(0xFF8B5CF6);
const Color darkBackground = Color(0xFF0A0A0F);

class ScheduleTask {
  final String id;
  String title;
  String notes;
  String category;
  String priority;
  DateTime dueDate;
  bool completed;

  ScheduleTask({
    required this.id,
    required this.title,
    required this.notes,
    required this.category,
    required this.priority,
    required this.dueDate,
    this.completed = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'notes': notes,
        'category': category,
        'priority': priority,
        'dueDate': dueDate.toIso8601String(),
        'completed': completed,
      };

  factory ScheduleTask.fromJson(Map<String, dynamic> json) {
    return ScheduleTask(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      notes: json['notes'] as String? ?? '',
      category: json['category'] as String? ?? 'Personal',
      priority: json['priority'] as String? ?? 'Medium',
      dueDate: DateTime.tryParse(json['dueDate'] as String? ?? '') ??
          DateTime.now(),
      completed: json['completed'] as bool? ?? false,
    );
  }
}

class PyNexaScheduleApp extends StatefulWidget {
  const PyNexaScheduleApp({super.key});

  @override
  State<PyNexaScheduleApp> createState() => _PyNexaScheduleAppState();
}

class _PyNexaScheduleAppState extends State<PyNexaScheduleApp> {
  bool _darkMode = true;

  void toggleTheme() => setState(() => _darkMode = !_darkMode);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PyNexa Schedule',
      debugShowCheckedModeBanner: false,
      themeMode: _darkMode ? ThemeMode.dark : ThemeMode.light,
      darkTheme: _buildTheme(Brightness.dark),
      theme: _buildTheme(Brightness.light),
      home: ScheduleHomePage(
        isDarkMode: _darkMode,
        onThemeChanged: toggleTheme,
      ),
    );
  }

  ThemeData _buildTheme(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: brandPurple,
      brightness: brightness,
      surface: dark ? const Color(0xFF12121A) : Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor:
          dark ? darkBackground : const Color(0xFFF6F5FA),
      appBarTheme: AppBarTheme(
        backgroundColor:
            dark ? darkBackground : const Color(0xFFF6F5FA),
        foregroundColor: dark ? Colors.white : const Color(0xFF171522),
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: dark ? const Color(0xFF15151F) : Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: dark
                ? Colors.white.withValues(alpha: 0.07)
                : Colors.black.withValues(alpha: 0.06),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor:
            dark ? const Color(0xFF1B1A26) : const Color(0xFFF1EFF7),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      ),
    );
  }
}

class ScheduleHomePage extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onThemeChanged;

  const ScheduleHomePage({
    super.key,
    required this.isDarkMode,
    required this.onThemeChanged,
  });

  @override
  State<ScheduleHomePage> createState() => _ScheduleHomePageState();
}

class _ScheduleHomePageState extends State<ScheduleHomePage> {
  static const String _storageKey = 'pynexa_schedule_tasks_v1';

  final List<ScheduleTask> _tasks = [];
  bool _loading = true;
  int _selectedTab = 0;
  DateTime _selectedDate = DateUtils.dateOnly(DateTime.now());
  String _filter = 'All';

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw != null) {
        final decoded = jsonDecode(raw) as List<dynamic>;
        _tasks
          ..clear()
          ..addAll(decoded.map(
            (item) => ScheduleTask.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          ));
      }
    } catch (_) {
      // If stored data is invalid, the app still opens safely.
    }

    if (mounted) {
      setState(() => _loading = false);
    }
  }

  Future<void> _saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _storageKey,
      jsonEncode(_tasks.map((task) => task.toJson()).toList()),
    );
  }

  List<ScheduleTask> get _visibleTasks {
    final result = _tasks.where((task) {
      final matchesTab = _selectedTab == 1
          ? !task.completed
          : _selectedTab == 2
              ? task.completed
              : true;

      final matchesDate = _selectedTab != 1 ||
          DateUtils.isSameDay(task.dueDate, _selectedDate);

      final matchesFilter = _filter == 'All' ||
          (_filter == 'Today' &&
              DateUtils.isSameDay(task.dueDate, DateTime.now())) ||
          (_filter == 'Upcoming' &&
              task.dueDate.isAfter(DateTime.now()) &&
              !DateUtils.isSameDay(task.dueDate, DateTime.now()));

      return matchesTab && matchesDate && matchesFilter;
    }).toList();

    result.sort((a, b) => a.dueDate.compareTo(b.dueDate));
    return result;
  }

  int get _completedCount => _tasks.where((task) => task.completed).length;

  int get _todayCount => _tasks
      .where((task) =>
          DateUtils.isSameDay(task.dueDate, DateTime.now()) &&
          !task.completed)
      .length;

  Future<void> _openTaskEditor({ScheduleTask? task}) async {
    final result = await showModalBottomSheet<ScheduleTask>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      showDragHandle: true,
      builder: (_) => TaskEditorSheet(
        existingTask: task,
        initialDate: _selectedDate,
      ),
    );

    if (result == null || !mounted) return;

    setState(() {
      final index = _tasks.indexWhere((item) => item.id == result.id);
      if (index == -1) {
        _tasks.add(result);
      } else {
        _tasks[index] = result;
      }
    });

    await _saveTasks();
  }

  Future<void> _toggleTask(ScheduleTask task) async {
    setState(() => task.completed = !task.completed);
    await _saveTasks();
  }

  Future<void> _deleteTask(ScheduleTask task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete task?'),
        content: Text('Remove "${task.title}" from your schedule?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.redAccent,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _tasks.removeWhere((item) => item.id == task.id));
    await _saveTasks();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.colorScheme.onSurface;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 39,
              height: 39,
              decoration: BoxDecoration(
                color: brandPurple.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(
                Icons.calendar_month_rounded,
                color: brandPurple,
              ),
            ),
            const SizedBox(width: 11),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PyNexa',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                ),
                Text(
                  'SCHEDULE',
                  style: TextStyle(
                    fontSize: 10,
                    letterSpacing: 2.2,
                    color: brandPurple,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: widget.isDarkMode ? 'Light mode' : 'Dark mode',
            onPressed: widget.onThemeChanged,
            icon: Icon(
              widget.isDarkMode
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
            ),
          ),
          const SizedBox(width: 5),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openTaskEditor(),
        backgroundColor: brandPurple,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New task'),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedTab,
        onDestinationSelected: (index) =>
            setState(() => _selectedTab = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.grid_view_rounded),
            label: 'Overview',
          ),
          NavigationDestination(
            icon: Icon(Icons.event_note_rounded),
            label: 'Schedule',
          ),
          NavigationDestination(
            icon: Icon(Icons.task_alt_rounded),
            label: 'Completed',
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: brandPurple),
            )
          : SafeArea(
              child: RefreshIndicator(
                color: brandPurple,
                onRefresh: _loadTasks,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
                  children: [
                    Text(
                      _greeting(),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: textColor.withValues(alpha: 0.65),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _selectedTab == 2
                          ? 'Your achievements.'
                          : _selectedTab == 1
                              ? 'Your schedule.'
                              : 'Make today count.',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.7,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      DateFormat('EEEE, MMMM d').format(DateTime.now()),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: textColor.withValues(alpha: 0.58),
                      ),
                    ),
                    const SizedBox(height: 22),
                    if (_selectedTab == 0) ...[
                      _buildWelcomeCard(),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              'Due today',
                              '$_todayCount',
                              Icons.today_rounded,
                              const Color(0xFF8B5CF6),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              'Completed',
                              '$_completedCount',
                              Icons.check_circle_outline_rounded,
                              const Color(0xFF22C58B),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 26),
                    ],
                    if (_selectedTab == 1) ...[
                      _buildDatePicker(),
                      const SizedBox(height: 22),
                    ],
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _selectedTab == 2
                              ? 'Completed tasks'
                              : _selectedTab == 1
                                  ? 'Tasks for ${DateFormat('MMM d').format(_selectedDate)}'
                                  : 'Your tasks',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          '${_visibleTasks.length} tasks',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: textColor.withValues(alpha: 0.55),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_selectedTab == 0) _buildFilterChips(),
                    if (_visibleTasks.isEmpty)
                      _buildEmptyState()
                    else
                      ..._visibleTasks.map(_buildTaskCard),
                  ],
                ),
              ),
            ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning 👋';
    if (hour < 17) return 'Good afternoon 👋';
    return 'Good evening 👋';
  }

  Widget _buildWelcomeCard() {
    return Container(
      padding: const EdgeInsets.all(21),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6541C8), Color(0xFF321C78)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'YOUR PERSONAL PLANNER',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                letterSpacing: 1.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 15),
          const Text(
            'Plan smarter.\nLive with purpose.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 25,
              height: 1.2,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Small steps, planned well, lead to big results.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 18),
          Align(
            alignment: Alignment.centerRight,
            child: Icon(
              Icons.calendar_month_rounded,
              size: 48,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 23),
            const SizedBox(height: 15),
            Text(
              value,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 3),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: ['All', 'Today', 'Upcoming'].map((filter) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(filter),
                selected: _filter == filter,
                selectedColor: brandPurple.withValues(alpha: 0.22),
                onSelected: (_) => setState(() => _filter = filter),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildDatePicker() {
    final dates = List.generate(
      14,
      (index) => DateUtils.dateOnly(DateTime.now()).add(Duration(days: index)),
    );

    return SizedBox(
      height: 88,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: dates.length,
        separatorBuilder: (_, __) => const SizedBox(width: 9),
        itemBuilder: (context, index) {
          final date = dates[index];
          final selected = DateUtils.isSameDay(date, _selectedDate);

          return InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => setState(() => _selectedDate = date),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 57,
              decoration: BoxDecoration(
                color: selected
                    ? brandPurple
                    : Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: selected
                      ? brandPurple
                      : Theme.of(context).dividerColor.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('EEE').format(date),
                    style: TextStyle(
                      fontSize: 11,
                      color: selected ? Colors.white : null,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    '${date.day}',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: selected ? Colors.white : null,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTaskCard(ScheduleTask task) {
    final theme = Theme.of(context);
    final isLate = !task.completed && task.dueDate.isBefore(DateTime.now());
    final priorityColor = task.priority == 'High'
        ? const Color(0xFFFF6B6B)
        : task.priority == 'Low'
            ? const Color(0xFF60A5FA)
            : const Color(0xFFF4B942);

    return Card(
      margin: const EdgeInsets.only(bottom: 11),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _openTaskEditor(task: task),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: task.completed,
                activeColor: brandPurple,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                onChanged: (_) => _toggleTask(task),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        decoration: task.completed
                            ? TextDecoration.lineThrough
                            : null,
                        color: task.completed
                            ? theme.colorScheme.onSurface
                                .withValues(alpha: 0.5)
                            : null,
                      ),
                    ),
                    if (task.notes.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Text(
                        task.notes,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.65),
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 7,
                      runSpacing: 6,
                      children: [
                        _smallTag(
                          task.category,
                          brandPurple.withValues(alpha: 0.15),
                          brandPurple,
                        ),
                        _smallTag(
                          task.priority,
                          priorityColor.withValues(alpha: 0.14),
                          priorityColor,
                        ),
                      ],
                    ),
                    const SizedBox(height: 9),
                    Row(
                      children: [
                        Icon(
                          isLate
                              ? Icons.warning_amber_rounded
                              : Icons.schedule_rounded,
                          size: 14,
                          color: isLate ? Colors.redAccent : null,
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            '${DateFormat('MMM d').format(task.dueDate)} · ${DateFormat('h:mm a').format(task.dueDate)}${isLate ? ' · Overdue' : ''}',
                            style: TextStyle(
                              fontSize: 11,
                              color: isLate
                                  ? Colors.redAccent
                                  : theme.colorScheme.onSurface
                                      .withValues(alpha: 0.65),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') _openTaskEditor(task: task);
                  if (value == 'delete') _deleteTask(task);
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('Edit task')),
                  PopupMenuItem(value: 'delete', child: Text('Delete task')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _smallTag(String text, Color background, Color foreground) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: foreground,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(top: 28),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 34),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(17),
                decoration: BoxDecoration(
                  color: brandPurple.withValues(alpha: 0.13),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.event_available_rounded,
                  size: 34,
                  color: brandPurple,
                ),
              ),
              const SizedBox(height: 15),
              Text(
                _selectedTab == 2 ? 'Nothing completed yet' : 'A fresh start',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                _selectedTab == 2
                    ? 'Tasks you complete will appear here.'
                    : 'Add a task and give your day some direction.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                ),
              ),
              if (_selectedTab != 2) ...[
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: () => _openTaskEditor(),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Create your first task'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class TaskEditorSheet extends StatefulWidget {
  final ScheduleTask? existingTask;
  final DateTime initialDate;

  const TaskEditorSheet({
    super.key,
    this.existingTask,
    required this.initialDate,
  });

  @override
  State<TaskEditorSheet> createState() => _TaskEditorSheetState();
}

class _TaskEditorSheetState extends State<TaskEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _notesController;

  late String _category;
  late String _priority;
  late DateTime _dueDate;
  bool _saving = false;

  final List<String> _categories = [
    'Personal',
    'Work',
    'Study',
    'Health',
    'Finance',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    final task = widget.existingTask;

    _titleController = TextEditingController(text: task?.title ?? '');
    _notesController = TextEditingController(text: task?.notes ?? '');
    _category = task?.category ?? 'Personal';
    _priority = task?.priority ?? 'Medium';
    _dueDate = task?.dueDate ??
        DateTime(
          widget.initialDate.year,
          widget.initialDate.month,
          widget.initialDate.day,
          DateTime.now().hour + 1,
          DateTime.now().minute,
        );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _dueDate.isBefore(DateUtils.dateOnly(now))
          ? DateUtils.dateOnly(now)
          : _dueDate,
      firstDate: DateUtils.dateOnly(now),
      lastDate: DateTime(now.year + 10),
    );

    if (selected != null) {
      setState(() {
        _dueDate = DateTime(
          selected.year,
          selected.month,
          selected.day,
          _dueDate.hour,
          _dueDate.minute,
        );
      });
    }
  }

  Future<void> _pickTime() async {
    final selected = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_dueDate),
    );

    if (selected != null) {
      setState(() {
        _dueDate = DateTime(
          _dueDate.year,
          _dueDate.month,
          _dueDate.day,
          selected.hour,
          selected.minute,
        );
      });
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    final existing = widget.existingTask;

    final task = ScheduleTask(
      id: existing?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      title: _titleController.text.trim(),
      notes: _notesController.text.trim(),
      category: _category,
      priority: _priority,
      dueDate: _dueDate,
      completed: existing?.completed ?? false,
    );

    Navigator.of(context).pop(task);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 5, 20, bottomInset + 20),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.existingTask == null ? 'Create a task' : 'Edit task',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Give your time a purpose. You can edit this later.',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 22),
              TextFormField(
                controller: _titleController,
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Task title',
                  hintText: 'e.g. Study Python for one hour',
                  prefixIcon: Icon(Icons.edit_note_rounded),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter a task title.';
                  }
                  if (value.trim().length > 100) {
                    return 'Keep the title under 100 characters.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _notesController,
                minLines: 2,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  hintText: 'Add details or what you want to accomplish...',
                  prefixIcon: Icon(Icons.notes_rounded),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _category,
                      decoration: const InputDecoration(labelText: 'Category'),
                      items: _categories
                          .map((item) => DropdownMenuItem(
                                value: item,
                                child: Text(item),
                              ))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) setState(() => _category = value);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _priority,
                      decoration: const InputDecoration(labelText: 'Priority'),
                      items: ['Low', 'Medium', 'High']
                          .map((item) => DropdownMenuItem(
                                value: item,
                                child: Text(item),
                              ))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) setState(() => _priority = value);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                'DEADLINE',
                style: theme.textTheme.labelMedium?.copyWith(
                  letterSpacing: 1.4,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 9),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickDate,
                      icon: const Icon(Icons.calendar_today_rounded, size: 17),
                      label: Text(DateFormat('MMM d, y').format(_dueDate)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickTime,
                      icon: const Icon(Icons.access_time_rounded, size: 17),
                      label: Text(DateFormat('h:mm a').format(_dueDate)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: Icon(
                    widget.existingTask == null
                        ? Icons.add_rounded
                        : Icons.check_rounded,
                  ),
                  label: Text(
                    widget.existingTask == null ? 'Save task' : 'Update task',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
