
/// Phase 5 Implementation: Spotter Credits Logic
/// This service handles the strict lean logic for rewarding users.
class HabitService {
  // 1 Credit = Rs. 1000

  /// Stub method to process a streak milestone hit.
  /// Returns the number of Spotter credits awarded.
  Future<int> processStreakMilestone(int streakDays) async {
    int creditsEarned = 0;

    // Lean Monetization Logic
    if (streakDays == 7) {
      creditsEarned = 1; // Awarded for first week
    } else if (streakDays == 15) {
      creditsEarned = 2; // Mid-month incentive
    } else if (streakDays == 30) {
      creditsEarned = 5; // Monthly major payout
    }

    if (creditsEarned > 0) {
      await _disburseCredits(creditsEarned);
    }
    
    return creditsEarned;
  }

  /// Disburse credits to the user wallet with a 30-day expiry.
  Future<void> _disburseCredits(int amount) async {
    // 30 day expiry logic
    final expiryDate = DateTime.now().add(const Duration(days: 30));
    
    // Future expansion: 
    // await supabase.from('user_wallet').insert({
    //   'credits': amount,
    //   'expires_at': expiryDate.toIso8601String(),
    //   'reason': 'streak_reward',
    // });
    
    print('Disbursed $amount credits. Expires at $expiryDate');
  }
}
