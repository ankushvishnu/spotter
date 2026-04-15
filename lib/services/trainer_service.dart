import 'package:flutter/foundation.dart';
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
    String? userTier,
  }) async {
    try {
      var response = await _supabase.rpc(
        'get_nearby_trainers',
        params: {
          'user_lat': latitude,
          'user_lng': longitude,
          'radius_meters': radiusMeters,
        },
      );

      // Tier visibility: Standard & Pro users can't see Elite trainers
      if (userTier != 'elite') {
        response = (response as List).where((t) => t['user_tier'] != 'elite').toList();
      }

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
    List<String>? serviceLocations,
    String? excludeUserId,
    bool verifiedOnly = false,
    int limit = AppConstants.trainersPerPage,
    String? userTier,
    String? city,
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
      if (serviceLocations != null && serviceLocations.isNotEmpty) {
        query = query.overlaps('service_locations', serviceLocations);
      }
      if (excludeUserId != null && excludeUserId.isNotEmpty) {
        query = query.neq('user_id', excludeUserId);
      }
      if (verifiedOnly) {
        query = query.eq('verification_status', 'verified');
      }

      // City filter
      if (city != null && city.isNotEmpty) {
        query = query.ilike('city', city);
      }

      // Tier visibility: Standard & Pro users can't see Elite trainers
      if (userTier != 'elite') {
        query = query.neq('user_tier', 'elite');
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
  Future<List<TrainerModel>> searchTrainers(String query, {String? excludeUserId, String? userTier, String? city}) async {
    try {
      var dbQuery = _supabase
          .from('trainer_profiles')
          .select()
          .ilike('full_name', '%$query%');

      if (excludeUserId != null && excludeUserId.isNotEmpty) {
        dbQuery = dbQuery.neq('user_id', excludeUserId);
      }

      // City filter
      if (city != null && city.isNotEmpty) {
        dbQuery = dbQuery.ilike('city', city);
      }

      // Tier visibility: Standard & Pro users can't see Elite trainers
      if (userTier != 'elite') {
        dbQuery = dbQuery.neq('user_tier', 'elite');
      }

      final response = await dbQuery.limit(20);

      return (response as List)
          .map((trainer) => TrainerModel.fromJson(trainer))
          .toList();
    } catch (e) {
      throw AppException.fromError(e, fallbackMessage: 'Search failed. Please try again.');
    }
  }

  // Toggle Save Trainer
  Future<bool> toggleSaveTrainer(String trainerId, String userId, bool isCurrentlySaved) async {
    try {
      if (isCurrentlySaved) {
        await _supabase.from('saved_trainers')
            .delete()
            .eq('user_id', userId)
            .eq('trainer_id', trainerId);
        return false;
      } else {
        await _supabase.from('saved_trainers')
            .insert({'user_id': userId, 'trainer_id': trainerId});
        return true;
      }
    } catch (e) {
      debugPrint('TrainerService: toggleSaveTrainer error: $e');
      return isCurrentlySaved;
    }
  }

  // Check if Trainer is Saved
  Future<bool> isTrainerSaved(String trainerId, String userId) async {
    try {
      final response = await _supabase.from('saved_trainers')
          .select()
          .eq('user_id', userId)
          .eq('trainer_id', trainerId)
          .maybeSingle();
      return response != null;
    } catch (e) {
      debugPrint('TrainerService: isTrainerSaved error: $e');
      return false;
    }
  }

  // Get Trainer Slots
  Future<List<Map<String, dynamic>>> getTrainerSlots(String trainerId, DateTime date) async {
    try {
      final dateStr = date.toIso8601String().split('T')[0];
      final response = await _supabase
          .from('trainer_slots')
          .select()
          .eq('trainer_id', trainerId)
          .eq('slot_date', dateStr);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw AppException.fromError(e, fallbackMessage: 'Failed to load slots.');
    }
  }

  // Add Trainer Slot
  Future<void> addTrainerSlot({
    required String trainerId,
    required DateTime date,
    required String startTime,
    required String endTime,
    required bool isPreferred,
  }) async {
    try {
      await _supabase.from('trainer_slots').insert({
        'trainer_id': trainerId,
        'slot_date': date.toIso8601String().split('T')[0],
        'start_time': startTime,
        'end_time': endTime,
        'is_preferred': isPreferred,
      });
    } catch (e) {
      throw AppException.fromError(e, fallbackMessage: 'Failed to add slot.');
    }
  }

  // Delete Trainer Slot
  Future<void> deleteTrainerSlot(String slotId) async {
    try {
      await _supabase.from('trainer_slots').delete().eq('id', slotId);
    } catch (e) {
      throw AppException.fromError(e, fallbackMessage: 'Failed to delete slot.');
    }
  }

  // Trainer tier is now managed via users.tier — see TierService

  // Get Trainer Profile by User ID (for the logged-in trainer)
  Future<Map<String, dynamic>?> getTrainerByUserId(String userId) async {
    try {
      final response = await _supabase
          .from('trainer_profiles')
          .select()
          .eq('user_id', userId)
          .maybeSingle();
      return response;
    } catch (e) {
      debugPrint('TrainerService: getTrainerByUserId error: $e');
      return null;
    }
  }
}
