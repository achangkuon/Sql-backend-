class ReviewModel {
  final String comment;
  final int rating;

  ReviewModel({
    required this.comment,
    required this.rating,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      comment: json['comment'] as String? ?? '',
      rating: json['rating'] as int? ?? 5,
    );
  }
}
