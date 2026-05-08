import 'package:flutter/foundation.dart';
import '../config/supabase_config.dart';
import '../models/trainer_availability.dart';
import '../models/blocked_slot.dart';
import '../models/booking_model.dart';
import '../utils/app_exception.dart';
import 'notification_service.dart';

class BookingService {
  final _supabase = SupabaseConfig.client;
  

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

      // 1. Check credits from user_credits table (1 credit = 1 session)
      debugPrint('💳 [Booking] Checking credits for user: $clientId');
      final creditData = await _supabase
          .from('user_credits')
          .select('id, total_credits, used_credits, available_credits')
          .eq('user_id', clientId)
          .maybeSingle();

      if (creditData == null) {
        throw AppException('No credits found. Please purchase credits first.');
      }

      final availableCredits = (creditData['available_credits'] as num?)?.toInt() ?? 0;
      final currentUsed = (creditData['used_credits'] as num?)?.toInt() ?? 0;
      debugPrint('💳 [Booking] Available credits: $availableCredits (1 credit = 1 session)');

      if (availableCredits < 1) {
        throw AppException('Insufficient credits. You have $availableCredits credits. You need at least 1 credit to book a session.');
      }

      // 2. Create booking
      debugPrint('📝 [Booking] Creating booking...');
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
      debugPrint('✅ [Booking] Booking created: ${response['id']}');

      // 3. Deduct 1 credit for this session
      debugPrint('💳 [Booking] Deducting 1 credit...');
      await _supabase.from('user_credits').update({
        'used_credits': currentUsed + 1,
        'last_usage_at': DateTime.now().toIso8601String(),
      }).eq('user_id', clientId);
      debugPrint('✅ [Booking] Credit deducted. Remaining: ${availableCredits - 1}');

      // 4. Log credit transaction for audit trail
      await _supabase.from('credit_transactions').insert({
        'user_id': clientId,
        'transaction_type': 'usage',
        'credits': 1,
        'description': 'Booked session worth ₹$totalPrice',
        'booking_id': response['id'],
      });
      debugPrint('✅ [Booking] Credit transaction logged.');

      return response;
    } catch (e) {
      debugPrint('❌ [Booking] Error: $e');
      if (e is AppException) rethrow;
      throw AppException.fromError(e, fallbackMessage: 'Failed to create booking: $e');
    }
  }

  // Create Bulk Booking (Multiple sessions)
  Future<List<Map<String, dynamic>>> createBulkBooking({
    required String clientId,
    required String trainerId,
    required List<Map<String, dynamic>> sessions, // [{date, time, duration, ...}]
    required int basePricePerSession,
    required int platformFeePerSession,
  }) async {
    try {
      final totalSessions = sessions.length;

      // 1. Check credits
      final creditData = await _supabase
          .from('user_credits')
          .select('available_credits, used_credits')
          .eq('user_id', clientId)
          .maybeSingle();

      if (creditData == null || (creditData['available_credits'] as int) < totalSessions) {
        throw AppException('Insufficient credits for $totalSessions sessions.');
      }

      // 2. Insert bookings in a loop (better to use a single insert for performance and atomicity)
      final List<Map<String, dynamic>> bookingsToInsert = sessions.map((s) {
        return {
          'client_id': clientId,
          'trainer_id': trainerId,
          'session_date': s['date'],
          'session_time': s['time'],
          'duration_minutes': s['duration'],
          'location_type': s['location_type'],
          'location_address': s['location_address'],
          'base_price': basePricePerSession,
          'platform_fee': platformFeePerSession,
          'total_price': basePricePerSession + platformFeePerSession,
          'status': 'pending',
          // We'll set the parent_booking_id after the first one or just link them all
        };
      }).toList();

      final response = await _supabase.from('bookings').insert(bookingsToInsert).select();
      
      // 3. Update credits
      await _supabase.from('user_credits').update({
        'used_credits': (creditData['used_credits'] as int) + totalSessions,
        'last_usage_at': DateTime.now().toIso8601String(),
      }).eq('user_id', clientId);

      // 4. Log transactions
      final List<Map<String, dynamic>> logs = (response as List).map((b) => {
        'user_id': clientId,
        'transaction_type': 'usage',
        'credits': 1,
        'description': 'Bulk booking session',
        'booking_id': b['id'],
      }).toList();
      
      await _supabase.from('credit_transactions').insert(logs);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw AppException.fromError(e, fallbackMessage: 'Failed to create bulk booking.');
    }
  }

  /// Fetch trainer's availability config (unavailable dates, pricing, schedule, specialties).
  /// Called on-demand when booking modal opens — NOT on every swipe card.
  Future<TrainerAvailability> getTrainerAvailability(String trainerId) async {
    try {
      final response = await _supabase
          .from('trainers')
          .select('unavailable_dates, package_options, session_durations, weekly_schedule, specialties')
          .eq('id', trainerId)
          .single();

      return TrainerAvailability.fromJson(response);
    } catch (e) {
      throw AppException.fromError(e, fallbackMessage: 'Failed to fetch trainer availability.');
    }
  }

  /// Get blocked time windows for a trainer on a specific date.
  /// Returns BlockedSlot list computed from existing pending/confirmed bookings.
  Future<List<BlockedSlot>> getBlockedTimesForDate(String trainerId, DateTime date) async {
    try {
      final dateStr = date.toIso8601String().split('T')[0];

      final existingBookings = await _supabase
          .from('bookings')
          .select('session_time, duration_minutes')
          .eq('trainer_id', trainerId)
          .eq('session_date', dateStr)
          .inFilter('status', ['pending', 'confirmed']);

      return (existingBookings as List)
          .map((b) => BlockedSlot.fromBooking(b))
          .toList();
    } catch (e) {
      debugPrint('BookingService: getBlockedTimesForDate error: $e');
      return []; // Return empty on error — show all slots as available
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
      
      // Schedule notifications for confirmed booking
      try {
        final bookingData = await getBooking(bookingId);
        if (bookingData != null) {
          final booking = BookingModel.fromJson(bookingData);
          await NotificationService().scheduleWorkoutNotifications(booking);
        }
      } catch (e) {
        debugPrint('Failed to schedule notifications securely: $e');
      }
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
      
      // Cancel notifications
      await NotificationService().cancelWorkoutNotifications(bookingId);
    } catch (e) {
      throw AppException.fromError(e, fallbackMessage: 'Failed to cancel booking.');
    }
  }

  // Cancel multiple bookings
  Future<void> cancelBulkBookings({
    required List<String> bookingIds,
    required String cancelledBy,
    String? cancellationReason,
  }) async {
    try {
      await _supabase.from('bookings').update({
        'status': 'cancelled',
        'cancelled_at': DateTime.now().toIso8601String(),
        'cancelled_by': cancelledBy,
        'cancellation_reason': cancellationReason,
      }).inFilter('id', bookingIds);
    } catch (e) {
      throw AppException.fromError(e, fallbackMessage: 'Failed to cancel bookings.');
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
          .order('status', ascending: true) // 'c'onfirmed comes before 'p'ending
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
          .or('session_date.lt.$today,status.in.(completed,cancelled)')
          .eq('archived', false);

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

  // Get archived bookings
  Future<List<Map<String, dynamic>>> getArchivedBookings(String userId, {bool isTrainer = false}) async {
    try {
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
          .eq('archived', true);

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
      throw AppException.fromError(e, fallbackMessage: 'Failed to load archived bookings.');
    }
  }

  // Archive bookings in bulk
  Future<void> archiveBookings(List<String> bookingIds) async {
    try {
      if (bookingIds.isEmpty) return;
      await _supabase
          .from('bookings')
          .update({'archived': true})
          .inFilter('id', bookingIds);
    } catch (e) {
      throw AppException.fromError(e, fallbackMessage: 'Failed to archive bookings.');
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

  // Get weekly progress stats for home screen
  Future<Map<String, dynamic>> getWeeklyProgressStats(String userId) async {
    try {
      final now = DateTime.now();
      final monday = now.subtract(Duration(days: now.weekday - 1));
      final mondayStr = DateTime(monday.year, monday.month, monday.day)
          .toIso8601String().split('T')[0];
      final sundayStr = DateTime(monday.year, monday.month, monday.day + 6)
          .toIso8601String().split('T')[0];

      final response = await _supabase
          .from('bookings')
          .select('session_date, duration_minutes, status')
          .eq('client_id', userId)
          .eq('status', 'completed')
          .gte('session_date', mondayStr)
          .lte('session_date', sundayStr);

      final bookings = List<Map<String, dynamic>>.from(response);

      // Total hours
      final totalMinutes = bookings.fold<int>(
        0, (sum, b) => sum + (b['duration_minutes'] as int? ?? 0),
      );
      final totalHours = totalMinutes / 60.0;

      // Sessions count
      final sessionsCount = bookings.length;

      // Daily breakdown (Mon=0, Sun=6)
      final dailyMinutes = List<int>.filled(7, 0);
      for (final b in bookings) {
        final date = DateTime.parse(b['session_date'] as String);
        final dayIndex = date.weekday - 1; // Monday = 0
        dailyMinutes[dayIndex] += (b['duration_minutes'] as int? ?? 0);
      }

      return {
        'totalHours': totalHours,
        'sessionsCount': sessionsCount,
        'dailyMinutes': dailyMinutes,
      };
    } catch (e) {
      debugPrint('BookingService: getWeeklyProgressStats error: $e');
      return {
        'totalHours': 0.0,
        'sessionsCount': 0,
        'dailyMinutes': List<int>.filled(7, 0),
      };
    }
  }
}