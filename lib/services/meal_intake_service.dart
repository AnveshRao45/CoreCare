import '../models/meal.dart';
import '../models/user_profile.dart';
import 'daily_goals_service.dart';
import 'hive_service.dart';
import 'nutrition_targets_service.dart';

class MealIntakeService {  static Future<void> logMeal(Meal meal) async {
    await DailyGoalsService.addMealIntake(meal);
    await _appendHistory(meal);
    await _markPlanMealLogged(meal.name);
  }

  static List<String> getLoggedPlanMealNames() {
    final raw = HiveService.getDailyData<List>('logged_plan_meals');
    if (raw == null) return [];
    return raw.map((e) => e.toString()).toList();
  }

  static bool isPlanMealLogged(String mealName) {
    final key = mealName.trim().toLowerCase();
    return getLoggedPlanMealNames()
        .any((n) => n.trim().toLowerCase() == key);
  }

  static Future<void> _markPlanMealLogged(String mealName) async {
    final names = getLoggedPlanMealNames();
    final key = mealName.trim().toLowerCase();
    if (names.any((n) => n.trim().toLowerCase() == key)) return;
    names.add(mealName);
    await HiveService.saveDailyData('logged_plan_meals', names);
  }

  static Future<void> logManualFood({
    required String name,
    required int calories,
    int carbsG = 0,
    int proteinG = 0,
    int fatG = 0,
    int fiberG = 0,
  }) async {
    final meal = Meal(
      name: name,
      totalCalories: calories,
      items: [
        FoodItem(
          name: name,
          calories: calories,
          carbsG: carbsG,
          proteinG: proteinG,
          fatG: fatG,
          fiberG: fiberG,
        ),
      ],
    );
    await logMeal(meal);
  }

  static List<Map<String, dynamic>> getTodayHistory() {
    final raw = HiveService.getDailyData<List>('meal_log_history');
    if (raw == null) return [];
    return raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  static Future<void> _appendHistory(Meal meal) async {
    final history = getTodayHistory();
    history.add({
      'time': DateTime.now().toIso8601String(),
      'name': meal.name,
      'calories': meal.totalCalories,
      'carbsG': meal.totalCarbsG,
      'proteinG': meal.totalProteinG,
      'fatG': meal.totalFatG,
      'fiberG': meal.totalFiberG,
    });
    await HiveService.saveDailyData('meal_log_history', history);
  }

  static List<String> buildRecommendations(UserProfile? user) {
    final tips = <String>[];
    final eaten = DailyGoalsService.getCaloriesEaten();
    final target = NutritionTargetsService.targetCalories(user);

    if (eaten < target * 0.7) {
      tips.add(
        'You are under your calorie target today. Add a balanced snack '
        'with protein to stay energized.',
      );
    } else if (eaten > target) {
      tips.add(
        'You have exceeded your calorie target. Choose lighter meals and '
        'prioritize vegetables and lean protein.',
      );
    } else {
      tips.add('Great job staying near your daily calorie target.');
    }

    final water = DailyGoalsService.getWaterIntake();
    final waterTarget = NutritionTargetsService.targetWaterGlasses();
    if (water < waterTarget) {
      tips.add('Drink ${waterTarget - water} more glasses of water today.');
    }

    switch (user?.activityLevel?.toLowerCase()) {
      case 'sedentary':
      case 'low':
        tips.add('Try a 10-minute walk after meals to boost daily movement.');
        break;
      case 'high':
      case 'very active':
        tips.add('Ensure post-workout protein to support recovery.');
        break;
      default:
        tips.add('Aim for 30 minutes of moderate activity most days.');
    }

    if (user?.dietaryRestrictions?.isNotEmpty ?? false) {
      tips.add(
        'Stick to your restrictions: ${user!.dietaryRestrictions!.join(", ")}.',
      );
    }

    return tips;
  }
}
