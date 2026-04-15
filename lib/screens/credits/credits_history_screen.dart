import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/credits_service.dart';
import '../../config/theme.dart';

class CreditsHistoryScreen extends StatefulWidget {
  const CreditsHistoryScreen({super.key});

  @override
  State<CreditsHistoryScreen> createState() => _CreditsHistoryScreenState();
}

class _CreditsHistoryScreenState extends State<CreditsHistoryScreen> {
  final CreditsService _creditsService = CreditsService();
  List<Map<String, dynamic>> _transactions = [];
  int _currentCredits = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final userId = context.read<AuthProvider>().user?.id;
    if (userId == null) return;

    final results = await Future.wait([
      _creditsService.getUserCredits(userId),
      _creditsService.getCreditHistory(userId),
    ]);

    if (mounted) {
      setState(() {
        _currentCredits = results[0] as int;
        _transactions = results[1] as List<Map<String, dynamic>>;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Credit History'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Balance card
                Container(
                  margin: const EdgeInsets.all(AppTheme.spacingLG),
                  padding: const EdgeInsets.all(AppTheme.spacingLG),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [AppTheme.primaryGlow],
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.account_balance_wallet_rounded,
                        color: AppTheme.backgroundColor,
                        size: 40,
                      ),
                      const SizedBox(width: AppTheme.spacingMD),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Available Credits',
                            style:
                                Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.backgroundColor.withValues(alpha: 0.8),
                            ),
                          ),
                          Text(
                            '$_currentCredits',
                            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                              color: AppTheme.backgroundColor,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Transaction list
                Expanded(
                  child: _transactions.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                          onRefresh: _loadHistory,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(
                                horizontal: AppTheme.spacingLG),
                            itemCount: _transactions.length,
                            itemBuilder: (context, index) {
                              return _buildTransactionTile(_transactions[index]);
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_rounded,
              size: 64, color: AppTheme.textSecondary.withValues(alpha: 0.4)),
          const SizedBox(height: AppTheme.spacingMD),
          Text(
            'No transactions yet',
            style: Theme.of(context)
                .textTheme
                .headlineMedium
                ?.copyWith(color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionTile(Map<String, dynamic> tx) {
    final isPurchase = (tx['transaction_type'] ?? tx['type']) == 'purchase';
    final credits = tx['credits'] as int? ?? 0;
    final description =
        tx['description'] as String? ?? (isPurchase ? 'Credits Purchased' : 'Session Booked');
    final date = tx['created_at'] != null
        ? DateTime.tryParse(tx['created_at'] as String)
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingMD),
      padding: const EdgeInsets.all(AppTheme.spacingMD),
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (isPurchase
                      ? AppTheme.successColor
                      : AppTheme.errorColor)
                  .withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isPurchase
                  ? Icons.add_circle_outline_rounded
                  : Icons.remove_circle_outline_rounded,
              color: isPurchase ? AppTheme.successColor : AppTheme.errorColor,
              size: 24,
            ),
          ),
          const SizedBox(width: AppTheme.spacingMD),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  description,
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                if (date != null)
                  Text(
                    '${date.day}/${date.month}/${date.year}',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppTheme.textSecondary),
                  ),
              ],
            ),
          ),
          Text(
            '${isPurchase ? '+' : '-'}$credits',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: isPurchase ? AppTheme.successColor : AppTheme.errorColor,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

