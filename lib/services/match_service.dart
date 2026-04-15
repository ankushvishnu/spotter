import 'package:flutter/foundation.dart';
import '../config/supabase_config.dart';
import '../models/trainer_model.dart';
import '../utils/app_exception.dart';

class MatchService {
  final _supabase = SupabaseConfig.client;

  /// Fetch trainers the user hasn't interacted with yet (swipe queue)
  Future<List<TrainerModel>> getSwipeQueue(String userId, {String? city}) async {
    try {
      Set<String> seenIds = {};
      
      // Only check previous matches if a valid userId is provided
      if (userId.trim().isNotEmpty) {
        final seen = await _supabase
            .from('matches')
            .select('trainer_id')
            .eq('user_id', userId);

        seenIds = (seen as List).map((m) => m['trainer_id'] as String).toSet();
      }

      // Fetch all trainers and exclude those already seen
      var query = _supabase
          .from('trainer_profiles')
          .select();
          
      if (userId.isNotEmpty) {
        query = query.neq('user_id', userId);
      }
      
      if (city != null && city.isNotEmpty && city != 'All') {
        // Assume city field exists on trainer_profiles view
        query = query.eq('city', city);
      }
      
      final response = await query
          .order('average_rating', ascending: false)
          .limit(30);

      final trainers = (response as List)
          .map((t) => TrainerModel.fromJson(t))
          .where((t) => !seenIds.contains(t.id))
          .toList();

      return trainers;
    } catch (e) {
      debugPrint('MatchService: getSwipeQueue error: $e');
      throw AppException.fromError(e, fallbackMessage: 'Failed to load trainers.');
    }
  }

  /// Record a right swipe — user liked this trainer
  Future<void> likeTrainer(String userId, String trainerId) async {
    try {
      await _supabase.from('matches').upsert({
        'user_id': userId,
        'trainer_id': trainerId,
        'user_liked': true,
        'match_type': 'swipe',
      }, onConflict: 'user_id,trainer_id');
    } catch (e) {
      debugPrint('MatchService: likeTrainer error: $e');
      throw AppException.fromError(e, fallbackMessage: 'Failed to save match.');
    }
  }

  /// Record a left swipe — user passed this trainer (no DB write, just local skip)
  Future<void> passTrainer(String userId, String trainerId) async {
    try {
      await _supabase.from('matches').upsert({
        'user_id': userId,
        'trainer_id': trainerId,
        'user_liked': false,
        'match_type': 'swipe',
      }, onConflict: 'user_id,trainer_id');
    } catch (e) {
      debugPrint('MatchService: passTrainer error: $e');
    }
  }

  /// Get mutual matches (trainer also approved)
  Future<List<Map<String, dynamic>>> getMutualMatches(String userId) async {
    try {
      final response = await _supabase
          .from('matches')
          .select('*, trainer:trainer_id(*)')
          .eq('user_id', userId)
          .eq('user_liked', true)
          .eq('trainer_approved', true);
      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      debugPrint('MatchService: getMutualMatches error: $e');
      return [];
    }
  }
}
