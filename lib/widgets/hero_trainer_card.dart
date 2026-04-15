import 'package:flutter/material.dart';
import '../models/trainer_model.dart';
import '../config/theme.dart';
import '../screens/trainers/trainer_detail_screen_modern.dart';
import '../utils/image_utils.dart';

class HeroTrainerCard extends StatelessWidget {
  final TrainerModel trainer;
  final VoidCallback? onTap;

  const HeroTrainerCard({super.key, required this.trainer, this.onTap});

  @override
  Widget build(BuildContext context) {
    final photos = trainer.profilePhotos ?? [];
    final photoUrl = photos.isNotEmpty ? photos[0] : trainer.avatarUrl;

    return GestureDetector(
      onTap: onTap ??
          () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TrainerDetailScreen(trainerId: trainer.id),
                ),
              ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withValues(alpha: 0.15),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // ── Background photo ─────────────────────────────────────
              photoUrl != null
                  ? Image.network(
                      corsProxyUrl(photoUrl),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildGradientBg(),
                    )
                  : _buildGradientBg(),

              // ── Bottom gradient scrim ─────────────────────────────────
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.25),
                        Colors.black.withValues(alpha: 0.85),
                      ],
                      stops: const [0.35, 0.6, 1.0],
                    ),
                  ),
                ),
              ),

              // ── Top badges ────────────────────────────────────────────
              Positioned(
                top: 14,
                right: 14,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (trainer.verificationStatus == 'verified' ||
                        trainer.verificationStatus == 'approved')
                      const _Badge(
                        icon: Icons.verified_rounded,
                        label: 'Verified',
                        color: AppTheme.accentColor,
                      ),
                    if (trainer.isPremium) ...[
                      const SizedBox(height: 6),
                      const _Badge(
                        icon: Icons.workspace_premium_rounded,
                        label: 'Pro',
                        color: AppTheme.warningColor,
                      ),
                    ],
                  ],
                ),
              ),

              // ── Bottom info ───────────────────────────────────────────
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name + city
                      Text(
                        trainer.fullName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (trainer.city != null) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.location_on_rounded,
                                size: 11, color: AppTheme.primaryColor),
                            const SizedBox(width: 3),
                            Text(
                              trainer.city!,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.75),
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],

                      const SizedBox(height: 10),

                      // Specialty chips
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: trainer.specialties
                            .take(2)
                            .map((s) => _SpecialtyChip(label: s))
                            .toList(),
                      ),

                      const SizedBox(height: 10),

                      // Rating + price row
                      Row(
                        children: [
                          const Icon(Icons.star_rounded,
                              size: 14, color: AppTheme.warningColor),
                          const SizedBox(width: 4),
                          Text(
                            trainer.ratingDisplay,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            ' (${trainer.totalReviews})',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 11,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '₹${trainer.pricePerSession}/hr',
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGradientBg() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1F3A), Color(0xFF0F1229)],
        ),
      ),
      child: Center(
        child: Text(
          trainer.fullName[0].toUpperCase(),
          style: const TextStyle(
            fontSize: 80,
            fontWeight: FontWeight.w900,
            color: AppTheme.primaryColor,
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _Badge({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.6), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _SpecialtyChip extends StatelessWidget {
  final String label;

  const _SpecialtyChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

