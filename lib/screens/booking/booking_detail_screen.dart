import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/booking_service.dart';
import '../../models/booking_model.dart';
import '../../config/theme.dart';

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
  BookingModel? _booking;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBooking();
  }

  Future<void> _loadBooking() async {
    setState(() => _isLoading = true);
    try {
      final booking = await _bookingService.getBooking(widget.bookingId);
      if (booking != null) {
        setState(() {
          _booking = BookingModel.fromJson(booking);
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading booking: $e')),
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
            color: AppTheme.textSecondary.withOpacity(0.5),
          ),
          SizedBox(height: AppTheme.spacingMD),
          Text(
            'Booking Not Found',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          SizedBox(height: AppTheme.spacingMD),
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
      padding: EdgeInsets.all(AppTheme.spacingLG),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status Card
          _buildStatusCard(),

          SizedBox(height: AppTheme.spacingLG),

          // Trainer Info
          _buildTrainerInfo(),

          SizedBox(height: AppTheme.spacingLG),

          // Session Details
          _buildSessionDetails(),

          SizedBox(height: AppTheme.spacingLG),

          // Payment Details
          _buildPaymentDetails(),

          if (_booking!.isPending || _booking!.isConfirmed) ...[
            SizedBox(height: AppTheme.spacingLG),
            _buildActions(),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    final statusColor = _getStatusColor(_booking!.status);
    return Container(
      padding: EdgeInsets.all(AppTheme.spacingLG),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [statusColor.withOpacity(0.2), statusColor.withOpacity(0.1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: statusColor.withOpacity(0.5), width: 2),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getStatusIcon(_booking!.status),
              color: statusColor,
              size: 32,
            ),
          ),
          SizedBox(width: AppTheme.spacingMD),
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
                SizedBox(height: AppTheme.spacingXS),
                Text(
                  _getStatusDescription(_booking!.status),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: statusColor.withOpacity(0.8),
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
      padding: EdgeInsets.all(AppTheme.spacingMD),
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
          SizedBox(width: AppTheme.spacingMD),
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
      padding: EdgeInsets.all(AppTheme.spacingMD),
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
          SizedBox(height: AppTheme.spacingMD),
          _buildDetailRow(
            icon: Icons.calendar_today_rounded,
            label: 'Date',
            value: _booking!.formattedDate,
          ),
          SizedBox(height: AppTheme.spacingMD),
          _buildDetailRow(
            icon: Icons.access_time_rounded,
            label: 'Time',
            value: _booking!.formattedTime,
          ),
          SizedBox(height: AppTheme.spacingMD),
          _buildDetailRow(
            icon: Icons.timer_rounded,
            label: 'Duration',
            value: '${_booking!.durationMinutes} minutes',
          ),
          SizedBox(height: AppTheme.spacingMD),
          _buildDetailRow(
            icon: Icons.location_on_rounded,
            label: 'Location',
            value: _booking!.locationDisplay,
          ),
          if (_booking!.locationAddress != null) ...[
            SizedBox(height: AppTheme.spacingXS),
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
      padding: EdgeInsets.all(AppTheme.spacingMD),
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
          SizedBox(height: AppTheme.spacingMD),
          _buildPriceRow('Session Fee', _booking!.basePrice),
          SizedBox(height: AppTheme.spacingSM),
          _buildPriceRow('Platform Fee', _booking!.platformFee),
          Divider(
            height: AppTheme.spacingLG,
            color: AppTheme.textSecondary.withOpacity(0.3),
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
        SizedBox(width: AppTheme.spacingMD),
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
        if (_booking!.isPending)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => _showCancelDialog(),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.errorColor,
                side: const BorderSide(color: AppTheme.errorColor),
                padding: EdgeInsets.symmetric(vertical: AppTheme.spacingMD),
              ),
              child: const Text('Cancel Booking'),
            ),
          ),
      ],
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
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}