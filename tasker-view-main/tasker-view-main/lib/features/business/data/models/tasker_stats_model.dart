class TaskerStatsModel {
  final double totalEarnings;
  final String tier;
  final int totalTasksCompleted;

  TaskerStatsModel({
    required this.totalEarnings,
    required this.tier,
    required this.totalTasksCompleted,
  });

  factory TaskerStatsModel.fromJson(Map<String, dynamic> json) {
    return TaskerStatsModel(
      totalEarnings: json['total_earnings'] != null ? (json['total_earnings'] as num).toDouble() : 0.0,
      tier: json['tier'] as String? ?? 'new',
      totalTasksCompleted: json['total_tasks_completed'] as int? ?? 0,
    );
  }
}
