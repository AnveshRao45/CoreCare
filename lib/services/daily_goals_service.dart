import '../services/hive_service.dart';

class DailyGoalsService {
  // Goal targets
  static const int targetWaterGlasses = 8;
  static const int targetSteps = 10000;
  static const int targetCalories = 2000;
  static const int targetWorkouts = 1;

  // Workout targets (reps per exercise)
  static const int targetSquats = 30;
  static const int targetPushups = 30;
  static const int targetBicepCurls = 30;

  // Get today's water intake
  static int getWaterIntake() {
    return HiveService.getDailyData<int>('water_glasses', defaultValue: 0) ?? 0;
  }

  // Add water intake
  static Future<void> addWater(int glasses) async {
    final current = getWaterIntake();
    await HiveService.saveDailyData('water_glasses', current + glasses);
  }

  // Get today's steps
  static int getSteps() {
    return HiveService.getDailyData<int>('steps', defaultValue: 0) ?? 0;
  }

  // Update steps
  static Future<void> updateSteps(int steps) async {
    await HiveService.saveDailyData('steps', steps);
  }

  // Get today's calories
  static int getCalories() {
    return HiveService.getDailyData<int>('calories', defaultValue: 0) ?? 0;
  }

  // Add calories
  static Future<void> addCalories(int calories) async {
    final current = getCalories();
    await HiveService.saveDailyData('calories', current + calories);
  }

  // Get workout counts
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

  // Add workout reps
  static Future<void> addWorkoutReps(String exerciseType, int reps) async {
    final key = 'workout_${exerciseType}';
    final current = HiveService.getDailyData<int>(key, defaultValue: 0) ?? 0;
    await HiveService.saveDailyData(key, current + reps);

    // Also track if a workout session was completed
    final workoutSessions = getCompletedWorkoutSessions();
    if (workoutSessions < targetWorkouts) {
      // Mark a workout session as completed if this is the first time today
      await HiveService.saveDailyData(
        'workout_sessions_completed',
        workoutSessions + 1,
      );
    }
  }

  // Get completed workout sessions
  static int getCompletedWorkoutSessions() {
    return HiveService.getDailyData<int>(
          'workout_sessions_completed',
          defaultValue: 0,
        ) ??
        0;
  }

  // Get total workout reps for the day
  static int getTotalWorkoutReps() {
    final counts = getWorkoutCounts();
    return counts['squats']! + counts['pushups']! + counts['bicep_curls']!;
  }

  // Calculate progress percentages
  static double getWaterProgress() {
    final current = getWaterIntake();
    return (current / targetWaterGlasses).clamp(0.0, 1.0);
  }

  static double getStepsProgress() {
    final current = getSteps();
    return (current / targetSteps).clamp(0.0, 1.0);
  }

  static double getCaloriesProgress() {
    final current = getCalories();
    return (current / targetCalories).clamp(0.0, 1.0);
  }

  static double getWorkoutProgress() {
    final completed = getCompletedWorkoutSessions();
    return (completed / targetWorkouts).clamp(0.0, 1.0);
  }

  // Get formatted progress strings
  static String getWaterProgressString() {
    final current = getWaterIntake();
    return '$current/$targetWaterGlasses glasses';
  }

  static String getStepsProgressString() {
    final current = getSteps();
    final stepsInK = (current / 1000).toStringAsFixed(1);
    final targetInK = (targetSteps / 1000).toStringAsFixed(0);
    return '${stepsInK}k/${targetInK}k';
  }

  static String getCaloriesProgressString() {
    final current = getCalories();
    return '$current/$targetCalories';
  }

  static String getWorkoutProgressString() {
    final completed = getCompletedWorkoutSessions();
    return '$completed/$targetWorkouts done';
  }

  // Reset daily goals (useful for testing or new day)
  static Future<void> resetDailyGoals() async {
    await HiveService.saveDailyData('water_glasses', 0);
    await HiveService.saveDailyData('steps', 0);
    await HiveService.saveDailyData('calories', 0);
    await HiveService.saveDailyData('workout_squats', 0);
    await HiveService.saveDailyData('workout_pushups', 0);
    await HiveService.saveDailyData('workout_bicep_curls', 0);
    await HiveService.saveDailyData('workout_sessions_completed', 0);
  }
}
