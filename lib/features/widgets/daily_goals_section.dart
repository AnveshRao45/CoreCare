import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:upgrade/providers/user_provider.dart';
import 'package:upgrade/services/daily_goals_service.dart';
import 'package:upgrade/providers/health_provider.dart';

class DailyGoalsSection extends ConsumerStatefulWidget {
  const DailyGoalsSection({super.key});

  @override
  ConsumerState<DailyGoalsSection> createState() => _DailyGoalsSectionState();
}

class _DailyGoalsSectionState extends ConsumerState<DailyGoalsSection> {
  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProfileProvider);
    final waterProgress = DailyGoalsService.getWaterProgress();
    final waterProgressString = DailyGoalsService.getWaterProgressString();
    final workoutProgress = DailyGoalsService.getWorkoutProgress();
    final workoutProgressString = DailyGoalsService.getWorkoutProgressString();
    final intakeProgress = DailyGoalsService.getCaloriesEatenProgress(user);
    final intakeString = DailyGoalsService.getCaloriesEatenProgressString(user);

    final vitals = ref.watch(healthVitalsProvider).value;
    double stepsProgress;
    String stepsProgressString;
    String burnedNote = '';

    if (vitals != null && vitals.isConnected) {
      stepsProgress = vitals.stepsProgress;
      stepsProgressString =
          '${vitals.stepsFormatted}/${(vitals.stepGoal / 1000).toStringAsFixed(0)}k';
      burnedNote = '${vitals.caloriesBurned} burned';
    } else {
      stepsProgress = DailyGoalsService.getStepsProgress();
      stepsProgressString = DailyGoalsService.getStepsProgressString();
      final burned = DailyGoalsService.getCaloriesBurned();
      if (burned > 0) burnedNote = '$burned burned';
    }

    final carbsP = DailyGoalsService.getCarbsProgress(user);
    final proteinP = DailyGoalsService.getProteinProgress(user);
    final fatP = DailyGoalsService.getFatProgress(user);
    final fiberP = DailyGoalsService.getFiberProgress();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'My Daily Goals',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C2C2C),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => setState(() {}),
                tooltip: 'Refresh goals',
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFD6E8FF), Color(0xFFEFF5FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      GestureDetector(
                        onTap: () async {
                          await DailyGoalsService.addWater(1);
                          setState(() {});
                        },
                        child: GoalCircle(
                          progress: waterProgress,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF42A5F5), Color(0xFF1E88E5)],
                          ),
                          icon: Icons.water_drop,
                          iconColor: Colors.blue,
                          label: 'Water',
                          sublabel: waterProgressString,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _editSteps(context),
                        child: GoalCircle(
                          progress: stepsProgress,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF66BB6A), Color(0xFF43A047)],
                          ),
                          icon: Icons.directions_walk,
                          iconColor: Colors.green,
                          label: 'Steps',
                          sublabel: stepsProgressString,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      GoalCircle(
                        progress: workoutProgress,
                        gradient: const LinearGradient(
                          colors: [Color(0xFFBA68C8), Color(0xFF8E24AA)],
                        ),
                        icon: Icons.fitness_center,
                        iconColor: Colors.purple,
                        label: 'Workout',
                        sublabel: workoutProgressString,
                      ),
                      GoalCircle(
                        progress: intakeProgress,
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFB74D), Color(0xFFF57C00)],
                        ),
                        icon: Icons.restaurant,
                        iconColor: Colors.orange,
                        label: 'Intake',
                        sublabel: burnedNote.isEmpty
                            ? intakeString
                            : '$intakeString · $burnedNote',
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Macronutrients (eaten today)',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2C2C2C),
                    ),
                  ),
                  const SizedBox(height: 8),
                  MacroBar(
                    label: 'Carbs',
                    progress: carbsP,
                    value:
                        '${DailyGoalsService.getCarbsEatenG()}g / ${DailyGoalsService.getTargetCarbsG(user)}g',
                    color: Colors.blue,
                  ),
                  MacroBar(
                    label: 'Protein',
                    progress: proteinP,
                    value:
                        '${DailyGoalsService.getProteinEatenG()}g / ${DailyGoalsService.getTargetProteinG(user)}g',
                    color: Colors.green,
                  ),
                  MacroBar(
                    label: 'Fat',
                    progress: fatP,
                    value:
                        '${DailyGoalsService.getFatEatenG()}g / ${DailyGoalsService.getTargetFatG(user)}g',
                    color: Colors.orange,
                  ),
                  MacroBar(
                    label: 'Fiber',
                    progress: fiberP,
                    value:
                        '${DailyGoalsService.getFiberEatenG()}g / ${DailyGoalsService.getTargetFiberG()}g',
                    color: Colors.brown,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _editSteps(BuildContext context) async {
    final ctrl = TextEditingController(
      text: DailyGoalsService.getSteps().toString(),
    );
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Update steps'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Steps today'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await DailyGoalsService.updateSteps(int.tryParse(ctrl.text) ?? 0);
      setState(() {});
    }
  }
}

class MacroBar extends StatelessWidget {
  final String label;
  final double progress;
  final String value;
  final Color color;

  const MacroBar({
    super.key,
    required this.label,
    required this.progress,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontSize: 12)),
              Text(value, style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: color.withValues(alpha: 0.15),
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class GoalCircle extends StatelessWidget {
  final double progress;
  final LinearGradient gradient;
  final IconData icon;
  final Color iconColor;
  final String label;
  final String sublabel;

  const GoalCircle({
    super.key,
    required this.progress,
    required this.gradient,
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.sublabel,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: 80,
          height: 80,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 80,
                height: 80,
                child: CircularProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  strokeWidth: 6,
                  backgroundColor: Colors.white.withValues(alpha: 0.5),
                  valueColor: AlwaysStoppedAnimation(gradient.colors.first),
                ),
              ),
              Icon(icon, color: iconColor, size: 28),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
        ),
        Text(
          sublabel,
          style: const TextStyle(fontSize: 10, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
