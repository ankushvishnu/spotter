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
    // DB stores keys either as numeric ("1"–"7", ISO: 1=Mon, 7=Sun) or as names ("monday"–"sunday").
    // We normalise everything to named keys for consistent querying.
    final rawSchedule = json['weekly_schedule'] as Map<String, dynamic>?;
    final weeklySchedule = <String, DaySchedule?>{};
    const days = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];

    // Build a helper that reads either "1"/"monday", "2"/"tuesday", etc.
    DaySchedule? parseDayEntry(Map<String, dynamic>? schedule, int isoWeekday) {
      if (schedule == null) return null;
      final numKey = isoWeekday.toString();         // "1" = Monday
      final nameKey = days[isoWeekday - 1];         // "monday"
      final entry = schedule[numKey] ?? schedule[nameKey];
      if (entry == null || entry is! Map<String, dynamic>) return null;
      // If the schedule has an `is_active` flag that is false, treat as day off
      if (entry['is_active'] == false) return null;
      return DaySchedule.fromJson(entry);
    }

    for (int i = 1; i <= 7; i++) {
      weeklySchedule[days[i - 1]] = parseDayEntry(rawSchedule, i);
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
