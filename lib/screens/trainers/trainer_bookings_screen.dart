import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/booking_service.dart';
import '../../models/booking_model.dart';
import '../../config/theme.dart';
import 'trainer_booking_detail_screen.dart';

class TrainerBookingsScreen extends StatefulWidget {
  const TrainerBookingsScreen({super.key});

  @override
  State<TrainerBookingsScreen> createState() => _TrainerBookingsScreenState();
}

class _TrainerBookingsScreenState extends State<TrainerBookingsScreen>
    with SingleTickerProviderStateMixin {
  final BookingService _bookingService = BookingService();
  late TabController _tabController;

  List<BookingModel> _pendingBookings = [];
  List<BookingModel> _confirmedBookings = [];
  bool _isLoading = true;
  String? _trainerId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadTrainerId();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTrainerId() async {
    final userId = context.read<AuthProvider>().user?.id;
    if (userId == null) return;

    // Get trainer ID from trainers table
    try {
      final trainer = await _bookingService.getTrainerByUserId(userId);
      if (trainer != null) {
        setState(() => _trainerId = trainer['id'] as String);
        _loadBookings();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading trainer info: $e')),
        );
      }
    }
  }

  Future<void> _loadBookings() async {
    if (_trainerId == null) return;

    setState(() => _isLoading = true);
    try {
      final upcoming = await _bookingService.getUpcomingBookings(
        _trainerId!,
        isTrainer: true,
      );

      final pending = upcoming
          .where((b) => BookingModel.fromJson(b).isPending)
          .map((b) => BookingModel.fromJson(b))
          .toList();

      final confirmed = upcoming
          .where((b) => BookingModel.fromJson(b).isConfirmed)
          .map((b) => BookingModel.fromJson(b))
          .toList();

      setState(() {
        _pendingBookings = pending;
        _confirmedBookings = confirmed;
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
                        _buildPendingTab(),
                        _buildConfirmedTab(),
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
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: AppTheme.spacingSM),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'My Schedule',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              Text(
                '${_pendingBookings.length} pending requests',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.warningColor,
                    ),
              ),
            ],
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
        tabs: [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.pending_actions_rounded, size: 20),
                const SizedBox(width: AppTheme.spacingXS),
                const Text('Pending'),
                if (_pendingBookings.isNotEmpty) ...[
                  const SizedBox(width: AppTheme.spacingXS),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.warningColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${_pendingBookings.length}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.backgroundColor,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_rounded, size: 20),
                SizedBox(width: AppTheme.spacingXS),
                Text('Confirmed'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingTab() {
    if (_pendingBookings.isEmpty) {
      return _buildEmptyState(
        icon: Icons.calendar_today_rounded,
        title: 'No Pending Requests',
        subtitle: 'New booking requests will appear here',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadBookings,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppTheme.spacingLG),
        itemCount: _pendingBookings.length,
        itemBuilder: (context, index) {
          final booking = _pendingBookings[index];
          return _buildBookingRequestCard(booking);
        },
      ),
    );
  }

  Widget _buildConfirmedTab() {
    if (_confirmedBookings.isEmpty) {
      return _buildEmptyState(
        icon: Icons.event_available_rounded,
        title: 'No Confirmed Sessions',
        subtitle: 'Confirmed bookings will appear here',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadBookings,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppTheme.spacingLG),
        itemCount: _confirmedBookings.length,
        itemBuilder: (context, index) {
          final booking = _confirmedBookings[index];
          return _buildConfirmedBookingCard(booking);
        },
      ),
    );
  }

  Widget _buildBookingRequestCard(BookingModel booking) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TrainerBookingDetailScreen(
              bookingId: booking.id,
            ),
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
            color: AppTheme.warningColor.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Client info
            Row(
              children: [
                // Client Avatar
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: AppTheme.energeticGradient,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      booking.clientName?[0].toUpperCase() ?? 'C',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: AppTheme.backgroundColor,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                  ),
                ),

                const SizedBox(width: AppTheme.spacingMD),

                // Client name
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.clientName ?? 'Unknown Client',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        'New booking request',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.warningColor,
                            ),
                      ),
                    ],
                  ),
                ),

                // "NEW" Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.warningColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.warningColor),
                  ),
                  child: Text(
                    'NEW',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.warningColor,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'You earn',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      '₹${booking.basePrice}',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                  ],
                ),
                const Spacer(),
                OutlinedButton(
                  onPressed: () => _showDeclineDialog(booking),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.errorColor,
                    side: const BorderSide(color: AppTheme.errorColor),
                  ),
                  child: const Text('Decline'),
                ),
                const SizedBox(width: AppTheme.spacingSM),
                ElevatedButton(
                  onPressed: () => _confirmBooking(booking),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.successColor,
                    foregroundColor: AppTheme.backgroundColor,
                  ),
                  child: const Text('Accept'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfirmedBookingCard(BookingModel booking) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TrainerBookingDetailScreen(
              bookingId: booking.id,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: AppTheme.spacingMD),
        padding: const EdgeInsets.all(AppTheme.spacingMD),
        decoration: BoxDecoration(
          gradient: AppTheme.cardGradient,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppTheme.successColor.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      booking.clientName?[0].toUpperCase() ?? 'C',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: AppTheme.backgroundColor,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                  ),
                ),
                const SizedBox(width: AppTheme.spacingMD),
                Expanded(
                  child: Text(
                    booking.clientName ?? 'Unknown',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                const Icon(
                  Icons.check_circle_rounded,
                  color: AppTheme.successColor,
                  size: 20,
                ),
              ],
            ),

            const SizedBox(height: AppTheme.spacingMD),

            // Session info
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
                  child: Text(
                    '₹${booking.basePrice}',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                    textAlign: TextAlign.right,
                  ),
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

  Future<void> _confirmBooking(BookingModel booking) async {
    try {
      await _bookingService.confirmBooking(booking.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Booking confirmed for ${booking.clientName}!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        _loadBookings(); // Refresh
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error confirming booking: $e')),
        );
      }
    }
  }

  Future<void> _showDeclineDialog(BookingModel booking) async {
    final userId = context.read<AuthProvider>().user?.id;
    if (userId == null) return;

    final reason = await showDialog<String>(
      context: context,
      builder: (context) => _DeclineReasonDialog(clientName: booking.clientName ?? 'Client'),
    );

    if (reason != null) {
      await _declineBooking(booking, reason, userId);
    }
  }

  Future<void> _declineBooking(BookingModel booking, String reason, String userId) async {
    try {
      await _bookingService.cancelBooking(
        bookingId: booking.id,
        cancelledBy: userId, // Use user_id, not trainer_id
        cancellationReason: reason,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking declined'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
        _loadBookings(); // Refresh
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error declining booking: $e')),
        );
      }
    }
  }
}

// Decline Reason Dialog
class _DeclineReasonDialog extends StatefulWidget {
  final String clientName;

  const _DeclineReasonDialog({required this.clientName});

  @override
  State<_DeclineReasonDialog> createState() => _DeclineReasonDialogState();
}

class _DeclineReasonDialogState extends State<_DeclineReasonDialog> {
  String? _selectedReason;
  final TextEditingController _customReasonController = TextEditingController();

  final List<String> _predefinedReasons = [
    'Time slot not available',
    'Already booked',
    'Location not accessible',
    'Need to reschedule',
    'Other',
  ];

  @override
  void dispose() {
    _customReasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Decline Booking?'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Let ${widget.clientName} know why you can\'t make it:'),
            const SizedBox(height: AppTheme.spacingMD),
            ...List.generate(_predefinedReasons.length, (index) {
              final reason = _predefinedReasons[index];
              return RadioListTile<String>(
                title: Text(reason),
                value: reason,
                groupValue: _selectedReason,
                onChanged: (value) {
                  setState(() => _selectedReason = value);
                },
              );
            }),
            if (_selectedReason == 'Other') ...[
              const SizedBox(height: AppTheme.spacingSM),
              TextField(
                controller: _customReasonController,
                decoration: const InputDecoration(
                  hintText: 'Enter reason...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            final reason = _selectedReason == 'Other'
                ? _customReasonController.text
                : _selectedReason;
            if (reason != null && reason.isNotEmpty) {
              Navigator.pop(context, reason);
            }
          },
          style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
          child: const Text('Decline Booking'),
        ),
      ],
    );
  }
}
