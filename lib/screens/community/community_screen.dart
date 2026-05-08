import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../config/theme.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen>
    with TickerProviderStateMixin {
  late AnimationController _streakPulse;
  late AnimationController _badgeShine;

  // Mock data — will be replaced with real backend data
  final int _currentStreak = 7;
  final int _longestStreak = 14;
  final int _totalSessions = 32;

  final List<_Achievement> _achievements = [
    _Achievement(
      icon: Icons.local_fire_department_rounded,
      title: 'Fire Starter',
      description: 'Complete 5 sessions',
      unlocked: true,
      color: Colors.orange,
    ),
    _Achievement(
      icon: Icons.fitness_center_rounded,
      title: 'Iron Will',
      description: 'Complete 10 sessions',
      unlocked: true,
      color: AppTheme.primaryColor,
    ),
    _Achievement(
      icon: Icons.bolt_rounded,
      title: 'Lightning Streak',
      description: '7-day session streak',
      unlocked: true,
      color: Colors.amber,
    ),
    _Achievement(
      icon: Icons.diamond_rounded,
      title: 'Diamond Grinder',
      description: 'Complete 50 sessions',
      unlocked: false,
      color: AppTheme.accentColor,
    ),
    _Achievement(
      icon: Icons.emoji_events_rounded,
      title: 'Champion',
      description: '30-day session streak',
      unlocked: false,
      color: AppTheme.warningColor,
    ),
    _Achievement(
      icon: Icons.military_tech_rounded,
      title: 'Legend',
      description: 'Complete 100 sessions',
      unlocked: false,
      color: AppTheme.secondaryColor,
    ),
  ];

  final List<_CommunityPost> _posts = [
    _CommunityPost(
      userName: 'Ali K.',
      userAvatar: 'A',
      timeAgo: '2h ago',
      content: 'Just hit my 10th consecutive session streak! Massive thanks to my trainer for pushing me. 💪',
      likes: 24,
      comments: 5,
      badge: '10x Streak 🔥',
      badgeColor: Colors.orange,
    ),
    _CommunityPost(
      userName: 'Sara T.',
      userAvatar: 'S',
      timeAgo: '5h ago',
      content: 'Completed the Elite Marathon Prep module. Can barely walk but so worth it!',
      likes: 42,
      comments: 12,
      badge: 'Marathon Prep 🏃‍♀️',
      badgeColor: AppTheme.primaryColor,
    ),
    _CommunityPost(
      userName: 'Priya M.',
      userAvatar: 'P',
      timeAgo: '8h ago',
      content: 'My PCOS-focused training plan is showing real results after 6 weeks. Down 4kg and feeling so much more energetic!',
      likes: 67,
      comments: 18,
      badge: 'Health Journey 💚',
      badgeColor: AppTheme.successColor,
    ),
    _CommunityPost(
      userName: 'Mike D.',
      userAvatar: 'M',
      timeAgo: '1d ago',
      content: 'Dropped 2 kgs this month. The new nutrition plan is working wonders!',
      likes: 89,
      comments: 21,
      badge: 'Goal Crushed 🎯',
      badgeColor: AppTheme.accentColor,
    ),
    _CommunityPost(
      userName: 'Ravi S.',
      userAvatar: 'R',
      timeAgo: '2d ago',
      content: 'First session with my new physio trainer — knee feels better already! Should have started rehab sooner.',
      likes: 31,
      comments: 8,
      badge: 'Recovery Path 🏥',
      badgeColor: AppTheme.secondaryColor,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _streakPulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _badgeShine = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _streakPulse.dispose();
    _badgeShine.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Spotter Community'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Streak header
            SliverToBoxAdapter(child: _buildStreakHeader()),

            // Achievements section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                child: Row(
                  children: [
                    Text(
                      'Achievements',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    const Spacer(),
                    Text(
                      '${_achievements.where((a) => a.unlocked).length}/${_achievements.length}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(child: _buildAchievementsRow()),

            // Feed header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                child: Text(
                  'Community Feed',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w900),
                ),
              ),
            ),

            // Posts
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                    child: _buildPostCard(_posts[index]),
                  );
                },
                childCount: _posts.length,
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          HapticFeedback.mediumImpact();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Post sharing coming soon! 🚀'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Share', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildStreakHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: AnimatedBuilder(
        animation: _streakPulse,
        builder: (context, child) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryColor.withValues(alpha: 0.2),
                  Colors.orange.withValues(
                      alpha: 0.08 + (_streakPulse.value * 0.08)),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppTheme.primaryColor.withValues(alpha: 0.2),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withValues(
                      alpha: 0.08 + (_streakPulse.value * 0.06)),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                // Streak flame
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        Colors.orange,
                        Colors.redAccent.withValues(alpha: 0.8),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withValues(
                            alpha: 0.3 + (_streakPulse.value * 0.2)),
                        blurRadius: 16 + (_streakPulse.value * 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.local_fire_department_rounded,
                          color: Colors.white, size: 28),
                      Text(
                        '$_currentStreak',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$_currentStreak Day Streak!',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildStreakStat(
                              'Best', '$_longestStreak days', Colors.orange),
                          const SizedBox(width: 16),
                          _buildStreakStat('Total', '$_totalSessions sessions',
                              AppTheme.primaryColor),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStreakStat(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _buildAchievementsRow() {
    return SizedBox(
      height: 120,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: _achievements.length,
        itemBuilder: (context, index) {
          final achievement = _achievements[index];
          return Container(
            width: 96,
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: achievement.unlocked
                  ? achievement.color.withValues(alpha: 0.1)
                  : AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: achievement.unlocked
                    ? achievement.color.withValues(alpha: 0.3)
                    : Colors.white.withValues(alpha: 0.05),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  achievement.icon,
                  color: achievement.unlocked
                      ? achievement.color
                      : AppTheme.textSecondary.withValues(alpha: 0.3),
                  size: 32,
                ),
                const SizedBox(height: 8),
                Text(
                  achievement.title,
                  style: TextStyle(
                    color: achievement.unlocked
                        ? AppTheme.textPrimary
                        : AppTheme.textSecondary.withValues(alpha: 0.5),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (!achievement.unlocked)
                  const Icon(Icons.lock_rounded,
                      size: 12, color: AppTheme.textSecondary),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPostCard(_CommunityPost post) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: post.badgeColor.withValues(alpha: 0.2),
                child: Text(
                  post.userAvatar,
                  style: TextStyle(
                    color: post.badgeColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.userName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      post.timeAgo,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: post.badgeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  post.badge,
                  style: TextStyle(
                    color: post.badgeColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            post.content,
            style: const TextStyle(
              fontSize: 15,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildInteractionButton(
                  Icons.favorite_border_rounded, '${post.likes}'),
              const SizedBox(width: 20),
              _buildInteractionButton(
                  Icons.chat_bubble_outline_rounded, '${post.comments}'),
              const Spacer(),
              Icon(Icons.share_outlined,
                  size: 18,
                  color: AppTheme.textSecondary.withValues(alpha: 0.5)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInteractionButton(IconData icon, String count) {
    return GestureDetector(
      onTap: () => HapticFeedback.lightImpact(),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.textSecondary),
          const SizedBox(width: 6),
          Text(
            count,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _Achievement {
  final IconData icon;
  final String title;
  final String description;
  final bool unlocked;
  final Color color;

  const _Achievement({
    required this.icon,
    required this.title,
    required this.description,
    required this.unlocked,
    required this.color,
  });
}

class _CommunityPost {
  final String userName;
  final String userAvatar;
  final String timeAgo;
  final String content;
  final int likes;
  final int comments;
  final String badge;
  final Color badgeColor;

  const _CommunityPost({
    required this.userName,
    required this.userAvatar,
    required this.timeAgo,
    required this.content,
    required this.likes,
    required this.comments,
    required this.badge,
    required this.badgeColor,
  });
}
