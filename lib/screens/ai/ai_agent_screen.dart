import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../config/supabase_config.dart';
import '../../services/chat_storage_service.dart';
import 'ai_chat_screen.dart';
import 'ai_generate_screen.dart';
import 'chat_history_screen.dart';

/// AI Agent Features Screen
/// Hub for all AI-powered features — fully functional with Cerebras inference
class AIAgentScreen extends StatefulWidget {
  const AIAgentScreen({super.key});

  @override
  State<AIAgentScreen> createState() => _AIAgentScreenState();
}

class _AIAgentScreenState extends State<AIAgentScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _headerPulse;
  final ChatStorageService _storage = ChatStorageService();
  int _historyCount = 0;
  bool _hasLocalToMigrate = false;

  final List<_AIFeature> _features = [
    const _AIFeature(
      id: 0,
      icon: Icons.chat_bubble_rounded,
      title: 'AI Coach Chat',
      description:
          'Get instant answers about fitness, nutrition, and training plans from our AI coach.',
      color: AppTheme.primaryColor,
      route: 'coach_chat',
    ),
    const _AIFeature(
      id: 1,
      icon: Icons.edit_note_rounded,
      title: 'Write My Bio',
      description:
          'Let AI craft a compelling trainer bio based on your expertise and style.',
      color: AppTheme.accentColor,
      route: 'write_bio',
    ),
    const _AIFeature(
      id: 2,
      icon: Icons.description_rounded,
      title: 'Write Description',
      description:
          'Generate engaging session descriptions that attract the right clients.',
      color: AppTheme.warningColor,
      route: 'write_description',
    ),
    const _AIFeature(
      id: 3,
      icon: Icons.fitness_center_rounded,
      title: 'Generate Workout Plan',
      description:
          'Create personalized workout plans tailored to goals and fitness level.',
      color: AppTheme.secondaryColor,
      route: 'workout_plan',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _headerPulse = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _loadHistoryCount();
    _checkMigration();
  }

  @override
  void dispose() {
    _headerPulse.dispose();
    super.dispose();
  }

  Future<void> _loadHistoryCount() async {
    final convs = await _storage.loadConversations();
    if (mounted) setState(() => _historyCount = convs.length);
  }

  Future<void> _checkMigration() async {
    final isAuth = SupabaseConfig.client.auth.currentSession != null;
    if (isAuth) {
      final hasLocal = await _storage.hasLocalConversations();
      if (hasLocal && mounted) {
        setState(() => _hasLocalToMigrate = true);
      }
    }
  }

  Future<void> _migrateChatHistory() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final count = await _storage.migrateLocalToSupabase();

    if (mounted) {
      Navigator.pop(context); // close loading
      setState(() => _hasLocalToMigrate = false);
      _loadHistoryCount();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '$count conversation${count != 1 ? 's' : ''} restored to your account! 🎉'),
          backgroundColor: AppTheme.successColor,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  void _navigateToFeature(_AIFeature feature) {
    if (feature.route == 'coach_chat') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AIChatScreen()),
      ).then((_) => _loadHistoryCount());
    } else {
      final configs = {
        'write_bio': {
          'title': 'Write My Bio',
          'description':
              'Tell us about your training experience, specialties, certifications, and personality — our AI will craft a professional, compelling bio for you.',
          'placeholder':
              'e.g., "5 years of personal training, certified NASM, specialize in strength training and weight loss. I\'m energetic and motivating..."',
        },
        'write_description': {
          'title': 'Session Description',
          'description':
              'Describe the type of session or class you offer — our AI will create an engaging description that attracts the right clients.',
          'placeholder':
              'e.g., "45-minute HIIT class for beginners, focuses on cardio and core, no equipment needed, suitable for all fitness levels..."',
        },
        'workout_plan': {
          'title': 'Workout Plan',
          'description':
              'Share the client\'s goals, fitness level, available equipment, and any limitations — our AI will generate a structured workout plan.',
          'placeholder':
              'e.g., "Beginner looking to lose weight, has dumbbells and a mat at home, can work out 3x per week, no knee exercises..."',
        },
      };

      final config = configs[feature.route]!;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AIGenerateScreen(
            feature: feature.route,
            title: config['title']!,
            description: config['description']!,
            placeholder: config['placeholder']!,
            icon: feature.icon,
            color: feature.color,
          ),
        ),
      ).then((_) => _loadHistoryCount());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Assistant'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacingLG),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Animated header
            AnimatedBuilder(
              animation: _headerPulse,
              builder: (context, child) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppTheme.spacingXL),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryColor,
                        Color.lerp(
                          AppTheme.primaryColor,
                          AppTheme.accentColor,
                          _headerPulse.value,
                        )!,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor
                            .withValues(alpha: 0.3 + (_headerPulse.value * 0.2)),
                        blurRadius: 20 + (_headerPulse.value * 10),
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.auto_awesome_rounded,
                          size: 48, color: AppTheme.backgroundColor),
                      const SizedBox(height: AppTheme.spacingMD),
                      Text(
                        'SPOTTER AI',
                        style: Theme.of(context)
                            .textTheme
                            .displaySmall
                            ?.copyWith(
                              color: AppTheme.backgroundColor,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 4,
                            ),
                      ),
                      const SizedBox(height: AppTheme.spacingXS),
                      Text(
                        'Your intelligent fitness companion',
                        style:
                            Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppTheme.backgroundColor
                                      .withValues(alpha: 0.8),
                                ),
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: AppTheme.spacingLG),

            // Migration banner
            if (_hasLocalToMigrate) ...[
              GestureDetector(
                onTap: _migrateChatHistory,
                child: Container(
                  padding: const EdgeInsets.all(AppTheme.spacingMD),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.successColor.withValues(alpha: 0.2),
                        AppTheme.successColor.withValues(alpha: 0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppTheme.successColor.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.cloud_upload_rounded,
                          color: AppTheme.successColor),
                      const SizedBox(width: AppTheme.spacingMD),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Restore your chats',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.successColor,
                                  ),
                            ),
                            Text(
                              'Tap to import your guest conversations to your account',
                              style:
                                  Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded,
                          size: 14, color: AppTheme.successColor),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spacingLG),
            ],

            // Chat History button
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const ChatHistoryScreen()),
                ).then((_) => _loadHistoryCount());
              },
              child: Container(
                padding: const EdgeInsets.all(AppTheme.spacingMD),
                decoration: BoxDecoration(
                  gradient: AppTheme.cardGradient,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.textSecondary.withValues(alpha: 0.15),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.history_rounded,
                          color: AppTheme.primaryColor, size: 22),
                    ),
                    const SizedBox(width: AppTheme.spacingMD),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Chat History',
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            _historyCount > 0
                                ? '$_historyCount conversation${_historyCount != 1 ? 's' : ''}'
                                : 'View past conversations',
                            style:
                                Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    if (_historyCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$_historyCount',
                          style: const TextStyle(
                            color: AppTheme.backgroundColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    const SizedBox(width: AppTheme.spacingSM),
                    const Icon(Icons.arrow_forward_ios_rounded,
                        size: 14, color: AppTheme.textSecondary),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppTheme.spacingXL),

            Text(
              'Choose a Feature',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: AppTheme.spacingMD),

            ...List.generate(_features.length, (i) {
              return Padding(
                padding: const EdgeInsets.only(bottom: AppTheme.spacingMD),
                child: _buildFeatureCard(_features[i]),
              );
            }),

            const SizedBox(height: AppTheme.spacingLG),

            // Powered by badge
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingMD),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.primaryColor.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.bolt_rounded,
                      color: AppTheme.primaryColor),
                  const SizedBox(width: AppTheme.spacingMD),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Powered by Cerebras AI',
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                              ),
                        ),
                        Text(
                          'Ultra-fast inference for real-time fitness intelligence',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard(_AIFeature feature) {
    return GestureDetector(
      onTap: () => _navigateToFeature(feature),
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacingLG),
        decoration: BoxDecoration(
          gradient: AppTheme.cardGradient,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: feature.color.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: feature.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(feature.icon, color: feature.color, size: 28),
            ),
            const SizedBox(width: AppTheme.spacingMD),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    feature.title,
                    style:
                        Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                  ),
                  const SizedBox(height: AppTheme.spacingXS),
                  Text(
                    feature.description,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: feature.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: feature.color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AIFeature {
  final int id;
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final String route;

  const _AIFeature({
    required this.id,
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.route,
  });
}

