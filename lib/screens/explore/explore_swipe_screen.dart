import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/match_service.dart';
import '../../models/trainer_model.dart';
import '../../config/theme.dart';
import '../trainers/trainer_detail_screen_modern.dart';
import '../booking/booking_request_modal.dart';
import '../../services/messaging_service.dart';
import '../messaging/chat_screen.dart';
import '../../utils/image_utils.dart';
import '../../widgets/auth_guard.dart';
import '../../utils/app_exception.dart';

class ExploreSwipeScreen extends StatefulWidget {
  final VoidCallback? onNavigateHome;
  const ExploreSwipeScreen({super.key, this.onNavigateHome});

  @override
  State<ExploreSwipeScreen> createState() => _ExploreSwipeScreenState();
}

class _ExploreSwipeScreenState extends State<ExploreSwipeScreen>
    with SingleTickerProviderStateMixin {
  final MatchService _matchService = MatchService();
  List<TrainerModel> _queue = [];
  bool _isLoading = true;
  bool _isAnimating = false;
  String _selectedCity = 'All';

  final List<String> _cities = ['All', 'Delhi', 'Mumbai', 'Bengaluru', 'London', 'New York'];

  // Drag state
  Offset _dragOffset = Offset.zero;
  double _dragAngle = 0;

  late AnimationController _snapController;
  late Animation<Offset> _snapAnimation;
  late Animation<double> _angleAnimation;

  @override
  void initState() {
    super.initState();
    _snapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _snapAnimation = Tween<Offset>(begin: Offset.zero, end: Offset.zero)
        .animate(CurvedAnimation(parent: _snapController, curve: Curves.easeOut));
    _angleAnimation = Tween<double>(begin: 0, end: 0)
        .animate(CurvedAnimation(parent: _snapController, curve: Curves.easeOut));
    _loadQueue();
  }

  @override
  void dispose() {
    _snapController.dispose();
    super.dispose();
  }

  Future<void> _loadQueue() async {
    setState(() => _isLoading = true);
    try {
      final userId = context.read<AuthProvider>().user?.id ?? '';
      final queue = await _matchService.getSwipeQueue(userId, city: _selectedCity);
      setState(() {
        _queue = queue;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppException.cleanMessage(e)), backgroundColor: AppTheme.errorColor),
        );
      }
    }
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (_isAnimating) return;
    setState(() {
      _dragOffset += details.delta;
      _dragAngle = (_dragOffset.dx / 300) * 0.3;
    });
  }

  void _onDragEnd(DragEndDetails details) {
    if (_isAnimating) return;
    final screenWidth = MediaQuery.of(context).size.width;
    final threshold = screenWidth * 0.4;

    if (_dragOffset.dx > threshold) {
      _swipe(right: true);
    } else if (_dragOffset.dx < -threshold) {
      _swipe(right: false);
    } else {
      _snapBack();
    }
  }

  void _snapBack() {
    _snapAnimation = Tween<Offset>(begin: _dragOffset, end: Offset.zero)
        .animate(CurvedAnimation(parent: _snapController, curve: Curves.elasticOut));
    _angleAnimation = Tween<double>(begin: _dragAngle, end: 0)
        .animate(CurvedAnimation(parent: _snapController, curve: Curves.elasticOut));
    _snapController
      ..reset()
      ..forward();
    _snapController.addListener(() {
      setState(() {
        _dragOffset = _snapAnimation.value;
        _dragAngle = _angleAnimation.value;
      });
    });
  }

  Future<void> _swipe({required bool right}) async {
    if (_queue.isEmpty || _isAnimating) return;

    // Fix 5: Guard likes for unauthenticated users
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.user?.id;
    if (userId == null || userId.isEmpty) {
      if (right) {
        _snapBack();
        AuthGuard.protect(
          context,
          intent: 'like this trainer',
          onAuthenticated: () {},
        );
      } else {
        _snapBack();
      }
      return;
    }

    _isAnimating = true;
    final screenWidth = MediaQuery.of(context).size.width;
    final targetX = right ? screenWidth * 1.5 : -screenWidth * 1.5;
    final endOffset = Offset(targetX, _dragOffset.dy - 50);
    final endAngle = right ? 0.4 : -0.4;

    _snapAnimation = Tween<Offset>(begin: _dragOffset, end: endOffset)
        .animate(CurvedAnimation(parent: _snapController, curve: Curves.easeIn));
    _angleAnimation = Tween<double>(begin: _dragAngle, end: endAngle)
        .animate(CurvedAnimation(parent: _snapController, curve: Curves.easeIn));

    _snapController.reset();
    _snapController.addListener(() {
      setState(() {
        _dragOffset = _snapAnimation.value;
        _dragAngle = _angleAnimation.value;
      });
    });

    await _snapController.forward();
    if (!mounted) return;

    final trainer = _queue.first;

    if (right) {
      _matchService.likeTrainer(userId, trainer.id);
      
      try {
        final messagingService = context.read<MessagingService>();
        final conversationId = await messagingService.getOrCreateConversation(
          userId1: userId,
          userId2: trainer.userId, 
        );
        
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatScreen(
                conversationId: conversationId,
                otherUserId: trainer.userId,
                otherUserName: trainer.fullName,
                otherUserAvatar: trainer.profilePhotos?.isNotEmpty == true ? trainer.profilePhotos!.first : null,
              ),
            ),
          ).then((_) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('💪 You matched with ${trainer.fullName}! Say hi.'),
                  backgroundColor: AppTheme.primaryColor,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          });
        }
      } catch (e) {
        _showLikeOverlay(trainer);
      }
    } else {
      _matchService.passTrainer(userId, trainer.id);
    }

    setState(() {
      _queue.removeAt(0);
      _dragOffset = Offset.zero;
      _dragAngle = 0;
      _isAnimating = false;
    });

    // Reload when queue is almost empty
    if (_queue.length <= 3) _loadQueue();
  }

  void _showLikeOverlay(TrainerModel trainer) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.favorite_rounded, color: Colors.white),
            const SizedBox(width: 8),
            Text('You liked ${trainer.fullName}!'),
          ],
        ),
        backgroundColor: AppTheme.primaryColor,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildCardStack()),
            _buildActionButtons(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final isGuest = context.watch<AuthProvider>().user == null;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          // Fix 2: Back button for guests to return to Home
          if (isGuest && widget.onNavigateHome != null) ...[
            GestureDetector(
              onTap: widget.onNavigateHome,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.arrow_back_rounded,
                  color: AppTheme.textPrimary,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Text(
            'Explore',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
          const Spacer(),
          // City Filter
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedCity,
                isDense: true,
                icon: const Icon(Icons.arrow_drop_down, color: AppTheme.primaryColor),
                dropdownColor: AppTheme.surfaceColor,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.textPrimary, fontWeight: FontWeight.bold),
                items: _cities.map((city) {
                  return DropdownMenuItem(value: city, child: Text(city));
                }).toList(),
                onChanged: (val) {
                  if (val != null && val != _selectedCity) {
                    setState(() { _selectedCity = val; });
                    _loadQueue();
                  }
                },
              ),
            ),
          ),
          const SizedBox(width: 8),
          if (_queue.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${_queue.length} trainers',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCardStack() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_queue.isEmpty) {
      return _buildEmptyState();
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        // Background card (next up)
        if (_queue.length > 1)
          Positioned(
            bottom: 20,
            child: Transform.scale(
              scale: 0.92,
              child: _buildTrainerCard(_queue[1], isBackground: true),
            ),
          ),
        // Top card (swipeable)
        GestureDetector(
          onPanUpdate: _onDragUpdate,
          onPanEnd: _onDragEnd,
          child: Transform.translate(
            offset: _dragOffset,
            child: Transform.rotate(
              angle: _dragAngle,
              child: Stack(
                children: [
                  _buildTrainerCard(_queue[0], isBackground: false),
                  // Like overlay
                  if (_dragOffset.dx > 40)
                    Positioned(
                      top: 40,
                      left: 20,
                      child: _buildSwipeLabel('LIKE', AppTheme.primaryColor),
                    ),
                  // Nope overlay
                  if (_dragOffset.dx < -40)
                    Positioned(
                      top: 40,
                      right: 20,
                      child: _buildSwipeLabel('NOPE', AppTheme.errorColor),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSwipeLabel(String text, Color color) {
    final opacity = ((_dragOffset.dx.abs() - 40) / 120).clamp(0.0, 1.0);
    return Opacity(
      opacity: opacity,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: color, width: 3),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: color,
            fontSize: 28,
            fontWeight: FontWeight.w900,
            letterSpacing: 3,
          ),
        ),
      ),
    );
  }

  Widget _buildTrainerCard(TrainerModel trainer, {required bool isBackground}) {
    final photos = trainer.profilePhotos ?? [];
    return Container(
      width: MediaQuery.of(context).size.width - 32,
      height: MediaQuery.of(context).size.height * 0.58,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Photo or gradient
            photos.isNotEmpty
                ? Image.network(corsProxyUrl(photos[0]), fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => trainer.avatarUrl != null
                        ? Image.network(corsProxyUrl(trainer.avatarUrl), fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _buildCardGradient(trainer))
                        : _buildCardGradient(trainer))
                : trainer.avatarUrl != null
                    ? Image.network(corsProxyUrl(trainer.avatarUrl), fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildCardGradient(trainer))
                    : _buildCardGradient(trainer),
            // Bottom gradient overlay
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.85),
                    ],
                    stops: const [0.4, 1.0],
                  ),
                ),
              ),
            ),
            // Info
            if (!isBackground)
              Positioned(
                bottom: 0, left: 0, right: 0,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              trainer.fullName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          if (trainer.verificationStatus == 'verified')
                            const Icon(Icons.verified_rounded,
                                color: AppTheme.accentColor, size: 24),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        trainer.specialtiesDisplay,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _buildInfoChip(
                            icon: Icons.star_rounded,
                            label: trainer.ratingDisplay,
                            color: AppTheme.warningColor,
                          ),
                          const SizedBox(width: 8),
                          _buildInfoChip(
                            icon: Icons.currency_rupee_rounded,
                            label: '${trainer.pricePerSession}/session',
                            color: AppTheme.primaryColor,
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => TrainerDetailScreen(trainerId: trainer.id),
                              ),
                            ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'View Profile',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
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
    );
  }

  Widget _buildCardGradient(TrainerModel trainer) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor.withValues(alpha: 0.6),
            AppTheme.accentColor.withValues(alpha: 0.6),
          ],
        ),
      ),
      child: Center(
        child: Text(
          trainer.fullName[0].toUpperCase(),
          style: const TextStyle(
            fontSize: 100,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Pass button
          _buildActionButton(
            icon: Icons.close_rounded,
            color: AppTheme.errorColor,
            size: 56,
            onTap: () => _swipe(right: false),
          ),
          // Book button  
          _buildActionButton(
            icon: Icons.calendar_today_rounded,
            color: AppTheme.accentColor,
            size: 44,
            onTap: () {
              if (_queue.isEmpty) return;
              AuthGuard.protect(
                context,
                intent: 'book a session',
                onAuthenticated: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => Padding(
                      padding: EdgeInsets.only(
                        bottom: MediaQuery.of(context).viewInsets.bottom,
                      ),
                      child: BookingRequestModal(trainer: _queue.first),
                    ),
                  );
                },
              );
            },
          ),
          // Like button
          _buildActionButton(
            icon: Icons.favorite_rounded,
            color: AppTheme.primaryColor,
            size: 56,
            onTap: () => _swipe(right: true),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required double size,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: _queue.isEmpty ? null : onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
        ),
        child: Icon(icon, color: color, size: size * 0.45),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.explore_off_rounded,
            size: 80,
            color: AppTheme.textSecondary.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 20),
          Text(
            'No more trainers!',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You\'ve seen everyone for now.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _loadQueue,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Refresh'),
          ),
        ],
      ),
    );
  }
}

