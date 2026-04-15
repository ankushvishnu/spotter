import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/goals_service.dart';
import '../../models/goal_model.dart';
import '../../config/theme.dart';
import 'add_goal_sheet.dart';

class MyGoalsScreen extends StatefulWidget {
  const MyGoalsScreen({super.key});

  @override
  State<MyGoalsScreen> createState() => _MyGoalsScreenState();
}

class _MyGoalsScreenState extends State<MyGoalsScreen>
    with SingleTickerProviderStateMixin {
  late final GoalsService _goalsService;
  List<GoalModel> _goals = [];
  List<int> _dailyBreakdown = List.filled(7, 0);
  int _streak = 0;
  bool _isLoading = true;

  late AnimationController _streakAnimCtrl;

  @override
  void initState() {
    super.initState();
    _goalsService = context.read<GoalsService>();
    _streakAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _loadData();
  }

  @override
  void dispose() {
    _streakAnimCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final userId = context.read<AuthProvider>().user?.id;
    if (userId == null) return;

    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _goalsService.getGoalsWithProgress(userId),
        _goalsService.getCurrentStreak(userId),
        _goalsService.getWeeklyDailyBreakdown(userId),
      ]);

      if (mounted) {
        setState(() {
          _goals = results[0] as List<GoalModel>;
          _streak = results[1] as int;
          _dailyBreakdown = results[2] as List<int>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleActivity(GoalModel goal) async {
    HapticFeedback.mediumImpact();
    final userId = context.read<AuthProvider>().user?.id;
    if (userId == null) return;

    if (goal.isCompletedToday) {
      await _goalsService.unlogActivity(
        goalId: goal.id,
        userId: userId,
      );
    } else {
      await _goalsService.logActivity(
        goalId: goal.id,
        userId: userId,
      );
    }
    _loadData();
  }

  Future<void> _deleteGoal(GoalModel goal) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        title: const Text('Remove Goal?'),
        content: Text('Remove "${goal.displayName}" from your goals?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _goalsService.deleteGoal(goal.id);
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.primaryColor,
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadData,
                      color: AppTheme.primaryColor,
                      child: ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        children: [
                          const SizedBox(height: 8),
                          if (_streak > 0) _buildStreakBanner(),
                          const SizedBox(height: 20),
                          _buildWeeklyChart(),
                          const SizedBox(height: 24),
                          _buildGoalsList(),
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildAddGoalFAB(),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'My Goals',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'This Week',
              style: TextStyle(
                color: AppTheme.primaryColor,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakBanner() {
    return AnimatedBuilder(
      animation: _streakAnimCtrl,
      builder: (context, child) {
        final scale = 1.0 + (_streakAnimCtrl.value * 0.05);
        return Transform.scale(
          scale: scale,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryColor.withValues(alpha: 0.2),
                  AppTheme.accentColor.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppTheme.primaryColor.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                const Text('🔥', style: TextStyle(fontSize: 32)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$_streak day streak!',
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Text(
                        'Keep the momentum going 💪',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWeeklyChart() {
    final dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final today = DateTime.now().weekday - 1; // 0 = Monday
    final maxVal = _dailyBreakdown.reduce((a, b) => a > b ? a : b);
    final maxHeight = maxVal > 0 ? maxVal.toDouble() : 1.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Weekly Activity',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '${_dailyBreakdown.fold<int>(0, (s, v) => s + v)} total',
                style: const TextStyle(
                  color: AppTheme.primaryColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 120,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (i) {
                final isToday = i == today;
                final barHeight = maxVal > 0
                    ? (_dailyBreakdown[i] / maxHeight) * 80 + 8
                    : 8.0;
                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (_dailyBreakdown[i] > 0)
                      Text(
                        '${_dailyBreakdown[i]}',
                        style: TextStyle(
                          color: isToday
                              ? AppTheme.primaryColor
                              : AppTheme.textSecondary,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    const SizedBox(height: 4),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeOutCubic,
                      width: 28,
                      height: barHeight,
                      decoration: BoxDecoration(
                        color: isToday
                            ? AppTheme.primaryColor
                            : _dailyBreakdown[i] > 0
                                ? AppTheme.primaryColor.withValues(alpha: 0.3)
                                : Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: isToday && _dailyBreakdown[i] > 0
                            ? [
                                BoxShadow(
                                  color: AppTheme.primaryColor.withValues(alpha: 0.4),
                                  blurRadius: 8,
                                ),
                              ]
                            : null,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      dayLabels[i],
                      style: TextStyle(
                        color: isToday
                            ? AppTheme.primaryColor
                            : AppTheme.textSecondary,
                        fontSize: 12,
                        fontWeight:
                            isToday ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalsList() {
    if (_goals.isEmpty) {
      return _buildEmptyGoals();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Your Goals',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 16),
        ..._goals.map((goal) => _buildGoalCard(goal)),
      ],
    );
  }

  Widget _buildGoalCard(GoalModel goal) {
    final dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final today = DateTime.now().weekday - 1;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: goal.isCompletedToday
              ? goal.displayColor.withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Icon circle
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: goal.displayColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(goal.displayEmoji, style: const TextStyle(fontSize: 22)),
                ),
              ),
              const SizedBox(width: 12),
              // Label + progress text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      goal.displayName,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${goal.progressText} ${goal.periodLabel}',
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              // Circular progress
              SizedBox(
                width: 44,
                height: 44,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: goal.progressPercent,
                      strokeWidth: 3.5,
                      backgroundColor: Colors.white.withValues(alpha: 0.08),
                      valueColor: AlwaysStoppedAnimation(goal.displayColor),
                    ),
                    Text(
                      '${(goal.progressPercent * 100).round()}%',
                      style: TextStyle(
                        color: goal.displayColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Log today button
              GestureDetector(
                onTap: () => _toggleActivity(goal),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: goal.isCompletedToday
                        ? goal.displayColor
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: goal.isCompletedToday
                          ? goal.displayColor
                          : Colors.white.withValues(alpha: 0.15),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    goal.isCompletedToday
                        ? Icons.check_rounded
                        : Icons.add_rounded,
                    size: 20,
                    color: goal.isCompletedToday
                        ? Colors.white
                        : AppTheme.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Weekly dots row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(7, (i) {
              final isToday = i == today;
              // For simplicity, we'll show today's dot as filled based on isCompletedToday
              final isFilled = i == today ? goal.isCompletedToday : false;
              return Column(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: isFilled
                          ? goal.displayColor.withValues(alpha: 0.3)
                          : Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(8),
                      border: isToday
                          ? Border.all(
                              color: goal.displayColor.withValues(alpha: 0.5),
                              width: 1.5,
                            )
                          : null,
                    ),
                    child: isFilled
                        ? Icon(
                            Icons.check_rounded,
                            size: 14,
                            color: goal.displayColor,
                          )
                        : null,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dayLabels[i],
                    style: TextStyle(
                      color: isToday
                          ? AppTheme.primaryColor
                          : AppTheme.textSecondary.withValues(alpha: 0.5),
                      fontSize: 10,
                      fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
                    ),
                  ),
                ],
              );
            }),
          ),
          // Long press hint
          const SizedBox(height: 4),
          GestureDetector(
            onTap: () => _deleteGoal(goal),
            child: Align(
              alignment: Alignment.centerRight,
              child: Icon(
                Icons.more_horiz_rounded,
                size: 18,
                color: AppTheme.textSecondary.withValues(alpha: 0.3),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyGoals() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.flag_rounded,
            size: 56,
            color: AppTheme.textSecondary.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          const Text(
            'No goals yet',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Set goals like drinking water, walking, or\nworkouts to build healthy habits!',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _showAddGoalSheet,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add Your First Goal'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddGoalFAB() {
    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [AppTheme.primaryGlow],
      ),
      child: FloatingActionButton.extended(
        onPressed: _showAddGoalSheet,
        backgroundColor: Colors.transparent,
        elevation: 0,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'Add Goal',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  void _showAddGoalSheet() async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const AddGoalSheet(),
    );
    if (result == true) _loadData();
  }
}

