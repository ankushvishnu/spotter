class UserModel {
  final String id;
  final String email;
  final String? phone;
  final String fullName;
  final String? avatarUrl;
  final DateTime? dateOfBirth;
  final String? gender;
  final String? bio;
  final Map<String, double>? location; // {lat, lng}
  final String? address;
  final String? city;
  final String? state;
  final String? pincode;
  final List<String>? fitnessGoals;
  final String? fitnessLevel;
  final List<String>? preferredSpecialties;
  final int? budgetMin;
  final int? budgetMax;
  final String role; // 'client' or 'trainer'
  final bool isVerified;
  final bool emailVerified;
  final String subscriptionTier;
  final DateTime? subscriptionExpiresAt;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.email,
    this.phone,
    required this.fullName,
    this.avatarUrl,
    this.dateOfBirth,
    this.gender,
    this.bio,
    this.location,
    this.address,
    this.city,
    this.state,
    this.pincode,
    this.fitnessGoals,
    this.fitnessLevel,
    this.preferredSpecialties,
    this.budgetMin,
    this.budgetMax,
    this.role = 'client',
    this.isVerified = false,
    this.emailVerified = false,
    this.subscriptionTier = 'free',
    this.subscriptionExpiresAt,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      email: json['email'],
      phone: json['phone'],
      fullName: json['full_name'],
      avatarUrl: json['avatar_url'],
      dateOfBirth: json['date_of_birth'] != null
          ? DateTime.parse(json['date_of_birth'])
          : null,
      gender: json['gender'],
      bio: json['bio'],
      location: json['location'] != null
          ? _parseLocation(json['location'])
          : null,
      address: json['address'],
      city: json['city'],
      state: json['state'],
      pincode: json['pincode'],
      fitnessGoals: json['fitness_goals'] != null
          ? List<String>.from(json['fitness_goals'])
          : null,
      fitnessLevel: json['fitness_level'],
      preferredSpecialties: json['preferred_specialties'] != null
          ? List<String>.from(json['preferred_specialties'])
          : null,
      budgetMin: json['budget_min'],
      budgetMax: json['budget_max'],
      role: json['role'] ?? 'client',
      isVerified: json['is_verified'] ?? false,
      emailVerified: json['email_verified'] ?? false,
      subscriptionTier: json['subscription_tier'] ?? 'free',
      subscriptionExpiresAt: json['subscription_expires_at'] != null
          ? DateTime.parse(json['subscription_expires_at'])
          : null,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'phone': phone,
      'full_name': fullName,
      'avatar_url': avatarUrl,
      'date_of_birth': dateOfBirth?.toIso8601String(),
      'gender': gender,
      'bio': bio,
      'address': address,
      'city': city,
      'state': state,
      'pincode': pincode,
      'fitness_goals': fitnessGoals,
      'fitness_level': fitnessLevel,
      'preferred_specialties': preferredSpecialties,
      'budget_min': budgetMin,
      'budget_max': budgetMax,
      'role': role,
      'is_verified': isVerified,
      'email_verified': emailVerified,
      'subscription_tier': subscriptionTier,
      'subscription_expires_at': subscriptionExpiresAt?.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? fullName,
    String? avatarUrl,
    String? bio,
    String? city,
    List<String>? fitnessGoals,
    String? fitnessLevel,
    List<String>? preferredSpecialties,
    int? budgetMin,
    int? budgetMax,
  }) {
    return UserModel(
      id: id,
      email: email,
      phone: phone,
      fullName: fullName ?? this.fullName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      dateOfBirth: dateOfBirth,
      gender: gender,
      bio: bio ?? this.bio,
      location: location,
      address: address,
      city: city ?? this.city,
      state: state,
      pincode: pincode,
      fitnessGoals: fitnessGoals ?? this.fitnessGoals,
      fitnessLevel: fitnessLevel ?? this.fitnessLevel,
      preferredSpecialties: preferredSpecialties ?? this.preferredSpecialties,
      budgetMin: budgetMin ?? this.budgetMin,
      budgetMax: budgetMax ?? this.budgetMax,
      role: role,
      isVerified: isVerified,
      emailVerified: emailVerified,
      subscriptionTier: subscriptionTier,
      subscriptionExpiresAt: subscriptionExpiresAt,
      createdAt: createdAt,
    );
  }

  // Helper method to parse PostGIS location
  static Map<String, double>? _parseLocation(dynamic location) {
    try {
      if (location == null) return null;
      
      // Handle different PostGIS response formats
      if (location is Map) {
        if (location.containsKey('coordinates')) {
          final coords = location['coordinates'];
          if (coords is List && coords.length >= 2) {
            return {
              'lng': _toDouble(coords[0]),
              'lat': _toDouble(coords[1]),
            };
          }
        }
      }
      
      return null;
    } catch (e) {
      print('Error parsing location: $e');
      return null;
    }
  }

  static double _toDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.parse(value);
    return 0.0;
  }
}