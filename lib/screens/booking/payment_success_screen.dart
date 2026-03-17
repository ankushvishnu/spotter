import 'package:flutter/material.dart';
import '../../config/theme.dart';

class PaymentSuccessScreen extends StatefulWidget {
  final String bookingId;
  final int amount;
  final String trainerName;

  const PaymentSuccessScreen({
    super.key,
    required this.bookingId,
    required this.amount,
    required this.trainerName,
  });

  @override
  State<PaymentSuccessScreen> createState() => _PaymentSuccessScreenState();
}

class _PaymentSuccessScreenState extends State<PaymentSuccessScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(AppTheme.spacingLG),
          child: Column(
            children: [
              const Spacer(),

              // Success Icon
              ScaleTransition(
                scale: _scaleAnimation,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    shape: BoxShape.circle,
                    boxShadow: [AppTheme.primaryGlow],
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    size: 64,
                    color: AppTheme.backgroundColor,
                  ),
                ),
              ),

              SizedBox(height: AppTheme.spacingXL),

              // Success Message
              FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    Text(
                      'Payment Successful!',
                      style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: AppTheme.spacingMD),
                    Text(
                      'Your session with ${widget.trainerName} has been booked',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              SizedBox(height: AppTheme.spacingXL),

              // Booking Details Card
              FadeTransition(
                opacity: _fadeAnimation,
                child: Container(
                  padding: EdgeInsets.all(AppTheme.spacingLG),
                  decoration: BoxDecoration(
                    gradient: AppTheme.cardGradient,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppTheme.primaryColor.withOpacity(0.2),
                    ),
                  ),
                  child: Column(
                    children: [
                      _buildDetailRow(
                        icon: Icons.receipt_long_rounded,
                        label: 'Booking ID',
                        value: widget.bookingId.substring(0, 8).toUpperCase(),
                      ),
                      Divider(
                        height: AppTheme.spacingLG,
                        color: AppTheme.textSecondary.withOpacity(0.2),
                      ),
                      _buildDetailRow(
                        icon: Icons.payment_rounded,
                        label: 'Amount Paid',
                        value: '₹${widget.amount}',
                      ),
                      Divider(
                        height: AppTheme.spacingLG,
                        color: AppTheme.textSecondary.withOpacity(0.2),
                      ),
                      _buildDetailRow(
                        icon: Icons.check_circle_rounded,
                        label: 'Status',
                        value: 'Pending Approval',
                        valueColor: AppTheme.warningColor,
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: AppTheme.spacingXL),

              // Info Box
              Container(
                padding: EdgeInsets.all(AppTheme.spacingMD),
                decoration: BoxDecoration(
                  color: AppTheme.accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.accentColor.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: AppTheme.accentColor,
                      size: 20,
                    ),
                    SizedBox(width: AppTheme.spacingMD),
                    Expanded(
                      child: Text(
                        'The trainer will confirm your booking request soon. You\'ll be notified once confirmed.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.accentColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Actions
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: AppTheme.spacingMD),
                  ),
                  child: const Text('BACK TO HOME'),
                ),
              ),

              SizedBox(height: AppTheme.spacingMD),

              TextButton(
                onPressed: () {
                  // TODO: Navigate to bookings
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                child: const Text('View My Bookings'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primaryColor, size: 20),
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
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: valueColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}