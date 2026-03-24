import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

class CreditsService {
  final _supabase = SupabaseConfig.client;

  /// Get user's current credit balance
  Future<int> getUserCredits(String userId) async {
    try {
      final response = await _supabase
          .from('user_credits')
          .select('available_credits')
          .eq('user_id', userId)
          .maybeSingle();
      return response?['available_credits'] as int? ?? 0;
    } catch (e) {
      debugPrint('CreditsService: getUserCredits error: $e');
      return 0;
    }
  }

  /// Add credits via Supabase RPC (mock payment)
  Future<void> addCredits({
    required String userId,
    required int credits,
    required int amountPaid,
    String description = 'Credit Purchase',
  }) async {
    await _supabase.rpc('add_user_credits', params: {
      'p_user_id': userId,
      'p_credits': credits,
      'p_description': description,
      'p_amount_paid': amountPaid,
    });
  }

  /// Deduct one credit for a booking (called on booking confirmation)
  Future<void> useCredit({
    required String userId,
    required String bookingId,
  }) async {
    await _supabase.rpc('use_user_credits', params: {
      'p_user_id': userId,
      'p_booking_id': bookingId,
      'p_credits': 1,
    });
  }

  /// Get credit transaction history for a user
  Future<List<Map<String, dynamic>>> getCreditHistory(String userId) async {
    try {
      final response = await _supabase
          .from('credit_transactions')
          .select('*')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(50);

      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      debugPrint('CreditsService: getCreditHistory error: $e');
      return [];
    }
  }

  /// Check if user has sufficient credits to make a booking
  Future<bool> hasSufficientCredits(String userId) async {
    final credits = await getUserCredits(userId);
    return credits >= 1;
  }
}
