import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../config/constants.dart';
import '../models/trainer_model.dart';
import '../utils/app_exception.dart';

class TrainerService {
  final _supabase = SupabaseConfig.client;

  // Get Nearby Trainers (using PostGIS function)
  Future<List<TrainerModel>> getNearbyTrainers({
    required double latitude,
    required double longitude,
    int radiusMeters = 5000,
    int limit = AppConstants.trainersPerPage,
  }) async {
    try {
      final response = await _supabase.rpc(
        'get_nearby_trainers',
        params: {
          'user_lat': latitude,
          'user_lng': longitude,
          'radius_meters': radiusMeters,
          'limit_count': limit,
        },
      );

      return (response as List)
          .map((trainer) => TrainerModel.fromJson(trainer))
          .toList();
    } catch (e) {
      throw AppException.fromError(e, fallbackMessage: 'Failed to load nearby trainers.');
    }
  }

  // Get All Trainers (with dynamic filter chaining)
  Future<List<TrainerModel>> getTrainers({
    String? specialty,
    int? maxPrice,
    double? minRating,
    int limit = AppConstants.trainersPerPage,
  }) async {
    try {
      var query = _supabase.from('trainer_profiles').select();

      if (specialty != null) {
        query = query.contains('specialties', <String>[specialty]);
      }
      if (maxPrice != null) {
        query = query.lte('price_per_session', maxPrice);
      }
      if (minRating != null) {
        query = query.gte('average_rating', minRating);
      }

      final response = await query
          .order('average_rating', ascending: false)
          .limit(limit);

      return (response as List)
          .map((trainer) => TrainerModel.fromJson(trainer))
          .toList();
    } catch (e) {
      throw AppException.fromError(e, fallbackMessage: 'Failed to load trainers.');
    }
  }

  // Get Trainer by ID
  Future<TrainerModel?> getTrainerById(String trainerId) async {
    try {
      final response = await _supabase
          .from('trainer_profiles')
          .select()
          .eq('trainer_id', trainerId)
          .maybeSingle();

      if (response == null) return null;
      return TrainerModel.fromJson(response);
    } catch (e) {
      throw AppException.fromError(e, fallbackMessage: 'Failed to load trainer details.');
    }
  }

  // Search Trainers by Name
  Future<List<TrainerModel>> searchTrainers(String query) async {
    try {
      final response = await _supabase
          .from('trainer_profiles')
          .select()
          .ilike('full_name', '%$query%')
          .limit(20);

      return (response as List)
          .map((trainer) => TrainerModel.fromJson(trainer))
          .toList();
    } catch (e) {
      throw AppException.fromError(e, fallbackMessage: 'Search failed. Please try again.');
    }
  }
}
