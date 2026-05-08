import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../profile/profile_screen.dart';
import '../vault/vault_screen.dart';
import '../community/community_screen.dart';
import '../settings/settings_screen.dart';

class NavigationMenuScreen extends StatelessWidget {
  /// Called just before a sub-screen is pushed. Use this to reset the
  /// parent navigator state (e.g. snap the bottom-nav back to Home tab).
  final VoidCallback? onScreenPushed;

  const NavigationMenuScreen({super.key, this.onScreenPushed});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Menu',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppTheme.textSecondary),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildMenuItem(
                  context,
                  icon: Icons.person_rounded,
                  title: 'Profile',
                  subtitle: 'View and edit your personal details',
                  onTap: () {
                    // Close menu first, notify parent, then push
                    Navigator.pop(context);
                    onScreenPushed?.call();
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => ProfileScreen(onNavigateTo: (_) {})),
                    );
                  },
                ),
                const SizedBox(height: 16),
                _buildMenuItem(
                  context,
                  icon: Icons.lock_rounded,
                  title: 'Spotter Vault',
                  subtitle: 'Past bookings, favourites, AI chats, plans',
                  onTap: () {
                    Navigator.pop(context);
                    onScreenPushed?.call();
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const VaultScreen()),
                    );
                  },
                ),
                const SizedBox(height: 16),
                _buildMenuItem(
                  context,
                  icon: Icons.people_rounded,
                  title: 'Spotter Community',
                  subtitle: 'Streaks, achievements, events',
                  onTap: () {
                    Navigator.pop(context);
                    onScreenPushed?.call();
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CommunityScreen()),
                    );
                  },
                ),
                const SizedBox(height: 16),
                _buildMenuItem(
                  context,
                  icon: Icons.settings_rounded,
                  title: 'Settings',
                  subtitle: 'Account, membership, credits, AI features',
                  onTap: () {
                    Navigator.pop(context);
                    onScreenPushed?.call();
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: AppTheme.cardGradient,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppTheme.primaryColor, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppTheme.textSecondary),
          ],
        ),
      ),
    );
  }
}
