import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/supabase_config.dart';

/// Service for interacting with the Cerebras AI Edge Function.
class CerebrasService {
  static final CerebrasService _instance = CerebrasService._internal();
  factory CerebrasService() => _instance;
  CerebrasService._internal();

  String get _baseUrl =>
      '${SupabaseConfig.supabaseUrl}/functions/v1/cerebras-ai';

  Map<String, String> get _headers {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'apikey': SupabaseConfig.supabaseAnonKey,
    };
    // Add JWT if authenticated
    final session = SupabaseConfig.client.auth.currentSession;
    if (session != null) {
      headers['Authorization'] = 'Bearer ${session.accessToken}';
    }
    return headers;
  }

  /// Stream a chat response (for coach_chat feature).
  /// Yields content chunks as they arrive.
  Stream<String> streamChat(List<Map<String, String>> messages) async* {
    try {
      final request = http.Request('POST', Uri.parse(_baseUrl));
      request.headers.addAll(_headers);
      request.body = jsonEncode({
        'feature': 'coach_chat',
        'messages': messages,
      });

      final response = await http.Client().send(request);

      if (response.statusCode == 429) {
        yield '[RATE_LIMITED]';
        return;
      }

      if (response.statusCode != 200) {
        final body = await response.stream.bytesToString();
        debugPrint('CerebrasService: Stream error $body');
        yield '[ERROR]AI service is temporarily unavailable. Please try again.';
        return;
      }

      // Parse SSE stream
      final stream = response.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter());

      await for (final line in stream) {
        if (line.startsWith('data: ')) {
          final data = line.substring(6).trim();
          if (data == '[DONE]') break;
          try {
            final json = jsonDecode(data);
            final delta = json['choices']?[0]?['delta']?['content'];
            if (delta != null && delta is String && delta.isNotEmpty) {
              yield delta;
            }
          } catch (_) {
            // Skip malformed chunks
          }
        }
      }
    } catch (e) {
      debugPrint('CerebrasService: streamChat error: $e');
      yield '[ERROR]Something went wrong. Please check your connection and try again.';
    }
  }

  /// Generate content (for write_bio, write_description, workout_plan).
  /// Returns the full generated text.
  Future<String> generate({
    required String feature,
    required String userMessage,
    Map<String, dynamic>? context,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: _headers,
        body: jsonEncode({
          'feature': feature,
          'messages': [
            {'role': 'user', 'content': userMessage},
          ],
          'context': context,
        }),
      );

      if (response.statusCode == 429) {
        return 'Daily limit reached. Sign up for unlimited AI access!';
      }

      if (response.statusCode != 200) {
        debugPrint('CerebrasService: generate error ${response.body}');
        return 'AI service is temporarily unavailable. Please try again.';
      }

      final data = jsonDecode(response.body);
      return data['content'] as String? ??
          'No response generated. Please try again.';
    } catch (e) {
      debugPrint('CerebrasService: generate error: $e');
      return 'Something went wrong. Please check your connection and try again.';
    }
  }
}
