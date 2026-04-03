class AvailabilityBlockModel {
  final String id;
  final String taskerId;
  final String blockType;
  final String title;
  final DateTime startTime;
  final DateTime endTime;
  final bool isRecurring;
  final String? recurrenceRule;
  final String? externalId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const AvailabilityBlockModel({
    required this.id,
    required this.taskerId,
    required this.blockType,
    required this.title,
    required this.startTime,
    required this.endTime,
    this.isRecurring = false,
    this.recurrenceRule,
    this.externalId,
    this.createdAt,
    this.updatedAt,
  });

  factory AvailabilityBlockModel.fromJson(Map<String, dynamic> json) {
    return AvailabilityBlockModel(
      id: json['id'] as String,
      taskerId: json['tasker_id'] as String,
      blockType: json['block_type'] as String,
      title: json['title'] as String? ?? 'Bloque',
      startTime: DateTime.parse(json['start_time'] as String).toLocal(),
      endTime: DateTime.parse(json['end_time'] as String).toLocal(),
      isRecurring: json['is_recurring'] as bool? ?? false,
      recurrenceRule: json['recurrence_rule'] as String?,
      externalId: json['external_id'] as String?,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String).toLocal() : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String).toLocal() : null,
    );
  }
}
