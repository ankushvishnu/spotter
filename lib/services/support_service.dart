import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

class SupportService {
  final _supabase = SupabaseConfig.client;

  Future<void> submitSupportRequest({
    required String userId,
    required String category,
    required String description,
  }) async {
    try {
      await _supabase.from('support_tickets').insert({
        'user_id': userId,
        'category': category,
        'description': description,
        'status': 'open',
      });
    } catch (e) {
      throw Exception('Failed to submit support request: $e');
    }
  }
}
