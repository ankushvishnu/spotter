import '../utils/geo_utils.dart';

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
          ? GeoUtils.parsePostGISLocation(json['location'])
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
    String? phone,
    String? avatarUrl,
    DateTime? dateOfBirth,
    String? gender,
    String? bio,
    Map<String, double>? location,
    String? address,
    String? city,
    String? state,
    String? pincode,
    List<String>? fitnessGoals,
    String? fitnessLevel,
    List<String>? preferredSpecialties,
    int? budgetMin,
    int? budgetMax,
    String? role,
    bool? isVerified,
    bool? emailVerified,
    String? subscriptionTier,
    DateTime? subscriptionExpiresAt,
  }) {
    return UserModel(
      id: id,
      email: email,
      phone: phone ?? this.phone,
      fullName: fullName ?? this.fullName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      bio: bio ?? this.bio,
      location: location ?? this.location,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      pincode: pincode ?? this.pincode,
      fitnessGoals: fitnessGoals ?? this.fitnessGoals,
      fitnessLevel: fitnessLevel ?? this.fitnessLevel,
      preferredSpecialties: preferredSpecialties ?? this.preferredSpecialties,
      budgetMin: budgetMin ?? this.budgetMin,
      budgetMax: budgetMax ?? this.budgetMax,
      role: role ?? this.role,
      isVerified: isVerified ?? this.isVerified,
      emailVerified: emailVerified ?? this.emailVerified,
      subscriptionTier: subscriptionTier ?? this.subscriptionTier,
      subscriptionExpiresAt: subscriptionExpiresAt ?? this.subscriptionExpiresAt,
      createdAt: createdAt,
    );
  }

}