import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:path_provider/path_provider.dart';
import 'package:upgrade/providers/llm_pro.dart';
import 'package:upgrade/providers/user_provider.dart';
import 'package:upgrade/routes/routes.dart';
import 'package:upgrade/services/hive_service.dart';
import '../models/meal.dart';
import '../widgets/model_download_widget.dart';
import '../llm_model_check.dart';

import 'widgets/meal_carousel.dart';
import 'widgets/greeting_header.dart';
import 'widgets/daily_goals_section.dart';
import 'widgets/workouts_section.dart';
import 'widgets/vitals_section.dart';
import 'widgets/progress_of_user.dart';

class HomeScreen extends ConsumerStatefulWidget {
  static const id = AppRoutes.homeScreen;
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String userName = 'User';
  int _refreshKey = 0; // Key to force rebuild of DailyGoalsSection

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    final userProfile = ref.read(userProfileProvider);
    userName = userProfile.build()!.name.toString();
  }

  void _refreshDailyGoals() {
    // Force rebuild of DailyGoalsSection by changing key
    setState(() {
      _refreshKey++;
    });
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning,';
    } else if (hour < 17) {
      return 'Good Afternoon,';
    } else {
      return 'Good Evening,';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Debug: Check cache status

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GreetingHeader(
                            greeting: _getGreeting(),
                            name: '$userName!',
                            subtitle: 'Ready to conquer your\ngoals?',
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            "Your Meal plan",
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2D3748),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      child: ProgresssOfUSer(key: ValueKey(_refreshKey)),
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                FutureBuilder<List<Meal>?>(
                  future: ref.read(llmProvider.notifier).generateMealPlan(),
                  builder: (context, snapshot) {
                    final state = ref.read(llmProvider).isLoaded;

                    if (!state) {
                      return ModelDownloadWidget();
                    } else if (snapshot.connectionState ==
                        ConnectionState.waiting) {
                      return _buildLoadingWidget();
                    } else if (snapshot.hasError) {
                      return _buildErrorWidget(snapshot.error.toString());
                    } else if (snapshot.hasData && snapshot.data != null) {
                      return _buildMealPlanSection(snapshot.data!);
                    } else {
                      return SizedBox();
                    }
                    //  else {
                    //   return _buildDownloadPromptWidget();
                    // }
                  },
                ),
                const SizedBox(height: 24),
                DailyGoalsSection(key: ValueKey(_refreshKey)),
                const SizedBox(height: 24),
                WorkoutsSection(onWorkoutCompleted: _refreshDailyGoals),
                const SizedBox(height: 24),
                const VitalsSection(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMealPlanSection(List<Meal> meals) {
    return MealCarousel(meals: meals, onMealLog: _handleMealLog);
  }

  Widget _buildErrorWidget(String error) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            const Text(
              'Error generating meal plan',
              style: TextStyle(fontSize: 16, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: const TextStyle(fontSize: 12, color: Colors.red),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF8A50)),
            ),
            SizedBox(height: 16),
            Text(
              'Checking AI Model...',
              style: TextStyle(fontSize: 16, color: Color(0xFF64748B)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDownloadPromptWidget() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFFF8A50).withValues(alpha: 0.1),
            const Color(0xFFFF6B35).withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFF8A50).withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF8A50).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.download,
                  color: Color(0xFFFF8A50),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI-Powered Meal Plans',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Download an AI model to get personalized recommendations',
                      style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Get AI-powered meal recommendations, nutrition advice, and personalized meal plans by downloading a nutrition-focused AI model.',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF64748B),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),

          // ModelDownloadWidget(onModelAvailable: _onModelAvailable),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue, size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Recommended: Gemma 2B Nutrition (~1.6GB) for best results',
                    style: TextStyle(fontSize: 12, color: Colors.blue),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _handleMealLog(Meal meal) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${meal.name} logged successfully!'),
        backgroundColor: const Color(0xFFFF8A50),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
