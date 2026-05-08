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
  final int initialTab;

  const MyBookingsScreen({
    super.key,
    this.initialTab = 0,
  });

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

  // New states for Selection and Sorting/Filtering
  bool _isSelectionMode = false;
  final Set<String> _selectedBookingIds = {};
  
  String _statusFilter = 'All';
  String _sortBy = 'Date ASC';

  @override
  void initState() {
    super.initState();
    _bookingService = context.read<BookingService>();
    _tabController = TabController(
      initialIndex: widget.initialTab,
      length: 2, 
      vsync: this,
    );
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
           if (_tabController.index == 1) {
             _isSelectionMode = false;
             _selectedBookingIds.clear();
           }
        });
      }
    });
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

  Future<void> _showBulkArchiveDialog() async {
    if (_selectedBookingIds.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.surfaceColor,
          title: const Text('Archive Bookings'),
          content: Text('Archive ${_selectedBookingIds.length} booking(s)? They will be moved to your Vault.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey),
              child: const Text('Archive', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      await _bookingService.archiveBookings(_selectedBookingIds.toList());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_selectedBookingIds.length} booking(s) archived'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.errorColor),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSelectionMode = false);
        _selectedBookingIds.clear();
        _loadBookings();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: _isSelectionMode && _selectedBookingIds.isNotEmpty
          ? Padding(
              padding: const EdgeInsets.only(bottom: 90.0), // Above the tab island
              child: FloatingActionButton.extended(
                onPressed: _tabController.index == 0 ? _showBulkCancelDialog : _showBulkArchiveDialog,
                backgroundColor: _tabController.index == 0 ? AppTheme.errorColor : Colors.blueGrey,
                icon: Icon(_tabController.index == 0 ? Icons.cancel_rounded : Icons.archive_rounded, color: Colors.white),
                label: Text('${_tabController.index == 0 ? 'Cancel' : 'Archive'} ${_selectedBookingIds.length}', style: const TextStyle(color: Colors.white)),
              ),
            )
          : null,
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
    final bool onPastTab = _tabController.index == 1;
    final int totalSelectable = onPastTab ? _pastBookings.length : _upcomingBookings.where((b) => b.isPending).length;
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingLG),
      child: Row(
        children: [
          // When in selection mode show count, otherwise show title
          if (_isSelectionMode)
            Text(
              '${_selectedBookingIds.length} of $totalSelectable selected',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: AppTheme.primaryColor),
            )
          else
            Text(
              'My Bookings',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
          const Spacer(),
          if ((_tabController.index == 0 && _upcomingBookings.isNotEmpty) || 
              (_tabController.index == 1 && _pastBookings.isNotEmpty))
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _isSelectionMode = !_isSelectionMode;
                  if (!_isSelectionMode) _selectedBookingIds.clear();
                });
              },
              icon: Icon(_isSelectionMode ? Icons.close_rounded : Icons.checklist_rounded, size: 20),
              label: Text(_isSelectionMode ? 'Cancel' : 'Select'),
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

  Widget _buildFilterSortBar() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLG, vertical: AppTheme.spacingMD),
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          // Sort Dropdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _sortBy,
                icon: const Icon(Icons.sort_rounded, color: AppTheme.primaryColor, size: 20),
                dropdownColor: AppTheme.surfaceColor,
                style: Theme.of(context).textTheme.bodySmall,
                onChanged: (String? newValue) {
                  if (newValue != null) setState(() => _sortBy = newValue);
                },
                items: <String>['Date ASC', 'Date DESC', 'Trainer', 'Speciality']
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(width: AppTheme.spacingMD),
          // Filter Chips
          ...['All', 'Pending'].map((status) {
            final isSelected = _statusFilter == status;
            return Padding(
              padding: const EdgeInsets.only(right: AppTheme.spacingSM),
              child: FilterChip(
                selected: isSelected,
                label: Text(status),
                onSelected: (selected) {
                  setState(() => _statusFilter = status);
                },
                backgroundColor: AppTheme.surfaceColor,
                selectedColor: AppTheme.primaryColor.withValues(alpha: 0.2),
                checkmarkColor: AppTheme.primaryColor,
                labelStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  List<BookingModel> _getFilteredAndSortedBookings(List<BookingModel> list) {
    // 1. Filter
    var filtered = list.where((b) {
      if (_statusFilter == 'All') return true;
      return b.status.toLowerCase() == _statusFilter.toLowerCase();
    }).toList();

    // 2. Sort
    filtered.sort((a, b) {
      switch (_sortBy) {
        case 'Date ASC':
          return a.sessionDate.compareTo(b.sessionDate);
        case 'Date DESC':
          return b.sessionDate.compareTo(a.sessionDate);
        case 'Trainer':
          return (a.trainerName ?? '').compareTo(b.trainerName ?? '');
        case 'Speciality':
          final aSpec = a.trainerSpecialties?.isNotEmpty == true ? a.trainerSpecialties!.first : '';
          final bSpec = b.trainerSpecialties?.isNotEmpty == true ? b.trainerSpecialties!.first : '';
          return aSpec.compareTo(bSpec);
        default:
          return 0;
      }
    });

    return filtered;
  }

  Widget _buildUpcomingTab() {
    final displayList = _getFilteredAndSortedBookings(_upcomingBookings);

    if (displayList.isEmpty) {
      return Column(
        children: [
          _buildFilterSortBar(),
          Expanded(
            child: _buildEmptyState(
              icon: Icons.calendar_today_rounded,
              title: 'No Upcoming Bookings',
              subtitle: 'No sessions match your filters, or book a new one!',
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        _buildFilterSortBar(),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadBookings,
            child: ListView.builder(
              padding: const EdgeInsets.all(AppTheme.spacingLG),
              itemCount: displayList.length,
              itemBuilder: (context, index) {
                final booking = displayList[index];
                return _buildBookingCard(booking, isUpcoming: true);
              },
            ),
          ),
        ),
      ],
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

    final bool allSelected = _pastBookings.isNotEmpty &&
        _pastBookings.every((b) => _selectedBookingIds.contains(b.id));

    return Column(
      children: [
        // ── Select All bar (only visible in selection mode) ─────────────────
        if (_isSelectionMode)
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.fromLTRB(AppTheme.spacingLG, 0, AppTheme.spacingLG, 0),
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMD, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Checkbox(
                  value: allSelected,
                  tristate: false,
                  onChanged: (val) {
                    setState(() {
                      if (val == true) {
                        // Select ALL past bookings
                        _selectedBookingIds.addAll(_pastBookings.map((b) => b.id));
                      } else {
                        // Deselect all
                        _selectedBookingIds.removeAll(_pastBookings.map((b) => b.id));
                      }
                    });
                  },
                  activeColor: AppTheme.primaryColor,
                  side: BorderSide(color: AppTheme.primaryColor.withValues(alpha: 0.6)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    allSelected ? 'Deselect All' : 'Select All (${_pastBookings.length})',
                    style: TextStyle(
                      color: allSelected ? AppTheme.primaryColor : AppTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
                if (_selectedBookingIds.isNotEmpty)
                  TextButton.icon(
                    onPressed: _showBulkArchiveDialog,
                    icon: const Icon(Icons.archive_rounded, size: 18),
                    label: Text('Archive ${_selectedBookingIds.length}'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.blueGrey,
                      textStyle: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
          ),
        if (_isSelectionMode) const SizedBox(height: AppTheme.spacingSM),
        // ── Booking list ─────────────────────────────────────────────────────
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadBookings,
            child: ListView.builder(
              padding: const EdgeInsets.all(AppTheme.spacingLG),
              itemCount: _pastBookings.length,
              itemBuilder: (context, index) {
                final booking = _pastBookings[index];
                return _buildBookingCard(booking, isUpcoming: false);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBookingCard(BookingModel booking, {required bool isUpcoming}) {
    // In upcoming -> can select if pending to cancel
    // In past -> can select anything to archive
    final bool canSelect = (isUpcoming && booking.isPending) || !isUpcoming;
    final bool isSelected = _selectedBookingIds.contains(booking.id);

    return GestureDetector(
      onTap: () {
        if (_isSelectionMode && canSelect) {
          setState(() {
            if (isSelected) {
              _selectedBookingIds.remove(booking.id);
            } else {
              _selectedBookingIds.add(booking.id);
            }
          });
          return;
        }
        if (_isSelectionMode) return; // Ignore clicks on non-pending if selecting

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
                if (_isSelectionMode && canSelect)
                  Padding(
                    padding: const EdgeInsets.only(right: AppTheme.spacingMD),
                    child: Checkbox(
                      value: isSelected,
                      onChanged: (val) {
                        setState(() {
                          if (val == true) {
                            _selectedBookingIds.add(booking.id);
                          } else {
                            _selectedBookingIds.remove(booking.id);
                          }
                        });
                      },
                      activeColor: AppTheme.primaryColor,
                    ),
                  ),

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
                if (!_isSelectionMode) _buildStatusBadge(booking.status),
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

  Future<void> _showBulkCancelDialog() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Selected Sessions?'),
        content: Text(
          'Are you sure you want to cancel ${_selectedBookingIds.length} sessions? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: const Text('Yes, Cancel All'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _cancelBulkBookings();
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

  Future<void> _cancelBulkBookings() async {
    final userId = context.read<AuthProvider>().user?.id;
    if (userId == null) return;

    setState(() => _isLoading = true);

    try {
      await _bookingService.cancelBulkBookings(
        bookingIds: _selectedBookingIds.toList(),
        cancelledBy: userId,
        cancellationReason: 'Bulk cancelled by client',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_selectedBookingIds.length} bookings cancelled successfully'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        setState(() {
          _isSelectionMode = false;
          _selectedBookingIds.clear();
        });
        _loadBookings(); // Refresh
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cancelling bookings: $e')),
        );
      }
    }
  }
}
