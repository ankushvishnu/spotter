import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/trainer_service.dart';
import '../../models/trainer_model.dart';
import '../trainers/trainer_detail_screen_modern.dart';
import '../search/search_screen.dart';
import '../../config/theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final TrainerService _trainerService = TrainerService();
  List<TrainerModel> _trainers = [];
  bool _isLoading = true;
  int _selectedIndex = 0;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _loadTrainers();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadTrainers() async {
    setState(() => _isLoading = true);
    try {
      final trainers = await _trainerService.getTrainers(limit: 20);
      setState(() {
        _trainers = trainers;
        _isLoading = false;
      });
      _animationController.forward();
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      body: SafeArea(
        child: _selectedIndex == 0 ? _buildHomeTab() : _buildPlaceholder(),
      ),
      bottomNavigationBar: _buildModernBottomNav(),
    );
  }

  Widget _buildHomeTab() {
    return CustomScrollView(
      slivers: [
        // Modern App Bar
        SliverToBoxAdapter(
          child: _buildHeader(),
        ),
        
        // Quick Stats
        SliverToBoxAdapter(
          child: _buildQuickStats(),
        ),
        
        // Section Header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 32, 20, 16),
            child: Row(
              children: [
                Text(
                  'Top Trainers',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {},
                  child: const Text('View All'),
                ),
              ],
            ),
          ),
        ),
        
        // Trainers Grid
        _isLoading
            ? SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Animated dumbbell icon
                      TweenAnimationBuilder<Offset>(
                        tween: Tween<Offset>(
                          begin: const Offset(0, -0.2),
                          end: const Offset(0, 0.2),
                        ),
                        duration: const Duration(seconds: 2),
                        curve: Curves.easeInOut,
                        builder: (context, offset, child) {
                          return Transform.translate(
                            offset: offset,
                            child: child,
                          );
                        },
                        child: Icon(
                          Icons.fitness_center_rounded,
                          size: 48,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingMD),
                      Text(
                        'Loading Trainers...',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingSM),
                      SizedBox(
                        width: 40,
                        height: 40,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final trainer = _trainers[index];
                      return ModernTrainerCard(
                        trainer: trainer,
                        animation: _animationController,
                        index: index,
                      );
                    },
                    childCount: _trainers.length,
                  ),
                ),
              ),
        
        const SliverPadding(padding: EdgeInsets.only(bottom: 20)),
      ],
    );
  }

  Widget _buildHeader() {
    final user = context.watch<AuthProvider>().user;

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMD),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fitness Category Icons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildFitnessIcon('strength'),
              _buildFitnessIcon('cardio'),
              _buildFitnessIcon('yoga'),
              _buildFitnessIcon('crossfit'),
              _buildFitnessIcon('nutrition'),
            ],
          ),
          const SizedBox(height: AppTheme.spacingMD),

          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: 'Hey ${user?.fullName.split(' ').first ?? 'Athlete'}! ',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          WidgetSpan(
                            child: Transform.rotate(
                              angle: 0.2,
                              child: Icon(
                                Icons.sports_gymnastics_rounded,
                                color: AppTheme.primaryColor,
                                size: 24,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingXS),
                    Text(
                      'Find Your
Perfect Trainer',
                      style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        height: 0.9,
                      ),
                    ),
                  ],
                ),
              ),
              // Enhanced Profile Avatar with Animation
              GestureDetector(
                onTap: () {
                  // TODO: Navigate to profile
                },
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: 1),
                  duration: AppTheme.mediumAnimation,
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: 1 + (value * 0.1),
                      child: Opacity(
                        opacity: value,
                        child: child,
                      ),
                    );
                  },
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [AppTheme.primaryGlow],
                    ),
                    child: Center(
                      child: Text(
                        user?.fullName[0].toUpperCase() ?? 'A',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: AppTheme.backgroundColor,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppTheme.spacingMD),

          // Enhanced Search Bar with Pulse Animation
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SearchScreen()),
              );
            },
            child: TweenAnimationBuilder<Color?>(
              tween: ColorTween(
                begin: AppTheme.surfaceColor,
                end: AppTheme.surfaceColor,
              ),
              duration: const Duration(seconds: 2),
              builder: (context, color, child) {
                return Container(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppTheme.primaryColor.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: child,
                );
              },
              child: TextField(
                enabled: false,
                decoration: InputDecoration(
                  hintText: 'Search trainers, specialties...',
                  hintStyle: TextStyle(color: AppTheme.textSecondary.withOpacity(0.5)),
                  prefixIcon: Icon(Icons.search, color: AppTheme.primaryColor, size: 24),
                  suffixIcon: Icon(Icons.tune, color: AppTheme.textSecondary.withOpacity(0.6), size: 20),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMD),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              icon: Icons.fitness_center_rounded,
              value: '${_trainers.length}',
              label: 'Trainers',
              color: AppTheme.primaryColor,
              gradient: AppTheme.primaryGradient,
            ),
          ),
          const SizedBox(width: AppTheme.spacingSM),
          Expanded(
            child: _buildStatCard(
              icon: Icons.star_rounded,
              value: '4.8',
              label: 'Avg Rating',
              color: AppTheme.warningColor,
              gradient: LinearGradient(
                colors: [AppTheme.warningColor, Colors.amber],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          const SizedBox(width: AppTheme.spacingSM),
          Expanded(
            child: _buildStatCard(
              icon: Icons.local_fire_department_rounded,
              value: '150+',
              label: 'Sessions',
              color: AppTheme.secondaryColor,
              gradient: AppTheme.energeticGradient,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
    Gradient? gradient,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: AppTheme.mediumAnimation,
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: Opacity(
            opacity: scale,
            child: child,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacingMD),
        decoration: BoxDecoration(
          gradient: gradient ?? AppTheme.cardGradient,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: AppTheme.spacingXS),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: AppTheme.spacingXS),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernBottomNav() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.surfaceColor, AppTheme.cardColor],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMD, vertical: AppTheme.spacingXS),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.home_rounded, 'Home', 0),
              _buildNavItem(Icons.explore_rounded, 'Explore', 1),
              _buildNavItem(Icons.chat_bubble_rounded, 'Messages', 2),
              _buildNavItem(Icons.calendar_today_rounded, 'Bookings', 3),
              _buildNavItem(Icons.person_rounded, 'Profile', 4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedIndex = index);
        // Add haptic feedback for better UX
        // HapticFeedback.lightImpact();
      },
      child: AnimatedContainer(
        duration: AppTheme.fastAnimation,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? AppTheme.spacingMD : AppTheme.spacingSM,
          vertical: AppTheme.spacingXS,
        ),
        decoration: BoxDecoration(
          gradient: isSelected ? AppTheme.primaryGradient.withOpacity(0.2) : null,
          color: isSelected ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isSelected ? Border.all(color: AppTheme.primaryColor.withOpacity(0.3), width: 1) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScale(
              duration: AppTheme.fastAnimation,
              scale: isSelected ? 1.1 : 1.0,
              child: Icon(
                icon,
                color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary,
                size: isSelected ? 26 : 24,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: AppTheme.spacingXS),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.construction_rounded,
            size: 64,
            color: AppTheme.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Coming Soon',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFitnessIcon(String category) {
    final icon = AppTheme.getFitnessIcon(category);
    final color = AppTheme.getFitnessColor(category);

    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: AppTheme.getFitnessGradient(category),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Center(
            child: Icon(icon, color: AppTheme.backgroundColor, size: 24),
          ),
        ),
        const SizedBox(height: AppTheme.spacingXS),
        Text(
          category,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// Modern Trainer Card Component
class ModernTrainerCard extends StatelessWidget {
  final TrainerModel trainer;
  final AnimationController animation;
  final int index;

  const ModernTrainerCard({
    super.key,
    required this.trainer,
    required this.animation,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: animation,
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
            parent: animation,
            curve: Interval(
              (index * 0.1).clamp(0.0, 1.0),
              ((index * 0.1) + 0.3).clamp(0.0, 1.0),
              curve: Curves.easeOut,
            ),
          ),
        ),
        child: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TrainerDetailScreen(trainerId: trainer.id),
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
                  // Enhanced Avatar with gradient border and glow
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [AppTheme.primaryGlow],
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
                          style: Theme.of(context).textTheme.displaySmall?.copyWith(
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
                        Text(
                          trainer.fullName,
                          style: Theme.of(context).textTheme.headlineMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          trainer.specialtiesDisplay,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
                  
                  // Enhanced Price with gradient
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [AppTheme.primaryGlow],
                    ),
                    child: Text(
                      trainer.priceDisplay,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.backgroundColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}