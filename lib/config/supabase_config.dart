import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  // TODO: Replace with your actual credentials
  static const String supabaseUrl = 'https://wflqpizdtuiiaicfuuby.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndmbHFwaXpkdHVpaWFpY2Z1dWJ5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzMxMzM2NjksImV4cCI6MjA4ODcwOTY2OX0.TG8fw3HTK2Ar8shwpfC81rd9E25jFjp8icsc5XXfClQ';

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}