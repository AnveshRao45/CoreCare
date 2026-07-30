import 'package:flutter/material.dart';

class Meal {
  final String name;
  final int calories;
  final List<String> items;
  final List<Color> gradientColors;
  final String illustrationUrl;
  final List<Widget> accentIcons;

  const Meal({
    required this.name,
    required this.calories,
    required this.items,
    required this.gradientColors,
    required this.illustrationUrl,
    required this.accentIcons,
  });

  static List<Meal> getMealData() {
    return [
      Meal(
        name: 'Breakfast',
        calories: 320,
        items: ['🥚 2 Boiled Eggs', '🍞 Whole Wheat Toast', '🍵 Green Tea'],
        gradientColors: [const Color(0xFFFFF3E0), const Color(0xFFFFE0B2)],
        illustrationUrl:
            'https://images.unsplash.com/photo-1533089860892-a7c6f0a88666?w=120&h=120&fit=crop&crop=center',
        accentIcons: [
          Positioned(
            top: 10,
            left: 10,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.wb_sunny, color: Colors.orange, size: 16),
            ),
          ),
        ],
      ),
      Meal(
        name: 'Lunch',
        calories: 450,
        items: [
          '🥗 Grilled Chicken Salad',
          '🫒 Olive Oil Dressing',
          '🍎 Apple Slices',
        ],
        gradientColors: [const Color(0xFFE0F7FA), const Color(0xFFFFE0B2)],
        illustrationUrl:
            'https://images.unsplash.com/photo-1546833999-b9f581a1996d?w=120&h=120&fit=crop&crop=center',
        accentIcons: [],
      ),
      Meal(
        name: 'Snack',
        calories: 180,
        items: ['🥛 Greek Yogurt', '🫐 Mixed Berries', '🥜 Almonds'],
        gradientColors: [const Color(0xFFE3F2FD), const Color(0xFFBBDEFB)],
        illustrationUrl:
            'https://images.unsplash.com/photo-1488477181946-6428a0291777?w=120&h=120&fit=crop&crop=center',
        accentIcons: [
          Positioned(
            top: 10,
            left: 10,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.cookie, color: Colors.blue, size: 16),
            ),
          ),
        ],
      ),
      Meal(
        name: 'Dinner',
        calories: 380,
        items: ['🐟 Salmon Fillet', '🌾 Quinoa', '🥦 Steamed Broccoli'],
        gradientColors: [const Color(0xFFF3E5F5), const Color(0xFFE1BEE7)],
        illustrationUrl:
            'https://images.unsplash.com/photo-1467003909585-2f8a72700288?w=120&h=120&fit=crop&crop=center',
        accentIcons: [
          Positioned(
            top: 10,
            left: 10,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.dinner_dining,
                color: Colors.purple,
                size: 16,
              ),
            ),
          ),
        ],
      ),
    ];
  }
}
