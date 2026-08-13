import 'package:flutter_test/flutter_test.dart';
import 'package:upgrade/models/user_profile.dart';
import 'package:upgrade/services/nutrition_targets_service.dart';

import 'test_helpers.dart';

void main() {
  setUp(() async {
    await initTestHive();
  });

  tearDown(() async {
    await closeTestHive();
  });

  UserProfile profile({
    String activity = 'Active',
    double weight = 70,
  }) {
    return UserProfile(
      age: 30,
      gender: 'male',
      height: 175,
      weight: weight,
      activityLevel: activity,
    );
  }

  test('missing anthropometrics returns default calories', () {
    expect(
      NutritionTargetsService.targetCalories(UserProfile()),
      NutritionTargetsService.defaultCalories,
    );
    expect(
      NutritionTargetsService.targetCalories(null),
      NutritionTargetsService.defaultCalories,
    );
  });

  test('onboarding activity labels change TDEE in expected order', () {
    final sedentary = NutritionTargetsService.targetCalories(
      profile(activity: 'Sedentary'),
    );
    final somewhat = NutritionTargetsService.targetCalories(
      profile(activity: 'Somewhat Active'),
    );
    final active = NutritionTargetsService.targetCalories(
      profile(activity: 'Active'),
    );
    final very = NutritionTargetsService.targetCalories(
      profile(activity: 'Very Active'),
    );

    expect(sedentary, lessThan(somewhat));
    expect(somewhat, lessThan(active));
    expect(active, lessThan(very));
  });

  test('protein target scales with body weight', () {
    final light = NutritionTargetsService.targetProteinG(
      profile(weight: 60),
    );
    final heavy = NutritionTargetsService.targetProteinG(
      profile(weight: 90),
    );

    expect(light, 96); // 60 * 1.6
    expect(heavy, 144); // 90 * 1.6
    expect(heavy, greaterThan(light));
  });

  test('macro splits stay near carb and fat calorie shares', () {
    final user = profile();
    final kcal = NutritionTargetsService.targetCalories(user);
    final carbs = NutritionTargetsService.targetCarbsG(user);
    final fat = NutritionTargetsService.targetFatG(user);

    expect(carbs, (kcal * 0.5 / 4).round());
    expect(fat, (kcal * 0.25 / 9).round());
    expect(NutritionTargetsService.targetFiberG(), 30);
  });
}
