import 'package:upgrade/pose_detec.dart';

import '../models/meal.dart';
import '../models/user_profile.dart';
import '../services/hive_service.dart';
import 'nutrition_targets_service.dart';

class DailyGoalsService {
  static const int targetWaterGlasses = 8;
  static const int targetSteps = 10000;
  static const int targetWorkouts = 1;

  static const int targetSquats = 30;
  static const int targetPushups = 30;
  static const int targetBicepCurls = 30;

  static int getTargetCalories(UserProfile? user) =>
      NutritionTargetsService.targetCalories(user);

  static int getTargetCarbsG(UserProfile? user) =>
      NutritionTargetsService.targetCarbsG(user);

  static int getTargetProteinG(UserProfile? user) =>
      NutritionTargetsService.targetProteinG(user);

  static int getTargetFatG(UserProfile? user) =>
      NutritionTargetsService.targetFatG(user);

  static int getTargetFiberG() => NutritionTargetsService.targetFiberG();

  static int getConfiguredTargetSteps() =>
      NutritionTargetsService.targetSteps();

  static int getConfiguredTargetWaterGlasses() =>
      NutritionTargetsService.targetWaterGlasses();

  // ── Water ──

  static int getWaterIntake() {
    return HiveService.getDailyData<int>('water_glasses', defaultValue: 0) ?? 0;
  }

  static Future<void> addWater(int glasses) async {
    final current = getWaterIntake();
    await HiveService.saveDailyData('water_glasses', current + glasses);
  }

  static double getHydrationLiters() {
    final stored = HiveService.getDailyData<num>(
      'hydration_liters',
      defaultValue: 0,
    );
    return (stored ?? 0).toDouble();
  }

  static Future<void> addHydrationLiters(double liters) async {
    final current = getHydrationLiters();
    await HiveService.saveDailyData('hydration_liters', current + liters);
    final glasses = (liters / 0.25).round();
    if (glasses > 0) await addWater(glasses);
  }

  // ── Calorie intake (eaten) ──

  static int getCaloriesEaten() {
    return HiveService.getDailyData<int>('calories_eaten', defaultValue: 0) ??
        0;
  }

  static Future<void> addCaloriesEaten(int calories) async {
    await _addInt('calories_eaten', calories);
  }

  static Future<void> addCalories(int calories) async {    await addCaloriesEaten(calories);
  }

  // ── Macros eaten (grams) ──

  static int getCarbsEatenG() =>
      HiveService.getDailyData<int>('carbs_eaten_g', defaultValue: 0) ?? 0;

  static int getProteinEatenG() =>
      HiveService.getDailyData<int>('protein_eaten_g', defaultValue: 0) ?? 0;

  static int getFatEatenG() =>
      HiveService.getDailyData<int>('fat_eaten_g', defaultValue: 0) ?? 0;

  static int getFiberEatenG() =>
      HiveService.getDailyData<int>('fiber_eaten_g', defaultValue: 0) ?? 0;

  static Future<void> addMealIntake(Meal meal) async {
    await addCaloriesEaten(meal.totalCalories);
    await _addInt('carbs_eaten_g', meal.totalCarbsG);
    await _addInt('protein_eaten_g', meal.totalProteinG);
    await _addInt('fat_eaten_g', meal.totalFatG);
    await _addInt('fiber_eaten_g', meal.totalFiberG);
  }

  // ── Calories burned (manual / fallback when no wearable) ──

  static int getCaloriesBurned() {
    return HiveService.getDailyData<int>('calories_burned', defaultValue: 0) ??
        HiveService.getDailyData<int>('calories', defaultValue: 0) ??
        0;
  }

  static Future<void> setCaloriesBurned(int calories) async {
    await HiveService.saveDailyData('calories_burned', calories);
  }

  static Future<void> addCaloriesBurned(int calories) async {
    await _addInt('calories_burned', calories);
  }

  // ── Steps ──

  static int getSteps() {
    return HiveService.getDailyData<int>('steps', defaultValue: 0) ?? 0;
  }

  static Future<void> updateSteps(int steps) async {
    await HiveService.saveDailyData('steps', steps);
  }

  // ── Workouts ──

  static String workoutKeyFor(ExerciseType type) {
    switch (type) {
      case ExerciseType.squat:
        return 'squats';
      case ExerciseType.pushup:
        return 'pushups';
      case ExerciseType.bicep:
        return 'bicep_curls';
    }
  }

  static Map<String, int> getWorkoutCounts() {
    return {
      'squats':
          HiveService.getDailyData<int>('workout_squats', defaultValue: 0) ?? 0,
      'pushups':
          HiveService.getDailyData<int>('workout_pushups', defaultValue: 0) ??
          0,
      'bicep_curls':
          HiveService.getDailyData<int>(
            'workout_bicep_curls',
            defaultValue: 0,
          ) ??
          0,
    };
  }

  static Future<void> addWorkoutReps(String exerciseType, int reps) async {
    final key = 'workout_${exerciseType}';
    final current = HiveService.getDailyData<int>(key, defaultValue: 0) ?? 0;
    await HiveService.saveDailyData(key, current + reps);

    final workoutSessions = getCompletedWorkoutSessions();
    if (workoutSessions < targetWorkouts) {
      await HiveService.saveDailyData(
        'workout_sessions_completed',
        workoutSessions + 1,
      );
    }
  }

  static int getCompletedWorkoutSessions() {
    return HiveService.getDailyData<int>(
          'workout_sessions_completed',
          defaultValue: 0,
        ) ??
        0;
  }

  static int getTotalWorkoutReps() {
    final counts = getWorkoutCounts();
    return counts['squats']! + counts['pushups']! + counts['bicep_curls']!;
  }

  // ── Progress ──

  static double getWaterProgress() {
    final target = getConfiguredTargetWaterGlasses();
    return (getWaterIntake() / target).clamp(0.0, 1.0);
  }

  static double getStepsProgress() {
    final target = getConfiguredTargetSteps();
    return (getSteps() / target).clamp(0.0, 1.0);
  }

  static double getCaloriesEatenProgress(UserProfile? user) {
    final target = getTargetCalories(user);
    if (target <= 0) return 0;
    return (getCaloriesEaten() / target).clamp(0.0, 1.0);
  }

  static double getCarbsProgress(UserProfile? user) {
    final target = getTargetCarbsG(user);
    if (target <= 0) return 0;
    return (getCarbsEatenG() / target).clamp(0.0, 1.0);
  }

  static double getProteinProgress(UserProfile? user) {
    final target = getTargetProteinG(user);
    if (target <= 0) return 0;
    return (getProteinEatenG() / target).clamp(0.0, 1.0);
  }

  static double getFatProgress(UserProfile? user) {
    final target = getTargetFatG(user);
    if (target <= 0) return 0;
    return (getFatEatenG() / target).clamp(0.0, 1.0);
  }

  static double getFiberProgress() {
    final target = getTargetFiberG();
    if (target <= 0) return 0;
    return (getFiberEatenG() / target).clamp(0.0, 1.0);
  }

  static double getWorkoutProgress() {
    final completed = getCompletedWorkoutSessions();
    return (completed / targetWorkouts).clamp(0.0, 1.0);
  }

  static String getWaterProgressString() {
    final target = getConfiguredTargetWaterGlasses();
    return '${getWaterIntake()}/$target glasses';
  }

  static String getStepsProgressString() {
    final current = getSteps();
    final target = getConfiguredTargetSteps();
    final stepsInK = (current / 1000).toStringAsFixed(1);
    final targetInK = (target / 1000).toStringAsFixed(0);
    return '${stepsInK}k/${targetInK}k';
  }

  static String getCaloriesEatenProgressString(UserProfile? user) {
    final target = getTargetCalories(user);
    return '${getCaloriesEaten()}/$target eaten';
  }

  static String getWorkoutProgressString() {
    final completed = getCompletedWorkoutSessions();
    return '$completed/$targetWorkouts done';
  }

  static Future<void> resetDailyGoals() async {
    await HiveService.saveDailyData('water_glasses', 0);
    await HiveService.saveDailyData('hydration_liters', 0.0);
    await HiveService.saveDailyData('calories_eaten', 0);
    await HiveService.saveDailyData('carbs_eaten_g', 0);
    await HiveService.saveDailyData('protein_eaten_g', 0);
    await HiveService.saveDailyData('fat_eaten_g', 0);
    await HiveService.saveDailyData('fiber_eaten_g', 0);
    await HiveService.saveDailyData('calories_burned', 0);
    await HiveService.saveDailyData('steps', 0);
    await HiveService.saveDailyData('workout_squats', 0);
    await HiveService.saveDailyData('workout_pushups', 0);
    await HiveService.saveDailyData('workout_bicep_curls', 0);
    await HiveService.saveDailyData('workout_sessions_completed', 0);
    await HiveService.saveDailyData('meal_log_history', <Map<String, dynamic>>[]);
    await HiveService.saveDailyData('logged_plan_meals', <String>[]);
  }

  static Future<void> _addInt(String key, int delta) async {
    final current = HiveService.getDailyData<int>(key, defaultValue: 0) ?? 0;
    await HiveService.saveDailyData(key, current + delta);
  }
}
