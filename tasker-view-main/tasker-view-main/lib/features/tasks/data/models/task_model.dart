class TaskModel {
  final String id;
  final String clientId;
  final String? assignedTaskerId;
  final String categoryId;
  final String? subcategoryId;
  final String title;
  final String description;
  final String status;
  final double? agreedPrice;
  final double? platformFee;
  final double? totalPrice;
  final DateTime createdAt;
  final String addressLine;
  final String? city;
  final double? latitude;
  final double? longitude;
  final String? taskSize;
  final List<String> toolsRequired;
  final List<String> photos;
  final double? estimatedDurationHours;
  final DateTime? preferredDate;
  final String? preferredTime;
  final bool isEmergency;
  final DateTime? publishedAt;
  final DateTime? confirmedAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime? cancelledAt;
  final String? cancellationReason;

  TaskModel({
    required this.id,
    required this.clientId,
    this.assignedTaskerId,
    required this.categoryId,
    this.subcategoryId,
    required this.title,
    required this.description,
    required this.status,
    this.agreedPrice,
    this.platformFee,
    this.totalPrice,
    required this.createdAt,
    required this.addressLine,
    this.city,
    this.latitude,
    this.longitude,
    this.taskSize,
    this.toolsRequired = const [],
    this.photos = const [],
    this.estimatedDurationHours,
    this.preferredDate,
    this.preferredTime,
    this.isEmergency = false,
    this.publishedAt,
    this.confirmedAt,
    this.startedAt,
    this.completedAt,
    this.cancelledAt,
    this.cancellationReason,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'] as String,
      clientId: json['client_id'] as String,
      assignedTaskerId: json['assigned_tasker_id'] as String?,
      categoryId: json['category_id'] as String,
      subcategoryId: json['subcategory_id'] as String?,
      title: json['title'] as String,
      description: json['description'] as String,
      status: json['status'] as String? ?? 'draft',
      agreedPrice: json['agreed_price'] != null
          ? (json['agreed_price'] as num).toDouble()
          : null,
      platformFee: json['platform_fee'] != null
          ? (json['platform_fee'] as num).toDouble()
          : null,
      totalPrice: json['total_price'] != null
          ? (json['total_price'] as num).toDouble()
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      addressLine: json['address_line'] as String? ?? '',
      city: json['city'] as String?,
      latitude: json['latitude'] != null
          ? (json['latitude'] as num).toDouble()
          : null,
      longitude: json['longitude'] != null
          ? (json['longitude'] as num).toDouble()
          : null,
      taskSize: json['task_size'] as String?,
      toolsRequired: json['tools_required'] != null
          ? List<String>.from(json['tools_required'] as List)
          : [],
      photos: json['photos'] != null
          ? List<String>.from(json['photos'] as List)
          : [],
      estimatedDurationHours: json['estimated_duration_hours'] != null
          ? (json['estimated_duration_hours'] as num).toDouble()
          : null,
      preferredDate: json['preferred_date'] != null
          ? DateTime.tryParse(json['preferred_date'] as String)
          : null,
      preferredTime: json['preferred_time'] as String?,
      isEmergency: json['is_emergency'] as bool? ?? false,
      publishedAt: json['published_at'] != null
          ? DateTime.tryParse(json['published_at'] as String)
          : null,
      confirmedAt: json['confirmed_at'] != null
          ? DateTime.tryParse(json['confirmed_at'] as String)
          : null,
      startedAt: json['started_at'] != null
          ? DateTime.tryParse(json['started_at'] as String)
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.tryParse(json['completed_at'] as String)
          : null,
      cancelledAt: json['cancelled_at'] != null
          ? DateTime.tryParse(json['cancelled_at'] as String)
          : null,
      cancellationReason: json['cancellation_reason'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'client_id': clientId,
      'assigned_tasker_id': assignedTaskerId,
      'category_id': categoryId,
      'subcategory_id': subcategoryId,
      'title': title,
      'description': description,
      'status': status,
      'agreed_price': agreedPrice,
      'platform_fee': platformFee,
      'total_price': totalPrice,
      'created_at': createdAt.toIso8601String(),
      'address_line': addressLine,
      'city': city,
      'latitude': latitude,
      'longitude': longitude,
      'task_size': taskSize,
      'tools_required': toolsRequired,
      'photos': photos,
      'estimated_duration_hours': estimatedDurationHours,
      'preferred_date': preferredDate?.toIso8601String().split('T').first,
      'preferred_time': preferredTime,
      'is_emergency': isEmergency,
    };
  }

  /// Human-readable task size label
  String get taskSizeLabel {
    switch (taskSize) {
      case 'small':
        return 'Pequena - Estimado < 2 horas';
      case 'medium':
        return 'Mediana - Estimado 2-5 horas';
      case 'large':
        return 'Grande - Estimado 5-8 horas';
      case 'project':
        return 'Proyecto - Mas de 1 dia';
      default:
        return 'Sin especificar';
    }
  }

  /// Short difficulty label
  String get taskSizeShort {
    switch (taskSize) {
      case 'small':
        return 'Pequena';
      case 'medium':
        return 'Mediana';
      case 'large':
        return 'Grande';
      case 'project':
        return 'Proyecto';
      default:
        return 'N/A';
    }
  }

  /// Duration label
  String get estimatedDurationLabel {
    if (estimatedDurationHours == null) return '';
    final h = estimatedDurationHours!;
    if (h < 1) return '${(h * 60).toInt()} min';
    final hours = h.toInt();
    final mins = ((h - hours) * 60).toInt();
    if (mins == 0) return '${hours}h';
    return '${hours}h ${mins}m';
  }
}



