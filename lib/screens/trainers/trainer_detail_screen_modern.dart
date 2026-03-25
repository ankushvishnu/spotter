import 'package:flutter/material.dart';
import '../../services/trainer_service.dart';
import '../../services/review_service.dart';
import '../../models/trainer_model.dart';
import '../../models/review_model.dart';
import '../../config/theme.dart';
import '../../services/messaging_service.dart';
import '../messaging/chat_screen.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../booking/booking_request_modal.dart';
import '../../utils/booking_status_utils.dart';

class TrainerDetailScreen extends StatefulWidget {
  final String trainerId;

  const TrainerDetailScreen({super.key, required this.trainerId});

  @override
  State<TrainerDetailScreen> createState() => _TrainerDetailScreenState();
}

class _TrainerDetailScreenState extends State<TrainerDetailScreen> {
  late final TrainerService _trainerService;
  final ReviewService _reviewService = ReviewService();
  TrainerModel? _trainer;
  List<ReviewModel> _reviews = [];
  bool _isLoading = true;
  bool _isLoadingReviews = false;
  bool _isSaved = false;
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _trainerService = context.read<TrainerService>();
    _loadTrainer();
    _checkIfSaved();
  }

  Future<void> _checkIfSaved() async {
    final userId = context.read<AuthProvider>().user?.id;
    if (userId == null) return;
    
    final saved = await _trainerService.isTrainerSaved(widget.trainerId, userId);
    if (mounted) setState(() => _isSaved = saved);
  }

  Future<void> _toggleSaved() async {
    final userId = context.read<AuthProvider>().user?.id;
    if (userId == null) return;

    final wasSaved = _isSaved;
    setState(() => _isSaved = !wasSaved); // Optimistic UI
    
    final newState = await _trainerService.toggleSaveTrainer(widget.trainerId, userId, wasSaved);
    
    if (newState == wasSaved) {
      // It failed, revert
      if (mounted) setState(() => _isSaved = wasSaved);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update favorites')),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(newState ? 'Trainer saved to favorites' : 'Removed from favorites'),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _loadTrainer() async {
    setState(() => _isLoading = true);
    try {
      final trainer = await _trainerService.getTrainerById(widget.trainerId);
      setState(() {
        _trainer = trainer;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading trainer: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _loadReviews() async {
    if (_isLoadingReviews || _reviews.isNotEmpty) return;
    setState(() => _isLoadingReviews = true);
    final reviews = await _reviewService.getTrainerReviews(widget.trainerId);
    if (mounted) {
      setState(() {
        _reviews = reviews;
        _isLoadingReviews = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_trainer == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Trainer Not Found')),
        body: const Center(child: Text('Trainer not found')),
      );
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(child: _buildHeader()),
          SliverToBoxAdapter(child: _buildTabs()),
          SliverToBoxAdapter(child: _buildTabContent()),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      backgroundColor: AppTheme.backgroundColor,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor.withOpacity(0.8),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor.withOpacity(0.8),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _isSaved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: AppTheme.primaryColor,
            ),
          ),
          onPressed: _toggleSaved,
        ),
        const SizedBox(width: 8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Hero Image Placeholder
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.primaryColor.withOpacity(0.3),
                    AppTheme.accentColor.withOpacity(0.3),
                  ],
                ),
              ),
              child: Center(
                child: Text(
                  _trainer!.fullName[0].toUpperCase(),
                  style: const TextStyle(
                    fontSize: 120,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.surfaceColor,
                  ),
                ),
              ),
            ),
            // Gradient Overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    AppTheme.backgroundColor.withOpacity(0.8),
                    AppTheme.backgroundColor,
                  ],
                  stops: const [0.0, 0.7, 1.0],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name
          Row(
            children: [
              Flexible(
                child: Text(
                  _trainer!.fullName,
                  style: Theme.of(context).textTheme.displayMedium,
                ),
              ),
              if (_trainer!.verificationStatus == 'verified') ...[
                const SizedBox(width: 8),
                const Icon(Icons.verified_rounded, color: AppTheme.accentColor, size: 32),
              ],
            ],
          ),
          const SizedBox(height: 8),
          
          // Specialties
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _trainer!.specialties.map((specialty) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.primaryColor.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  specialty.toUpperCase(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              );
            }).toList(),
          ),
          
          const SizedBox(height: 20),
          
          // Stats Row
          Row(
            children: [
              _buildStatItem(
                Icons.star_rounded,
                _trainer!.ratingDisplay,
                'Rating',
                AppTheme.warningColor,
              ),
              const SizedBox(width: 24),
              _buildStatItem(
                Icons.people_rounded,
                '${_trainer!.totalReviews}',
                'Reviews',
                AppTheme.primaryColor,
              ),
              const SizedBox(width: 24),
              _buildStatItem(
                Icons.fitness_center_rounded,
                '${_trainer!.totalSessionsCompleted}+',
                'Sessions',
                AppTheme.accentColor,
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Experience
          if (_trainer!.yearsOfExperience != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.emoji_events_rounded,
                      color: AppTheme.primaryColor,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_trainer!.yearsOfExperience} Years',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      Text(
                        'Professional Experience',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label, Color color) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildTabs() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _buildTab('About', 0),
          _buildTab('Certifications', 1),
          _buildTab('Reviews', 2),
        ],
      ),
    );
  }

  Widget _buildTab(String label, int index) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _selectedTab = index);
          if (index == 2) _loadReviews();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? AppTheme.primaryColor : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: [
        _buildAboutTab(),
        _buildCertificationsTab(),
        _buildReviewsTab(),
      ][_selectedTab],
    );
  }

  Widget _buildAboutTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_trainer!.bio != null) ...[
          Text(
            'About',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 12),
          Text(
            _trainer!.bio!,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              height: 1.6,
            ),
          ),
          const SizedBox(height: 24),
        ],
        
        // Session Durations
        if (_trainer!.sessionDurations != null) ...[
          Text(
            'Session Options',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _trainer!.sessionDurations!.map((duration) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.primaryColor.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  '$duration min',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
        ],
        
        // Service Locations
        if (_trainer!.serviceLocations != null) ...[
          Text(
            'Training Locations',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 12),
          ...(_trainer!.serviceLocations!.map((location) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(
                    BookingStatusUtils.getLocationIcon(location),
                    color: AppTheme.primaryColor,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    BookingStatusUtils.getLocationDisplay(location),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            );
          }).toList()),
        ],
      ],
    );
  }

  Widget _buildCertificationsTab() {
    if (_trainer!.certifications == null || _trainer!.certifications!.isEmpty) {
      return const Center(
        child: Text('No certifications listed'),
      );
    }

    return Column(
      children: _trainer!.certifications!.map((cert) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.successColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.verified_rounded,
                  color: AppTheme.successColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  cert,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ── Reviews Tab ───────────────────────────────────────────────────────────
  Widget _buildReviewsTab() {
    if (_isLoadingReviews) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_reviews.isEmpty) {
      return Center(
        child: Column(
          children: [
            const SizedBox(height: 24),
            Icon(
              Icons.star_border_rounded,
              size: 56,
              color: AppTheme.textSecondary.withOpacity(0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'No Reviews Yet',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Book a session to be the first to review!',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
          ],
        ),
      );
    }

    // Rating summary
    final avg = _reviews.fold<double>(0, (sum, r) => sum + r.rating) /
        _reviews.length;
    final breakdown = <int, int>{1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
    for (final r in _reviews) {
      breakdown[r.rating] = (breakdown[r.rating] ?? 0) + 1;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Rating Summary Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: AppTheme.cardGradient,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              // Big rating number
              Column(
                children: [
                  Text(
                    avg.toStringAsFixed(1),
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          color: AppTheme.warningColor,
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  Row(
                    children: List.generate(
                      5,
                      (i) => Icon(
                        i < avg.round()
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        color: AppTheme.warningColor,
                        size: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_reviews.length} review${_reviews.length > 1 ? 's' : ''}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(width: 24),
              // Rating breakdown bars
              Expanded(
                child: Column(
                  children: [5, 4, 3, 2, 1].map((star) {
                    final count = breakdown[star] ?? 0;
                    final fraction =
                        _reviews.isEmpty ? 0.0 : count / _reviews.length;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          Text(
                            '$star',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppTheme.textSecondary,
                                    ),
                          ),
                          const SizedBox(width: 6),
                          Icon(Icons.star_rounded,
                              size: 12, color: AppTheme.warningColor),
                          const SizedBox(width: 6),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: fraction,
                                backgroundColor:
                                    AppTheme.textSecondary.withOpacity(0.15),
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                    AppTheme.warningColor),
                                minHeight: 6,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '$count',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Individual review cards
        ..._reviews.map((review) => _buildReviewCard(review)),
      ],
    );
  }

  Widget _buildReviewCard(ReviewModel review) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Reviewer info + rating
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    review.reviewerName[0].toUpperCase(),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppTheme.backgroundColor,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          review.reviewerName,
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        if (review.isVerified) ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.verified_rounded,
                              color: AppTheme.accentColor, size: 14),
                        ],
                      ],
                    ),
                    Text(
                      review.formattedDate,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              // Stars
              Row(
                children: List.generate(
                  5,
                  (i) => Icon(
                    i < review.rating
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: AppTheme.warningColor,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),

          // Review text
          if (review.reviewText != null && review.reviewText!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              review.reviewText!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textPrimary,
                    height: 1.5,
                  ),
            ),
          ],

          // Sub-ratings
          if (review.professionalismRating != null ||
              review.punctualityRating != null ||
              review.knowledgeRating != null) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                if (review.professionalismRating != null)
                  _buildSubRatingChip(
                      'Pro', review.professionalismRating!),
                if (review.punctualityRating != null)
                  _buildSubRatingChip(
                      'Time', review.punctualityRating!),
                if (review.knowledgeRating != null)
                  _buildSubRatingChip(
                      'Knowledge', review.knowledgeRating!),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSubRatingChip(String label, int rating) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.warningColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.warningColor,
                ),
          ),
          const SizedBox(width: 4),
          Icon(Icons.star_rounded, size: 12, color: AppTheme.warningColor),
          const SizedBox(width: 2),
          Text(
            '$rating',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.warningColor,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Price',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  _trainer!.priceDisplay,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 20),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  _showBookingSheet();
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('BOOK SESSION'),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: IconButton(
                icon: const Icon(Icons.chat_bubble_rounded),
                color: AppTheme.primaryColor,
                onPressed: () async {
                  final currentUser = context.read<AuthProvider>().user;
                  if (currentUser == null || _trainer == null) return;

                  try {
                    // Get or create conversation
                    final messagingService = context.read<MessagingService>();
                    final conversationId = await messagingService.getOrCreateConversation(
                      userId1: currentUser.id,
                      userId2: _trainer!.userId,
                    );

                    // Navigate to chat
                    if (mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatScreen(
                            conversationId: conversationId,
                            otherUserId: _trainer!.userId,
                            otherUserName: _trainer!.fullName,
                            otherUserAvatar: null,
                          ),
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error opening chat: $e')),
                      );
                    }
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBookingSheet() {
    if (_trainer == null) return;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => BookingRequestModal(trainer: _trainer!),
    );
  }

}