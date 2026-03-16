import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/booking_service.dart';
import '../../models/booking_model.dart';
import '../../config/theme.dart';

class TrainerBookingDetailScreen extends StatefulWidget {
  final String bookingId;

  const TrainerBookingDetailScreen({
    super.key,
    required this.bookingId,
  });

  @override
  State<TrainerBookingDetailScreen> createState() =>
      _TrainerBookingDetailScreenState();
}

class _TrainerBookingDetailScreenState
    extends State<TrainerBookingDetailScreen> {
  final BookingService _bookingService = BookingService();
  BookingModel? _booking;
  bool _isLoading = true;
  String? _trainerId;

  @override
  void initState() {
    super.initState();
    _loadBooking();
  }

  Future<void> _loadBooking() async {
    final userId = context.read<AuthProvider>().user?.id;
    if (userId == null) return;

    setState(() => _isLoading = true);
    try {
      // Get trainer ID
      final trainer = await _bookingService.getTrainerByUserId(userId);
      _trainerId = trainer?['id'] as String?;

      // Get booking
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
        title: const Text('Booking Request'),
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

          // Client Info
          _buildClientInfo(),

          SizedBox(height: AppTheme.spacingLG),

          // Session Details
          _buildSessionDetails(),

          SizedBox(height: AppTheme.spacingLG),

          // Earnings
          _buildEarningsCard(),

          if (_booking!.isPending) ...[
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

  Widget _buildClientInfo() {
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
              gradient: AppTheme.energeticGradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                _booking!.clientName?[0].toUpperCase() ?? 'C',
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
                  'Client',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                ),
                Text(
                  _booking!.clientName ?? 'Unknown',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
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

  Widget _buildEarningsCard() {
    return Container(
      padding: EdgeInsets.all(AppTheme.spacingMD),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor.withOpacity(0.2),
            AppTheme.accentColor.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Earnings',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          SizedBox(height: AppTheme.spacingMD),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Session Fee',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                '₹${_booking!.basePrice}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          SizedBox(height: AppTheme.spacingSM),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Platform Fee (15%)',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
              ),
              Text(
                '-₹${_booking!.platformFee}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
              ),
            ],
          ),
          Divider(
            height: AppTheme.spacingLG,
            color: AppTheme.primaryColor.withOpacity(0.3),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'You Earn',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              Text(
                '₹${_booking!.basePrice}',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w900,
                    ),
              ),
            ],
          ),
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

  Widget _buildActions() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _confirmBooking(),
            icon: const Icon(Icons.check_circle_rounded),
            label: const Text('Accept Booking'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.successColor,
              foregroundColor: AppTheme.backgroundColor,
              padding: EdgeInsets.symmetric(vertical: AppTheme.spacingMD),
            ),
          ),
        ),
        SizedBox(height: AppTheme.spacingSM),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _showDeclineDialog(),
            icon: const Icon(Icons.cancel_rounded),
            label: const Text('Decline Booking'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.errorColor,
              side: const BorderSide(color: AppTheme.errorColor),
              padding: EdgeInsets.symmetric(vertical: AppTheme.spacingMD),
            ),
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
        return 'Waiting for your response';
      case 'confirmed':
        return 'Session confirmed!';
      case 'completed':
        return 'Session completed';
      case 'cancelled':
        return 'This booking was cancelled';
      default:
        return '';
    }
  }

  Future<void> _confirmBooking() async {
    try {
      await _bookingService.confirmBooking(widget.bookingId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Booking confirmed for ${_booking!.clientName}!'),
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

  Future<void> _showDeclineDialog() async {
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => _DeclineReasonDialog(
        clientName: _booking!.clientName ?? 'Client',
      ),
    );

    if (reason != null) {
      await _declineBooking(reason);
    }
  }

  Future<void> _declineBooking(String reason) async {
    final userId = context.read<AuthProvider>().user?.id;
    if (userId == null) return;

    try {
      await _bookingService.cancelBooking(
        bookingId: widget.bookingId,
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

// Decline Reason Dialog (reused from main screen)
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
            SizedBox(height: AppTheme.spacingMD),
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
              SizedBox(height: AppTheme.spacingSM),
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