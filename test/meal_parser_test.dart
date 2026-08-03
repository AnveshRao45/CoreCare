import 'package:flutter_test/flutter_test.dart';
import 'package:upgrade/models/meal.dart';

void main() {
  group('FoodItem.fromJson', () {
    test('parses macros with G suffix keys', () {
      final item = FoodItem.fromJson({
        'name': 'Oats',
        'calories': 150,
        'carbsG': 27,
        'proteinG': 5,
        'fatG': 3,
        'fiberG': 4,
      });

      expect(item.name, 'Oats');
      expect(item.calories, 150);
      expect(item.carbsG, 27);
      expect(item.proteinG, 5);
      expect(item.fatG, 3);
      expect(item.fiberG, 4);
    });

    test('accepts short macro key aliases from LLM output', () {
      final item = FoodItem.fromJson({
        'name': 'Egg',
        'calories': 70.4,
        'carbs': '1',
        'protein': 6,
        'fat': 5.2,
        'fiber': null,
      });

      expect(item.calories, 70);
      expect(item.carbsG, 1);
      expect(item.proteinG, 6);
      expect(item.fatG, 5);
      expect(item.fiberG, 0);
    });
  });

  group('Meal.fromJson', () {
    test('parses a breakfast meal and totals macros', () {
      final meal = Meal.fromJson({
        'name': 'Breakfast',
        'totalCalories': 420,
        'items': [
          {
            'name': 'Oats',
            'calories': 300,
            'carbsG': 50,
            'proteinG': 10,
            'fatG': 6,
            'fiberG': 5,
          },
          {
            'name': 'Banana',
            'calories': 120,
            'carbsG': 27,
            'proteinG': 1,
            'fatG': 0,
            'fiberG': 3,
          },
        ],
      });

      expect(meal.name, 'Breakfast');
      expect(meal.totalCalories, 420);
      expect(meal.items, hasLength(2));
      expect(meal.totalCarbsG, 77);
      expect(meal.totalProteinG, 11);
      expect(meal.totalFatG, 6);
      expect(meal.totalFiberG, 8);
    });

    test('sums item calories when totalCalories is missing', () {
      final meal = Meal.fromJson({
        'name': 'Snacks',
        'items': [
          {'name': 'Apple', 'calories': 95},
          {'name': 'Yogurt', 'calories': 120},
        ],
      });

      expect(meal.totalCalories, 215);
      expect(meal.name, 'Snacks');
    });

    test('defaults empty items and Meal name when fields are absent', () {
      final meal = Meal.fromJson(<String, dynamic>{});

      expect(meal.name, 'Meal');
      expect(meal.items, isEmpty);
      expect(meal.totalCalories, 0);
    });
  });
}
