import '../models/trainer_model.dart';
import '../models/user_model.dart';

/// Scores and ranks trainers for a given user based on profile compatibility.
/// Pure Dart logic — no network calls. Runs on an already-fetched trainer list.
class MatchmakingService {
  static const _specialtyMatchScore = 30;
  static const _budgetMatchScore = 20;
  static const _cityMatchScore = 15;
  static const _ratingScoreMultiplier = 10; // per star

  /// Returns trainers sorted by match score (highest first).
  List<TrainerModel> rankTrainers(UserModel user, List<TrainerModel> trainers) {
    final scored = trainers.map((t) {
      final score = _score(user, t);
      return _ScoredTrainer(trainer: t, score: score);
    }).toList()
      ..sort((a, b) => b.score.compareTo(a.score));

    return scored.map((s) => s.trainer).toList();
  }

  int _score(UserModel user, TrainerModel trainer) {
    int score = 0;

    // Specialty match: +30 per matching specialty
    final preferredSpecialties = user.preferredSpecialties ?? [];
    if (preferredSpecialties.isNotEmpty) {
      final overlap = trainer.specialties
          .where((s) => preferredSpecialties.contains(s))
          .length;
      score += overlap * _specialtyMatchScore;
    }

    // Budget match: +20 if within budget range
    final budgetMin = user.budgetMin;
    final budgetMax = user.budgetMax;
    if (budgetMin != null && budgetMax != null) {
      if (trainer.pricePerSession >= budgetMin &&
          trainer.pricePerSession <= budgetMax) {
        score += _budgetMatchScore;
      }
    } else if (budgetMax != null && trainer.pricePerSession <= budgetMax) {
      score += _budgetMatchScore;
    }

    // City match: +15 if trainer is in same city
    if (user.city != null &&
        trainer.city != null &&
        user.city!.toLowerCase() == trainer.city!.toLowerCase()) {
      score += _cityMatchScore;
    }

    // Rating: +10 per star (0–50)
    score += (trainer.averageRating * _ratingScoreMultiplier).toInt();

    return score;
  }
}

class _ScoredTrainer {
  final TrainerModel trainer;
  final int score;
  _ScoredTrainer({required this.trainer, required this.score});
}
