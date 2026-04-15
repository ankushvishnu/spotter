import 'package:flutter/foundation.dart';
import '../config/supabase_config.dart';
import '../utils/app_exception.dart';

class TransferSessionService {
  final _supabase = SupabaseConfig.client;

  Future<void> transferSession({
    required String bookingId,
    required String clientId,
    String reason = 'Transferred to another trainer',
  }) async {
    try {
      // 1. Cancel the current booking
      await _supabase.from('bookings').update({
        'status': 'cancelled',
        'cancelled_at': DateTime.now().toIso8601String(),
        'cancelled_by': clientId,
        'cancellation_reason': reason,
      }).eq('id', bookingId);
    } catch (e) {
      debugPrint('❌ [TransferSession] Error: $e');
      throw AppException.fromError(e, fallbackMessage: 'Failed to transfer session.');
    }
  }
}
