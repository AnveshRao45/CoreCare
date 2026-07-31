import 'package:flutter/material.dart';
import '../../models/meal.dart';
import 'meal_card.dart';

class MealCarousel extends StatefulWidget {
  final List<Meal> meals;
  final Set<String> loggedMealNames;
  final Function(Meal)? onMealLog;

  const MealCarousel({
    super.key,
    required this.meals,
    this.loggedMealNames = const {},
    this.onMealLog,
  });

  @override
  State<MealCarousel> createState() => _MealCarouselState();
}

class _MealCarouselState extends State<MealCarousel> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  List<Color> _getGradientColors(String mealName) {
    switch (mealName.toLowerCase()) {
      case 'breakfast':
        return [const Color(0xFFFFB347), const Color(0xFFFF8C42)];
      case 'lunch':
        return [const Color(0xFF4ECDC4), const Color(0xFF44A08D)];
      case 'dinner':
        return [const Color(0xFF667eea), const Color(0xFF764ba2)];
      case 'snacks':
        return [const Color(0xFFf093fb), const Color(0xFFf5576c)];
      default:
        return [const Color(0xFFFF8A50), const Color(0xFFFF6B35)];
    }
  }

  String _getIllustrationUrl(String mealName) {
    switch (mealName.toLowerCase()) {
      case 'breakfast':
        return 'https://images.unsplash.com/photo-1533089860892-a7c6f0a88666?w=400';
      case 'lunch':
        return 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=400';
      case 'dinner':
        return 'https://images.unsplash.com/photo-1567620905732-2d1ec7ab7445?w=400';
      case 'snacks':
        return 'https://images.unsplash.com/photo-1559054663-e431885ca2eb?w=400';
      default:
        return 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=400';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 320,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemCount: widget.meals.length,
            itemBuilder: (context, index) {
              final meal = widget.meals[index];
              final isLogged = widget.loggedMealNames.contains(
                meal.name.trim().toLowerCase(),
              );
              return MealCard(
                name: meal.name,
                calories: meal.totalCalories,
                items: meal.items,
                gradientColors: _getGradientColors(meal.name),
                illustrationUrl: _getIllustrationUrl(meal.name),
                isLogged: isLogged,
                onLogMeal: isLogged ? null : () => widget.onMealLog?.call(meal),
              );
            },
          ),
        ),
        const SizedBox(height: 20),
        _buildPageIndicators(),
      ],
    );
  }

  Widget _buildPageIndicators() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        widget.meals.length,
        (index) => Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: _currentIndex == index ? 12 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: _currentIndex == index
                ? Colors.orange
                : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}
