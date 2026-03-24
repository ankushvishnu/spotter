import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/review_model.dart';

class ReviewService {
  final _supabase = SupabaseConfig.client;

  /// Fetch all reviews for a trainer
  Future<List<ReviewModel>> getTrainerReviews(String trainerId) async {
    try {
      final response = await _supabase
          .from('reviews')
          .select('''
            *,
            reviewer:users!reviews_reviewer_id_fkey(id, full_name, avatar_url)
          ''')
          .eq('trainer_id', trainerId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((r) => ReviewModel.fromJson(r))
          .toList();
    } catch (e) {
      debugPrint('ReviewService: getTrainerReviews error: $e');
      return [];
    }
  }

  /// Check if user has already reviewed a booking
  Future<bool> hasReviewedBooking(String bookingId, String reviewerId) async {
    try {
      final response = await _supabase
          .from('reviews')
          .select('id')
          .eq('booking_id', bookingId)
          .eq('reviewer_id', reviewerId)
          .maybeSingle();
      return response != null;
    } catch (e) {
      debugPrint('ReviewService: hasReviewedBooking error: $e');
      return false;
    }
  }

  /// Submit a review for a trainer session
  Future<void> submitReview({
    required String reviewerId,
    required String trainerId,
    required String bookingId,
    required int rating,
    String? reviewText,
    int? professionalismRating,
    int? punctualityRating,
    int? knowledgeRating,
  }) async {
    await _supabase.from('reviews').insert({
      'reviewer_id': reviewerId,
      'trainer_id': trainerId,
      'booking_id': bookingId,
      'rating': rating,
      'review_text': reviewText?.isEmpty == true ? null : reviewText,
      'professionalism_rating': professionalismRating,
      'punctuality_rating': punctualityRating,
      'knowledge_rating': knowledgeRating,
      'is_verified': true,
    });
  }

  /// Get average rating stats for a trainer
  Future<Map<String, dynamic>> getTrainerRatingStats(String trainerId) async {
    try {
      final reviews = await getTrainerReviews(trainerId);
      if (reviews.isEmpty) {
        return {
          'average_rating': 0.0,
          'total_reviews': 0,
          'rating_breakdown': {1: 0, 2: 0, 3: 0, 4: 0, 5: 0},
        };
      }

      final avgRating = reviews.fold<double>(0, (sum, r) => sum + r.rating) /
          reviews.length;
      final breakdown = <int, int>{1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
      for (final r in reviews) {
        breakdown[r.rating] = (breakdown[r.rating] ?? 0) + 1;
      }

      return {
        'average_rating': avgRating,
        'total_reviews': reviews.length,
        'rating_breakdown': breakdown,
      };
    } catch (e) {
      debugPrint('ReviewService: getTrainerRatingStats error: $e');
      return {'average_rating': 0.0, 'total_reviews': 0};
    }
  }
}
