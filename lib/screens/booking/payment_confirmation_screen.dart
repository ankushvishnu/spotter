import 'package:flutter/material.dart';
import '../../config/theme.dart';
import 'payment_success_screen.dart';

class PaymentConfirmationScreen extends StatelessWidget {
  final String bookingId;
  final int totalAmount;
  final String trainerName;

  const PaymentConfirmationScreen({
    super.key,
    required this.bookingId,
    required this.totalAmount,
    required this.trainerName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.spacingLG),
          child: Column(
            children: [
              // Amount Card
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingXL),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [AppTheme.primaryGlow],
                ),
                child: Column(
                  children: [
                    Text(
                      'Total Amount',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.backgroundColor,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingSM),
                    Text(
                      '₹$totalAmount',
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        color: AppTheme.backgroundColor,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingXS),
                    Text(
                      'Session with $trainerName',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.backgroundColor.withValues(alpha: 0.9),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppTheme.spacingXL),

              // Demo Notice
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingMD),
                decoration: BoxDecoration(
                  color: AppTheme.warningColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.warningColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      color: AppTheme.warningColor,
                    ),
                    const SizedBox(width: AppTheme.spacingMD),
                    Expanded(
                      child: Text(
                        'This is a demo payment. No actual transaction will occur.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.warningColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppTheme.spacingXL),

              // Payment Methods (Demo)
              ListView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildPaymentOption(
                    context,
                    icon: Icons.credit_card_rounded,
                    title: 'Credit/Debit Card',
                    subtitle: 'Visa, Mastercard, Amex',
                  ),
                  const SizedBox(height: AppTheme.spacingMD),
                  _buildPaymentOption(
                    context,
                    icon: Icons.account_balance_rounded,
                    title: 'UPI',
                    subtitle: 'Google Pay, PhonePe, Paytm',
                  ),
                  const SizedBox(height: AppTheme.spacingMD),
                  _buildPaymentOption(
                    context,
                    icon: Icons.account_balance_wallet_rounded,
                    title: 'Net Banking',
                    subtitle: 'All major banks',
                  ),
                ],
              ),

              const SizedBox(height: AppTheme.spacingLG),

              // Pay Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Simulate payment success
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PaymentSuccessScreen(
                          bookingId: bookingId,
                          amount: totalAmount,
                          trainerName: trainerName,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingMD),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('PAY NOW'),
                      SizedBox(width: AppTheme.spacingSM),
                      Icon(Icons.arrow_forward_rounded, size: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMD),
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppTheme.primaryColor),
          ),
          const SizedBox(width: AppTheme.spacingMD),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: AppTheme.textSecondary,
          ),
        ],
      ),
    );
  }
}
