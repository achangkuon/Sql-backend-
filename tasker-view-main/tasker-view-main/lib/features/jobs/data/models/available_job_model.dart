class AvailableJobModel {
  final String id;
  final String clientId;
  final String category;
  final String? subcategory;
  final String? details;
  final double? priceMin;
  final double? priceMax;
  final String? locationLabel;
  final double? latitude;
  final double? longitude;
  final String status;
  final DateTime createdAt;

  AvailableJobModel({
    required this.id,
    required this.clientId,
    required this.category,
    this.subcategory,
    this.details,
    this.priceMin,
    this.priceMax,
    this.locationLabel,
    this.latitude,
    this.longitude,
    required this.status,
    required this.createdAt,
  });

  factory AvailableJobModel.fromJson(Map<String, dynamic> json) {
    return AvailableJobModel(
      id:            json['id'] as String,
      clientId:      json['client_id'] as String,
      category:      json['category'] as String? ?? '',
      subcategory:   json['subcategory'] as String?,
      details:       json['details'] as String?,
      priceMin:      json['price_min']  != null ? (json['price_min']  as num).toDouble() : null,
      priceMax:      json['price_max']  != null ? (json['price_max']  as num).toDouble() : null,
      locationLabel: json['location_label'] as String?,
      latitude:      json['latitude']  != null ? (json['latitude']  as num).toDouble() : null,
      longitude:     json['longitude'] != null ? (json['longitude'] as num).toDouble() : null,
      status:        json['status'] as String? ?? 'pending',
      createdAt:     DateTime.parse(json['created_at'] as String),
    );
  }

  /// Título legible: primera subcategoría o slug de categoría
  String get title {
    final first = subcategory?.split(', ').first.trim() ?? '';
    return first.isNotEmpty ? first : category;
  }

  /// Rango de precio formateado
  String get priceRange {
    final min = priceMin?.toStringAsFixed(0);
    final max = priceMax?.toStringAsFixed(0);
    if (min == null && max == null) return 'Precio a negociar';
    if (min == max || max == null) return '\$$min';
    if (min == null) return 'Hasta \$$max';
    return '\$$min – \$$max';
  }

  /// Tiempo transcurrido desde la creación
  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 60)  return 'hace ${diff.inMinutes} min';
    if (diff.inHours   < 24)  return 'hace ${diff.inHours}h';
    return 'hace ${diff.inDays}d';
  }
}
