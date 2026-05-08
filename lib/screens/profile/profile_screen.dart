import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/auth_provider.dart';
import '../../services/profile_service.dart';
import '../../services/trainer_service.dart';
import '../../services/credits_service.dart';
import '../../services/booking_service.dart';
import '../../services/review_service.dart';
import '../../models/user_model.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';
import '../../utils/image_utils.dart';
import '../trainers/trainer_bookings_screen.dart';
import '../credits/credits_history_screen.dart';
import '../settings/settings_screen.dart';
import '../ai/ai_agent_screen.dart';
import '../credits/buy_credits_screen.dart';
import '../support/contact_support_screen.dart';
import '../auth/login_screen.dart';
import '../trainers/trainer_onboarding_screen.dart';
import '../trainers/saved_trainers_screen.dart';

class ProfileScreen extends StatefulWidget {
  final Function(int)? onNavigateTo;

  const ProfileScreen({super.key, this.onNavigateTo});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final ProfileService _profileService;
  late final CreditsService _creditsService;
  final ImagePicker _imagePicker = ImagePicker();
  
  UserModel? _user;
  Map<String, dynamic>? _trainerProfile;
  bool _isLoading = true;
  bool _isEditing = false;
  int _currentCredits = 0;

  // Controllers
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final _phoneController = TextEditingController();

  // Selected values
  String? _selectedGender;
  String? _selectedFitnessLevel;
  List<String> _selectedGoals = [];
  List<String> _selectedSpecialties = [];
  double _budgetMin = 1000;
  double _budgetMax = 5000;

  @override
  void initState() {
    super.initState();
    _profileService = context.read<ProfileService>();
    _creditsService = CreditsService();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      final user = await _profileService.getCurrentUserProfile();
      if (!mounted) return;
      int credits = 0;
      if (user != null) {
        final trainerService = context.read<TrainerService>();
        
        // Fetch all stats in parallel
        final results = await Future.wait([
          _creditsService.getUserCredits(user.id),
        ]);
        if (!mounted) return;
        credits = results[0] as int;

        if (user.role == 'trainer') {
          _trainerProfile = await trainerService.getTrainerByUserId(user.id);
        }
      }
      if (user != null) {
        setState(() {
          _user = user;
          _currentCredits = credits;
          _nameController.text = user.fullName;
          _bioController.text = user.bio ?? '';
          _phoneController.text = user.phone ?? '';
          _selectedGender = user.gender;
          _selectedFitnessLevel = user.fitnessLevel;
          _selectedGoals = List.from(user.fitnessGoals ?? []);
          _selectedSpecialties = List.from(user.preferredSpecialties ?? []);
          _budgetMin = (user.budgetMin ?? 1000).toDouble();
          _budgetMax = (user.budgetMax ?? 5000).toDouble();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profile: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    if (_user == null) return;

    setState(() => _isLoading = true);
    try {
      await _profileService.updateProfile(
        userId: _user!.id,
        fullName: _nameController.text,
        bio: _bioController.text.isEmpty ? null : _bioController.text,
        phone: _phoneController.text.isEmpty ? null : _phoneController.text,
        gender: _selectedGender,
        fitnessLevel: _selectedFitnessLevel,
        fitnessGoals: _selectedGoals,
        preferredSpecialties: _selectedSpecialties,
        budgetMin: _budgetMin.toInt(),
        budgetMax: _budgetMax.toInt(),
      );

      await _loadProfile();
      setState(() => _isEditing = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving profile: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 70,
    );

    if (image != null && _user != null) {
      setState(() => _isLoading = true);
      try {
        await _profileService.uploadAvatar(_user!.id, image.path);
        await _loadProfile();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile photo updated!'),
              backgroundColor: AppTheme.successColor,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error uploading image: $e')),
          );
        }
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _user == null
              ? _buildUnauthenticatedState()
              : _isEditing
                  ? _buildEditMode()
                  : _buildViewMode(),
    );
  }

  Widget _buildUnauthenticatedState() {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.backgroundColor,
      ),
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            floating: false,
            pinned: true,
            backgroundColor: AppTheme.backgroundColor,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppTheme.primaryColor.withValues(alpha: 0.2),
                      AppTheme.backgroundColor,
                    ],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.auto_awesome_rounded,
                          color: AppTheme.primaryColor,
                          size: 48,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              title: const Text(
                'SPOTTER PRO',
                style: TextStyle(
                  fontFamily: 'Bebas Neue',
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.textPrimary,
                  letterSpacing: 1.5,
                ),
              ),
              centerTitle: true,
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'AI-POWERED FITNESS',
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2.0,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Unlock your full potential with intelligent AI tools designed for your elite fitness journey.',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 16,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 48),
                  _buildAiFeatureItemLux(
                    icon: Icons.psychology_rounded,
                    title: 'Personal Motivator',
                    description: 'Get real-time psychological cues and habit-building strategies to stay consistent.',
                    gradient: const LinearGradient(colors: [Color(0xFFFF5C1A), Color(0xFFFF9E1A)]),
                  ),
                  const SizedBox(height: 32),
                  _buildAiFeatureItemLux(
                    icon: Icons.restaurant_menu_rounded,
                    title: 'Smart Nutritionist',
                    description: 'Instant macro-optimized meal plans based on what\'s in your fridge.',
                    gradient: const LinearGradient(colors: [Color(0xFF8A2BE2), Color(0xFF4B0082)]),
                  ),
                  const SizedBox(height: 32),
                  _buildAiFeatureItemLux(
                    icon: Icons.calendar_month_rounded,
                    title: 'Schedule Architect',
                    description: 'Dynamically adapts your training blocks when life gets busy.',
                    gradient: const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFDAA520)]),
                  ),
                  const SizedBox(height: 64),
                  Container(
                    width: double.infinity,
                    height: 64,
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryColor.withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text(
                        'GET STARTED NOW',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: TextButton(
                      onPressed: () {
                        // Navigate to AI explore
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AIAgentScreen()),
                        );
                      },
                      child: const Text(
                        'EXPLORE AI FEATURES →',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiFeatureItemLux({
    required IconData icon,
    required String title,
    required String description,
    required Gradient gradient,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: (gradient as LinearGradient).colors.first.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title.toUpperCase(),
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                description,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  Widget _buildViewMode() {
    return CustomScrollView(
      slivers: [
        _buildAppBar(),
        SliverToBoxAdapter(child: _buildProfileHeader()),
        SliverToBoxAdapter(child: _buildStats()),
        SliverToBoxAdapter(child: _buildInfoSection()),
        SliverToBoxAdapter(child: _buildPreferencesSection()),
        SliverToBoxAdapter(child: _buildActionsSection()),
        const SliverPadding(padding: EdgeInsets.only(bottom: 120)),
      ],
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 100,
      floating: false,
      pinned: true,
      backgroundColor: AppTheme.backgroundColor,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          'Profile',
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        centerTitle: false,
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.edit_rounded),
          onPressed: () => setState(() => _isEditing = true),
        ),
        const SizedBox(width: AppTheme.spacingSM),
      ],
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingLG),
      child: Column(
        children: [
          // Avatar
          Stack(
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(60),
                  boxShadow: [AppTheme.primaryGlow],
                ),
                padding: const EdgeInsets.all(4),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(56),
                  child: _user!.avatarUrl != null && _user!.avatarUrl!.isNotEmpty
                      ? Image.network(
                          corsProxyUrl(_user!.avatarUrl!),
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildProfileInitial(),
                        )
                      : _buildProfileInitial(),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [AppTheme.primaryGlow],
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      color: AppTheme.backgroundColor,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: AppTheme.spacingMD),
          
          // Name
          Text(
            _user!.fullName,
            style: Theme.of(context).textTheme.headlineLarge,
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: AppTheme.spacingXS),
          
          // Email
          Text(
            _user!.email,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          
          if (_user!.bio != null && _user!.bio!.isNotEmpty) ...[
            const SizedBox(height: AppTheme.spacingMD),
            Text(
              _user!.bio!,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProfileInitial() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(56),
      ),
      child: Center(
        child: Text(
          _user!.fullName.isNotEmpty ? _user!.fullName[0].toUpperCase() : '?',
          style: Theme.of(context).textTheme.displayLarge?.copyWith(
            color: AppTheme.primaryColor,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }

  Widget _buildStats() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLG),
      child: Column(
        children: [
          // Credits Banner
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const BuyCreditsScreen(),
                ),
              ).then((_) => _loadProfile());
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppTheme.spacingMD),
              decoration: BoxDecoration(
                gradient: AppTheme.cardGradient,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: AppTheme.primaryColor.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.account_balance_wallet_rounded,
                        color: AppTheme.primaryColor, size: 22),
                  ),
                  const SizedBox(width: AppTheme.spacingMD),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$_currentCredits Credit${_currentCredits != 1 ? 's' : ''}',
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        Text(
                          'Tap to buy more session credits',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded,
                      size: 14, color: AppTheme.textSecondary),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildInfoSection() {
    return Container(
      margin: const EdgeInsets.all(AppTheme.spacingLG),
      padding: const EdgeInsets.all(AppTheme.spacingLG),
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Personal Info',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: AppTheme.spacingMD),
          
          if (_user!.phone != null)
            _buildInfoRow(Icons.phone_rounded, 'Phone', _user!.phone!),
          
          if (_user!.gender != null)
            _buildInfoRow(Icons.person_rounded, 'Gender', _user!.gender!),
          
          if (_user!.fitnessLevel != null)
            _buildInfoRow(
              Icons.trending_up_rounded,
              'Fitness Level',
              _user!.fitnessLevel!.toUpperCase(),
            ),
          
          if (_user!.city != null)
            _buildInfoRow(Icons.location_on_rounded, 'Location', _user!.city!),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingMD),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppTheme.primaryColor, size: 20),
          ),
          const SizedBox(width: AppTheme.spacingMD),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreferencesSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLG),
      padding: const EdgeInsets.all(AppTheme.spacingLG),
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _user!.role == 'trainer' ? 'Trainer Professional Details' : 'Fitness Preferences',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: AppTheme.spacingMD),
          
          if (_user!.role == 'trainer' && _trainerProfile != null) ...[
            _buildInfoRow(Icons.monetization_on_rounded, 'Price per Session', '₹${_trainerProfile!['price_per_session'] ?? 500}'),
            if (_trainerProfile!['years_of_experience'] != null)
              _buildInfoRow(Icons.workspace_premium_rounded, 'Experience', '${_trainerProfile!['years_of_experience']} Years'),
            if (_trainerProfile!['specialties'] != null) ...[
              Text(
                'Specialties',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: AppTheme.spacingXS),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List<String>.from(_trainerProfile!['specialties']).map((specialty) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.accentColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      specialty,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.accentColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: AppTheme.spacingMD),
            ],
            if (_trainerProfile!['certifications'] != null) ...[
              Text(
                'Certifications',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: AppTheme.spacingXS),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List<String>.from(_trainerProfile!['certifications']).map((cert) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      cert,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: AppTheme.spacingMD),
            ]
          ] else ...[
            // Goals
          if (_user!.fitnessGoals != null && _user!.fitnessGoals!.isNotEmpty) ...[
            Text(
              'Goals',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: AppTheme.spacingXS),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _user!.fitnessGoals!.map((goal) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    goal,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: AppTheme.spacingMD),
          ],
          
          // Specialties
          if (_user!.preferredSpecialties != null && _user!.preferredSpecialties!.isNotEmpty) ...[
            Text(
              'Preferred Specialties',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: AppTheme.spacingXS),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _user!.preferredSpecialties!.map((specialty) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.accentColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    specialty,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.accentColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: AppTheme.spacingMD),
          ],
          
            // Budget
            Text(
              'Budget Range',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: AppTheme.spacingXS),
            Text(
              '₹${_user!.budgetMin ?? 1000} - ₹${_user!.budgetMax ?? 5000} per session',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionsSection() {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacingLG),
      child: Column(
        children: [
          // Show trainer schedule button if user is a trainer
          if (_user?.role == 'trainer') ...[
            _buildActionButton(
              icon: Icons.calendar_today_rounded,
              label: 'My Schedule (Trainer)',
              color: AppTheme.primaryColor,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TrainerBookingsScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: AppTheme.spacingSM),
            _buildActionButton(
              icon: Icons.manage_accounts_rounded,
              label: 'Edit Trainer Profile',
              color: AppTheme.accentColor,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TrainerOnboardingScreen(isEditing: true),
                  ),
                ).then((_) => _loadProfile());
              },
            ),
            const SizedBox(height: AppTheme.spacingSM),
          ],
          _buildActionButton(
            icon: Icons.settings_rounded,
            label: 'Settings',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
          const SizedBox(height: AppTheme.spacingSM),
          _buildActionButton(
            icon: Icons.receipt_long_rounded,
            label: 'Credit History',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CreditsHistoryScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: AppTheme.spacingSM),
        _buildActionButton(
            icon: Icons.help_outline_rounded,
            label: 'Help & Support',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ContactSupportScreen()),
              );
            },
          ),
          const SizedBox(height: AppTheme.spacingSM),
          _buildActionButton(
            icon: Icons.logout_rounded,
            label: 'Logout',
            color: AppTheme.errorColor,
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Logout'),
                  content: const Text('Are you sure you want to logout?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Logout'),
                    ),
                  ],
                ),
              );

              if (confirm == true && mounted) {
                await context.read<AuthProvider>().signOut();
                if (mounted) {
                  // Clear entire navigation stack and go to login
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                    (route) => false,
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacingMD),
        decoration: BoxDecoration(
          gradient: AppTheme.cardGradient,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, color: color ?? AppTheme.primaryColor),
            const SizedBox(width: AppTheme.spacingMD),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: color ?? AppTheme.textPrimary,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppTheme.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  // EDIT MODE - Next part coming...
  Widget _buildEditMode() {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          backgroundColor: AppTheme.backgroundColor,
          title: const Text('Edit Profile'),
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () {
              setState(() => _isEditing = false);
              _loadProfile(); // Reset changes
            },
          ),
          actions: [
            TextButton(
              onPressed: _saveProfile,
              child: const Text('Save'),
            ),
            const SizedBox(width: AppTheme.spacingSM),
          ],
        ),
        SliverPadding(
          padding: const EdgeInsets.all(AppTheme.spacingLG),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _buildEditForm(),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildEditForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Basic Info
        Text(
          'Basic Information',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: AppTheme.spacingMD),
        
        TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Full Name',
            prefixIcon: Icon(Icons.person_outline),
          ),
        ),
        
        const SizedBox(height: AppTheme.spacingMD),
        
        TextFormField(
          controller: _bioController,
          decoration: const InputDecoration(
            labelText: 'Bio',
            prefixIcon: Icon(Icons.info_outline),
          ),
          maxLines: 3,
        ),
        
        const SizedBox(height: AppTheme.spacingMD),
        
        TextFormField(
          controller: _phoneController,
          decoration: const InputDecoration(
            labelText: 'Phone',
            prefixIcon: Icon(Icons.phone_outlined),
          ),
          keyboardType: TextInputType.phone,
        ),
        
        const SizedBox(height: AppTheme.spacingXL),
        
        // Fitness Info
        Text(
          'Fitness Information',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: AppTheme.spacingMD),
        
        // Fitness Level
        DropdownButtonFormField<String>(
          initialValue: _selectedFitnessLevel,
          decoration: const InputDecoration(
            labelText: 'Fitness Level',
            prefixIcon: Icon(Icons.trending_up_rounded),
          ),
          items: ['beginner', 'intermediate', 'advanced'].map((level) {
            return DropdownMenuItem(
              value: level,
              child: Text(level.toUpperCase()),
            );
          }).toList(),
          onChanged: (value) {
            setState(() => _selectedFitnessLevel = value);
          },
        ),
        
        const SizedBox(height: AppTheme.spacingMD),
        
        // Gender
        DropdownButtonFormField<String>(
          initialValue: _selectedGender,
          decoration: const InputDecoration(
            labelText: 'Gender',
            prefixIcon: Icon(Icons.person_outline),
          ),
          items: ['male', 'female', 'other'].map((gender) {
            return DropdownMenuItem(
              value: gender,
              child: Text(gender.toUpperCase()),
            );
          }).toList(),
          onChanged: (value) {
            setState(() => _selectedGender = value);
          },
        ),
        
        const SizedBox(height: AppTheme.spacingXL),
        
        // Fitness Goals
        Text(
          'Fitness Goals',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: AppTheme.spacingSM),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: AppConstants.fitnessGoals.map((goal) {
            final isSelected = _selectedGoals.contains(goal);
            return GestureDetector(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _selectedGoals.remove(goal);
                  } else {
                    _selectedGoals.add(goal);
                  }
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primaryColor : AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  goal,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isSelected ? AppTheme.backgroundColor : AppTheme.textPrimary,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        
        const SizedBox(height: AppTheme.spacingXL),
        
        // Preferred Specialties
        Text(
          'Preferred Specialties',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: AppTheme.spacingSM),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: AppConstants.specialties.map((specialty) {
            final isSelected = _selectedSpecialties.contains(specialty);
            return GestureDetector(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _selectedSpecialties.remove(specialty);
                  } else {
                    _selectedSpecialties.add(specialty);
                  }
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.accentColor : AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? AppTheme.accentColor : AppTheme.textSecondary.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  specialty,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isSelected ? AppTheme.backgroundColor : AppTheme.textPrimary,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        
        const SizedBox(height: AppTheme.spacingXL),
        
        // Budget Range
        Text(
          'Budget Range: ₹${_budgetMin.toInt()} - ₹${_budgetMax.toInt()}',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: AppTheme.spacingSM),
        RangeSlider(
          values: RangeValues(_budgetMin, _budgetMax),
          min: AppConstants.minPrice.toDouble(),
          max: AppConstants.maxPrice.toDouble(),
          divisions: 40,
          activeColor: AppTheme.primaryColor,
          inactiveColor: AppTheme.textSecondary.withValues(alpha: 0.2),
          labels: RangeLabels(
            '₹${_budgetMin.toInt()}',
            '₹${_budgetMax.toInt()}',
          ),
          onChanged: (values) {
            setState(() {
              _budgetMin = values.start;
              _budgetMax = values.end;
            });
          },
        ),
        
        const SizedBox(height: AppTheme.spacingXXL),
      ],
    );
  }
}
