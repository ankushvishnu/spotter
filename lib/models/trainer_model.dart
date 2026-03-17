import '../utils/geo_utils.dart';

class TrainerModel {
  final String id;
  final String userId;
  final String fullName;
  final String? avatarUrl;
  final String? bio;
  final String? city;
  final Map<String, double>? location;
  final List<String> specialties;
  final int? yearsOfExperience;
  final List<String>? certifications;
  final int pricePerSession;
  final List<int>? sessionDurations;
  final List<String>? serviceLocations;
  final double averageRating;
  final int totalReviews;
  final int totalSessionsCompleted;
  final String verificationStatus;
  final bool isPremium;
  final List<String>? profilePhotos;
  final double? distanceMeters; // For nearby search results

  TrainerModel({
    required this.id,
    required this.userId,
    required this.fullName,
    this.avatarUrl,
    this.bio,
    this.city,
    this.location,
    required this.specialties,
    this.yearsOfExperience,
    this.certifications,
    required this.pricePerSession,
    this.sessionDurations,
    this.serviceLocations,
    this.averageRating = 0.0,
    this.totalReviews = 0,
    this.totalSessionsCompleted = 0,
    this.verificationStatus = 'pending',
    this.isPremium = false,
    this.profilePhotos,
    this.distanceMeters,
  });

  factory TrainerModel.fromJson(Map<String, dynamic> json) {
    return TrainerModel(
      id: json['trainer_id'] ?? json['id'],
      userId: json['user_id'],
      fullName: json['full_name'],
      avatarUrl: json['avatar_url'],
      bio: json['bio'],
      city: json['city'],
      location: json['location'] != null
          ? GeoUtils.parsePostGISLocation(json['location'])
          : null,
      specialties: List<String>.from(json['specialties']),
      yearsOfExperience: json['years_of_experience'],
      certifications: json['certifications'] != null
          ? List<String>.from(json['certifications'])
          : null,
      pricePerSession: json['price_per_session'],
      sessionDurations: json['session_durations'] != null
          ? List<int>.from(json['session_durations'])
          : null,
      serviceLocations: json['service_locations'] != null
          ? List<String>.from(json['service_locations'])
          : null,
      averageRating: json['average_rating'] != null
          ? double.parse(json['average_rating'].toString())
          : 0.0,
      totalReviews: json['total_reviews'] ?? 0,
      totalSessionsCompleted: json['total_sessions_completed'] ?? 0,
      verificationStatus: json['verification_status'] ?? 'pending',
      isPremium: json['is_premium'] ?? false,
      profilePhotos: json['profile_photos'] != null
          ? List<String>.from(json['profile_photos'])
          : null,
      distanceMeters: json['distance_meters'] != null
          ? double.parse(json['distance_meters'].toString())
          : null,
    );
  }

  // Distance in kilometers
  double? get distanceKm =>
      distanceMeters != null ? distanceMeters! / 1000 : null;

  String get distanceDisplay {
    if (distanceKm == null) return '';
    if (distanceKm! < 1) {
      return '${(distanceKm! * 1000).toStringAsFixed(0)}m away';
    }
    return '${distanceKm!.toStringAsFixed(1)}km away';
  }

  String get specialtiesDisplay => specialties.join(', ');

  String get priceDisplay => '₹$pricePerSession/session';

  String get ratingDisplay => averageRating.toStringAsFixed(1);

}