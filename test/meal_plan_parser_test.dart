import 'package:flutter_test/flutter_test.dart';
import 'package:upgrade/utils/meal_plan_parser.dart';

const _samplePlan = '''
[
  {"name":"Breakfast","totalCalories":400,"items":[
    {"name":"Oats","calories":400,"carbsG":60,"proteinG":12,"fatG":8,"fiberG":6}
  ]},
  {"name":"Lunch","totalCalories":500,"items":[
    {"name":"Rice bowl","calories":500,"carbsG":70,"proteinG":20,"fatG":10,"fiberG":5}
  ]},
  {"name":"Dinner","totalCalories":500,"items":[
    {"name":"Fish","calories":500,"carbsG":20,"proteinG":40,"fatG":20,"fiberG":2}
  ]},
  {"name":"Snacks","totalCalories":200,"items":[
    {"name":"Yogurt","calories":200,"carbsG":15,"proteinG":12,"fatG":8,"fiberG":0}
  ]}
]
''';

void main() {
  test('parses a clean four-meal JSON array', () {
    final meals = parseMealPlanJson(_samplePlan);

    expect(meals, hasLength(4));
    expect(meals.map((m) => m.name).toList(), [
      'Breakfast',
      'Lunch',
      'Dinner',
      'Snacks',
    ]);
    expect(meals.first.totalCalories, 400);
  });

  test('strips markdown fences before decoding', () {
    final raw = '```json\n$_samplePlan\n```';
    final meals = parseMealPlanJson(raw);

    expect(meals, hasLength(4));
    expect(meals[1].name, 'Lunch');
  });

  test('ignores prose before the JSON array', () {
    final raw = 'Sure, here is a plan:\n$_samplePlan\nHope this helps!';
    final meals = parseMealPlanJson(raw);

    expect(meals, hasLength(4));
    expect(meals.last.name, 'Snacks');
  });

  test('returns empty list for unrecoverable output', () {
    expect(parseMealPlanJson('I cannot help with that.'), isEmpty);
    expect(parseMealPlanJson('{not: an array}'), isEmpty);
  });
}
