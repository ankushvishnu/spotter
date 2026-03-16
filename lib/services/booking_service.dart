import 'package:supabase_flutter/supabase_flutter.dart';

class BookingService {
  final _supabase = Supabase.instance.client;

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
    final totalPrice = basePrice + platformFee;

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

    return response;
  }

  // Get user bookings
  Future<List<Map<String, dynamic>>> getClientBookings(String clientId) async {
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
  }

  // Get trainer bookings
  Future<List<Map<String, dynamic>>> getTrainerBookings(String trainerId) async {
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
  }

  // Get booking by ID
  Future<Map<String, dynamic>?> getBooking(String bookingId) async {
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
  }

  // Confirm booking (trainer accepts)
  Future<void> confirmBooking(String bookingId) async {
    await _supabase.from('bookings').update({
      'status': 'confirmed',
      'confirmed_at': DateTime.now().toIso8601String(),
    }).eq('id', bookingId);
  }

  // Cancel booking
  Future<void> cancelBooking({
    required String bookingId,
    required String cancelledBy,
    String? cancellationReason,
  }) async {
    await _supabase.from('bookings').update({
      'status': 'cancelled',
      'cancelled_at': DateTime.now().toIso8601String(),
      'cancelled_by': cancelledBy,
      'cancellation_reason': cancellationReason,
    }).eq('id', bookingId);
  }

  // Complete booking (after session)
  Future<void> completeBooking(String bookingId) async {
    await _supabase.from('bookings').update({
      'status': 'completed',
      'completed_at': DateTime.now().toIso8601String(),
    }).eq('id', bookingId);
  }

  // Get upcoming bookings
  Future<List<Map<String, dynamic>>> getUpcomingBookings(String userId, {bool isTrainer = false}) async {
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
  }

  // Get past bookings
  Future<List<Map<String, dynamic>>> getPastBookings(String userId, {bool isTrainer = false}) async {
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
  }

  // Calculate platform fee (15% for now)
  int calculatePlatformFee(int basePrice) {
    return (basePrice * 0.15).round();
  }

  // Get trainer by user ID
  Future<Map<String, dynamic>?> getTrainerByUserId(String userId) async {
    final response = await _supabase
        .from('trainers')
        .select('id, user_id')
        .eq('user_id', userId)
        .maybeSingle();

    return response;
  }
}