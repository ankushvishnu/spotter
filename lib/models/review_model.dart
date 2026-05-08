import 'package:intl/intl.dart';

class ReviewModel {
  final String id;
  final String reviewerId;
  final String trainerId;
  final String? bookingId;   // nullable — manually-seeded reviews may have no booking
  final int rating;
  final String? reviewText;
  final int? professionalismRating;
  final int? punctualityRating;
  final int? knowledgeRating;
  final bool isVerified;
  final DateTime createdAt;

  // Joined reviewer info
  final String reviewerName;
  final String? reviewerAvatar;

  ReviewModel({
    required this.id,
    required this.reviewerId,
    required this.trainerId,
    this.bookingId,
    required this.rating,
    this.reviewText,
    this.professionalismRating,
    this.punctualityRating,
    this.knowledgeRating,
    this.isVerified = true,
    required this.createdAt,
    required this.reviewerName,
    this.reviewerAvatar,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      id: json['id'] as String,
      reviewerId: json['reviewer_id'] as String,
      trainerId: json['trainer_id'] as String,
      bookingId: json['booking_id'] as String?,   // safe null cast
      rating: json['rating'] as int,
      reviewText: json['review_text'] as String?,
      professionalismRating: json['professionalism_rating'] as int?,
      punctualityRating: json['punctuality_rating'] as int?,
      knowledgeRating: json['knowledge_rating'] as int?,
      isVerified: json['is_verified'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      reviewerName: json['reviewer']?['full_name'] as String? ?? 'Anonymous',
      reviewerAvatar: json['reviewer']?['avatar_url'] as String?,
    );
  }

  String get formattedDate {
    return DateFormat('MMM d, yyyy').format(createdAt);
  }

  double get averageSubRating {
    final ratings = [
      professionalismRating,
      punctualityRating,
      knowledgeRating,
    ].whereType<int>().toList();
    if (ratings.isEmpty) return rating.toDouble();
    return ratings.reduce((a, b) => a + b) / ratings.length;
  }
}
