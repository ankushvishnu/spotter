import 'package:flutter/material.dart';

class GoalModel {
  final String id;
  final String userId;
  final String activityType;
  final String? customLabel;
  final int targetValue;
  final String targetPeriod;
  final String? iconName;
  final bool isActive;
  final DateTime createdAt;

  // Computed - populated after fetching logs
  int currentProgress;
  bool isCompletedToday;

  GoalModel({
    required this.id,
    required this.userId,
    required this.activityType,
    this.customLabel,
    required this.targetValue,
    required this.targetPeriod,
    this.iconName,
    this.isActive = true,
    required this.createdAt,
    this.currentProgress = 0,
    this.isCompletedToday = false,
  });

  factory GoalModel.fromJson(Map<String, dynamic> json) {
    return GoalModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      activityType: json['activity_type'] as String,
      customLabel: json['custom_label'] as String?,
      targetValue: json['target_value'] as int,
      targetPeriod: json['target_period'] as String,
      iconName: json['icon_name'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  String get displayName {
    if (activityType == 'custom' && customLabel != null) return customLabel!;
    return _presetLabels[activityType] ?? activityType;
  }

  IconData get displayIcon {
    return _presetIcons[activityType] ?? Icons.star_rounded;
  }

  String get displayEmoji {
    return _presetEmojis[activityType] ?? '⭐';
  }

  Color get displayColor {
    return _presetColors[activityType] ?? const Color(0xFFFF5C1A);
  }

  double get progressPercent {
    if (targetValue <= 0) return 0;
    return (currentProgress / targetValue).clamp(0.0, 1.0);
  }

  String get progressText => '$currentProgress/$targetValue';

  String get periodLabel => targetPeriod == 'daily' ? 'per day' : 'per week';

  static const Map<String, String> _presetLabels = {
    'booking': 'Workouts',
    'walking': 'Walking',
    'water': 'Water',
    'cycling': 'Cycling',
    'meditation': 'Meditation',
    'stretching': 'Stretching',
    'running': 'Running',
    'sleep': 'Sleep',
  };

  static const Map<String, IconData> _presetIcons = {
    'booking': Icons.fitness_center_rounded,
    'walking': Icons.directions_walk_rounded,
    'water': Icons.water_drop_rounded,
    'cycling': Icons.pedal_bike_rounded,
    'meditation': Icons.self_improvement_rounded,
    'stretching': Icons.accessibility_new_rounded,
    'running': Icons.directions_run_rounded,
    'sleep': Icons.bedtime_rounded,
  };

  static const Map<String, String> _presetEmojis = {
    'booking': '🏋️',
    'walking': '🚶',
    'water': '💧',
    'cycling': '🚴',
    'meditation': '🧘',
    'stretching': '🤸',
    'running': '🏃',
    'sleep': '😴',
  };

  static const Map<String, Color> _presetColors = {
    'booking': Color(0xFFFF5C1A),
    'walking': Color(0xFF4CAF50),
    'water': Color(0xFF2196F3),
    'cycling': Color(0xFFFF9800),
    'meditation': Color(0xFF9C27B0),
    'stretching': Color(0xFFE91E63),
    'running': Color(0xFF00BCD4),
    'sleep': Color(0xFF3F51B5),
  };

  static List<Map<String, dynamic>> get presetActivities => [
    {'type': 'booking', 'label': 'Workouts', 'defaultTarget': 3, 'period': 'weekly'},
    {'type': 'walking', 'label': 'Walking', 'defaultTarget': 5, 'period': 'weekly'},
    {'type': 'water', 'label': 'Water (glasses)', 'defaultTarget': 8, 'period': 'daily'},
    {'type': 'cycling', 'label': 'Cycling', 'defaultTarget': 3, 'period': 'weekly'},
    {'type': 'meditation', 'label': 'Meditation', 'defaultTarget': 5, 'period': 'weekly'},
    {'type': 'stretching', 'label': 'Stretching', 'defaultTarget': 4, 'period': 'weekly'},
    {'type': 'running', 'label': 'Running', 'defaultTarget': 3, 'period': 'weekly'},
    {'type': 'sleep', 'label': 'Sleep (8hrs)', 'defaultTarget': 7, 'period': 'weekly'},
  ];
}

class ActivityLogModel {
  final String id;
  final String userId;
  final String goalId;
  final DateTime loggedDate;
  final int value;
  final String? notes;
  final DateTime createdAt;

  ActivityLogModel({
    required this.id,
    required this.userId,
    required this.goalId,
    required this.loggedDate,
    required this.value,
    this.notes,
    required this.createdAt,
  });

  factory ActivityLogModel.fromJson(Map<String, dynamic> json) {
    return ActivityLogModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      goalId: json['goal_id'] as String,
      loggedDate: DateTime.parse(json['logged_date'] as String),
      value: json['value'] as int? ?? 1,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
