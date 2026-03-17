import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Centralized exception class for user-friendly error messages.
class AppException implements Exception {
  final String message;
  final dynamic originalError;

  AppException(this.message, [this.originalError]);

  @override
  String toString() => message;

  /// Maps common Supabase/network errors to user-friendly strings.
  static AppException fromError(dynamic error, {String? fallbackMessage}) {
    final fallback = fallbackMessage ?? 'Something went wrong. Please try again.';

    if (error is AuthException) {
      return AppException(_mapAuthError(error), error);
    }

    if (error is PostgrestException) {
      debugPrint('PostgrestException: ${error.message} (code: ${error.code})');
      return AppException(fallback, error);
    }

    if (error is AppException) {
      return error;
    }

    final errorStr = error.toString().toLowerCase();
    if (errorStr.contains('socketexception') ||
        errorStr.contains('connection refused') ||
        errorStr.contains('network')) {
      return AppException('No internet connection. Please check your network.', error);
    }

    if (errorStr.contains('timeout')) {
      return AppException('Request timed out. Please try again.', error);
    }

    debugPrint('Unhandled error: $error');
    return AppException(fallback, error);
  }

  static String _mapAuthError(AuthException error) {
    final msg = error.message.toLowerCase();

    if (msg.contains('invalid login credentials') || msg.contains('invalid_credentials')) {
      return 'Incorrect email or password. Please try again.';
    }
    if (msg.contains('email not confirmed')) {
      return 'Please verify your email before logging in.';
    }
    if (msg.contains('user already registered') || msg.contains('already_exists')) {
      return 'An account with this email already exists.';
    }
    if (msg.contains('weak password') || msg.contains('too short')) {
      return 'Password is too weak. Use at least 6 characters.';
    }
    if (msg.contains('rate limit') || msg.contains('too many requests')) {
      return 'Too many attempts. Please wait a moment and try again.';
    }

    return error.message;
  }
}
