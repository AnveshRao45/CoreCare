import 'package:flutter/material.dart';
import '../../models/meal.dart';
import 'meal_card.dart';

class MealCarousel extends StatefulWidget {
  final List<Meal> meals;
  final Function(Meal)? onMealLog;

  const MealCarousel({super.key, required this.meals, this.onMealLog});

  @override
  State<MealCarousel> createState() => _MealCarouselState();
}

class _MealCarouselState extends State<MealCarousel> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 220,
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
              return MealCard(
                name: meal.name,
                calories: meal.calories,
                items: meal.items,
                gradientColors: meal.gradientColors,
                illustrationUrl: meal.illustrationUrl,
                onLogMeal: () => widget.onMealLog?.call(meal),
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
