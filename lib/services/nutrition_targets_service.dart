import '../models/user_profile.dart';
import '../services/hive_service.dart';

class NutritionTargetsService {  static const int defaultCalories = 2000;
  static const int defaultWaterGlasses = 8;
  static const int defaultSteps = 10000;
  static const int defaultFiberG = 30;

  static int targetCalories(UserProfile? user) {
    final custom = HiveService.getSetting<int>('target_calories');
    if (custom != null && custom > 0) return custom;
    return _calculateTdee(user);
  }

  static int targetCarbsG(UserProfile? user) {
    final custom = HiveService.getSetting<int>('target_carbs_g');
    if (custom != null && custom > 0) return custom;
    return (targetCalories(user) * 0.5 / 4).round();
  }

  static int targetProteinG(UserProfile? user) {
    final custom = HiveService.getSetting<int>('target_protein_g');
    if (custom != null && custom > 0) return custom;
    final weight = user?.weight ?? 70;
    return (weight * 1.6).round();
  }

  static int targetFatG(UserProfile? user) {
    final custom = HiveService.getSetting<int>('target_fat_g');
    if (custom != null && custom > 0) return custom;
    return (targetCalories(user) * 0.25 / 9).round();
  }

  static int targetFiberG() {
    final custom = HiveService.getSetting<int>('target_fiber_g');
    if (custom != null && custom > 0) return custom;
    return defaultFiberG;
  }

  static int targetWaterGlasses() {
    final custom = HiveService.getSetting<int>('target_water_glasses');
    if (custom != null && custom > 0) return custom;
    return defaultWaterGlasses;
  }

  static int targetSteps() {
    final custom = HiveService.getSetting<int>('target_steps');
    if (custom != null && custom > 0) return custom;
    return defaultSteps;
  }

  static Future<void> saveCustomTargets({
    int? calories,
    int? carbsG,
    int? proteinG,
    int? fatG,
    int? fiberG,
    int? waterGlasses,
    int? steps,
  }) async {
    if (calories != null) {
      await HiveService.saveSetting('target_calories', calories);
    }
    if (carbsG != null) await HiveService.saveSetting('target_carbs_g', carbsG);
    if (proteinG != null) {
      await HiveService.saveSetting('target_protein_g', proteinG);
    }
    if (fatG != null) await HiveService.saveSetting('target_fat_g', fatG);
    if (fiberG != null) await HiveService.saveSetting('target_fiber_g', fiberG);
    if (waterGlasses != null) {
      await HiveService.saveSetting('target_water_glasses', waterGlasses);
    }
    if (steps != null) await HiveService.saveSetting('target_steps', steps);
  }

  static int _calculateTdee(UserProfile? user) {
    if (user?.age == null ||
        user?.weight == null ||
        user?.height == null ||
        user?.gender == null) {
      return defaultCalories;
    }

    double bmr;
    if (user!.gender!.toLowerCase() == 'male') {
      bmr = 88.362 +
          13.397 * user.weight! +
          4.799 * user.height! -
          5.677 * user.age!;
    } else {
      bmr = 447.593 +
          9.247 * user.weight! +
          3.098 * user.height! -
          4.330 * user.age!;
    }

    double factor = 1.55;
    switch (user.activityLevel?.toLowerCase()) {
      case 'sedentary':
      case 'low':
        factor = 1.2;
        break;
      case 'light':
      case 'lightly active':
        factor = 1.375;
        break;
      case 'high':
      case 'very active':
        factor = 1.725;
        break;
      case 'extremely active':
        factor = 1.9;
        break;
    }
    return (bmr * factor).round();
  }
}
