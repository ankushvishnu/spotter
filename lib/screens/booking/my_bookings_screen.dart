import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/auth_provider.dart';
import '../../services/booking_service.dart';
import '../../services/review_service.dart';
import '../../config/supabase_config.dart';
import '../../models/booking_model.dart';
import '../../config/theme.dart';
import '../../utils/booking_status_utils.dart';
import 'booking_detail_screen.dart';
import '../reviews/create_review_screen.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen>
    with SingleTickerProviderStateMixin {
  late final BookingService _bookingService;
  final ReviewService _reviewService = ReviewService();
  late TabController _tabController;
  RealtimeChannel? _subscription;

  List<BookingModel> _upcomingBookings = [];
  List<BookingModel> _pastBookings = [];
  final Set<String> _reviewedBookingIds = {};
  bool _isLoading = true;
  String? _lastUserId;

  @override
  void initState() {
    super.initState();
    _bookingService = context.read<BookingService>();
    _tabController = TabController(length: 2, vsync: this);
    _loadBookings();
    _setupRealtime();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final currentUserId = context.watch<AuthProvider>().user?.id;
    if (currentUserId != null && currentUserId != _lastUserId) {
      _lastUserId = currentUserId;
      _loadBookings();
      _setupRealtime();
    }
  }

  void _setupRealtime() {
    final userId = context.read<AuthProvider>().user?.id;
    if (userId == null) return;

    _subscription = SupabaseConfig.client
        .channel('public:bookings:client_$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'bookings',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'client_id',
            value: userId,
          ),
          callback: (payload) {
            if (mounted) _loadBookings();
          },
        )
        .subscribe();
  }

  @override
  void dispose() {
    _subscription?.unsubscribe();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadBookings() async {
    final userId = context.read<AuthProvider>().user?.id;
    if (userId == null) return;

    setState(() => _isLoading = true);
    try {
      // Parallel fetch: upcoming + past bookings at the same time
      final results = await Future.wait([
        _bookingService.getUpcomingBookings(userId),
        _bookingService.getPastBookings(userId),
      ]);

      final upcoming = results[0];
      final past = results[1];
      final pastModels = past.map((b) => BookingModel.fromJson(b)).toList();

      // Batch review check: single query instead of N+1
      final completedIds = pastModels
          .where((b) => b.status == 'completed')
          .map((b) => b.id)
          .toList();
      final reviewed = await _reviewService.getReviewedBookingIds(completedIds, userId);

      setState(() {
        _upcomingBookings = upcoming.map((b) => BookingModel.fromJson(b)).toList();
        _pastBookings = pastModels;
        _reviewedBookingIds
          ..clear()
          ..addAll(reviewed);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading bookings: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildTabBar(),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildUpcomingTab(),
                        _buildPastTab(),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingLG),
      child: Row(
        children: [
          Text(
            'My Bookings',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLG),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          borderRadius: BorderRadius.circular(12),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: AppTheme.backgroundColor,
        unselectedLabelColor: AppTheme.textSecondary,
        labelStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
        tabs: const [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.upcoming_rounded, size: 20),
                SizedBox(width: AppTheme.spacingXS),
                Text('Upcoming'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history_rounded, size: 20),
                SizedBox(width: AppTheme.spacingXS),
                Text('Past'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingTab() {
    if (_upcomingBookings.isEmpty) {
      return _buildEmptyState(
        icon: Icons.calendar_today_rounded,
        title: 'No Upcoming Bookings',
        subtitle: 'Book a session with a trainer to get started!',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadBookings,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppTheme.spacingLG),
        itemCount: _upcomingBookings.length,
        itemBuilder: (context, index) {
          final booking = _upcomingBookings[index];
          return _buildBookingCard(booking, isUpcoming: true);
        },
      ),
    );
  }

  Widget _buildPastTab() {
    if (_pastBookings.isEmpty) {
      return _buildEmptyState(
        icon: Icons.history_rounded,
        title: 'No Past Bookings',
        subtitle: 'Your completed sessions will appear here',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadBookings,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppTheme.spacingLG),
        itemCount: _pastBookings.length,
        itemBuilder: (context, index) {
          final booking = _pastBookings[index];
          return _buildBookingCard(booking, isUpcoming: false);
        },
      ),
    );
  }

  Widget _buildBookingCard(BookingModel booking, {required bool isUpcoming}) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BookingDetailScreen(bookingId: booking.id),
          ),
        ).then((_) => _loadBookings()); // Refresh on return
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: AppTheme.spacingMD),
        padding: const EdgeInsets.all(AppTheme.spacingMD),
        decoration: BoxDecoration(
          gradient: AppTheme.cardGradient,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: BookingStatusUtils.getStatusColor(booking.status).withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Trainer info & status
            Row(
              children: [
                // Trainer Avatar
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      booking.trainerName?[0].toUpperCase() ?? 'T',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: AppTheme.backgroundColor,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                  ),
                ),

                const SizedBox(width: AppTheme.spacingMD),

                // Trainer name & specialties
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.trainerName ?? 'Unknown Trainer',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      if (booking.trainerSpecialties != null &&
                          booking.trainerSpecialties!.isNotEmpty)
                        Text(
                          booking.trainerSpecialties!.join(', '),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.primaryColor,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),

                // Status Badge
                _buildStatusBadge(booking.status),
              ],
            ),

            const SizedBox(height: AppTheme.spacingMD),

            // Divider
            Divider(
              color: AppTheme.textSecondary.withValues(alpha: 0.2),
              height: 1,
            ),

            const SizedBox(height: AppTheme.spacingMD),

            // Session Details
            Row(
              children: [
                Expanded(
                  child: _buildDetailItem(
                    icon: Icons.calendar_today_rounded,
                    label: booking.formattedDate,
                  ),
                ),
                Expanded(
                  child: _buildDetailItem(
                    icon: Icons.access_time_rounded,
                    label: booking.formattedTime,
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppTheme.spacingSM),

            Row(
              children: [
                Expanded(
                  child: _buildDetailItem(
                    icon: Icons.timer_rounded,
                    label: '${booking.durationMinutes} min',
                  ),
                ),
                Expanded(
                  child: _buildDetailItem(
                    icon: Icons.location_on_rounded,
                    label: booking.locationDisplay,
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppTheme.spacingMD),

            // Price & Actions
            Row(
              children: [
                Text(
                  '₹${booking.totalPrice}',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const Spacer(),
                if (isUpcoming && booking.isPending)
                  TextButton(
                    onPressed: () => _showCancelDialog(booking),
                    child: const Text('Cancel'),
                  ),
                // Rate Session button for completed past bookings
                if (!isUpcoming && booking.status == 'completed')
                  _reviewedBookingIds.contains(booking.id)
                      ? Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.warningColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star_rounded, size: 14, color: AppTheme.warningColor),
                              const SizedBox(width: 4),
                              Text(
                                'Rated',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppTheme.warningColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        )
                      : TextButton.icon(
                          onPressed: () async {
                            final submitted = await Navigator.push<bool>(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CreateReviewScreen(
                                  bookingId: booking.id,
                                  trainerId: booking.trainerId ?? '',
                                  trainerName: booking.trainerName ?? 'Trainer',
                                ),
                              ),
                            );
                            if (submitted == true) _loadBookings();
                          },
                          icon: const Icon(Icons.star_outline_rounded, size: 18),
                          label: const Text('Rate'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppTheme.warningColor,
                          ),
                        ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppTheme.textSecondary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem({required IconData icon, required String label}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.textSecondary),
        const SizedBox(width: AppTheme.spacingXS),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    final color = BookingStatusUtils.getStatusColor(status);
    final icon = BookingStatusUtils.getStatusIcon(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            BookingStatusUtils.getStatusText(status),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: AppTheme.textSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: AppTheme.spacingMD),
          Text(
            title,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
          ),
          const SizedBox(height: AppTheme.spacingSM),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }



  Future<void> _showCancelDialog(BookingModel booking) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Booking?'),
        content: Text(
          'Are you sure you want to cancel your session with ${booking.trainerName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _cancelBooking(booking);
    }
  }

  Future<void> _cancelBooking(BookingModel booking) async {
    final userId = context.read<AuthProvider>().user?.id;
    if (userId == null) return;

    try {
      await _bookingService.cancelBooking(
        bookingId: booking.id,
        cancelledBy: userId,
        cancellationReason: 'Cancelled by client',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking cancelled successfully'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        _loadBookings(); // Refresh
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cancelling booking: $e')),
        );
      }
    }
  }
}
