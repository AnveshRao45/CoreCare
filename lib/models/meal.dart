class MealPlan {
  final List<Meal> meals;

  MealPlan({required this.meals});

  factory MealPlan.fromJson(Map<String, dynamic> json) {
    return MealPlan(
      meals: (json['meals'] as List)
          .map((e) => Meal.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'meals': meals.map((e) => e.toJson()).toList()};
  }
}

class Meal {
  final String name;
  final int totalCalories;
  final List<FoodItem> items;

  Meal({required this.name, required this.totalCalories, required this.items});

  factory Meal.fromJson(Map<String, dynamic> json) {
    return Meal(
      name: json['name'],
      totalCalories: json['totalCalories'],
      items: (json['items'] as List)
          .map((e) => FoodItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'totalCalories': totalCalories,
      'items': items.map((e) => e.toJson()).toList(),
    };
  }
}

class FoodItem {
  final String name;
  final int calories;

  FoodItem({required this.name, required this.calories});

  factory FoodItem.fromJson(Map<String, dynamic> json) {
    return FoodItem(name: json['name'], calories: json['calories']);
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'calories': calories};
  }
}
