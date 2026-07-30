import 'package:flutter/material.dart';
import 'dart:ui';

class MealCard extends StatelessWidget {
  final String name;
  final int calories;
  final List<String> items;
  final List<Color> gradientColors;
  final String illustrationUrl;
  final VoidCallback? onLogMeal;

  const MealCard({
    super.key,
    required this.name,
    required this.calories,
    required this.items,
    required this.gradientColors,
    required this.illustrationUrl,
    this.onLogMeal,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadiusGeometry.circular(24),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 0),

      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Bottom container with image at right corner
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradientColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    // Image positioned at right corner
                    Positioned(
                      top: -20,
                      right: -20,
                      child: Container(
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.network(
                            illustrationUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Icon(
                                  Icons.restaurant,
                                  size: 60,
                                  color: Colors.white,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Top container with blurred background
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      gradientColors[0].withValues(alpha: 0.85),
                      gradientColors[1].withValues(alpha: 0.75),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 1.0, sigmaY: 1.0),
                  child: Container(
                    color: Colors.white.withValues(alpha: 0.05),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Meal title
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFFF8A50),
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Calories
                        Row(
                          children: [
                            const Text(
                              "⚡ ",
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFFFF8A50),
                              ),
                            ),
                            Text(
                              "$calories kcal",
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFFF8A50),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Food items
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: items
                                .take(3)
                                .map(
                                  (item) => Padding(
                                    padding: const EdgeInsets.only(bottom: 2),
                                    child: Text(
                                      item,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Color(0xFF9E9E9E),
                                        height: 1.2,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                        const SizedBox(height: 2),
                        // Log Meal button
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton.icon(
                            onPressed: onLogMeal,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF8A50),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 2,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              elevation: 0,
                            ),
                            icon: const Icon(
                              Icons.check_circle,
                              size: 16,
                              color: Colors.white,
                            ),
                            label: const Text(
                              "Log Meal",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
