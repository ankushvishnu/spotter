import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Centralized exception class for user-friendly error messages.
class AppException implements Exception {
  final String message;
  final dynamic originalError;
  final String? errorCode;

  AppException(this.message, [this.originalError, this.errorCode]);

  @override
  String toString() => message;

  /// Strips 'Exception:', 'AppException:', etc. for clean UI display.
  static String cleanMessage(dynamic error) {
    String msg = error.toString();
    // Strip common prefixes
    for (final prefix in [
      'Exception: ',
      'AppException: ',
      'PostgrestException: ',
    ]) {
      if (msg.startsWith(prefix)) {
        msg = msg.substring(prefix.length);
      }
    }
    return msg;
  }

  /// Maps common Supabase/network errors to user-friendly strings.
  static AppException fromError(dynamic error, {String? fallbackMessage}) {
    final fallback =
        fallbackMessage ?? 'Something went wrong. Please try again.';

    if (error is AuthException) {
      return AppException(_mapAuthError(error), error);
    }

    if (error is PostgrestException) {
      debugPrint('PostgrestException: ${error.message} (code: ${error.code})');
      final mapped = _mapPostgresError(error);
      return AppException(mapped ?? fallback, error, error.code);
    }

    if (error is AppException) {
      return error;
    }

    final errorStr = error.toString().toLowerCase();
    if (errorStr.contains('socketexception') ||
        errorStr.contains('connection refused') ||
        errorStr.contains('network')) {
      return AppException(
          'No internet connection. Please check your network.', error);
    }

    if (errorStr.contains('timeout')) {
      return AppException('Request timed out. Please try again.', error);
    }

    debugPrint('Unhandled error: $error');
    return AppException(fallback, error);
  }

  /// Maps Postgres error codes to human-friendly messages.
  static String? _mapPostgresError(PostgrestException error) {
    final code = error.code;
    if (code == null) return null;

    switch (code) {
      // RLS / permission denied
      case '42501':
        final msg = error.message.toLowerCase();
        if (msg.contains('review') || msg.contains('reviews')) {
          return 'Session pending from Trainer. You can review once the trainer completes the session.';
        }
        return 'You don\'t have permission to perform this action.';

      // Unique constraint violation
      case '23505':
        final msg = error.message.toLowerCase();
        if (msg.contains('review')) {
          return 'You have already reviewed this session.';
        }
        if (msg.contains('email')) {
          return 'An account with this email already exists.';
        }
        return 'This action has already been completed.';

      // Foreign key violation
      case '23503':
        return 'The referenced item no longer exists. Please refresh and try again.';

      // Check constraint violation
      case '23514':
        return 'The value you entered is out of the allowed range.';

      // Not null violation
      case '23502':
        return 'A required field is missing. Please fill in all required fields.';

      // Table/relation not found
      case '42P01':
        return 'Something went wrong on our end. Please try again later.';

      // Insufficient resources / rate limited
      case '53000':
      case '53100':
      case '53200':
      case '53300':
        return 'The service is temporarily busy. Please try again in a moment.';

      default:
        return null;
    }
  }

  static String _mapAuthError(AuthException error) {
    final msg = error.message.toLowerCase();

    if (msg.contains('invalid login credentials') ||
        msg.contains('invalid_credentials')) {
      return 'Incorrect email or password. Please try again.';
    }
    if (msg.contains('email not confirmed')) {
      return 'Please verify your email before logging in.';
    }
    if (msg.contains('user already registered') ||
        msg.contains('already_exists')) {
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
