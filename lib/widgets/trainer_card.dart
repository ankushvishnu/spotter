import 'package:flutter/material.dart';
import '../models/trainer_model.dart';
import '../config/theme.dart';
import '../screens/trainers/trainer_detail_screen_modern.dart';

/// Reusable trainer card widget used on Home and Search screens.
class TrainerCard extends StatelessWidget {
  final TrainerModel trainer;
  final Animation<double>? animation;
  final int index;
  final VoidCallback? onTap;

  const TrainerCard({
    super.key,
    required this.trainer,
    this.animation,
    this.index = 0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final card = _buildCard(context);

    // If animation is provided, wrap with fade+slide transitions
    if (animation != null) {
      return FadeTransition(
        opacity: Tween<double>(begin: 0, end: 1).animate(
          CurvedAnimation(
            parent: animation!,
            curve: Interval(
              (index * 0.1).clamp(0.0, 1.0),
              ((index * 0.1) + 0.3).clamp(0.0, 1.0),
              curve: Curves.easeOut,
            ),
          ),
        ),
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.1),
            end: Offset.zero,
          ).animate(
            CurvedAnimation(
              parent: animation!,
              curve: Interval(
                (index * 0.1).clamp(0.0, 1.0),
                ((index * 0.1) + 0.3).clamp(0.0, 1.0),
                curve: Curves.easeOut,
              ),
            ),
          ),
          child: card,
        ),
      );
    }

    return card;
  }

  Widget _buildCard(BuildContext context) {
    return GestureDetector(
      onTap: onTap ??
          () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    TrainerDetailScreen(trainerId: trainer.id),
              ),
            );
          },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.cardColor,
              AppTheme.cardColor.withOpacity(0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar with gradient border
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primaryColor, AppTheme.accentColor],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.all(3),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceColor,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Center(
                    child: Text(
                      trainer.fullName[0].toUpperCase(),
                      style:
                          Theme.of(context).textTheme.displaySmall?.copyWith(
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.w900,
                              ),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 16),

              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            trainer.fullName,
                            style: Theme.of(context).textTheme.headlineMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (trainer.verificationStatus == 'verified') ...[
                          const SizedBox(width: 4),
                          const Icon(Icons.verified_rounded, color: AppTheme.accentColor, size: 16),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      trainer.specialtiesDisplay,
                      style:
                          Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppTheme.primaryColor,
                              ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.warningColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                size: 14,
                                color: AppTheme.warningColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                trainer.ratingDisplay,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: AppTheme.warningColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${trainer.totalReviews} reviews',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Price
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  trainer.priceDisplay,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
