class PlannerGoal {
  final String id;
  String title;
  String description;
  int target;
  int progress;
  DateTime? deadline;
  bool completed;

  PlannerGoal({
    required this.id,
    required this.title,
    this.description = "",
    this.target = 10,
    this.progress = 0,
    this.deadline,
    this.completed = false,
  });

  double get percentage {
    if (target <= 0) return 0;
    return (progress / target).clamp(0.0, 1.0);
  }

  Map<String, dynamic> toJson() => {
        "id": id,
        "title": title,
        "description": description,
        "target": target,
        "progress": progress,
        "deadline": deadline?.toIso8601String(),
        "completed": completed,
      };

  factory PlannerGoal.fromJson(Map<String, dynamic> json) {
    final rawDeadline = json["deadline"];

    return PlannerGoal(
      id: json["id"]?.toString() ?? "",
      title: json["title"]?.toString() ?? "Untitled Goal",
      description: json["description"]?.toString() ?? "",
      target: (json["target"] as num?)?.toInt() ?? 10,
      progress: (json["progress"] as num?)?.toInt() ?? 0,
      deadline: rawDeadline is String
          ? DateTime.tryParse(rawDeadline)
          : null,
      completed: json["completed"] == true,
    );
  }
}
