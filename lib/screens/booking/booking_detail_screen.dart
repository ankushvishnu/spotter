import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/booking_service.dart';
import '../../services/review_service.dart';
import '../../models/booking_model.dart';
import '../../config/theme.dart';
import '../../utils/app_exception.dart';
import '../reviews/create_review_screen.dart';
import '../../services/transfer_session_service.dart';
import '../home/home_screen_modern.dart';
import '../../config/supabase_config.dart';

class BookingDetailScreen extends StatefulWidget {
  final String bookingId;

  const BookingDetailScreen({
    super.key,
    required this.bookingId,
  });

  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  final BookingService _bookingService = BookingService();
  final ReviewService _reviewService = ReviewService();
  BookingModel? _booking;
  bool _isLoading = true;
  bool _hasReview = false;

  @override
  void initState() {
    super.initState();
    _loadBooking();
  }

  Future<void> _loadBooking() async {
    setState(() => _isLoading = true);
    try {
      final booking = await _bookingService.getBooking(widget.bookingId);
      if (!mounted) return;
      if (booking != null) {
        final model = BookingModel.fromJson(booking);
        // Check if already reviewed (only for completed bookings)
        bool hasReview = false;
        if (model.isCompleted) {
          final userId = context.read<AuthProvider>().user?.id;
          if (userId != null) {
            hasReview = await _reviewService.hasReviewedBooking(
              widget.bookingId,
              userId,
            );
          }
        }
        setState(() {
          _booking = model;
          _hasReview = hasReview;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppException.cleanMessage(e)),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Details'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _booking == null
              ? _buildErrorState()
              : _buildContent(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 64,
            color: AppTheme.textSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: AppTheme.spacingMD),
          Text(
            'Booking Not Found',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: AppTheme.spacingMD),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Go Back'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingLG),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status Card
          _buildStatusCard(),

          const SizedBox(height: AppTheme.spacingLG),

          // Trainer Info
          _buildTrainerInfo(),

          const SizedBox(height: AppTheme.spacingLG),

          // Session Details
          _buildSessionDetails(),

          const SizedBox(height: AppTheme.spacingLG),

          // Payment Details
          _buildPaymentDetails(),

          if (_booking!.isPending || _booking!.isConfirmed) ...[
            const SizedBox(height: AppTheme.spacingLG),
            _buildActions(),
          ],
          // Rate Session button for completed (or past confirmed) and unreviewed bookings
          if ((_booking!.isCompleted || (_booking!.isConfirmed && _booking!.sessionDate.isBefore(DateTime.now()))) && !_hasReview) ...[
            const SizedBox(height: AppTheme.spacingLG),
            _buildRateSessionButton(),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    final statusColor = _getStatusColor(_booking!.status);
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingLG),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [statusColor.withValues(alpha: 0.2), statusColor.withValues(alpha: 0.1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: statusColor.withValues(alpha: 0.5), width: 2),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getStatusIcon(_booking!.status),
              color: statusColor,
              size: 32,
            ),
          ),
          const SizedBox(width: AppTheme.spacingMD),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _booking!.statusDisplay,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: AppTheme.spacingXS),
                Text(
                  _getStatusDescription(_booking!.status),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: statusColor.withValues(alpha: 0.8),
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrainerInfo() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMD),
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                _booking!.trainerName?[0].toUpperCase() ?? 'T',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: AppTheme.backgroundColor,
                      fontWeight: FontWeight.w900,
                    ),
              ),
            ),
          ),
          const SizedBox(width: AppTheme.spacingMD),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Trainer',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                ),
                Text(
                  _booking!.trainerName ?? 'Unknown',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                if (_booking!.trainerSpecialties != null &&
                    _booking!.trainerSpecialties!.isNotEmpty)
                  Text(
                    _booking!.trainerSpecialties!.join(', '),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.primaryColor,
                        ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionDetails() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMD),
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Session Details',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: AppTheme.spacingMD),
          _buildDetailRow(
            icon: Icons.calendar_today_rounded,
            label: 'Date',
            value: _booking!.formattedDate,
          ),
          const SizedBox(height: AppTheme.spacingMD),
          _buildDetailRow(
            icon: Icons.access_time_rounded,
            label: 'Time',
            value: _booking!.formattedTime,
          ),
          const SizedBox(height: AppTheme.spacingMD),
          _buildDetailRow(
            icon: Icons.timer_rounded,
            label: 'Duration',
            value: '${_booking!.durationMinutes} minutes',
          ),
          const SizedBox(height: AppTheme.spacingMD),
          _buildDetailRow(
            icon: Icons.location_on_rounded,
            label: 'Location',
            value: _booking!.locationDisplay,
          ),
          if (_booking!.locationAddress != null) ...[
            const SizedBox(height: AppTheme.spacingXS),
            Padding(
              padding: const EdgeInsets.only(left: 36),
              child: Text(
                _booking!.locationAddress!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPaymentDetails() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMD),
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payment Details',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: AppTheme.spacingMD),
          _buildPriceRow('Session Fee', _booking!.basePrice),
          const SizedBox(height: AppTheme.spacingSM),
          _buildPriceRow('Platform Fee', _booking!.platformFee),
          Divider(
            height: AppTheme.spacingLG,
            color: AppTheme.textSecondary.withValues(alpha: 0.3),
          ),
          _buildPriceRow('Total', _booking!.totalPrice, isTotal: true),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.primaryColor),
        const SizedBox(width: AppTheme.spacingMD),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPriceRow(String label, int amount, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                fontSize: isTotal ? 16 : 14,
              ),
        ),
        Text(
          '₹$amount',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isTotal ? AppTheme.primaryColor : AppTheme.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: isTotal ? 18 : 14,
              ),
        ),
      ],
    );
  }

  Widget _buildActions() {
    return Column(
      children: [
        if (_booking!.isPending || _booking!.isConfirmed) ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _showRescheduleDialog(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentColor,
                padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingMD),
              ),
              child: const Text('Reschedule Booking'),
            ),
          ),
          const SizedBox(height: AppTheme.spacingSM),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => _showTransferDialog(),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingMD),
              ),
              child: const Text('Transfer Session to Another Trainer'),
            ),
          ),
          const SizedBox(height: AppTheme.spacingSM),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => _showCancelDialog(),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.errorColor,
                side: const BorderSide(color: AppTheme.errorColor),
                padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingMD),
              ),
              child: const Text('Cancel Booking'),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildRateSessionButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CreateReviewScreen(
                bookingId: _booking!.id,
                trainerId: _booking!.trainerId,
                trainerName: _booking!.trainerName ?? 'Trainer',
              ),
            ),
          ).then((submitted) {
            if (submitted == true) {
              setState(() => _hasReview = true);
            }
          });
        },
        icon: const Icon(Icons.star_rounded, size: 20),
        label: const Text('Rate This Session'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingMD),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return AppTheme.warningColor;
      case 'confirmed':
        return AppTheme.successColor;
      case 'completed':
        return AppTheme.accentColor;
      case 'cancelled':
        return AppTheme.errorColor;
      default:
        return AppTheme.textSecondary;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.schedule_rounded;
      case 'confirmed':
        return Icons.check_circle_rounded;
      case 'completed':
        return Icons.verified_rounded;
      case 'cancelled':
        return Icons.cancel_rounded;
      default:
        return Icons.info_rounded;
    }
  }

  String _getStatusDescription(String status) {
    switch (status) {
      case 'pending':
        return 'Waiting for trainer approval';
      case 'confirmed':
        return 'Your session is confirmed!';
      case 'completed':
        return 'Session completed successfully';
      case 'cancelled':
        return 'This booking was cancelled';
      default:
        return '';
    }
  }

  Future<void> _showCancelDialog() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Booking?'),
        content: const Text(
          'Are you sure you want to cancel this booking? This action cannot be undone.',
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
      await _cancelBooking();
    }
  }

  Future<void> _cancelBooking() async {
    final userId = context.read<AuthProvider>().user?.id;
    if (userId == null) return;

    try {
      await _bookingService.cancelBooking(
        bookingId: widget.bookingId,
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
        Navigator.pop(context); // Go back
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppException.cleanMessage(e)),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _showRescheduleDialog() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _booking!.sessionDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (date == null) return;

    if (!mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: int.parse(_booking!.sessionTime.split(':')[0]),
        minute: int.parse(_booking!.sessionTime.split(':')[1]),
      ),
    );
    if (time == null) return;

    if (!mounted) return;
    try {
      await SupabaseConfig.client.from('bookings').update({
        'session_date': date.toIso8601String().split('T')[0],
        'session_time': '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:00',
        'status': 'pending', 
      }).eq('id', _booking!.id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Rescheduled successfully')));
        _loadBooking();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to reschedule: $e')));
      }
    }
  }

  Future<void> _showTransferDialog() async {
    final userId = context.read<AuthProvider>().user?.id;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Transfer Session'),
        content: const Text(
          'This will cancel your current booking and take you to the Explore page to find a new trainer. Proceed?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.primaryColor),
            child: const Text('Transfer'),
          ),
        ],
      ),
    );


    if (confirm == true) {
      if (userId == null) return;

      try {
        await TransferSessionService().transferSession(bookingId: _booking!.id, clientId: userId);
        if (!mounted) return;
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
               content: Text('Session transferred.'),
               backgroundColor: AppTheme.successColor,
            ),
           );
           Navigator.of(context).pushAndRemoveUntil(
             MaterialPageRoute(builder: (_) => const HomeScreen(initialIndex: 2)), 
             (route) => false
           );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to transfer: $e')));
        }
      }
    }
  }
}
