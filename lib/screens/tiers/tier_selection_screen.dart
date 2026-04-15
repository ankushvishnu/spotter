import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/tier_service.dart';

class TierSelectionScreen extends StatefulWidget {
  const TierSelectionScreen({super.key});

  @override
  State<TierSelectionScreen> createState() => _TierSelectionScreenState();
}

class _TierSelectionScreenState extends State<TierSelectionScreen>
    with SingleTickerProviderStateMixin {
  final TierService _tierService = TierService();
  String _currentTier = 'standard';
  String? _selectedTier;
  bool _isLoading = true;
  bool _isPurchasing = false;
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _loadCurrentTier();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentTier() async {
    final userId = context.read<AuthProvider>().user?.id;
    if (userId == null) {
      setState(() => _isLoading = false);
      return;
    }
    final tier = await _tierService.getCurrentTier(userId);
    if (mounted) {
      setState(() {
        _currentTier = tier;
        _selectedTier = tier;
        _isLoading = false;
      });
    }
  }

  Future<void> _handlePurchase() async {
    if (_selectedTier == null || _selectedTier == _currentTier) return;

    final userId = context.read<AuthProvider>().user?.id;
    if (userId == null) return;

    setState(() => _isPurchasing = true);

    final success = await _tierService.purchaseTier(userId, _selectedTier!);

    if (mounted) {
      setState(() => _isPurchasing = false);

      if (success) {
        setState(() => _currentTier = _selectedTier!);
        // Refresh user profile to reflect new tier
        await context.read<AuthProvider>().refreshUser();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Welcome to ${TierService.getTierInfo(_selectedTier!).label}! 🎉',
              ),
              backgroundColor: AppTheme.successColor,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to update tier. Please try again.'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Membership'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.backgroundColor, AppTheme.surfaceColor],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppTheme.spacingLG),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header
                      Center(
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: AppTheme.primaryGradient,
                                boxShadow: [AppTheme.primaryGlow],
                              ),
                              child: const Icon(
                                Icons.workspace_premium_rounded,
                                size: 36,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: AppTheme.spacingMD),
                            Text(
                              'Choose Your Tier',
                              style: Theme.of(context)
                                  .textTheme
                                  .displaySmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w900,
                                  ),
                            ),
                            const SizedBox(height: AppTheme.spacingSM),
                            Text(
                              'Unlock premium features & access top trainers',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: AppTheme.textSecondary),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: AppTheme.spacingXL),

                      // Tier Cards
                      ...TierService.tiers.map((tier) {
                        final isSelected = _selectedTier == tier.id;
                        final isCurrent = _currentTier == tier.id;
                        return _buildTierCard(tier, isSelected, isCurrent);
                      }),

                      const SizedBox(height: AppTheme.spacingLG),

                      // Purchase Button
                      if (_selectedTier != null &&
                          _selectedTier != _currentTier) ...[
                        Container(
                          decoration:
                              AppTheme.energeticButtonDecoration(radius: 16),
                          child: ElevatedButton(
                            onPressed: _isPurchasing ? null : _handlePurchase,
                            style: AppTheme.gradientButtonStyle(radius: 16),
                            child: _isPurchasing
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor:
                                          AlwaysStoppedAnimation<Color>(
                                              Colors.white),
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        _getButtonText(),
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Icon(
                                          Icons.arrow_forward_rounded,
                                          size: 20),
                                    ],
                                  ),
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacingSM),
                        Text(
                          'Payment integration coming soon — tier will be applied instantly for now.',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                color: AppTheme.textSecondary,
                                fontStyle: FontStyle.italic,
                              ),
                          textAlign: TextAlign.center,
                        ),
                      ],

                      const SizedBox(height: AppTheme.spacingXXL),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  String _getButtonText() {
    final selectedInfo = TierService.getTierInfo(_selectedTier!);
    final currentIndex =
        TierService.tiers.indexWhere((t) => t.id == _currentTier);
    final selectedIndex =
        TierService.tiers.indexWhere((t) => t.id == _selectedTier);

    if (selectedIndex > currentIndex) {
      return selectedInfo.pricePerMonth > 0
          ? 'Upgrade to ${selectedInfo.label} — ₹${selectedInfo.pricePerMonth}/mo'
          : 'Switch to ${selectedInfo.label}';
    } else {
      return 'Downgrade to ${selectedInfo.label}';
    }
  }

  Widget _buildTierCard(TierInfo tier, bool isSelected, bool isCurrent) {
    // Determine if this is the "recommended" tier
    final isRecommended = tier.id == 'pro';

    // Tier-specific gradient colors
    final cardColors = _getTierColors(tier.id);

    return GestureDetector(
      onTap: () {
        setState(() => _selectedTier = tier.id);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    cardColors[0].withValues(alpha: 0.15),
                    cardColors[1].withValues(alpha: 0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : AppTheme.cardGradient,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected
                ? cardColors[0]
                : AppTheme.textSecondary.withValues(alpha: 0.15),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: cardColors[0].withValues(alpha: 0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Text(tier.icon, style: const TextStyle(fontSize: 32)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            tier.label,
                            style: TextStyle(
                              color: isSelected
                                  ? cardColors[0]
                                  : AppTheme.textPrimary,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (isCurrent) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.successColor.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'CURRENT',
                                style: TextStyle(
                                  color: AppTheme.successColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                          ],
                          if (isRecommended && !isCurrent) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                gradient: AppTheme.primaryGradient,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'POPULAR',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        tier.description,
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                // Price
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (tier.pricePerMonth > 0) ...[
                      Text(
                        '₹${tier.pricePerMonth}',
                        style: TextStyle(
                          color: isSelected
                              ? cardColors[0]
                              : AppTheme.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const Text(
                        '/month',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ] else ...[
                      Text(
                        'FREE',
                        style: TextStyle(
                          color: isSelected
                              ? cardColors[0]
                              : AppTheme.successColor,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Divider
            Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    cardColors[0].withValues(alpha: 0.3),
                    Colors.transparent,
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Features
            ...tier.features.map((feature) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      size: 18,
                      color: isSelected
                          ? cardColors[0]
                          : AppTheme.successColor.withValues(alpha: 0.7),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        feature,
                        style: TextStyle(
                          color: isSelected
                              ? AppTheme.textPrimary
                              : AppTheme.textSecondary,
                          fontSize: 13,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),

            // Radio indicator
            const SizedBox(height: 8),
            Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? cardColors[0] : Colors.transparent,
                  border: Border.all(
                    color: isSelected
                        ? cardColors[0]
                        : AppTheme.textSecondary.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? const Icon(Icons.check, color: Colors.white, size: 16)
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Color> _getTierColors(String tierId) {
    switch (tierId) {
      case 'standard':
        return [AppTheme.accentColor, AppTheme.warningColor];
      case 'pro':
        return [AppTheme.primaryColor, AppTheme.accentColor];
      case 'elite':
        return [AppTheme.secondaryColor, const Color(0xFFFF6B6B)];
      default:
        return [AppTheme.primaryColor, AppTheme.accentColor];
    }
  }
}

