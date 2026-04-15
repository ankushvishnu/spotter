import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/user_model.dart';
import '../utils/app_exception.dart';

class ProfileService {
  final _supabase = SupabaseConfig.client;

  // Get current user profile
  Future<UserModel?> getCurrentUserProfile() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return null;

      final response = await _supabase
          .from('users')
          .select()
          .eq('id', userId)
          .maybeSingle();

      return response != null ? UserModel.fromJson(response) : null;
    } catch (e) {
      throw AppException.fromError(e, fallbackMessage: 'Failed to load profile.');
    }
  }

  // Update user profile
  Future<void> updateProfile({
    required String userId,
    String? fullName,
    String? bio,
    String? phone,
    DateTime? dateOfBirth,
    String? gender,
    List<String>? fitnessGoals,
    String? fitnessLevel,
    List<String>? preferredSpecialties,
    int? budgetMin,
    int? budgetMax,
    String? preferredGender,
    String? preferredLanguage,
    String? preferredTimeOfDay,
  }) async {
    try {
      final updates = <String, dynamic>{};

      if (fullName != null) updates['full_name'] = fullName;
      if (bio != null) updates['bio'] = bio;
      if (phone != null) updates['phone'] = phone;
      if (dateOfBirth != null) updates['date_of_birth'] = dateOfBirth.toIso8601String();
      if (gender != null) updates['gender'] = gender;
      if (fitnessGoals != null) updates['fitness_goals'] = fitnessGoals;
      if (fitnessLevel != null) updates['fitness_level'] = fitnessLevel;
      if (preferredSpecialties != null) updates['preferred_specialties'] = preferredSpecialties;
      if (budgetMin != null) updates['budget_min'] = budgetMin;
      if (budgetMax != null) updates['budget_max'] = budgetMax;
      if (preferredGender != null) updates['preferred_gender'] = preferredGender;
      if (preferredLanguage != null) updates['preferred_language'] = preferredLanguage;
      if (preferredTimeOfDay != null) updates['preferred_time_of_day'] = preferredTimeOfDay;

      updates['updated_at'] = DateTime.now().toIso8601String();

      await _supabase.from('users').update(updates).eq('id', userId);
    } catch (e) {
      throw AppException.fromError(e, fallbackMessage: 'Failed to update profile.');
    }
  }

  // Upload avatar
  Future<String> uploadAvatar(String userId, String filePath) async {
    try {
      final fileName = 'avatar_$userId.jpg';
      final file = File(filePath);

      await _supabase.storage
          .from('avatars')
          .upload(fileName, file, fileOptions: const FileOptions(upsert: true));

      final publicUrl = _supabase.storage.from('avatars').getPublicUrl(fileName);

      // Update user record
      await _supabase.from('users').update({'avatar_url': publicUrl}).eq('id', userId);

      return publicUrl;
    } catch (e) {
      throw AppException.fromError(e, fallbackMessage: 'Failed to upload photo.');
    }
  }

  // Update location
  Future<void> updateLocation({
    required String userId,
    required double latitude,
    required double longitude,
    String? address,
    String? city,
    String? state,
    String? pincode,
  }) async {
    try {
      final updates = <String, dynamic>{
        'location': 'POINT($longitude $latitude)',
      };

      if (address != null) updates['address'] = address;
      if (city != null) updates['city'] = city;
      if (state != null) updates['state'] = state;
      if (pincode != null) updates['pincode'] = pincode;

      await _supabase.from('users').update(updates).eq('id', userId);
    } catch (e) {
      throw AppException.fromError(e, fallbackMessage: 'Failed to update location.');
    }
  }
}