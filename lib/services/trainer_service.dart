import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../config/constants.dart';
import '../models/trainer_model.dart';

class TrainerService {
  final _supabase = SupabaseConfig.client;

  // Get Nearby Trainers (using PostGIS function)
  Future<List<TrainerModel>> getNearbyTrainers({
    required double latitude,
    required double longitude,
    int radiusMeters = 5000,
    int limit = AppConstants.trainersPerPage,
  }) async {
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
  }

  // Get All Trainers (with filters)
  Future<List<TrainerModel>> getTrainers({
    String? specialty,
    int? maxPrice,
    double? minRating,
    int limit = AppConstants.trainersPerPage,
  }) async {
    List<Map<String, dynamic>> response;

    // Build query based on filters
    if (specialty != null && maxPrice != null && minRating != null) {
      // All filters
      response = await _supabase
          .from('trainer_profiles')
          .select()
          .contains('specialties', <String>[specialty])
          .lte('price_per_session', maxPrice)
          .gte('average_rating', minRating)
          .order('average_rating', ascending: false)
          .limit(limit);
    } else if (specialty != null && maxPrice != null) {
      response = await _supabase
          .from('trainer_profiles')
          .select()
          .contains('specialties', <String>[specialty])
          .lte('price_per_session', maxPrice)
          .order('average_rating', ascending: false)
          .limit(limit);
    } else if (specialty != null && minRating != null) {
      response = await _supabase
          .from('trainer_profiles')
          .select()
          .contains('specialties', <String>[specialty])
          .gte('average_rating', minRating)
          .order('average_rating', ascending: false)
          .limit(limit);
    } else if (maxPrice != null && minRating != null) {
      response = await _supabase
          .from('trainer_profiles')
          .select()
          .lte('price_per_session', maxPrice)
          .gte('average_rating', minRating)
          .order('average_rating', ascending: false)
          .limit(limit);
    } else if (specialty != null) {
      response = await _supabase
          .from('trainer_profiles')
          .select()
          .contains('specialties', <String>[specialty])
          .order('average_rating', ascending: false)
          .limit(limit);
    } else if (maxPrice != null) {
      response = await _supabase
          .from('trainer_profiles')
          .select()
          .lte('price_per_session', maxPrice)
          .order('average_rating', ascending: false)
          .limit(limit);
    } else if (minRating != null) {
      response = await _supabase
          .from('trainer_profiles')
          .select()
          .gte('average_rating', minRating)
          .order('average_rating', ascending: false)
          .limit(limit);
    } else {
      // No filters
      response = await _supabase
          .from('trainer_profiles')
          .select()
          .order('average_rating', ascending: false)
          .limit(limit);
    }

    return response
        .map((trainer) => TrainerModel.fromJson(trainer))
        .toList();
  }

  // Get Trainer by ID
  Future<TrainerModel?> getTrainerById(String trainerId) async {
    final response = await _supabase
        .from('trainer_profiles')
        .select()
        .eq('trainer_id', trainerId)
        .maybeSingle();

    if (response == null) return null;
    return TrainerModel.fromJson(response);
  }

  // Search Trainers by Name
  Future<List<TrainerModel>> searchTrainers(String query) async {
    final response = await _supabase
        .from('trainer_profiles')
        .select()
        .ilike('full_name', '%$query%')
        .limit(20);

    return (response as List)
        .map((trainer) => TrainerModel.fromJson(trainer))
        .toList();
  }
}

