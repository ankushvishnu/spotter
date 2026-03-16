import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/auth_provider.dart';
import '../../services/profile_service.dart';
import '../../models/user_model.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';
import '../trainers/trainer_bookings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ProfileService _profileService = ProfileService();
  final ImagePicker _imagePicker = ImagePicker();
  
  UserModel? _user;
  bool _isLoading = true;
  bool _isEditing = false;

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
      if (user != null) {
        setState(() {
          _user = user;
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
              ? _buildErrorState()
              : _isEditing
                  ? _buildEditMode()
                  : _buildViewMode(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 64,
            color: AppTheme.textSecondary.withOpacity(0.5),
          ),
          SizedBox(height: AppTheme.spacingMD),
          Text(
            'Error Loading Profile',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          SizedBox(height: AppTheme.spacingSM),
          TextButton(
            onPressed: _loadProfile,
            child: const Text('Retry'),
          ),
        ],
      ),
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
        const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
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
        SizedBox(width: AppTheme.spacingSM),
      ],
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: EdgeInsets.all(AppTheme.spacingLG),
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
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceColor,
                    borderRadius: BorderRadius.circular(56),
                  ),
                  child: Center(
                    child: Text(
                      _user!.fullName[0].toUpperCase(),
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
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
          
          SizedBox(height: AppTheme.spacingMD),
          
          // Name
          Text(
            _user!.fullName,
            style: Theme.of(context).textTheme.headlineLarge,
            textAlign: TextAlign.center,
          ),
          
          SizedBox(height: AppTheme.spacingXS),
          
          // Email
          Text(
            _user!.email,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          
          if (_user!.bio != null && _user!.bio!.isNotEmpty) ...[
            SizedBox(height: AppTheme.spacingMD),
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

  Widget _buildStats() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppTheme.spacingLG),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              icon: Icons.fitness_center_rounded,
              value: '0',
              label: 'Sessions',
            ),
          ),
          SizedBox(width: AppTheme.spacingSM),
          Expanded(
            child: _buildStatCard(
              icon: Icons.star_rounded,
              value: '0',
              label: 'Reviews',
            ),
          ),
          SizedBox(width: AppTheme.spacingSM),
          Expanded(
            child: _buildStatCard(
              icon: Icons.bookmark_rounded,
              value: '0',
              label: 'Saved',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Container(
      padding: EdgeInsets.all(AppTheme.spacingMD),
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppTheme.primaryColor, size: 24),
          SizedBox(height: AppTheme.spacingXS),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection() {
    return Container(
      margin: EdgeInsets.all(AppTheme.spacingLG),
      padding: EdgeInsets.all(AppTheme.spacingLG),
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
          SizedBox(height: AppTheme.spacingMD),
          
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
      padding: EdgeInsets.only(bottom: AppTheme.spacingMD),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppTheme.primaryColor, size: 20),
          ),
          SizedBox(width: AppTheme.spacingMD),
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
      margin: EdgeInsets.symmetric(horizontal: AppTheme.spacingLG),
      padding: EdgeInsets.all(AppTheme.spacingLG),
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Fitness Preferences',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          SizedBox(height: AppTheme.spacingMD),
          
          // Goals
          if (_user!.fitnessGoals != null && _user!.fitnessGoals!.isNotEmpty) ...[
            Text(
              'Goals',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
            SizedBox(height: AppTheme.spacingXS),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _user!.fitnessGoals!.map((goal) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.2),
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
            SizedBox(height: AppTheme.spacingMD),
          ],
          
          // Specialties
          if (_user!.preferredSpecialties != null && _user!.preferredSpecialties!.isNotEmpty) ...[
            Text(
              'Preferred Specialties',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
            SizedBox(height: AppTheme.spacingXS),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _user!.preferredSpecialties!.map((specialty) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.accentColor.withOpacity(0.2),
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
            SizedBox(height: AppTheme.spacingMD),
          ],
          
          // Budget
          Text(
            'Budget Range',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          SizedBox(height: AppTheme.spacingXS),
          Text(
            '₹${_user!.budgetMin ?? 1000} - ₹${_user!.budgetMax ?? 5000} per session',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsSection() {
    return Padding(
      padding: EdgeInsets.all(AppTheme.spacingLG),
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
            SizedBox(height: AppTheme.spacingSM),
          ],
          _buildActionButton(
            icon: Icons.settings_rounded,
            label: 'Settings',
            onTap: () {
              // TODO: Navigate to settings
            },
          ),
          SizedBox(height: AppTheme.spacingSM),
          _buildActionButton(
            icon: Icons.help_outline_rounded,
            label: 'Help & Support',
            onTap: () {
              // TODO: Navigate to help
            },
          ),
          SizedBox(height: AppTheme.spacingSM),
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
        padding: EdgeInsets.all(AppTheme.spacingMD),
        decoration: BoxDecoration(
          gradient: AppTheme.cardGradient,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, color: color ?? AppTheme.primaryColor),
            SizedBox(width: AppTheme.spacingMD),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: color ?? AppTheme.textPrimary,
                ),
              ),
            ),
            Icon(
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
            SizedBox(width: AppTheme.spacingSM),
          ],
        ),
        SliverPadding(
          padding: EdgeInsets.all(AppTheme.spacingLG),
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
        SizedBox(height: AppTheme.spacingMD),
        
        TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Full Name',
            prefixIcon: Icon(Icons.person_outline),
          ),
        ),
        
        SizedBox(height: AppTheme.spacingMD),
        
        TextFormField(
          controller: _bioController,
          decoration: const InputDecoration(
            labelText: 'Bio',
            prefixIcon: Icon(Icons.info_outline),
          ),
          maxLines: 3,
        ),
        
        SizedBox(height: AppTheme.spacingMD),
        
        TextFormField(
          controller: _phoneController,
          decoration: const InputDecoration(
            labelText: 'Phone',
            prefixIcon: Icon(Icons.phone_outlined),
          ),
          keyboardType: TextInputType.phone,
        ),
        
        SizedBox(height: AppTheme.spacingXL),
        
        // Fitness Info
        Text(
          'Fitness Information',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        SizedBox(height: AppTheme.spacingMD),
        
        // Fitness Level
        DropdownButtonFormField<String>(
          value: _selectedFitnessLevel,
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
        
        SizedBox(height: AppTheme.spacingMD),
        
        // Gender
        DropdownButtonFormField<String>(
          value: _selectedGender,
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
        
        SizedBox(height: AppTheme.spacingXL),
        
        // Fitness Goals
        Text(
          'Fitness Goals',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        SizedBox(height: AppTheme.spacingSM),
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
                    color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary.withOpacity(0.3),
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
        
        SizedBox(height: AppTheme.spacingXL),
        
        // Preferred Specialties
        Text(
          'Preferred Specialties',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        SizedBox(height: AppTheme.spacingSM),
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
                    color: isSelected ? AppTheme.accentColor : AppTheme.textSecondary.withOpacity(0.3),
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
        
        SizedBox(height: AppTheme.spacingXL),
        
        // Budget Range
        Text(
          'Budget Range: ₹${_budgetMin.toInt()} - ₹${_budgetMax.toInt()}',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        SizedBox(height: AppTheme.spacingSM),
        RangeSlider(
          values: RangeValues(_budgetMin, _budgetMax),
          min: AppConstants.minPrice.toDouble(),
          max: AppConstants.maxPrice.toDouble(),
          divisions: 40,
          activeColor: AppTheme.primaryColor,
          inactiveColor: AppTheme.textSecondary.withOpacity(0.2),
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
        
        SizedBox(height: AppTheme.spacingXXL),
      ],
    );
  }
}