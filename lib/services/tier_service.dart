import 'package:flutter/foundation.dart';
import '../config/supabase_config.dart';

/// Information about a membership tier
class TierInfo {
  final String id;
  final String label;
  final String icon;
  final String description;
  final int pricePerMonth; // in ₹, 0 = free
  final List<String> features;

  const TierInfo({
    required this.id,
    required this.label,
    required this.icon,
    required this.description,
    required this.pricePerMonth,
    required this.features,
  });
}

class TierService {
  final _supabase = SupabaseConfig.client;

  /// All available membership tiers
  static const List<TierInfo> tiers = [
    TierInfo(
      id: 'standard',
      label: 'Standard',
      icon: '⭐',
      description: 'Get started with Spotter',
      pricePerMonth: 0,
      features: [
        'Browse Standard & Pro trainers',
        '2 bookings per month',
        'Basic session tracking',
        'Community support',
      ],
    ),
    TierInfo(
      id: 'pro',
      label: 'Pro',
      icon: '🔥',
      description: 'Unlock priority access',
      pricePerMonth: 499,
      features: [
        'Browse Standard & Pro trainers',
        'Unlimited bookings',
        'Priority booking slots',
        'Discounted sessions',
        'Advanced progress tracking',
        'Priority support',
      ],
    ),
    TierInfo(
      id: 'elite',
      label: 'Elite',
      icon: '💎',
      description: 'The ultimate fitness experience',
      pricePerMonth: 999,
      features: [
        'Access to ALL Elite Trainers',
        'Unlimited Bookings & Priority Slots',
        'Spotter Vault & AI Chatbot',
        'Dedicated Nutritionist (Coming soon!)',
        'Free Spotter Gym Check-ins (Coming soon!)',
        'Monthly Community Catch-ups (Coming soon!)',
        'Exclusive Offline Masterclasses (Coming soon!)',
        'Personal Concierge Support',
      ],
    ),
  ];

  /// Get tier info by id
  static TierInfo getTierInfo(String tierId) {
    return tiers.firstWhere(
      (t) => t.id == tierId,
      orElse: () => tiers.first,
    );
  }

  /// Get current user's tier from the database
  Future<String> getCurrentTier(String userId) async {
    try {
      final response = await _supabase
          .from('users')
          .select('tier')
          .eq('id', userId)
          .single();
      return response['tier'] ?? 'standard';
    } catch (e) {
      debugPrint('Error fetching tier: $e');
      return 'standard';
    }
  }

  /// Purchase/upgrade tier — updates users.tier
  /// Returns true on success
  Future<bool> purchaseTier(String userId, String tierId) async {
    try {
      await _supabase.from('users').update({
        'tier': tierId,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);
      return true;
    } catch (e) {
      debugPrint('Error purchasing tier: $e');
      return false;
    }
  }

  /// Check if a user can see a trainer based on their tiers
  /// Standard & Pro users see Standard & Pro trainers only
  /// Elite users see all trainers
  static bool canUserSeeTrainer(String userTier, String trainerTier) {
    if (userTier == 'elite') return true; // Elite sees everyone
    if (trainerTier == 'elite') return false; // Non-elite can't see elite trainers
    return true; // Standard & Pro can see Standard & Pro
  }
}
