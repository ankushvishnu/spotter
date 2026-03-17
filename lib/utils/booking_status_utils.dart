import 'package:flutter/material.dart';
import '../../config/theme.dart';

/// Shared utilities for booking status display.
class BookingStatusUtils {
  static Color getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return AppTheme.warningColor;
      case 'confirmed':
        return AppTheme.successColor;
      case 'completed':
        return AppTheme.accentColor;
      case 'cancelled':
        return AppTheme.errorColor;
      default:
        return AppTheme.textSecondary;
    }
  }

  static IconData getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.schedule_rounded;
      case 'confirmed':
        return Icons.check_circle_rounded;
      case 'completed':
        return Icons.verified_rounded;
      case 'cancelled':
        return Icons.cancel_rounded;
      default:
        return Icons.info_rounded;
    }
  }

  static String getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'confirmed':
        return 'Confirmed';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status.toUpperCase();
    }
  }

  static String getLocationDisplay(String locationType) {
    switch (locationType) {
      case 'trainer_space':
        return 'Trainer\'s Studio';
      case 'client_location':
        return 'Your Location';
      case 'park':
        return 'Outdoor/Park';
      case 'gym':
        return 'Gym';
      default:
        return locationType;
    }
  }

  static IconData getLocationIcon(String locationType) {
    switch (locationType) {
      case 'trainer_space':
        return Icons.home_work_rounded;
      case 'client_location':
        return Icons.home_rounded;
      case 'park':
        return Icons.park_rounded;
      case 'gym':
        return Icons.fitness_center_rounded;
      default:
        return Icons.location_on_rounded;
    }
  }
}
