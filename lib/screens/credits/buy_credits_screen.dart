import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/credits_service.dart';
import '../../models/credit_package.dart';
import '../../config/theme.dart';
import '../booking/payment_success_screen.dart';

class BuyCreditsScreen extends StatefulWidget {
  const BuyCreditsScreen({super.key});

  @override
  State<BuyCreditsScreen> createState() => _BuyCreditsScreenState();
}

class _BuyCreditsScreenState extends State<BuyCreditsScreen> {
  final CreditsService _creditsService = CreditsService();
  int _currentCredits = 0;
  bool _isLoadingBalance = true;
  String? _buyingPackageId;

  static final List<CreditPackage> packages = [
    const CreditPackage(credits: 1, price: 2000, discount: 0, tag: ''),
    const CreditPackage(credits: 3, price: 5700, discount: 5, tag: 'Popular'),
    const CreditPackage(credits: 5, price: 9000, discount: 10, tag: 'Best Value'),
    const CreditPackage(credits: 10, price: 17000, discount: 15, tag: 'Pro'),
  ];

  @override
  void initState() {
    super.initState();
    _loadBalance();
  }

  Future<void> _loadBalance() async {
    final userId = context.read<AuthProvider>().user?.id;
    if (userId == null) return;
    final credits = await _creditsService.getUserCredits(userId);
    if (mounted) {
      setState(() {
        _currentCredits = credits;
        _isLoadingBalance = false;
      });
    }
  }

  Future<void> _buyPackage(CreditPackage package) async {
    final userId = context.read<AuthProvider>().user?.id;
    if (userId == null) return;

    setState(() => _buyingPackageId = '${package.credits}');

    try {
      await _creditsService.addCredits(
        userId: userId,
        credits: package.credits,
        amountPaid: package.price,
        description: 'Purchased ${package.credits} session credit(s)',
      );

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentSuccessScreen(
              bookingId: 'credits-${DateTime.now().millisecondsSinceEpoch}',
              amount: package.price,
              trainerName: '${package.credits} Session Credit(s)',
              isCreditPurchase: true,
            ),
          ),
        ).then((_) => _loadBalance());
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Purchase failed: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _buyingPackageId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buy Session Credits'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacingLG),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current balance banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppTheme.spacingLG),
              decoration: BoxDecoration(
                gradient: AppTheme.cardGradient,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppTheme.primaryColor.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppTheme.spacingMD),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_rounded,
                      color: AppTheme.primaryColor,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingMD),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current Balance',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      _isLoadingBalance
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              '$_currentCredits Credit${_currentCredits != 1 ? 's' : ''}',
                              style:
                                  Theme.of(context).textTheme.headlineLarge?.copyWith(
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppTheme.spacingXL),

            Text(
              'Choose a Package',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: AppTheme.spacingSM),
            Text(
              '1 credit = 1 confirmed session',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppTheme.spacingLG),

            ...packages.map((package) => Padding(
              padding: const EdgeInsets.only(bottom: AppTheme.spacingMD),
              child: _buildPackageCard(package),
            )),

            const SizedBox(height: AppTheme.spacingXL),

            // Info box
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingMD),
              decoration: BoxDecoration(
                color: AppTheme.accentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.accentColor.withValues(alpha: 0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline_rounded,
                      color: AppTheme.accentColor, size: 20),
                  const SizedBox(width: AppTheme.spacingSM),
                  Expanded(
                    child: Text(
                      'Credits are deducted when a booking is confirmed by the trainer. Unused credits never expire.',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppTheme.accentColor),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppTheme.spacingLG),
          ],
        ),
      ),
    );
  }

  Widget _buildPackageCard(CreditPackage package) {
    final isBuying = _buyingPackageId == '${package.credits}';
    final hasBestTag = package.tag.isNotEmpty;

    return GestureDetector(
      onTap: isBuying ? null : () => _buyPackage(package),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedContainer(
            duration: AppTheme.fastAnimation,
            padding: const EdgeInsets.all(AppTheme.spacingLG),
            decoration: BoxDecoration(
              gradient: package.discount > 0
                  ? AppTheme.primaryGradient
                  : AppTheme.cardGradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: package.discount > 0 ? [AppTheme.primaryGlow] : [],
            ),
            child: Row(
              children: [
                // Credit circle
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundColor.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      '${package.credits}',
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: package.discount > 0
                            ? AppTheme.backgroundColor
                            : AppTheme.primaryColor,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppTheme.spacingMD),

                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        package.label,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: package.discount > 0
                              ? AppTheme.backgroundColor
                              : AppTheme.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (package.discount > 0)
                        Text(
                          'Save ${package.discount}% vs single session',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                color: AppTheme.backgroundColor.withValues(alpha: 0.8),
                              ),
                        ),
                    ],
                  ),
                ),

                // Price
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    isBuying
                        ? SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: package.discount > 0
                                  ? AppTheme.backgroundColor
                                  : AppTheme.primaryColor,
                            ),
                          )
                        : Text(
                            '₹${package.price}',
                            style:
                                Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: package.discount > 0
                                  ? AppTheme.backgroundColor
                                  : AppTheme.primaryColor,
                            ),
                          ),
                    if (package.discount > 0)
                      Text(
                        '₹${package.originalPrice}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          decoration: TextDecoration.lineThrough,
                          color: AppTheme.backgroundColor.withValues(alpha: 0.6),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // Tag badge
          if (hasBestTag)
            Positioned(
              top: -10,
              right: AppTheme.spacingLG,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.warningColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  package.tag,
                  style: const TextStyle(
                    color: AppTheme.backgroundColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

