import 'package:flutter/material.dart';

/// Represents a trainer's availability configuration, fetched on-demand
/// when the booking modal opens.
class TrainerAvailability {
  /// Dates the trainer has explicitly marked as unavailable
  final List<DateTime> unavailableDates;

  /// Price per duration in minutes → ₹ (from `package_options` jsonb)
  /// e.g. {45: 900, 60: 1600, 90: 2000}
  final Map<int, int> durationPrices;

  /// Supported session durations in minutes, e.g. [45, 60, 90]
  final List<int> sessionDurations;

  /// Working hours per weekday (from `weekly_schedule` jsonb)
  /// Key: lowercase day name ("monday"..."sunday")
  /// Value: null if day off, or {start: TimeOfDay, end: TimeOfDay}
  final Map<String, DaySchedule?> weeklySchedule;

  /// Trainer's specialties (up to 5) — used as booking categories
  final List<String> specialties;

  TrainerAvailability({
    required this.unavailableDates,
    required this.durationPrices,
    required this.sessionDurations,
    required this.weeklySchedule,
    required this.specialties,
  });

  /// Parse from raw Supabase row
  factory TrainerAvailability.fromJson(Map<String, dynamic> json) {
    // Parse unavailable_dates
    final rawDates = json['unavailable_dates'] as List<dynamic>?;
    final unavailableDates = rawDates
        ?.map((d) => DateTime.tryParse(d.toString()))
        .whereType<DateTime>()
        .toList() ?? [];

    // Parse package_options: {"45": 900, "60": 1600, "90": 2000}
    final rawPackage = json['package_options'] as Map<String, dynamic>?;
    final durationPrices = <int, int>{};
    if (rawPackage != null) {
      for (final entry in rawPackage.entries) {
        final minutes = int.tryParse(entry.key);
        final price = (entry.value as num?)?.toInt();
        if (minutes != null && price != null) {
          durationPrices[minutes] = price;
        }
      }
    }

    // Parse session_durations
    final rawDurations = json['session_durations'] as List<dynamic>?;
    final sessionDurations = rawDurations
        ?.map((d) => (d as num).toInt())
        .toList() ?? [45, 60, 90];

    // Parse weekly_schedule
    final rawSchedule = json['weekly_schedule'] as Map<String, dynamic>?;
    final weeklySchedule = <String, DaySchedule?>{};
    const days = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
    for (final day in days) {
      final dayData = rawSchedule?[day];
      if (dayData != null && dayData is Map<String, dynamic>) {
        weeklySchedule[day] = DaySchedule.fromJson(dayData);
      } else {
        weeklySchedule[day] = null; // Day off
      }
    }

    // Parse specialties
    final rawSpecialties = json['specialties'] as List<dynamic>?;
    final specialties = rawSpecialties?.map((s) => s.toString()).toList() ?? [];

    return TrainerAvailability(
      unavailableDates: unavailableDates,
      durationPrices: durationPrices,
      sessionDurations: sessionDurations,
      weeklySchedule: weeklySchedule,
      specialties: specialties,
    );
  }

  /// Check if a specific date is unavailable (explicitly blocked)
  bool isDateUnavailable(DateTime date) {
    return unavailableDates.any((d) =>
      d.year == date.year && d.month == date.month && d.day == date.day);
  }

  /// Check if trainer works on a given weekday
  bool worksOnDay(DateTime date) {
    final dayName = _dayName(date.weekday);
    return weeklySchedule[dayName] != null;
  }

  /// Get working hours for a given date, or null if day off
  DaySchedule? getScheduleForDate(DateTime date) {
    return weeklySchedule[_dayName(date.weekday)];
  }

  /// Get price for a given duration, fallback to base price calculation
  int getPriceForDuration(int durationMinutes, int fallbackBasePrice) {
    return durationPrices[durationMinutes] ??
        (fallbackBasePrice * (durationMinutes / 60)).round();
  }

  static String _dayName(int weekday) {
    const names = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
    return names[weekday - 1];
  }
}

/// Working hours for a single day
class DaySchedule {
  final TimeOfDay start;
  final TimeOfDay end;

  const DaySchedule({required this.start, required this.end});

  factory DaySchedule.fromJson(Map<String, dynamic> json) {
    return DaySchedule(
      start: _parseTime(json['start'] as String? ?? '06:00'),
      end: _parseTime(json['end'] as String? ?? '21:00'),
    );
  }

  static TimeOfDay _parseTime(String time) {
    final parts = time.split(':');
    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: parts.length > 1 ? int.parse(parts[1]) : 0,
    );
  }

  /// Total working minutes
  int get totalMinutes =>
      (end.hour * 60 + end.minute) - (start.hour * 60 + start.minute);
}
