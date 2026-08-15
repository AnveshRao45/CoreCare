import 'dart:convert';

import 'package:upgrade/models/meal.dart';

/// Recover a meal-plan list from raw on-device LLM text.
///
/// Handles common small-model failure modes: markdown fences and prose
/// before/after the JSON array. Returns an empty list when recovery fails.
List<Meal> parseMealPlanJson(String rawOutput) {
  try {
    String cleaned = rawOutput;
    if (cleaned.contains('```json')) {
      final startIndex = cleaned.indexOf('```json') + 7;
      final endIndex = cleaned.indexOf('```', startIndex);
      cleaned = endIndex != -1
          ? cleaned.substring(startIndex, endIndex)
          : cleaned.substring(startIndex);
    } else if (cleaned.contains('```')) {
      final startIndex = cleaned.indexOf('```') + 3;
      final endIndex = cleaned.indexOf('```', startIndex);
      cleaned = endIndex != -1
          ? cleaned.substring(startIndex, endIndex)
          : cleaned.substring(startIndex);
    }
    cleaned = cleaned.trim();

    final start = cleaned.indexOf('[');
    var end = -1;
    if (start != -1) {
      var bracketCount = 0;
      for (var i = start; i < cleaned.length; i++) {
        if (cleaned[i] == '[') bracketCount++;
        if (cleaned[i] == ']') {
          bracketCount--;
          if (bracketCount == 0) {
            end = i;
            break;
          }
        }
      }
    }
    if (start == -1 || end == -1) return [];

    final parsed = jsonDecode(cleaned.substring(start, end + 1));
    if (parsed is! List) return [];

    final meals = <Meal>[];
    for (final mealData in parsed) {
      if (mealData is Map<String, dynamic>) {
        meals.add(Meal.fromJson(mealData));
      } else if (mealData is Map) {
        meals.add(Meal.fromJson(Map<String, dynamic>.from(mealData)));
      }
    }
    return meals;
  } catch (_) {
    return [];
  }
}
