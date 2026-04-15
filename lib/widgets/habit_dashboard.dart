import 'package:flutter/material.dart';
import '../../config/theme.dart';
import 'glass_card.dart';
import 'habit_ring.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class HabitDashboard extends StatefulWidget {
  const HabitDashboard({super.key});

  @override
  State<HabitDashboard> createState() => _HabitDashboardState();
}

class _HabitDashboardState extends State<HabitDashboard> {
  // Mock data for demonstration - would be wired to a HabitProvider
  double waterProgress = 0.6;
  double stepsProgress = 0.3;
  double workoutProgress = 0.0;
  int currentStreak = 12;

  void _tapRing(String type) {
    // In a real app we'd dispatch an update to a state manager
    setState(() {
      if (type == 'water') waterProgress = (waterProgress + 0.2).clamp(0.0, 1.0);
      if (type == 'steps') stepsProgress = (stepsProgress + 0.1).clamp(0.0, 1.0);
      if (type == 'workout') workoutProgress = (workoutProgress + 1.0).clamp(0.0, 1.0);
    });
    
    // Check if celebration is needed
    if (waterProgress == 1.0 && stepsProgress >= 1.0 && workoutProgress == 1.0) {
      // Trigger global confetti here
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final isGuest = user == null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GlassCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Daily Goals',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isGuest ? 'Sign in to track your progress' : 'Keep your streak alive!',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.accentColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.accentColor.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.local_fire_department_rounded, color: AppTheme.accentColor, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        isGuest ? '0' : '$currentStreak',
                        style: const TextStyle(
                          color: AppTheme.accentColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                GestureDetector(
                  onTap: () => _tapRing('water'),
                  child: HabitRing(
                    progress: isGuest ? 0.3 : waterProgress,
                    icon: Icons.water_drop_rounded,
                    baseColor: const Color(0xFF00E5FF),
                    label: 'Water',
                  ),
                ),
                GestureDetector(
                  onTap: () => _tapRing('workout'),
                  child: HabitRing(
                    progress: isGuest ? 0.0 : workoutProgress,
                    icon: Icons.fitness_center_rounded,
                    baseColor: AppTheme.primaryColor,
                    label: 'Workout',
                  ),
                ),
                GestureDetector(
                  onTap: () => _tapRing('steps'),
                  child: HabitRing(
                    progress: isGuest ? 0.8 : stepsProgress,
                    icon: Icons.directions_walk_rounded,
                    baseColor: AppTheme.successColor,
                    label: 'Steps',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

