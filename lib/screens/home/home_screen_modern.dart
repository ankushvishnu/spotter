import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../../providers/auth_provider.dart';
import '../../services/trainer_service.dart';
import '../../services/booking_service.dart';
import '../../services/goals_service.dart';
import '../../models/trainer_model.dart';
import '../../models/booking_model.dart';
import '../explore/explore_swipe_screen.dart';
import '../search/search_screen.dart';
import '../navigation/navigation_menu_screen.dart';
import '../messaging/conversations_screen.dart';
import '../booking/my_bookings_screen.dart';
import '../booking/booking_detail_screen.dart';
import '../trainers/trainer_detail_screen_modern.dart';
import '../goals/my_goals_screen.dart';
import '../onboarding/onboarding_screen.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';
import '../../utils/image_utils.dart';
import '../../widgets/dynamic_mesh_background.dart';
import '../../widgets/video_background.dart';
import '../ai/ai_agent_screen.dart';
import '../../widgets/auth_guard.dart';
// ── Category definition ───────────────────────────────────────────────────────

class _Category {
  final String id;
  final String label;
  final IconData icon;
  final List<String>? specialties; // multiple values matched via overlaps
  final double? minRating;
  final List<String>? serviceLocations;

  const _Category({
    required this.id,
    required this.label,
    required this.icon,
    this.specialties,
    this.minRating,
    this.serviceLocations,
  });
}

const _categories = [
  _Category(id: 'strength', label: 'Strength', icon: Icons.fitness_center_rounded,
      specialties: ['Strength Training', 'strength', 'Bodybuilding', 'Muscle Gain']),
  _Category(id: 'cardio',   label: 'Cardio',   icon: Icons.directions_run_rounded,
      specialties: ['Cardio', 'cardio', 'HIIT', 'hiit', 'CrossFit', 'Weight Loss']),
  _Category(id: 'yoga',     label: 'Yoga',     icon: Icons.self_improvement_rounded,
      specialties: ['Yoga', 'yoga', 'Meditation', 'Pilates']),
  _Category(id: 'boxing',   label: 'Boxing',   icon: Icons.sports_mma_rounded,
      specialties: ['Boxing', 'Kickboxing', 'Martial Arts']),
  _Category(id: 'physio',   label: 'Physio',   icon: Icons.medical_services_rounded,
      specialties: ['Physiotherapy', 'Rehabilitation', 'Injury Recovery', 'physio']),
  _Category(id: 'online',   label: 'Online',   icon: Icons.video_call_rounded,
      serviceLocations: ['online']),
  _Category(id: 'top',      label: 'Top Rated', icon: Icons.star_rounded,
      minRating: 4.5),
];

const _taglines = [
  'Find your perfect trainer',
  'Your fitness journey starts here',
  'Train smarter, not harder',
  'Level up with expert guidance',
];

// ── HomeScreen ────────────────────────────────────────────────────────────────

class HomeScreen extends StatefulWidget {
  final int initialIndex;
  const HomeScreen({super.key, this.initialIndex = 0});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final TrainerService _trainerService;

  List<TrainerModel> _featured = [];
  List<TrainerModel> _nearby = [];
  bool _loadingFeatured = true;
  bool _loadingNearby = true;

  late int _selectedNav;
  String? _activeCategory; // null = show all
  String? _selectedCity; // null = all cities

  late final PageController _featuredPageCtrl;
  late final String _tagline;

  // Dynamic session & progress data
  BookingModel? _nextSession;
  bool _loadingSession = true;
  double _weeklyHours = 0;
  int _weeklySessions = 0;
  int _streak = 0;
  double _goalCompletion = 0;
  List<int> _dailyBars = List.filled(7, 0);

  static const _emptySessionMessages = [
    'No upcoming sessions 😢 Let\'s Tango!',
    'It\'s Zumba time! Book a session 💃',
    'Your muscles miss you! Time to train 💪',
    'Rest day? Or just haven\'t booked yet? 🤔',
    'Your trainer is waiting! Let\'s go! 🔥',
    'Time to sweat! Book your next session 🏋️',
  ];

  late final String _emptySessionMsg;

  @override
  void initState() {
    super.initState();
    _selectedNav = widget.initialIndex;
    _trainerService = context.read<TrainerService>();
    _featuredPageCtrl = PageController(viewportFraction: 0.88);
    _tagline = _taglines[math.Random().nextInt(_taglines.length)];
    _emptySessionMsg = _emptySessionMessages[math.Random().nextInt(_emptySessionMessages.length)];
    _loadFeatured();
    _loadNearby();
    _loadNextSession();
    _loadProgressData();
  }

  String? _lastUserId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final newUserId = context.watch<AuthProvider>().user?.id;
    if (newUserId != _lastUserId) {
      _lastUserId = newUserId;
      if (newUserId != null) {
        // Refresh data on auth load/login
        _loadNextSession();
        _loadProgressData();
        _loadFeatured();
        _loadNearby();
      }
    }
  }

  @override
  void dispose() {
    _featuredPageCtrl.dispose();
    super.dispose();
  }

  // ── dynamic session + progress loading ─────────────────────────────────────

  Future<void> _loadNextSession() async {
    final userId = context.read<AuthProvider>().user?.id;
    if (userId == null) {
      setState(() => _loadingSession = false);
      return;
    }
    try {
      final bookingService = context.read<BookingService>();
      final upcoming = await bookingService.getUpcomingBookings(userId);
      if (mounted) {
        final confirmedSessions = upcoming.where((b) => b['status'] == 'confirmed').toList();
        setState(() {
          _nextSession = confirmedSessions.isNotEmpty
              ? BookingModel.fromJson(confirmedSessions.first)
              : null;
          _loadingSession = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingSession = false);
    }
  }

  Future<void> _loadProgressData() async {
    final userId = context.read<AuthProvider>().user?.id;
    if (userId == null) return;
    try {
      final bookingService = context.read<BookingService>();
      final goalsService = context.read<GoalsService>();

      final results = await Future.wait([
        bookingService.getWeeklyProgressStats(userId),
        goalsService.getProgressSummary(userId),
      ]);

      final bookingStats = results[0];
      final goalsSummary = results[1];

      if (mounted) {
        setState(() {
          _weeklyHours = (bookingStats['totalHours'] as num).toDouble();
          _weeklySessions = bookingStats['sessionsCount'] as int;
          _streak = goalsSummary['streak'] as int;
          _goalCompletion = (goalsSummary['completionPercent'] as num).toDouble();
          _dailyBars = goalsSummary['dailyBreakdown'] as List<int>;
        });
      }
    } catch (_) {}
  }

  // ── data loading ────────────────────────────────────────────────────────────

  Future<void> _loadFeatured({_Category? cat}) async {
    setState(() => _loadingFeatured = true);
    try {
      final userId = context.read<AuthProvider>().user?.id;
      List<TrainerModel> trainers;

      if (cat?.specialties != null && cat!.specialties!.isNotEmpty) {
        trainers = await _trainerService.getTrainers(
          excludeUserId: userId,
          minRating: cat.minRating,
          serviceLocations: cat.serviceLocations,
          specialties: cat.specialties,
          city: _selectedCity,
          limit: 5,
        );
      } else {
        trainers = await _trainerService.getTrainers(
          excludeUserId: userId,
          minRating: cat?.minRating,
          serviceLocations: cat?.serviceLocations,
          city: _selectedCity,
          limit: 5,
        );
      }

      if (mounted) setState(() { _featured = trainers; _loadingFeatured = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingFeatured = false);
    }
  }

  Future<void> _loadNearby() async {
    try {
      final perm = await Geolocator.checkPermission();
      LocationPermission granted = perm;
      if (perm == LocationPermission.denied) {
        granted = await Geolocator.requestPermission();
      }

      if (granted == LocationPermission.denied ||
          granted == LocationPermission.deniedForever) {
        // Fall back to general list
        if (!mounted) return;
        final userId = context.read<AuthProvider>().user?.id;
        final trainers = await _trainerService.getTrainers(
          excludeUserId: userId,
          city: _selectedCity,
          limit: 8,
        );
        if (mounted) setState(() { _nearby = trainers; _loadingNearby = false; });
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );
      final trainers = await _trainerService.getNearbyTrainers(
        latitude: pos.latitude,
        longitude: pos.longitude,
        radiusMeters: 10000,
        limit: 8,
      );
      if (mounted) setState(() { _nearby = trainers; _loadingNearby = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingNearby = false);
    }
  }

  void _selectCategory(String id) {
    HapticFeedback.selectionClick();
    if (_activeCategory == id) {
      setState(() => _activeCategory = null);
      _loadFeatured();
    } else {
      setState(() => _activeCategory = id);
      final cat = _categories.firstWhere((c) => c.id == id);
      _loadFeatured(cat: cat);
    }
    if (_featuredPageCtrl.hasClients) {
      try {
        _featuredPageCtrl.animateToPage(0,
            duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      } catch (_) {
        // Ignored. The PageView might be unmounted concurrently.
      }
    }
  }

  // ── shell build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isCurrent = ModalRoute.of(context)?.isCurrent ?? true;
    return PopScope(
      canPop: !isCurrent || _selectedNav == 0, // Allow pop if another screen is on top, or if on Home tab
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && isCurrent) {
          setState(() => _selectedNav = 0); // Go back to Home tab
        }
      },
      child: Scaffold(
        backgroundColor: Colors.transparent, // Background handled by DynamicMeshBackground
        extendBody: true,
        body: DynamicMeshBackground(
          child: IndexedStack(
            index: _selectedNav,
            children: [
              _buildHomeTab(),
              ExploreSwipeScreen(onNavigateHome: () => setState(() => _selectedNav = 0)),
              const ConversationsScreen(),
              const MyBookingsScreen(),
            ],
          ),
        ),
        bottomNavigationBar: _buildFloatingNav(),
      ),
    );
  }

  // ── home tab ────────────────────────────────────────────────────────────────

  Widget _buildHomeTab() {
    final authProvider = context.watch<AuthProvider>();
    final isAuthenticated = authProvider.isAuthenticated;
    final isOnboarded = authProvider.user?.isOnboarded ?? false;
    
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(child: _buildJSXHero()),
        
        if (!isAuthenticated)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: _buildActionCTA(
                title: 'Join Spotter Free',
                subtitle: 'Log in or sign up to save favorites and track your progress.',
                buttonText: 'Login / Sign Up',
                onTap: () {
                  AuthGuard.protect(context, onAuthenticated: () {}, intent: 'create an account or sign in');
                },
                gradient: AppTheme.cardGradient,
              ),
            ),
          )
        else if (!isOnboarded)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: _buildActionCTA(
                title: 'Complete Your Profile',
                subtitle: 'A complete profile helps you find the perfect match & track goals.',
                buttonText: 'Complete Profile',
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const OnboardingScreen()));
                },
                gradient: LinearGradient(colors: [AppTheme.primaryColor.withValues(alpha: 0.3), AppTheme.backgroundColor]),
              ),
            ),
          )
        else if (authProvider.user?.fitnessGoals?.any((g) => ['PCOS/PCOD', 'Post Menopause'].contains(g)) ?? false)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: _buildActionCTA(
                title: 'Specialized Health Tips',
                subtitle: 'Explore workouts specifically designed for your health profile.',
                buttonText: 'View Tips',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Specialized health tips coming soon!')),
                  );
                },
                gradient: LinearGradient(
                  colors: [Colors.pinkAccent.withValues(alpha: 0.2), AppTheme.backgroundColor],
                ),
              ),
            ),
          ),
          
        SliverToBoxAdapter(child: _buildJSXSearchBar()),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
        SliverToBoxAdapter(child: _buildSectionLabelJSX('Top Trainers Nearby', actionText: 'View all →', onAction: () => setState(() => _selectedNav = 1))),
        const SliverToBoxAdapter(child: SizedBox(height: 12)),
        SliverToBoxAdapter(child: _buildTrainersScroll()),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
        SliverToBoxAdapter(child: _buildAskSpotter()), // Retain Ask Spotter Assistant
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
        SliverToBoxAdapter(child: _buildSectionLabelJSX('Upcoming Session')),
        const SliverToBoxAdapter(child: SizedBox(height: 12)),
        SliverToBoxAdapter(child: _buildJSXNextSession()),
        const SliverToBoxAdapter(child: SizedBox(height: 28)),
        SliverToBoxAdapter(child: _buildJSXMyProgress()),
        // bottom padding for floating nav
        const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
      ],
    );
  }

  Widget _buildActionCTA({required String title, required String subtitle, required String buttonText, required VoidCallback onTap, required Gradient gradient}) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingLG),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton(
            onPressed: onTap,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            child: Text(buttonText),
          ),
        ],
      ),
    );
  }

  // ── hero ────────────────────────────────────────────────────────────────────
  Widget _buildJSXHero() {
    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 60, bottom: 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'ULTIMATE FLEXIBILITY',
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2.0,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  height: 1,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppTheme.primaryColor, Colors.transparent],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'ANY CITY.\nANY\nTRAINER.',
            style: TextStyle(
              fontSize: 56,
              height: 0.9,
              fontWeight: FontWeight.w900,
              fontFamily: 'Bebas Neue',
              color: AppTheme.textPrimary,
              shadows: [
                Shadow(
                  color: AppTheme.primaryColor.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(2, 2),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Transfer sessions instantly. Crush goals everywhere.',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // ── search bar ──────────────────────────────────────────────────────────────

  // ── search bar & chips (JSX style) ──────────────────────────────────────────
  Widget _buildJSXSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.05),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 30,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        children: [
          // The Input
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SearchScreen()),
            ),
            child: Container(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppTheme.cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ),
              child: const Row(
                children: [
                  Icon(Icons.search_rounded, color: AppTheme.textSecondary, size: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Search trainers, specialties...',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // City selector
          SizedBox(
            height: 34,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildCityChip(null, 'All Cities'),
                ...AppConstants.supportedCities.map((c) => _buildCityChip(c, c)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Category Chips
          SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, i) {
                final cat = _categories[i];
                final active = _activeCategory == cat.id;
                return GestureDetector(
                  onTap: () => _selectCategory(cat.id),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: active ? AppTheme.primaryColor : Colors.transparent,
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(
                        color: active ? AppTheme.primaryColor : Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Text(
                      cat.label,
                      style: TextStyle(
                        color: active ? Colors.black : AppTheme.textPrimary,
                        fontSize: 13,
                        fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCityChip(String? cityValue, String label) {
    final active = _selectedCity == cityValue;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _selectedCity = cityValue;
        });
        _loadFeatured();
        _loadNearby();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(left: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? AppTheme.accentColor : Colors.transparent,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: active ? AppTheme.accentColor : Colors.white.withValues(alpha: 0.15),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.black : AppTheme.textSecondary,
            fontSize: 12,
            fontWeight: active ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  // ── section label & horizontal trainer scroll (JSX style) ──────────────────
  Widget _buildSectionLabelJSX(String title, {String? actionText, VoidCallback? onAction}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
            ),
          ),
          if (actionText != null)
            GestureDetector(
              onTap: onAction,
              child: Text(
                actionText,
                style: const TextStyle(
                  color: AppTheme.primaryColor,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTrainersScroll() {
    if (_loadingNearby && _loadingFeatured) {
      return const SizedBox(
        height: 180,
        child: Center(
          child: CircularProgressIndicator(color: AppTheme.primaryColor),
        ),
      );
    }

    // When a category filter is active, show filtered results from _featured
    // Otherwise, show nearby trainers (or featured as fallback)
    final displayList = _activeCategory != null
        ? _featured
        : (_nearby.isNotEmpty ? _nearby : _featured);

    if (displayList.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Text('No trainers found.',
            style: TextStyle(color: AppTheme.textSecondary)),
      );
    }

    return SizedBox(
      height: 200,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: displayList.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, i) {
          final t = displayList[i];
          final photoUrl = (t.profilePhotos?.isNotEmpty == true)
              ? t.profilePhotos!.first
              : t.avatarUrl;
              
          // JSX trainer card styling  
          return GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => TrainerDetailScreen(trainerId: t.id)),
            ),
            child: Container(
              width: 140,
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.primaryColor.withValues(alpha: 0.5),
                        width: 2,
                      ),
                    ),
                    child: ClipOval(
                      child: photoUrl != null
                          ? Image.network(
                              corsProxyUrl(photoUrl),
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _buildAvatarInitial(t.fullName),
                            )
                          : _buildAvatarInitial(t.fullName),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    t.fullName.split(' ').first,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.star_rounded, color: AppTheme.warningColor, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        t.averageRating > 0 ? t.averageRating.toStringAsFixed(1) : '4.9',
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── ask spotter ─────────────────────────────────────────────────────────────

  Widget _buildAskSpotter() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AIAgentScreen()),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppTheme.primaryColor.withValues(alpha: 0.15),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withValues(alpha: 0.05),
                blurRadius: 20,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  shape: BoxShape.circle,
                  boxShadow: [AppTheme.primaryGlow],
                ),
                child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ask Spotter',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Need a workout plan or meal ideas?',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.send_rounded, color: AppTheme.primaryColor),
            ],
          ),
        ),
      ),
    );
  }

  // ── upcoming session (dynamic) ──────────────────────────────────────────────
  Widget _buildJSXNextSession() {
    if (_loadingSession) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          height: 120,
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(24),
          ),
          child: const Center(
            child: CircularProgressIndicator(
              color: AppTheme.primaryColor, strokeWidth: 2),
          ),
        ),
      );
    }

    // No upcoming session — fun empty state
    if (_nextSession == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          clipBehavior: Clip.none,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Column(
            children: [
              const Text('🎭', style: TextStyle(fontSize: 36)),
              const SizedBox(height: 12),
              Text(
                _emptySessionMsg,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedNav = 1); // Go to Explore
                },
                child: Container(
                  width: double.infinity,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withValues(alpha: 0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      'Book a Session',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Real upcoming session
    final session = _nextSession!;
    final sessionLabel = session.trainerSpecialties?.isNotEmpty == true
        ? session.trainerSpecialties!.first
        : 'Training Session';
    final trainerName = session.trainerName ?? 'Trainer';
    final dateStr = session.formattedDate;
    final timeStr = session.formattedTime;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        clipBehavior: Clip.none,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withValues(alpha: 0.05),
              blurRadius: 30,
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: Text('🔥', style: TextStyle(fontSize: 24)),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sessionLabel,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$dateStr at $timeStr with $trainerName',
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: Container(
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withValues(alpha: 0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BookingDetailScreen(
                          bookingId: session.id,
                        ),
                      ),
                    ).then((_) => _loadNextSession());
                  },
                  child: const Text(
                    'Join Session',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── My Progress (dynamic) ─────────────────────────────────────────────────────
  Widget _buildJSXMyProgress() {
    final dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final today = DateTime.now().weekday - 1;
    final maxVal = _dailyBars.reduce((a, b) => a > b ? a : b);
    final maxHeight = maxVal > 0 ? maxVal.toDouble() : 1.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'My Progress',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              GestureDetector(
                onTap: () {
                  AuthGuard.protect(
                    context,
                    intent: 'view your goals',
                    onAuthenticated: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const MyGoalsScreen()),
                      ).then((_) => _loadProgressData());
                    },
                  );
                },
                child: const Text(
                  'View Goals →',
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Stats row
          Row(
            children: [
              Expanded(
                child: _buildProgressStat(
                  _weeklyHours.toStringAsFixed(1),
                  'hrs trained',
                  AppTheme.primaryColor,
                ),
              ),
              Expanded(
                child: _buildProgressStat(
                  '$_weeklySessions',
                  'sessions',
                  AppTheme.accentColor,
                ),
              ),
              Expanded(
                child: _buildProgressStat(
                  _streak > 0 ? '🔥 $_streak' : '0',
                  'day streak',
                  AppTheme.warningColor,
                ),
              ),
              Expanded(
                child: _buildProgressStat(
                  '${(_goalCompletion * 100).round()}%',
                  'goals',
                  AppTheme.successColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Activity Chart
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Activity',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      _weeklyHours.toStringAsFixed(1),
                      style: const TextStyle(
                        fontFamily: 'Bebas Neue',
                        fontSize: 42,
                        color: AppTheme.textPrimary,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'hrs',
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Dynamic Chart with day labels
                SizedBox(
                  height: 110,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: List.generate(7, (i) {
                      final isToday = i == today;
                      final barVal = _dailyBars[i];
                      final barHeight = maxVal > 0
                          ? (barVal / maxHeight) * 70 + 8
                          : 8.0;
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeOutCubic,
                            width: 20,
                            height: barHeight,
                            decoration: BoxDecoration(
                              color: isToday
                                  ? AppTheme.primaryColor
                                  : barVal > 0
                                      ? AppTheme.primaryColor.withValues(alpha: 0.3)
                                      : Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(5),
                              boxShadow: isToday && barVal > 0
                                  ? [
                                      BoxShadow(
                                        color: AppTheme.primaryColor.withValues(alpha: 0.4),
                                        blurRadius: 8,
                                      ),
                                    ]
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            dayLabels[i],
                            style: TextStyle(
                              color: isToday
                                  ? AppTheme.primaryColor
                                  : AppTheme.textSecondary,
                              fontSize: 11,
                              fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
                            ),
                          ),
                        ],
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressStat(String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarInitial(String fullName) {
    return Container(
      color: AppTheme.surfaceColor,
      child: Center(
        child: Text(
          fullName.isNotEmpty ? fullName[0].toUpperCase() : '?',
          style: const TextStyle(
            color: AppTheme.primaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
    );
  }

  // ── floating bottom nav ──────────────────────────────────────────────────────

  Widget _buildFloatingNav() {
    final authProvider = context.watch<AuthProvider>();
    if (!authProvider.isAuthenticated) {
      return const SizedBox.shrink(); // Disable island entirely for guests
    }

    final items = [
      const _NavItem(icon: Icons.home_rounded, label: 'Home'),
      const _NavItem(icon: Icons.explore_rounded, label: 'Explore'),
      const _NavItem(icon: Icons.chat_bubble_rounded, label: 'Messages'),
      const _NavItem(icon: Icons.calendar_today_rounded, label: 'Bookings'),
      const _NavItem(icon: Icons.menu_rounded, label: 'Menu'),
    ];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
        child: Container(
          height: 64,
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: AppTheme.primaryColor.withValues(alpha: 0.08),
                blurRadius: 24,
              ),
            ],
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.07),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (i) {
              final selected = _selectedNav == i;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  if (i == 4) {
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: Colors.transparent,
                      isScrollControlled: true,
                      builder: (context) => NavigationMenuScreen(
                        onScreenPushed: () {
                          // Reset to Home tab so back-button from sub-screens returns to Home
                          setState(() => _selectedNav = 0);
                        },
                      ),
                    );
                  } else {
                    setState(() => _selectedNav = i);
                  }
                },
                behavior: HitTestBehavior.opaque,
                child: SizedBox(
                  width: 56,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedScale(
                        scale: selected ? 1.15 : 1.0,
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOut,
                        child: Icon(
                          items[i].icon,
                          size: 22,
                          color: selected
                              ? AppTheme.primaryColor
                              : AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: selected ? 16 : 0,
                        height: 3,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

// ── Helper widgets ─────────────────────────────────────────────────────────────

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}

  


/// Animated pulsing green dot indicating live/real-time data.
class _LiveDot extends StatefulWidget {
  @override
  State<_LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<_LiveDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 950))
      ..repeat(reverse: true);
    _scale = Tween<double>(begin: 0.7, end: 1.3).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: AppTheme.primaryColor,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
