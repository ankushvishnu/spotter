import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static String get supabaseUrl => dotenv.env['SUPABASE_URL']!;
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY']!;

  /// The production PWA URL for auth redirects
  static const String siteUrl = 'https://spotterfitness.vercel.app';

  /// Auth callback URL — where email confirmation links redirect to
  static String get authCallbackUrl => kIsWeb
      ? '$siteUrl/auth-callback'
      : 'io.spotter.app://auth-callback';

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}