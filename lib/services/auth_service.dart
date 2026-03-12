import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/user_model.dart';

class AuthService {
  final _supabase = SupabaseConfig.client;

  // Get current user
  User? get currentUser => _supabase.auth.currentUser;

  // Auth state stream
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  // Sign Up
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    // User profile is automatically created by database trigger
    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': fullName},
    );

    return response;
  }

  // Sign In
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  // Sign Out
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  // Reset Password
  Future<void> resetPassword(String email) async {
    await _supabase.auth.resetPasswordForEmail(email);
  }

  // Update Password
  Future<UserResponse> updatePassword(String newPassword) async {
    return await _supabase.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }

  // Get User Profile
  Future<UserModel?> getUserProfile(String userId) async {
    final response = await _supabase
        .from('users')
        .select()
        .eq('id', userId)
        .maybeSingle();

    if (response == null) return null;
    return UserModel.fromJson(response);
  }
}