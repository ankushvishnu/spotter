import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/user_model.dart';
import '../utils/app_exception.dart';

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
    String role = 'client',
  }) async {
    try {
      // User profile is automatically created by database trigger.
      // Role is passed via metadata so the trigger sets the correct role.
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        emailRedirectTo: SupabaseConfig.authCallbackUrl,
        data: {
          'full_name': fullName,
          'role': role,
        },
      );
      return response;
    } catch (e) {
      throw AppException.fromError(e, fallbackMessage: 'Failed to create account.');
    }
  }

  // Sign In
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      return await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      throw AppException.fromError(e, fallbackMessage: 'Failed to sign in.');
    }
  }

  // Sign Out
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      debugPrint('Sign out error: $e');
      // Don't throw — allow sign out to proceed even if network fails
    }
  }

  // Reset Password
  Future<void> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
    } catch (e) {
      throw AppException.fromError(e, fallbackMessage: 'Failed to send reset email.');
    }
  }

  // Update Password
  Future<UserResponse> updatePassword(String newPassword) async {
    try {
      return await _supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );
    } catch (e) {
      throw AppException.fromError(e, fallbackMessage: 'Failed to update password.');
    }
  }

  // Get User Profile
  Future<UserModel?> getUserProfile(String userId) async {
    try {
      final response = await _supabase
          .from('users')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (response == null) return null;
      return UserModel.fromJson(response);
    } catch (e) {
      throw AppException.fromError(e, fallbackMessage: 'Failed to load profile.');
    }
  }
}