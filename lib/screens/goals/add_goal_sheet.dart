import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/goals_service.dart';
import '../../models/goal_model.dart';
import '../../config/theme.dart';

class AddGoalSheet extends StatefulWidget {
  const AddGoalSheet({super.key});

  @override
  State<AddGoalSheet> createState() => _AddGoalSheetState();
}

class _AddGoalSheetState extends State<AddGoalSheet> {
  String? _selectedType;
  final _customLabelController = TextEditingController();
  int _targetValue = 3;
  String _targetPeriod = 'weekly';
  bool _isSubmitting = false;

  @override
  void dispose() {
    _customLabelController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selectedType == null) return;

    final userId = context.read<AuthProvider>().user?.id;
    if (userId == null) return;

    setState(() => _isSubmitting = true);

    final goalsService = context.read<GoalsService>();
    final result = await goalsService.createGoal(
      userId: userId,
      activityType: _selectedType!,
      customLabel: _selectedType == 'custom'
          ? _customLabelController.text.trim()
          : null,
      targetValue: _targetValue,
      targetPeriod: _targetPeriod,
    );

    setState(() => _isSubmitting = false);

    if (result != null && mounted) {
      HapticFeedback.heavyImpact();
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Text(
                'Add a Goal',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
            // Presets grid
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Choose an activity',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 12),
            _buildPresetsGrid(),
            // Custom label field
            if (_selectedType == 'custom') ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: TextField(
                  controller: _customLabelController,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Enter activity name...',
                    hintStyle: const TextStyle(color: AppTheme.textSecondary),
                    filled: true,
                    fillColor: AppTheme.surfaceColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            // Target value
            if (_selectedType != null) ...[
              const SizedBox(height: 16),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Set your target',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _buildTargetPicker(),
              const SizedBox(height: 16),
              // Period toggle
              _buildPeriodToggle(),
              const SizedBox(height: 24),
              // Submit
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryColor.withValues(alpha: 0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Add Goal',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPresetsGrid() {
    final presets = GoalModel.presetActivities;
    // Add custom option
    final allOptions = [
      ...presets,
      {
        'type': 'custom',
        'label': 'Custom',
        'defaultTarget': 1,
        'period': 'weekly'
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: allOptions.map((opt) {
          final type = opt['type'] as String;
          final label = opt['label'] as String;
          final isSelected = _selectedType == type;
          final emoji = GoalModel(
            id: '',
            userId: '',
            activityType: type,
            targetValue: 1,
            targetPeriod: 'weekly',
            createdAt: DateTime.now(),
          ).displayEmoji;

          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() {
                _selectedType = type;
                if (type != 'custom') {
                  _targetValue = opt['defaultTarget'] as int;
                  _targetPeriod = opt['period'] as String;
                }
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.primaryColor.withValues(alpha: 0.15)
                    : AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? AppTheme.primaryColor
                      : Colors.white.withValues(alpha: 0.05),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: TextStyle(
                      color: isSelected
                          ? AppTheme.primaryColor
                          : AppTheme.textPrimary,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTargetPicker() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const Text(
              'Target:',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
              ),
            ),
            const Spacer(),
            IconButton(
              onPressed: _targetValue > 1
                  ? () => setState(() => _targetValue--)
                  : null,
              icon: Icon(
                Icons.remove_circle_outline_rounded,
                color: _targetValue > 1
                    ? AppTheme.textPrimary
                    : AppTheme.textSecondary.withValues(alpha: 0.3),
              ),
            ),
            Container(
              width: 44,
              alignment: Alignment.center,
              child: Text(
                '$_targetValue',
                style: const TextStyle(
                  color: AppTheme.primaryColor,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Bebas Neue',
                ),
              ),
            ),
            IconButton(
              onPressed: _targetValue < 30
                  ? () => setState(() => _targetValue++)
                  : null,
              icon: Icon(
                Icons.add_circle_outline_rounded,
                color: _targetValue < 30
                    ? AppTheme.textPrimary
                    : AppTheme.textSecondary.withValues(alpha: 0.3),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodToggle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _targetPeriod = 'daily'),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: _targetPeriod == 'daily'
                        ? AppTheme.primaryColor
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      'Daily',
                      style: TextStyle(
                        color: _targetPeriod == 'daily'
                            ? Colors.white
                            : AppTheme.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _targetPeriod = 'weekly'),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: _targetPeriod == 'weekly'
                        ? AppTheme.primaryColor
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      'Weekly',
                      style: TextStyle(
                        color: _targetPeriod == 'weekly'
                            ? Colors.white
                            : AppTheme.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

