import 'package:flutter/foundation.dart';
import '../config/supabase_config.dart';
import '../models/goal_model.dart';

class GoalsService {
  final _supabase = SupabaseConfig.client;

  // ── GOALS CRUD ──────────────────────────────────────────────────────────────

  /// Fetch all active goals for a user
  Future<List<GoalModel>> getActiveGoals(String userId) async {
    try {
      final response = await _supabase
          .from('user_goals')
          .select('*')
          .eq('user_id', userId)
          .eq('is_active', true)
          .order('created_at', ascending: true);

      return (response as List)
          .map((g) => GoalModel.fromJson(g))
          .toList();
    } catch (e) {
      debugPrint('GoalsService: getActiveGoals error: $e');
      return [];
    }
  }

  /// Create a new goal
  Future<GoalModel?> createGoal({
    required String userId,
    required String activityType,
    String? customLabel,
    required int targetValue,
    required String targetPeriod,
    String? iconName,
  }) async {
    try {
      final response = await _supabase.from('user_goals').insert({
        'user_id': userId,
        'activity_type': activityType,
        'custom_label': customLabel,
        'target_value': targetValue,
        'target_period': targetPeriod,
        'icon_name': iconName,
      }).select().single();

      return GoalModel.fromJson(response);
    } catch (e) {
      debugPrint('GoalsService: createGoal error: $e');
      return null;
    }
  }

  /// Update a goal
  Future<void> updateGoal({
    required String goalId,
    int? targetValue,
    String? targetPeriod,
    bool? isActive,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };
      if (targetValue != null) updates['target_value'] = targetValue;
      if (targetPeriod != null) updates['target_period'] = targetPeriod;
      if (isActive != null) updates['is_active'] = isActive;

      await _supabase
          .from('user_goals')
          .update(updates)
          .eq('id', goalId);
    } catch (e) {
      debugPrint('GoalsService: updateGoal error: $e');
    }
  }

  /// Soft-delete: deactivate a goal
  Future<void> deleteGoal(String goalId) async {
    try {
      await _supabase
          .from('user_goals')
          .update({'is_active': false, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', goalId);
    } catch (e) {
      debugPrint('GoalsService: deleteGoal error: $e');
    }
  }

  // ── ACTIVITY LOGGING ────────────────────────────────────────────────────────

  /// Log activity completion for today (upsert)
  Future<bool> logActivity({
    required String goalId,
    required String userId,
    int value = 1,
    String? notes,
  }) async {
    try {
      final today = DateTime.now().toIso8601String().split('T')[0];
      await _supabase.from('activity_logs').upsert({
        'goal_id': goalId,
        'user_id': userId,
        'logged_date': today,
        'value': value,
        'notes': notes,
      }, onConflict: 'user_id,goal_id,logged_date');
      return true;
    } catch (e) {
      debugPrint('GoalsService: logActivity error: $e');
      return false;
    }
  }

  /// Remove activity log for a specific date
  Future<bool> unlogActivity({
    required String goalId,
    required String userId,
    DateTime? date,
  }) async {
    try {
      final targetDate = (date ?? DateTime.now()).toIso8601String().split('T')[0];
      await _supabase
          .from('activity_logs')
          .delete()
          .eq('goal_id', goalId)
          .eq('user_id', userId)
          .eq('logged_date', targetDate);
      return true;
    } catch (e) {
      debugPrint('GoalsService: unlogActivity error: $e');
      return false;
    }
  }

  // ── PROGRESS & STATS ────────────────────────────────────────────────────────

  /// Get activity logs for the current week for all goals  
  Future<List<ActivityLogModel>> getWeeklyLogs(String userId) async {
    try {
      final now = DateTime.now();
      // Monday of current week
      final monday = now.subtract(Duration(days: now.weekday - 1));
      final mondayStr = DateTime(monday.year, monday.month, monday.day)
          .toIso8601String().split('T')[0];
      final sundayStr = DateTime(monday.year, monday.month, monday.day + 6)
          .toIso8601String().split('T')[0];

      final response = await _supabase
          .from('activity_logs')
          .select('*')
          .eq('user_id', userId)
          .gte('logged_date', mondayStr)
          .lte('logged_date', sundayStr)
          .order('logged_date', ascending: true);

      return (response as List)
          .map((l) => ActivityLogModel.fromJson(l))
          .toList();
    } catch (e) {
      debugPrint('GoalsService: getWeeklyLogs error: $e');
      return [];
    }
  }

  /// Get goals with their weekly progress populated 
  Future<List<GoalModel>> getGoalsWithProgress(String userId) async {
    try {
      final goals = await getActiveGoals(userId);
      if (goals.isEmpty) return goals;

      final logs = await getWeeklyLogs(userId);
      final today = DateTime.now().toIso8601String().split('T')[0];

      for (final goal in goals) {
        final goalLogs = logs.where((l) => l.goalId == goal.id).toList();
        
        if (goal.targetPeriod == 'daily') {
          // For daily goals, progress = today's value
          final todayLog = goalLogs.where(
            (l) => l.loggedDate.toIso8601String().split('T')[0] == today
          ).toList();
          goal.currentProgress = todayLog.isNotEmpty ? todayLog.first.value : 0;
          goal.isCompletedToday = todayLog.isNotEmpty;
        } else {
          // For weekly goals, progress = sum of all logs this week
          goal.currentProgress = goalLogs.fold<int>(0, (sum, l) => sum + l.value);
          final todayLog = goalLogs.where(
            (l) => l.loggedDate.toIso8601String().split('T')[0] == today
          ).toList();
          goal.isCompletedToday = todayLog.isNotEmpty;
        }
      }

      return goals;
    } catch (e) {
      debugPrint('GoalsService: getGoalsWithProgress error: $e');
      return [];
    }
  }

  /// Get daily activity counts for the current week (Mon-Sun)
  /// Returns a list of 7 integers representing activity count per day
  Future<List<int>> getWeeklyDailyBreakdown(String userId) async {
    try {
      final logs = await getWeeklyLogs(userId);
      final now = DateTime.now();
      final monday = now.subtract(Duration(days: now.weekday - 1));

      final dailyCounts = List<int>.filled(7, 0);
      for (final log in logs) {
        final dayIndex = log.loggedDate.difference(
          DateTime(monday.year, monday.month, monday.day)
        ).inDays;
        if (dayIndex >= 0 && dayIndex < 7) {
          dailyCounts[dayIndex] += log.value;
        }
      }
      return dailyCounts;
    } catch (e) {
      debugPrint('GoalsService: getWeeklyDailyBreakdown error: $e');
      return List<int>.filled(7, 0);
    }
  }

  /// Calculate current streak: consecutive days with at least one logged activity 
  Future<int> getCurrentStreak(String userId) async {
    try {
      // Fetch last 60 days of logs to calculate streak
      final sixtyDaysAgo = DateTime.now()
          .subtract(const Duration(days: 60))
          .toIso8601String().split('T')[0];

      final response = await _supabase
          .from('activity_logs')
          .select('logged_date')
          .eq('user_id', userId)
          .gte('logged_date', sixtyDaysAgo)
          .order('logged_date', ascending: false);

      if ((response as List).isEmpty) return 0;

      // Get unique dates
      final dates = (response as List)
          .map((r) => r['logged_date'] as String)
          .toSet()
          .toList()
        ..sort((a, b) => b.compareTo(a)); // newest first

      int streak = 0;
      final today = DateTime.now();
      var checkDate = DateTime(today.year, today.month, today.day);

      for (final dateStr in dates) {
        final logDate = DateTime.parse(dateStr);
        final diff = checkDate.difference(logDate).inDays;

        if (diff == 0) {
          streak++;
          checkDate = checkDate.subtract(const Duration(days: 1));
        } else if (diff == 1 && streak == 0) {
          // Allow yesterday as start if nothing logged today yet
          streak++;
          checkDate = logDate.subtract(const Duration(days: 1));
        } else {
          break;
        }
      }

      return streak;
    } catch (e) {
      debugPrint('GoalsService: getCurrentStreak error: $e');
      return 0;
    }
  }

  /// Get aggregated progress summary for the home screen
  Future<Map<String, dynamic>> getProgressSummary(String userId) async {
    try {
      final results = await Future.wait([
        getGoalsWithProgress(userId),
        getCurrentStreak(userId),
        getWeeklyDailyBreakdown(userId),
      ]);

      final goals = results[0] as List<GoalModel>;
      final streak = results[1] as int;
      final dailyBreakdown = results[2] as List<int>;

      // Calculate overall goal completion percentage
      double completionPercent = 0;
      if (goals.isNotEmpty) {
        final totalCompletion = goals.fold<double>(
          0, (sum, g) => sum + g.progressPercent,
        );
        completionPercent = totalCompletion / goals.length;
      }

      return {
        'goals': goals,
        'streak': streak,
        'dailyBreakdown': dailyBreakdown,
        'completionPercent': completionPercent,
        'totalActivitiesThisWeek': dailyBreakdown.fold<int>(0, (s, v) => s + v),
      };
    } catch (e) {
      debugPrint('GoalsService: getProgressSummary error: $e');
      return {
        'goals': <GoalModel>[],
        'streak': 0,
        'dailyBreakdown': List<int>.filled(7, 0),
        'completionPercent': 0.0,
        'totalActivitiesThisWeek': 0,
      };
    }
  }
}
