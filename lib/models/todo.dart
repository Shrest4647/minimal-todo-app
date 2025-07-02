class Todo {
  final int id;
  final String task;
  bool completed;
  DateTime? deadline;
  DateTime? created;
  DateTime? updated;
  DateTime? completedAt;
  bool? reminder;

  Todo({
    required this.id,
    required this.task,
    required this.completed,
    this.deadline,
    this.created,
    this.updated,
    this.completedAt,
    this.reminder,
  }) {
    created = created ?? DateTime.now();
    deadline = deadline ?? created?.add(const Duration(days: 1));
    updated = updated ?? created;
  }
}