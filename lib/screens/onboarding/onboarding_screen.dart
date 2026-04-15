import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../config/theme.dart';
import '../../config/supabase_config.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isLoading = false;

  // Form State
  String? _fitnessLevel;
  final List<String> _goals = [];
  final List<String> _preferredSpecialties = [];
  String? _city;

  final List<String> _fitnessLevelOptions = ['Beginner', 'Intermediate', 'Advanced'];
  final List<String> _goalOptions = ['Weight Loss', 'Muscle Gain', 'Flexibility', 'Endurance', 'General Fitness', 'Rehab'];
  final List<String> _specialtyOptions = ['Yoga', 'HIIT', 'Strength', 'Pilates', 'Cardio', 'Zumba'];

  void _nextPage() {
    FocusScope.of(context).unfocus();
    if (_currentPage < 3) {
      _pageController.nextPage(
        duration: AppTheme.fastAnimation,
        curve: Curves.easeIn,
      );
    } else {
      _finishOnboarding();
    }
  }

  void _skipAction() {
    _finishOnboarding(skipped: true);
  }

  Future<void> _finishOnboarding({bool skipped = false}) async {
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.user;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      final updates = <String, dynamic>{
        'is_onboarded': true,
      };

      if (!skipped) {
        if (_fitnessLevel != null) updates['fitness_level'] = _fitnessLevel;
        if (_goals.isNotEmpty) updates['fitness_goals'] = _goals;
        if (_preferredSpecialties.isNotEmpty) updates['preferred_specialties'] = _preferredSpecialties;
        if (_city != null && _city!.isNotEmpty) updates['city'] = _city;
      }

      await SupabaseConfig.client
          .from('users')
          .update(updates)
          .eq('id', user.id);

      await authProvider.refreshUser(); // Updates the user model inside auth provider

      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save profile: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Identify role
    final role = context.watch<AuthProvider>().user?.role ?? 'client';
    
    // For trainers, we ideally redirect to the robust TrainerOnboardingScreen if they aren't onboarded, 
    // or we can embed similar logic. Given TrainerOnboardingScreen explicitly exists, 
    // we can use it to fulfill the trainer flow here.

    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Profile'),
        actions: [
          TextButton(
            onPressed: _skipAction,
            child: const Text('Skip'),
          ),
        ],
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: (idx) => setState(() => _currentPage = idx),
        children: [
          _buildQuestionPage(
            title: 'What is your current fitness level?',
            subtitle: 'This helps us find the right trainers and routines for you.',
            content: Column(
              children: _fitnessLevelOptions.map((level) => RadioListTile<String>(
                title: Text(level),
                value: level,
                groupValue: _fitnessLevel,
                onChanged: (val) {
                  setState(() => _fitnessLevel = val);
                },
                activeColor: AppTheme.primaryColor,
              )).toList(),
            ),
          ),
          _buildQuestionPage(
            title: 'What are your primary goals?',
            subtitle: 'Select all that apply.',
            content: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _goalOptions.map((goal) {
                final isSelected = _goals.contains(goal);
                return FilterChip(
                  label: Text(goal),
                  selected: isSelected,
                  onSelected: (val) {
                    setState(() {
                      if (val) {
                        _goals.add(goal);
                      } else {
                        _goals.remove(goal);
                      }
                    });
                  },
                  selectedColor: AppTheme.primaryColor.withValues(alpha: 0.2),
                );
              }).toList(),
            ),
          ),
          _buildQuestionPage(
            title: 'What training styles do you prefer?',
            subtitle: 'Select all that apply.',
            content: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _specialtyOptions.map((spec) {
                final isSelected = _preferredSpecialties.contains(spec);
                return FilterChip(
                  label: Text(spec),
                  selected: isSelected,
                  onSelected: (val) {
                    setState(() {
                      if (val) {
                        _preferredSpecialties.add(spec);
                      } else {
                        _preferredSpecialties.remove(spec);
                      }
                    });
                  },
                  selectedColor: AppTheme.primaryColor.withValues(alpha: 0.2),
                );
              }).toList(),
            ),
          ),
          _buildQuestionPage(
            title: 'Where do you live?',
            subtitle: 'So we can find nearby trainers.',
            content: TextFormField(
              initialValue: _city,
              decoration: const InputDecoration(
                labelText: 'City',
                prefixIcon: Icon(Icons.location_city_rounded),
              ),
              onChanged: (val) => _city = val,
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingLG),
          child: ElevatedButton(
            onPressed: () {
              // Basic validation check
              if (_currentPage == 0 && _fitnessLevel == null) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a fitness level')));
                return;
              }
              _nextPage();
            },
            child: Text(_currentPage == 3 ? 'Get Started' : 'Next'),
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionPage({
    required String title,
    required String subtitle,
    required Widget content,
  }) {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacingLG),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: AppTheme.spacingSM),
          Text(subtitle, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary)),
          const SizedBox(height: AppTheme.spacingXL),
          Expanded(child: SingleChildScrollView(child: content)),
        ],
      ),
    );
  }
}

