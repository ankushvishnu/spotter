import 'package:flutter/material.dart';
import '../config/supabase_config.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  UserModel? _user;
  bool _isLoading = true;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;

  AuthProvider() {
    _initAuth();
  }

  Future<void> _initAuth() async {
    // Listen to auth state changes
    SupabaseConfig.client.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      if (session != null) {
        _loadUserProfile(session.user.id);
      } else {
        _user = null;
        _isLoading = false;
        notifyListeners();
      }
    });

    // Check current session
    final session = SupabaseConfig.client.auth.currentSession;
    if (session != null) {
      await _loadUserProfile(session.user.id);
    } else {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Loads user profile from DB.
  /// Retries up to [maxAttempts] times to handle the case where the
  /// `handle_new_user` DB trigger hasn't finished creating the row yet.
  Future<void> _loadUserProfile(String userId, {int maxAttempts = 6}) async {
    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        final profile = await _authService.getUserProfile(userId);
        if (profile != null) {
          _user = profile;
          _isLoading = false;
          notifyListeners();
          return;
        }
        // Profile not yet created by DB trigger — wait and retry
        if (attempt < maxAttempts) {
          await Future.delayed(const Duration(milliseconds: 600));
        }
      } catch (e) {
        debugPrint('Error loading user profile (attempt $attempt): $e');
        if (attempt < maxAttempts) {
          await Future.delayed(const Duration(milliseconds: 600));
        }
      }
    }
    // All retries exhausted — proceed without profile
    _user = null;
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String fullName,
    String role = 'client',
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _authService.signUp(
        email: email,
        password: password,
        fullName: fullName,
        role: role,
      );

      // If Supabase requires email confirmation, session is null.
      // The auth listener won't fire with a session, so we must
      // reset isLoading here — otherwise the app stays on the loader forever.
      if (response.session == null) {
        _isLoading = false;
        notifyListeners();
        return false; // false = email confirmation needed
      }

      // Session exists (auto-confirm enabled):
      // auth state listener will call _loadUserProfile which sets isLoading = false.
      return true; // true = logged in immediately
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.signIn(email: email, password: password);
      // Auth state listener will handle the rest
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    _user = null;
    notifyListeners();
  }

  Future<void> refreshUser() async {
    if (_user != null) {
      await _loadUserProfile(_user!.id);
    }
  }
}
