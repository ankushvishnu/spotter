import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../credits/buy_credits_screen.dart';
import '../credits/credits_history_screen.dart';
import '../ai/ai_agent_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppTheme.spacingLG),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              context,
              title: 'Account',
              items: [
                _SettingItem(
                  icon: Icons.lock_outline_rounded,
                  label: 'Change Password',
                  onTap: () => _showComingSoon(context, 'Change Password'),
                ),
                _SettingItem(
                  icon: Icons.email_outlined,
                  label: 'Update Email',
                  onTap: () => _showComingSoon(context, 'Update Email'),
                ),
                _SettingItem(
                  icon: Icons.phone_outlined,
                  label: 'Update Phone',
                  onTap: () => _showComingSoon(context, 'Update Phone'),
                ),
              ],
            ),
            SizedBox(height: AppTheme.spacingLG),

            _buildSection(
              context,
              title: 'Credits',
              items: [
                _SettingItem(
                  icon: Icons.add_card_rounded,
                  label: 'Buy Credits',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const BuyCreditsScreen()),
                  ),
                ),
                _SettingItem(
                  icon: Icons.receipt_long_rounded,
                  label: 'Credit History',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CreditsHistoryScreen()),
                  ),
                ),
              ],
            ),
            SizedBox(height: AppTheme.spacingLG),

            _buildSection(
              context,
              title: 'AI Features',
              items: [
                _SettingItem(
                  icon: Icons.auto_awesome_rounded,
                  label: 'AI Assistant',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AIAgentScreen()),
                  ),
                ),
              ],
            ),
            SizedBox(height: AppTheme.spacingLG),

            _buildSection(
              context,
              title: 'Notifications',
              items: [
                _SettingItem(
                  icon: Icons.notifications_outlined,
                  label: 'Notification Preferences',
                  onTap: () => _showComingSoon(context, 'Notifications'),
                ),
              ],
            ),
            SizedBox(height: AppTheme.spacingLG),

            _buildSection(
              context,
              title: 'Privacy',
              items: [
                _SettingItem(
                  icon: Icons.privacy_tip_outlined,
                  label: 'Privacy Settings',
                  onTap: () => _showComingSoon(context, 'Privacy'),
                ),
                _SettingItem(
                  icon: Icons.policy_outlined,
                  label: 'Privacy Policy',
                  onTap: () => _showComingSoon(context, 'Privacy Policy'),
                ),
              ],
            ),
            SizedBox(height: AppTheme.spacingLG),

            _buildSection(
              context,
              title: 'About',
              items: [
                _SettingItem(
                  icon: Icons.info_outline_rounded,
                  label: 'About Spotter',
                  trailing: 'v1.0.0',
                  onTap: () {},
                ),
                _SettingItem(
                  icon: Icons.star_outline_rounded,
                  label: 'Rate the App',
                  onTap: () => _showComingSoon(context, 'Rate App'),
                ),
                _SettingItem(
                  icon: Icons.help_outline_rounded,
                  label: 'Help & Support',
                  onTap: () => _showComingSoon(context, 'Help & Support'),
                ),
              ],
            ),

            SizedBox(height: AppTheme.spacingXXL),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required List<_SettingItem> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(
              left: AppTheme.spacingXS, bottom: AppTheme.spacingSM),
          child: Text(
            title.toUpperCase(),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            gradient: AppTheme.cardGradient,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: items.asMap().entries.map((entry) {
              final i = entry.key;
              final item = entry.value;
              return Column(
                children: [
                  _buildSettingTile(context, item),
                  if (i < items.length - 1)
                    Divider(
                      height: 1,
                      color: AppTheme.textSecondary.withOpacity(0.1),
                      indent: 56,
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingTile(BuildContext context, _SettingItem item) {
    return InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppTheme.spacingMD,
          vertical: AppTheme.spacingMD,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(item.icon, color: AppTheme.primaryColor, size: 20),
            ),
            SizedBox(width: AppTheme.spacingMD),
            Expanded(
              child: Text(
                item.label,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
            if (item.trailing != null)
              Text(
                item.trailing!,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            SizedBox(width: AppTheme.spacingXS),
            const Icon(Icons.chevron_right_rounded,
                color: AppTheme.textSecondary, size: 20),
          ],
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature — Coming Soon!'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class _SettingItem {
  final IconData icon;
  final String label;
  final String? trailing;
  final VoidCallback onTap;

  const _SettingItem({
    required this.icon,
    required this.label,
    this.trailing,
    required this.onTap,
  });
}
