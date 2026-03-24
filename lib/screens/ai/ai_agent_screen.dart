import 'package:flutter/material.dart';
import '../../config/theme.dart';

/// AI Agent Features Screen
/// Provides AI-powered assistance for trainers and clients
class AIAgentScreen extends StatefulWidget {
  const AIAgentScreen({super.key});

  @override
  State<AIAgentScreen> createState() => _AIAgentScreenState();
}

class _AIAgentScreenState extends State<AIAgentScreen> {
  int _selectedFeature = -1;

  final List<_AIFeature> _features = [
    _AIFeature(
      id: 0,
      icon: Icons.chat_bubble_rounded,
      title: 'AI Coach Chat',
      description: 'Get instant answers about fitness, nutrition, and training plans from our AI coach.',
      color: AppTheme.primaryColor,
    ),
    _AIFeature(
      id: 1,
      icon: Icons.edit_note_rounded,
      title: 'Write My Bio',
      description: 'Let AI craft a compelling trainer bio based on your expertise and style.',
      color: AppTheme.accentColor,
    ),
    _AIFeature(
      id: 2,
      icon: Icons.description_rounded,
      title: 'Write Description',
      description: 'Generate engaging session descriptions that attract the right clients.',
      color: AppTheme.warningColor,
    ),
    _AIFeature(
      id: 3,
      icon: Icons.fitness_center_rounded,
      title: 'Generate Workout Plan',
      description: 'Create personalized workout plans tailored to client goals and fitness level.',
      color: AppTheme.secondaryColor,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Assistant'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppTheme.spacingLG),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(AppTheme.spacingXL),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [AppTheme.primaryGlow],
              ),
              child: Column(
                children: [
                  const Icon(Icons.auto_awesome_rounded,
                      size: 48, color: AppTheme.backgroundColor),
                  SizedBox(height: AppTheme.spacingMD),
                  Text(
                    'SPOTTER AI',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: AppTheme.backgroundColor,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 4,
                    ),
                  ),
                  SizedBox(height: AppTheme.spacingXS),
                  Text(
                    'Your intelligent fitness companion',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.backgroundColor.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: AppTheme.spacingXL),

            Text(
              'Choose a Feature',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            SizedBox(height: AppTheme.spacingMD),

            ...List.generate(_features.length, (i) {
              return Padding(
                padding: EdgeInsets.only(bottom: AppTheme.spacingMD),
                child: _buildFeatureCard(_features[i]),
              );
            }),

            SizedBox(height: AppTheme.spacingLG),

            // Coming soon banner
            Container(
              padding: EdgeInsets.all(AppTheme.spacingMD),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.primaryColor.withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.rocket_launch_rounded,
                      color: AppTheme.primaryColor),
                  SizedBox(width: AppTheme.spacingMD),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Powered by GPT-4',
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        Text(
                          'AI features coming in the next release. Stay tuned!',
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
    final isSelected = _selectedFeature == feature.id;

    return GestureDetector(
      onTap: () {
        setState(() => _selectedFeature = feature.id);
        _showComingSoon(feature.title);
      },
      child: AnimatedContainer(
        duration: AppTheme.fastAnimation,
        padding: EdgeInsets.all(AppTheme.spacingLG),
        decoration: BoxDecoration(
          gradient: isSelected ? AppTheme.cardGradient : null,
          color: isSelected ? null : AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? feature.color
                : AppTheme.textSecondary.withOpacity(0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: feature.color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(feature.icon, color: feature.color, size: 28),
            ),
            SizedBox(width: AppTheme.spacingMD),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    feature.title,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  SizedBox(height: AppTheme.spacingXS),
                  Text(
                    feature.description,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: isSelected ? feature.color : AppTheme.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature — Coming Soon! 🚀'),
        backgroundColor: AppTheme.surfaceColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

  const _AIFeature({
    required this.id,
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });
}
