import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../utils/app_exception.dart';

class BookingService {
  final _supabase = SupabaseConfig.client;

  // Create a new booking
  Future<Map<String, dynamic>> createBooking({
    required String clientId,
    required String trainerId,
    required DateTime sessionDate,
    required String sessionTime,
    required int durationMinutes,
    required String locationType,
    String? locationAddress,
    double? latitude,
    double? longitude,
    required int basePrice,
    required int platformFee,
  }) async {
    try {
      final totalPrice = basePrice + platformFee;

      // 1. Create booking first (so we have booking_id)
      final response = await _supabase.from('bookings').insert({
        'client_id': clientId,
        'trainer_id': trainerId,
        'session_date': sessionDate.toIso8601String().split('T')[0],
        'session_time': sessionTime,
        'duration_minutes': durationMinutes,
        'location_type': locationType,
        'location_address': locationAddress,
        'location_coords': latitude != null && longitude != null
            ? 'POINT($longitude $latitude)'
            : null,
        'base_price': basePrice,
        'platform_fee': platformFee,
        'total_price': totalPrice,
        'status': 'pending',
      }).select().single();

      // 2. Deduct credits via RPC
      try {
        await _supabase.rpc('use_user_credits', params: {
          'user_id': clientId,
          'booking_id': response['id'],
          'credits': totalPrice,
        });
      } catch (rpcError) {
        // Rollback booking if credit deduction fails
        await _supabase.from('bookings').delete().eq('id', response['id']);
        throw AppException('Insufficient balance. You do not have enough credits to book this session.');
      }

      return response;
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException.fromError(e, fallbackMessage: 'Failed to create booking.');
    }
  }

  // Get user bookings
  Future<List<Map<String, dynamic>>> getClientBookings(String clientId) async {
    try {
      final response = await _supabase
          .from('bookings')
          .select('''
            *,
            trainer:trainers!bookings_trainer_id_fkey(
              id,
              user_id,
              specialties,
              price_per_session,
              users!trainers_user_id_fkey(full_name, avatar_url)
            )
          ''')
          .eq('client_id', clientId)
          .order('session_date', ascending: false)
          .order('session_time', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw AppException.fromError(e, fallbackMessage: 'Failed to load your bookings.');
    }
  }

  // Get trainer bookings
  Future<List<Map<String, dynamic>>> getTrainerBookings(String trainerId) async {
    try {
      final response = await _supabase
          .from('bookings')
          .select('''
            *,
            client:users!bookings_client_id_fkey(id, full_name, avatar_url)
          ''')
          .eq('trainer_id', trainerId)
          .order('session_date', ascending: false)
          .order('session_time', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw AppException.fromError(e, fallbackMessage: 'Failed to load trainer bookings.');
    }
  }

  // Get booking by ID
  Future<Map<String, dynamic>?> getBooking(String bookingId) async {
    try {
      final response = await _supabase
          .from('bookings')
          .select('''
            *,
            trainer:trainers!bookings_trainer_id_fkey(
              id,
              user_id,
              specialties,
              users!trainers_user_id_fkey(full_name, avatar_url)
            ),
            client:users!bookings_client_id_fkey(id, full_name, avatar_url)
          ''')
          .eq('id', bookingId)
          .maybeSingle();

      return response;
    } catch (e) {
      throw AppException.fromError(e, fallbackMessage: 'Failed to load booking details.');
    }
  }

  // Confirm booking (trainer accepts)
  Future<void> confirmBooking(String bookingId) async {
    try {
      await _supabase.from('bookings').update({
        'status': 'confirmed',
        'confirmed_at': DateTime.now().toIso8601String(),
      }).eq('id', bookingId);
    } catch (e) {
      throw AppException.fromError(e, fallbackMessage: 'Failed to confirm booking.');
    }
  }

  // Cancel booking
  Future<void> cancelBooking({
    required String bookingId,
    required String cancelledBy,
    String? cancellationReason,
  }) async {
    try {
      await _supabase.from('bookings').update({
        'status': 'cancelled',
        'cancelled_at': DateTime.now().toIso8601String(),
        'cancelled_by': cancelledBy,
        'cancellation_reason': cancellationReason,
      }).eq('id', bookingId);
    } catch (e) {
      throw AppException.fromError(e, fallbackMessage: 'Failed to cancel booking.');
    }
  }

  // Complete booking (after session)
  Future<void> completeBooking(String bookingId) async {
    try {
      await _supabase.from('bookings').update({
        'status': 'completed',
        'completed_at': DateTime.now().toIso8601String(),
      }).eq('id', bookingId);
    } catch (e) {
      throw AppException.fromError(e, fallbackMessage: 'Failed to complete booking.');
    }
  }

  // Get upcoming bookings
  Future<List<Map<String, dynamic>>> getUpcomingBookings(String userId, {bool isTrainer = false}) async {
    try {
      final today = DateTime.now().toIso8601String().split('T')[0];
      
      var query = _supabase
          .from('bookings')
          .select('''
            *,
            trainer:trainers!bookings_trainer_id_fkey(
              id,
              user_id,
              specialties,
              users!trainers_user_id_fkey(full_name, avatar_url)
            ),
            client:users!bookings_client_id_fkey(id, full_name, avatar_url)
          ''')
          .gte('session_date', today)
          .inFilter('status', ['pending', 'confirmed']);

      if (isTrainer) {
        query = query.eq('trainer_id', userId);
      } else {
        query = query.eq('client_id', userId);
      }

      final response = await query
          .order('session_date', ascending: true)
          .order('session_time', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw AppException.fromError(e, fallbackMessage: 'Failed to load upcoming bookings.');
    }
  }

  // Get past bookings
  Future<List<Map<String, dynamic>>> getPastBookings(String userId, {bool isTrainer = false}) async {
    try {
      final today = DateTime.now().toIso8601String().split('T')[0];
      
      var query = _supabase
          .from('bookings')
          .select('''
            *,
            trainer:trainers!bookings_trainer_id_fkey(
              id,
              user_id,
              specialties,
              users!trainers_user_id_fkey(full_name, avatar_url)
            ),
            client:users!bookings_client_id_fkey(id, full_name, avatar_url)
          ''')
          .or('session_date.lt.$today,status.in.(completed,cancelled)');

      if (isTrainer) {
        query = query.eq('trainer_id', userId);
      } else {
        query = query.eq('client_id', userId);
      }

      final response = await query
          .order('session_date', ascending: false)
          .order('session_time', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw AppException.fromError(e, fallbackMessage: 'Failed to load past bookings.');
    }
  }

  // Calculate platform fee (15% for now)
  int calculatePlatformFee(int basePrice) {
    return (basePrice * 0.15).round();
  }

  // Get trainer by user ID
  Future<Map<String, dynamic>?> getTrainerByUserId(String userId) async {
    try {
      final response = await _supabase
          .from('trainers')
          .select('id, user_id')
          .eq('user_id', userId)
          .maybeSingle();

      return response;
    } catch (e) {
      throw AppException.fromError(e, fallbackMessage: 'Failed to load trainer info.');
    }
  }
}