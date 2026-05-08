import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/booking_service.dart';
import '../../services/trainer_service.dart';
import '../booking/my_bookings_screen.dart';
import '../booking/archived_bookings_screen.dart';
import '../reviews/my_reviews_screen.dart';
import '../trainers/saved_trainers_screen.dart';
import '../ai/ai_agent_screen.dart';

class VaultScreen extends StatefulWidget {
  const VaultScreen({super.key});

  @override
  State<VaultScreen> createState() => _VaultScreenState();
}

class _VaultScreenState extends State<VaultScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  int _pastBookingsCount = 0;
  int _savedTrainersCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _loadCounts();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadCounts() async {
    final userId = context.read<AuthProvider>().user?.id;
    if (userId == null) {
      setState(() => _isLoading = false);
      return;
    }
    try {
      final bookingService = BookingService();
      final trainerService = context.read<TrainerService>();
      final results = await Future.wait([
        bookingService.getPastBookings(userId),
        trainerService.getSavedTrainers(userId),
      ]);
      if (mounted) {
        setState(() {
          _pastBookingsCount = (results[0] as List).length;
          _savedTrainersCount = (results[1] as List).length;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Spotter Vault'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppTheme.spacingLG),
          children: [
            // Animated header
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Container(
                  padding: const EdgeInsets.all(24),
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryColor.withValues(alpha: 0.15),
                        AppTheme.accentColor.withValues(
                            alpha: 0.05 + (_pulseController.value * 0.08)),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: AppTheme.primaryColor.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryColor.withValues(
                                  alpha: 0.25 + (_pulseController.value * 0.15)),
                              blurRadius: 16,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.lock_rounded,
                            color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Your Personal Vault',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.w900),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'All your fitness journey data, securely stored.',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            _buildVaultCard(
              title: 'Past Bookings',
              subtitle: 'Review your workout history and receipts',
              icon: Icons.history_rounded,
              color: AppTheme.primaryColor,
              count: _isLoading ? null : _pastBookingsCount,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const MyBookingsScreen(initialTab: 1)),
                ).then((_) => _loadCounts());
              },
            ),
            const SizedBox(height: 16),

            _buildVaultCard(
              title: 'Archived Bookings',
              subtitle: 'Hidden past sessions',
              icon: Icons.archive_rounded,
              color: Colors.blueGrey,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const ArchivedBookingsScreen()),
                );
              },
            ),
            const SizedBox(height: 16),

            _buildVaultCard(
              title: 'Saved Trainers',
              subtitle: 'Your favorite certified professionals',
              icon: Icons.bookmark_rounded,
              color: AppTheme.accentColor,
              count: _isLoading ? null : _savedTrainersCount,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const SavedTrainersScreen()),
                ).then((_) => _loadCounts());
              },
            ),
            const SizedBox(height: 16),
            
            _buildVaultCard(
              title: 'My Reviews',
              subtitle: 'Manage your ratings and feedback',
              icon: Icons.star_rounded,
              color: Colors.amber,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const MyReviewsScreen()),
                );
              },
            ),
            const SizedBox(height: 16),

            _buildVaultCard(
              title: 'AI Companion Chats',
              subtitle: 'Your personal fitness assistant transcripts',
              icon: Icons.auto_awesome_rounded,
              color: AppTheme.secondaryColor,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const AIAgentScreen()),
                );
              },
            ),
            const SizedBox(height: 16),

            _buildVaultCard(
              title: 'Nutrition Plans',
              subtitle: 'Your diet and macro goals',
              icon: Icons.restaurant_rounded,
              color: AppTheme.successColor,
              comingSoon: true,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Nutrition Plans coming soon! 🥗'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
            const SizedBox(height: 16),

            _buildVaultCard(
              title: 'Workout Plans',
              subtitle: 'Saved routines and schedules',
              icon: Icons.list_alt_rounded,
              color: AppTheme.warningColor,
              comingSoon: true,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Workout Plans coming soon! 💪'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVaultCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    int? count,
    bool comingSoon = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      if (comingSoon) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.warningColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'SOON',
                            style: TextStyle(
                              color: AppTheme.warningColor,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (count != null && count > 0)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right_rounded,
                color: AppTheme.textSecondary.withValues(alpha: 0.5)),
          ],
        ),
      ),
    );
  }
}
