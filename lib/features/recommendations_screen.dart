import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:upgrade/providers/user_provider.dart';
import 'package:upgrade/routes/routes.dart';
import 'package:upgrade/services/meal_intake_service.dart';

class RecommendationsScreen extends ConsumerWidget {
  static const id = AppRoutes.recommendationsScreen;
  const RecommendationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProfileProvider);
    final tips = MealIntakeService.buildRecommendations(user);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your recommendations'),
        backgroundColor: const Color(0xFF9947EB),
        foregroundColor: Colors.white,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: tips.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          return Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: const Color(0xFF9947EB).withValues(alpha: 0.15),
                child: const Icon(Icons.tips_and_updates, color: Color(0xFF9947EB)),
              ),
              title: Text(tips[index]),
            ),
          );
        },
      ),
    );
  }
}
