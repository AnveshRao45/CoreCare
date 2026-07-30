import '../models/meal.dart';

List<Meal> fallbackDailyMeals() {  return [
    Meal(
      name: 'Breakfast',
      totalCalories: 420,
      items: [
        FoodItem(
          name: 'Oatmeal with berries',
          calories: 280,
          carbsG: 45,
          proteinG: 10,
          fatG: 6,
          fiberG: 8,
        ),
        FoodItem(
          name: 'Greek yogurt',
          calories: 140,
          carbsG: 8,
          proteinG: 14,
          fatG: 4,
          fiberG: 0,
        ),
      ],
    ),
    Meal(
      name: 'Lunch',
      totalCalories: 550,
      items: [
        FoodItem(
          name: 'Grilled chicken salad',
          calories: 380,
          carbsG: 18,
          proteinG: 42,
          fatG: 14,
          fiberG: 6,
        ),
        FoodItem(
          name: 'Whole grain bread',
          calories: 170,
          carbsG: 30,
          proteinG: 6,
          fatG: 2,
          fiberG: 4,
        ),
      ],
    ),
    Meal(
      name: 'Dinner',
      totalCalories: 620,
      items: [
        FoodItem(
          name: 'Salmon with vegetables',
          calories: 450,
          carbsG: 20,
          proteinG: 38,
          fatG: 22,
          fiberG: 7,
        ),
        FoodItem(
          name: 'Brown rice',
          calories: 170,
          carbsG: 35,
          proteinG: 4,
          fatG: 2,
          fiberG: 3,
        ),
      ],
    ),
    Meal(
      name: 'Snacks',
      totalCalories: 200,
      items: [
        FoodItem(
          name: 'Apple with almonds',
          calories: 200,
          carbsG: 22,
          proteinG: 5,
          fatG: 12,
          fiberG: 5,
        ),
      ],
    ),
  ];
}
