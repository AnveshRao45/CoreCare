class FoodItem {
  final String name;
  final int calories;
  final int carbsG;
  final int proteinG;
  final int fatG;
  final int fiberG;

  FoodItem({
    required this.name,
    required this.calories,
    this.carbsG = 0,
    this.proteinG = 0,
    this.fatG = 0,
    this.fiberG = 0,
  });

  factory FoodItem.fromJson(Map<String, dynamic> json) {
    return FoodItem(
      name: json['name'] as String? ?? '',
      calories: _asInt(json['calories']),
      carbsG: _asInt(json['carbsG'] ?? json['carbs']),
      proteinG: _asInt(json['proteinG'] ?? json['protein']),
      fatG: _asInt(json['fatG'] ?? json['fat']),
      fiberG: _asInt(json['fiberG'] ?? json['fiber']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'calories': calories,
      'carbsG': carbsG,
      'proteinG': proteinG,
      'fatG': fatG,
      'fiberG': fiberG,
    };
  }

  static int _asInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.round();
    return int.tryParse(v.toString()) ?? 0;
  }
}

class Meal {
  final String name;
  final int totalCalories;
  final List<FoodItem> items;

  Meal({required this.name, required this.totalCalories, required this.items});

  int get totalCarbsG => items.fold(0, (s, i) => s + i.carbsG);
  int get totalProteinG => items.fold(0, (s, i) => s + i.proteinG);
  int get totalFatG => items.fold(0, (s, i) => s + i.fatG);
  int get totalFiberG => items.fold(0, (s, i) => s + i.fiberG);

  factory Meal.fromJson(Map<String, dynamic> json) {
    final items = (json['items'] as List?)
            ?.map((e) => FoodItem.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    final totalCal = json['totalCalories'] != null
        ? FoodItem._asInt(json['totalCalories'])
        : items.fold(0, (s, i) => s + i.calories);
    return Meal(
      name: json['name'] as String? ?? 'Meal',
      totalCalories: totalCal,
      items: items,
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
