import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/auth_provider.dart';
import '../../config/theme.dart';
import '../../config/supabase_config.dart';

/// Full Trainer Onboarding/Profile Setup Screen
/// Covers all fields from feature points.md
class TrainerOnboardingScreen extends StatefulWidget {
  /// Set to true when editing existing profile, false for first-time setup
  final bool isEditing;
  /// Called after profile is saved (used by AuthWrapper for first-time flow)
  final VoidCallback? onComplete;

  const TrainerOnboardingScreen({super.key, this.isEditing = false, this.onComplete});

  @override
  State<TrainerOnboardingScreen> createState() =>
      _TrainerOnboardingScreenState();
}

class _TrainerOnboardingScreenState extends State<TrainerOnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _supabase = SupabaseConfig.client;
  bool _isLoading = false;
  int _currentStep = 0;

  // --- Tier selection removed — trainers set own pricing freely ---
  // Tier is now managed via the Membership page (users.tier)

  // --- Basic Info ---
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final _phoneController = TextEditingController();
  DateTime? _dateOfBirth;
  String? _selectedGender;

  // --- Professional Details ---
  final _experienceController = TextEditingController();
  final _credentialsController = TextEditingController();
  final _membershipsController = TextEditingController();
  final _priceController = TextEditingController();
  final List<String> _certificates = [];
  final _certificateController = TextEditingController();
  final List<XFile> _certificateFiles = [];
  final _imagePicker = ImagePicker();

  // --- Specialties / Categories ---
  final List<String> _allCategories = [
    'Gym', 'Weight Gain', 'Weight Loss', 'Yoga', 'Pilates',
    'Meditation', 'Running', 'Swimming', 'Cycling', 'Boxing',
    'Kickboxing', 'Spinning', 'Zumba', 'Aerobics', 'Dance',
    'Kids Training', 'HIIT', 'Crossfit', 'Bodybuilding',
    'Strength Training', 'Calisthenics', 'MMA', 'Karate', 'Judo',
    'Taekwondo', 'Muay Thai', 'Jiu-Jitsu', 'Gymnastics',
    'Home Training', 'Dance Trainer', 'Mall Khamb',
  ];
  final List<String> _selectedCategories = [];

  // --- Preferences ---
  String? _selectedDemographic; // e.g., teens, adults, seniors
  String? _selectedRange; // e.g., 2km, 5km, 10km+
  String? _selectedTrainingMode; // e.g., online, in-person, both

  // --- Location ---
  final _gymNameController = TextEditingController();
  final _locationController = TextEditingController();
  final List<String> _preferredTimeSlots = [];
  final List<String> _allTimeSlots = [
    'Early Morning (5–7 AM)', 'Morning (7–9 AM)', 'Mid-Morning (9–11 AM)',
    'Noon (11 AM–1 PM)', 'Afternoon (1–4 PM)',
    'Evening (4–7 PM)', 'Night (7–10 PM)',
  ];

  static const List<String> _genderOptions = ['Male', 'Female', 'Other', 'Prefer not to say'];
  static const List<String> _demographicOptions = ['Kids (5–12)', 'Teens (13–17)', 'Adults (18–45)', 'Seniors (45+)', 'All Ages'];
  static const List<String> _rangeOptions = ['2 km', '5 km', '10 km', '15 km', '20+ km', 'Online Only'];
  static const List<String> _trainingModeOptions = ['In-Person', 'Online', 'Both'];

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _phoneController.dispose();
    _experienceController.dispose();
    _credentialsController.dispose();
    _membershipsController.dispose();
    _priceController.dispose();
    _certificateController.dispose();
    _gymNameController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickCertificateFile() async {
    try {
      final pickedFile = await _imagePicker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _certificateFiles.add(pickedFile);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick document: $e')),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please fill out all required fields first'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
      return;
    }

    final userId = context.read<AuthProvider>().user?.id;
    if (userId == null) return;

    setState(() => _isLoading = true);
    try {
      // 1. Update the users table with basic info
      await _supabase.from('users').update({
        'full_name': _nameController.text.trim(),
        'bio': _bioController.text.trim().isEmpty ? null : _bioController.text.trim(),
        'phone': _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        'gender': _selectedGender?.toLowerCase(),
        'date_of_birth': _dateOfBirth?.toIso8601String().split('T').first,
        'city': _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);

      // 2. Build certifications list (combine credentials text + explicit certs)
      final List<String> allCertifications = [
        ..._certificates,
        if (_credentialsController.text.trim().isNotEmpty)
          _credentialsController.text.trim(),
        if (_membershipsController.text.trim().isNotEmpty)
          _membershipsController.text.trim(),
      ];

      // 3. Determine pricing (trainer sets their own price)
      final int pricePerSession = int.tryParse(_priceController.text) ?? 500;

      // 4. Upsert trainer record
      final trainerData = await _supabase.from('trainers').upsert({
        'user_id': userId,
        'specialties': _selectedCategories.map((c) => c.toLowerCase()).toList(),
        'years_of_experience': int.tryParse(_experienceController.text),
        'certifications': allCertifications.isEmpty ? null : allCertifications,
        'price_per_session': pricePerSession,
        'gym_affiliations': _gymNameController.text.trim().isEmpty
            ? null
            : [_gymNameController.text.trim()],
        'service_locations': _locationController.text.trim().isEmpty
            ? null
            : [_locationController.text.trim()],
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id').select('id').single();

      final trainerId = trainerData['id'] as String;

      // 5. Upload certificate files if any
      for (var file in _certificateFiles) {
        final fileName = 'cert_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final filePath = '$trainerId/$fileName';
        
        final bytes = await file.readAsBytes();
        await _supabase.storage.from('certificates').uploadBinary(
          filePath, 
          bytes,
        );
        final publicUrl = _supabase.storage.from('certificates').getPublicUrl(filePath);
        
        await _supabase.from('trainer_certifications').insert({
          'trainer_id': trainerId,
          'certification_name': 'Uploaded Document', 
          'document_url': publicUrl,
          'document_type': 'image',
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.isEditing
                ? 'Profile updated! ✅'
                : 'Profile created! Pending admin verification. ✅'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        if (widget.onComplete != null) {
          widget.onComplete!();
        } else {
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving profile: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Trainer Profile' : 'Create Trainer Profile'),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: Stepper(
          currentStep: _currentStep,
          onStepTapped: (step) => setState(() => _currentStep = step),
          onStepContinue: () {
            if (_currentStep < 3) {
              setState(() => _currentStep++);
            } else {
              _saveProfile();
            }
          },
          onStepCancel: () {
            if (_currentStep > 0) setState(() => _currentStep--);
          },
          controlsBuilder: (context, details) {
            return Padding(
              padding: const EdgeInsets.only(top: AppTheme.spacingMD),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : details.onStepContinue,
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(_currentStep < 3 ? 'Next' : 'Save Profile'),
                    ),
                  ),
                  if (_currentStep > 0) ...
                  [
                    const SizedBox(width: AppTheme.spacingSM),
                    OutlinedButton(
                      onPressed: details.onStepCancel,
                      child: const Text('Back'),
                    ),
                  ],
                ],
              ),
            );
          },
          steps: [
            Step(
              title: const Text('Basic Info'),
              isActive: _currentStep >= 0,
              content: _buildBasicInfoStep(),
            ),
            Step(
              title: const Text('Professional'),
              isActive: _currentStep >= 1,
              content: _buildProfessionalStep(),
            ),
            Step(
              title: const Text('Specialties'),
              isActive: _currentStep >= 2,
              content: _buildSpecialtiesStep(),
            ),
            Step(
              title: const Text('Location & Slots'),
              isActive: _currentStep >= 3,
              content: _buildLocationStep(),
            ),
          ],
        ),
      ),
    );
  }

  // ── Step 1: Basic Info ────────────────────────────────────────────────────
  Widget _buildBasicInfoStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Full Name *',
            prefixIcon: Icon(Icons.person_outline),
          ),
          validator: (v) => v == null || v.isEmpty ? 'Required' : null,
        ),
        const SizedBox(height: AppTheme.spacingMD),

        TextFormField(
          controller: _bioController,
          maxLines: 3,
          maxLength: 300,
          decoration: const InputDecoration(
            labelText: 'Bio / About You',
            hintText: 'Tell clients about your training style...',
            prefixIcon: Icon(Icons.info_outline),
          ),
        ),
        const SizedBox(height: AppTheme.spacingMD),

        TextFormField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: 'Phone Number (masked to clients)',
            prefixIcon: Icon(Icons.phone_outlined),
          ),
        ),
        const SizedBox(height: AppTheme.spacingMD),

        // Date of Birth
        GestureDetector(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: DateTime(1990),
              firstDate: DateTime(1940),
              lastDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
            );
            if (picked != null) setState(() => _dateOfBirth = picked);
          },
          child: Container(
            padding: const EdgeInsets.all(AppTheme.spacingMD),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.cake_rounded, color: AppTheme.primaryColor),
                const SizedBox(width: AppTheme.spacingMD),
                Text(
                  _dateOfBirth != null
                      ? 'Born: ${_dateOfBirth!.day}/${_dateOfBirth!.month}/${_dateOfBirth!.year}'
                      : 'Date of Birth (tap to select)',
                  style: _dateOfBirth != null
                      ? Theme.of(context).textTheme.bodyLarge
                      : Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppTheme.spacingMD),

        DropdownButtonFormField<String>(
          initialValue: _selectedGender,
          decoration: const InputDecoration(
            labelText: 'Gender',
            prefixIcon: Icon(Icons.wc_rounded),
          ),
          items: _genderOptions
              .map((g) => DropdownMenuItem(value: g, child: Text(g)))
              .toList(),
          onChanged: (v) => setState(() => _selectedGender = v),
        ),
      ],
    );
  }

  // ── Step 2: Professional Details ─────────────────────────────────────────
  Widget _buildProfessionalStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _experienceController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Years of Experience',
            prefixIcon: Icon(Icons.workspace_premium_rounded),
          ),
        ),
        const SizedBox(height: AppTheme.spacingXL),

        // ── Price per Session ────────────────────────────────────────
        Text('Set Your Price', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: AppTheme.spacingSM),
        Text(
          'Set your own price per session. You can change this anytime.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: AppTheme.spacingMD),

        TextFormField(
          controller: _priceController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Price per Session (₹) *',
            hintText: 'e.g., 500, 1000, 2000',
            prefixIcon: Icon(Icons.currency_rupee_rounded),
          ),
          validator: (v) {
            if (v == null || v.isEmpty) return 'Please enter your price per session';
            if (int.tryParse(v) == null || int.parse(v) <= 0) {
              return 'Enter a valid price';
            }
            return null;
          },
        ),
        const SizedBox(height: AppTheme.spacingMD),

        TextFormField(
          controller: _credentialsController,
          decoration: const InputDecoration(
            labelText: 'Credentials / Qualifications',
            hintText: 'e.g., ACE CPT, NASM, B.Sc Sports Science',
            prefixIcon: Icon(Icons.school_rounded),
          ),
        ),
        const SizedBox(height: AppTheme.spacingMD),

        TextFormField(
          controller: _membershipsController,
          decoration: const InputDecoration(
            labelText: 'Professional Memberships',
            hintText: 'e.g., ACSM, NSCA member',
            prefixIcon: Icon(Icons.card_membership_rounded),
          ),
        ),
        const SizedBox(height: AppTheme.spacingXL),

        // Certificates input list
        Text('Certifications', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: AppTheme.spacingSM),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _certificateController,
                decoration: const InputDecoration(
                  hintText: 'Add a certificate...',
                  prefixIcon: Icon(Icons.add_circle_outline),
                ),
              ),
            ),
            const SizedBox(width: AppTheme.spacingSM),
            IconButton(
              onPressed: () {
                final cert = _certificateController.text.trim();
                if (cert.isNotEmpty) {
                  setState(() {
                    _certificates.add(cert);
                    _certificateController.clear();
                  });
                }
              },
              icon: const Icon(Icons.check_circle_rounded, color: AppTheme.primaryColor, size: 32),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacingSM),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _certificates.map((cert) {
            return Chip(
              label: Text(cert),
              deleteIcon: const Icon(Icons.close, size: 16),
              onDeleted: () => setState(() => _certificates.remove(cert)),
              backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.15),
              labelStyle: const TextStyle(color: AppTheme.primaryColor),
            );
          }).toList(),
        ),

        // ── Certificate Document Upload ──
        const SizedBox(height: AppTheme.spacingXL),
        Text('Certificate Documents', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: AppTheme.spacingSM),
        Text('Upload photos of your certifications (optional)', style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: AppTheme.spacingMD),
        OutlinedButton.icon(
          onPressed: _pickCertificateFile,
          icon: const Icon(Icons.upload_file_rounded),
          label: const Text('Upload Document'),
        ),
        if (_certificateFiles.isNotEmpty) ...[
          const SizedBox(height: AppTheme.spacingMD),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _certificateFiles.map((file) {
              final fileName = file.name;
              return Chip(
                label: Text(fileName, overflow: TextOverflow.ellipsis, maxLines: 1),
                deleteIcon: const Icon(Icons.close, size: 16),
                onDeleted: () => setState(() => _certificateFiles.remove(file)),
                backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.15),
                labelStyle: const TextStyle(color: AppTheme.primaryColor, fontSize: 12),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  // ── Step 3: Specialties / Categories ─────────────────────────────────────
  static const int _maxSpecialties = 5;

  Widget _buildSpecialtiesStep() {
    final selectedCount = _selectedCategories.length;
    final atMax = selectedCount >= _maxSpecialties;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with counter
        Row(
          children: [
            Expanded(
              child: Text(
                'Select your specialties',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: atMax
                    ? AppTheme.primaryColor.withValues(alpha: 0.15)
                    : AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: atMax
                      ? AppTheme.primaryColor
                      : AppTheme.textSecondary.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                '$selectedCount / $_maxSpecialties',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: atMax ? AppTheme.primaryColor : AppTheme.textSecondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacingXS),
        Text(
          'Choose up to $_maxSpecialties specialties that best describe your training expertise.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: AppTheme.spacingMD),

        // Category chips
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _allCategories.map((cat) {
            final isSelected = _selectedCategories.contains(cat);
            final isDisabled = !isSelected && atMax;
            return FilterChip(
              label: Text(cat),
              selected: isSelected,
              onSelected: isDisabled
                  ? null
                  : (selected) {
                      if (selected && _selectedCategories.length >= _maxSpecialties) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'You can select up to $_maxSpecialties specialties only.',
                            ),
                            duration: Duration(seconds: 2),
                          ),
                        );
                        return;
                      }
                      setState(() {
                        if (selected) {
                          _selectedCategories.add(cat);
                        } else {
                          _selectedCategories.remove(cat);
                        }
                      });
                    },
              selectedColor: AppTheme.primaryColor.withValues(alpha: 0.25),
              checkmarkColor: AppTheme.primaryColor,
              labelStyle: TextStyle(
                color: isDisabled
                    ? AppTheme.textSecondary.withValues(alpha: 0.4)
                    : isSelected
                        ? AppTheme.primaryColor
                        : AppTheme.textPrimary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              side: BorderSide(
                color: isSelected
                    ? AppTheme.primaryColor
                    : AppTheme.textSecondary.withValues(alpha: isDisabled ? 0.15 : 0.3),
              ),
              backgroundColor: isDisabled
                  ? AppTheme.surfaceColor.withValues(alpha: 0.5)
                  : AppTheme.surfaceColor,
            );
          }).toList(),
        ),
        const SizedBox(height: AppTheme.spacingMD),

        // Preferences
        DropdownButtonFormField<String>(
          initialValue: _selectedDemographic,
          decoration: const InputDecoration(
            labelText: 'Target Demographic',
            prefixIcon: Icon(Icons.people_rounded),
          ),
          items: _demographicOptions
              .map((d) => DropdownMenuItem(value: d, child: Text(d)))
              .toList(),
          onChanged: (v) => setState(() => _selectedDemographic = v),
        ),
        const SizedBox(height: AppTheme.spacingMD),

        DropdownButtonFormField<String>(
          initialValue: _selectedTrainingMode,
          decoration: const InputDecoration(
            labelText: 'Training Mode / Preference',
            prefixIcon: Icon(Icons.play_circle_outline_rounded),
          ),
          items: _trainingModeOptions
              .map((m) => DropdownMenuItem(value: m, child: Text(m)))
              .toList(),
          onChanged: (v) => setState(() => _selectedTrainingMode = v),
        ),
      ],
    );
  }

  // ── Step 4: Location & Time Slots ─────────────────────────────────────────
  Widget _buildLocationStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _locationController,
          decoration: const InputDecoration(
            labelText: 'City / Area',
            prefixIcon: Icon(Icons.location_on_rounded),
          ),
        ),
        const SizedBox(height: AppTheme.spacingMD),

        TextFormField(
          controller: _gymNameController,
          decoration: const InputDecoration(
            labelText: 'Preferred Gym (optional)',
            hintText: 'e.g., Gold\'s Gym, Cult.fit',
            prefixIcon: Icon(Icons.fitness_center_rounded),
          ),
        ),
        const SizedBox(height: AppTheme.spacingMD),

        DropdownButtonFormField<String>(
          initialValue: _selectedRange,
          decoration: const InputDecoration(
            labelText: 'Travel Range / Distance',
            prefixIcon: Icon(Icons.social_distance_rounded),
          ),
          items: _rangeOptions
              .map((r) => DropdownMenuItem(value: r, child: Text(r)))
              .toList(),
          onChanged: (v) => setState(() => _selectedRange = v),
        ),
        const SizedBox(height: AppTheme.spacingXL),

        Text('Preferred Time Slots', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: AppTheme.spacingSM),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _allTimeSlots.map((slot) {
            final isSelected = _preferredTimeSlots.contains(slot);
            return FilterChip(
              label: Text(slot, style: const TextStyle(fontSize: 12)),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _preferredTimeSlots.add(slot);
                  } else {
                    _preferredTimeSlots.remove(slot);
                  }
                });
              },
              selectedColor: AppTheme.accentColor.withValues(alpha: 0.2),
              checkmarkColor: AppTheme.accentColor,
              labelStyle: TextStyle(
                color: isSelected ? AppTheme.accentColor : AppTheme.textPrimary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              side: BorderSide(
                color: isSelected
                    ? AppTheme.accentColor
                    : AppTheme.textSecondary.withValues(alpha: 0.3),
              ),
              backgroundColor: AppTheme.surfaceColor,
            );
          }).toList(),
        ),
      ],
    );
  }
}

