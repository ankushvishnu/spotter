import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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

  Future<void> _loadUserProfile(String userId) async {
    try {
      _user = await _authService.getUserProfile(userId);
    } catch (e) {
      debugPrint('Error loading user profile: $e');
      _user = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.signUp(
        email: email,
        password: password,
        fullName: fullName,
      );
      // Auth state listener will handle the rest
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
