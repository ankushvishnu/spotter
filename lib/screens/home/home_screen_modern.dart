import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/trainer_service.dart';
import '../../models/trainer_model.dart';
import '../../widgets/trainer_card.dart';
import '../search/search_screen.dart';
import '../profile/profile_screen.dart';
import '../messaging/conversations_screen.dart';
import '../booking/my_bookings_screen.dart';
import '../../config/theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late final TrainerService _trainerService;
  List<TrainerModel> _trainers = [];
  bool _isLoading = true;
  int _selectedIndex = 0;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _trainerService = context.read<TrainerService>();
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
      final userId = context.read<AuthProvider>().user?.id;
      final trainers = await _trainerService.getTrainers(
        limit: 20,
        excludeUserId: userId,
      );
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
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          SafeArea(child: _buildHomeTab()),
          const SearchScreen(),
          const ConversationsScreen(),
          const MyBookingsScreen(),
          const ProfileScreen(),
        ],
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
        
        // Sticky Quick Actions
        SliverPersistentHeader(
          pinned: true,
          delegate: _StickyQuickActionsDelegate(
            child: Container(
              color: AppTheme.backgroundColor,
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: _buildQuickActions(),
            ),
          ),
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
                  'Featured Trainers',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ],
            ),
          ),
        ),
        
        // Trainers Carousel
        _isLoading
            ? const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            : SliverToBoxAdapter(
                child: SizedBox(
                  height: 340,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _trainers.length,
                    itemBuilder: (context, index) {
                      final trainer = _trainers[index];
                      return Container(
                        width: MediaQuery.of(context).size.width * 0.85,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: TrainerCard(
                          trainer: trainer,
                          animation: _animationController,
                          index: index,
                        ),
                      );
                    },
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
      padding: const EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'SPOTTER',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hey ${user?.fullName.split(' ').first ?? 'Athlete'}! 👋',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Find Your Trainer',
                      style: Theme.of(context).textTheme.displayMedium,
                    ),
                  ],
                ),
              ),
              // Profile Avatar
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ProfileScreen()),
                  );
                },
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.primaryColor, AppTheme.accentColor],
                    ),
                    borderRadius: BorderRadius.circular(15),
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
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Search Bar
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SearchScreen()),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: TextField(
                enabled: false,
                decoration: InputDecoration(
                  hintText: 'Search trainers, specialties...',
                  hintStyle: TextStyle(color: AppTheme.textSecondary.withOpacity(0.5)),
                  prefixIcon: const Icon(Icons.search, color: AppTheme.primaryColor),
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

  Widget _buildQuickActions() {
    final actions = [
      {'icon': Icons.flash_on_rounded, 'label': 'Quick Book'},
      {'icon': Icons.video_call_rounded, 'label': 'Online'},
      {'icon': Icons.directions_run_rounded, 'label': 'In Person'},
      {'icon': Icons.star_rounded, 'label': 'Top Rated'},
    ];
    
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        final action = actions[index];
        return Padding(
          padding: const EdgeInsets.only(right: 12),
          child: ElevatedButton.icon(
            onPressed: () {},
            icon: Icon(action['icon'] as IconData, size: 18),
            label: Text(action['label'] as String),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.surfaceColor,
              foregroundColor: AppTheme.textPrimary,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: Colors.white.withOpacity(0.1)),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickStats() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              icon: Icons.fitness_center,
              value: '${_trainers.length}',
              label: 'Trainers',
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              icon: Icons.star_rounded,
              value: _trainers.isNotEmpty
                  ? (_trainers.fold<double>(0, (sum, t) => sum + t.averageRating) / _trainers.length).toStringAsFixed(1)
                  : '–',
              label: 'Avg Rating',
              color: AppTheme.warningColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              icon: Icons.local_fire_department_rounded,
              value: _trainers.isNotEmpty
                  ? '${_trainers.fold<int>(0, (sum, t) => sum + t.totalSessionsCompleted)}+'
                  : '–',
              label: 'Sessions',
              color: AppTheme.secondaryColor,
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
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildModernBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
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
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 16 : 8,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary,
              size: 24,
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
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
}

class _StickyQuickActionsDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _StickyQuickActionsDelegate({required this.child});

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  double get maxExtent => 70.0;

  @override
  double get minExtent => 70.0;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) => true;
}