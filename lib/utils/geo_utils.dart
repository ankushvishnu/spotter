import 'package:flutter/foundation.dart';

/// Shared utilities for parsing PostGIS location data.
class GeoUtils {
  /// Parses PostGIS location response into lat/lng map.
  static Map<String, double>? parsePostGISLocation(dynamic location) {
    try {
      if (location == null) return null;

      // Handle different PostGIS response formats
      if (location is Map) {
        if (location.containsKey('coordinates')) {
          final coords = location['coordinates'];
          if (coords is List && coords.length >= 2) {
            return {
              'lng': toDouble(coords[0]),
              'lat': toDouble(coords[1]),
            };
          }
        }
      }

      return null;
    } catch (e) {
      debugPrint('Error parsing location: $e');
      return null;
    }
  }

  /// Safely converts dynamic values to double.
  static double toDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.parse(value);
    return 0.0;
  }
}
