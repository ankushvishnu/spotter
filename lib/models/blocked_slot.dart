import 'package:flutter/material.dart';

/// Represents a time window that is already booked for a trainer on a specific date.
class BlockedSlot {
  final TimeOfDay start;
  final TimeOfDay end;

  const BlockedSlot({required this.start, required this.end});

  /// Create from a booking row's session_time + duration_minutes
  factory BlockedSlot.fromBooking(Map<String, dynamic> booking) {
    final timeParts = (booking['session_time'] as String).split(':');
    final startHour = int.parse(timeParts[0]);
    final startMinute = int.parse(timeParts[1]);
    final duration = (booking['duration_minutes'] as num).toInt();

    final startMinutes = startHour * 60 + startMinute;
    final endMinutes = startMinutes + duration;

    return BlockedSlot(
      start: TimeOfDay(hour: startHour, minute: startMinute),
      end: TimeOfDay(hour: endMinutes ~/ 60, minute: endMinutes % 60),
    );
  }

  /// Check if a proposed session [proposedStart] with [durationMinutes]
  /// would overlap with this blocked slot.
  bool conflictsWith(TimeOfDay proposedStart, int durationMinutes) {
    final pStartMin = proposedStart.hour * 60 + proposedStart.minute;
    final pEndMin = pStartMin + durationMinutes;
    final bStartMin = start.hour * 60 + start.minute;
    final bEndMin = end.hour * 60 + end.minute;

    // Overlap if proposed starts before blocked ends AND proposed ends after blocked starts
    return pStartMin < bEndMin && pEndMin > bStartMin;
  }

  @override
  String toString() =>
      '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}'
      '–${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}';
}
