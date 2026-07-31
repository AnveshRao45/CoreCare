import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:upgrade/features/ai_chat_screen.dart';
import 'package:upgrade/features/edit_profile_screen.dart';
import 'package:upgrade/features/recommendations_screen.dart';
import 'package:upgrade/providers/llm_pro.dart';
import 'package:upgrade/providers/user_provider.dart';
import 'package:upgrade/providers/health_provider.dart';
import 'package:upgrade/routes/navigation.dart';
import 'package:upgrade/routes/routes.dart';
import 'package:upgrade/data/fallback_meals.dart';
import 'package:upgrade/services/meal_intake_service.dart';
import 'package:upgrade/services/daily_goals_service.dart';
import 'package:upgrade/services/nutrition_targets_service.dart';

import '../models/meal.dart';
import '../widgets/model_download_widget.dart';

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
  List<Meal>? _meals;
  bool _mealLoading = false;
  String? _mealError;
  bool _usingFallbackMeals = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(healthVitalsProvider.notifier).refresh();
      _loadMealPlanIfReady();
    });
  }

  void _loadUserData() {
    final userProfile = ref.read(userProfileProvider);
    userName = userProfile?.name?.toString() ?? 'User';
  }

  void _refreshGoals() => setState(() {});

  Set<String> get _loggedMealNameKeys =>
      MealIntakeService.getLoggedPlanMealNames()
          .map((n) => n.trim().toLowerCase())
          .toSet();

  Future<void> _onModelReady() async {
    await ref.read(llmProvider.notifier).checkAvailability();
    await _loadMealPlanIfReady();
  }

  Future<void> _loadMealPlanIfReady({bool regenerate = false}) async {
    final llm = ref.read(llmProvider);
    if (!llm.isLoaded) {
      setState(() {
        _meals = fallbackDailyMeals();
        _usingFallbackMeals = true;
        _mealLoading = false;
        _mealError = null;
      });
      return;
    }

    setState(() {
      _mealLoading = true;
      _mealError = null;
      _usingFallbackMeals = false;
    });

    try {
      final meals = await ref.read(llmProvider.notifier).generateMealPlan(
            isRegenerate: regenerate,
            useWebEnrichment: false,
          );
      if (!mounted) return;
      setState(() {
        _meals = meals.isNotEmpty ? meals : fallbackDailyMeals();
        _usingFallbackMeals = meals.isEmpty;
        _mealLoading = false;
        if (meals.isEmpty) {
          _mealError = 'AI plan unavailable — showing sample meals.';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _meals = fallbackDailyMeals();
        _usingFallbackMeals = true;
        _mealLoading = false;
        _mealError = e.toString();
      });
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning,';
    if (hour < 17) return 'Good Afternoon,';
    return 'Good Evening,';
  }

  void _openAiChat() {
    final llm = ref.read(llmProvider);
    if (!llm.isLoaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Download the AI model first using the card below.'),
          backgroundColor: Color(0xFFFF8A50),
        ),
      );
      return;
    }
    Navigation.instance.navigateTo(AiChatScreen.id.path);
  }

  Future<void> _handleMealLog(Meal meal) async {
    if (MealIntakeService.isPlanMealLogged(meal.name)) return;
    await MealIntakeService.logMeal(meal);
    _refreshGoals();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${meal.name} logged (+${meal.totalCalories} kcal)',
        ),
        backgroundColor: const Color(0xFFFF8A50),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _showManualFoodDialog() async {
    final nameCtrl = TextEditingController();
    final calCtrl = TextEditingController();
    final carbsCtrl = TextEditingController();
    final proteinCtrl = TextEditingController();
    final fatCtrl = TextEditingController();
    final fiberCtrl = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log food manually'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Food name'),
              ),
              TextField(
                controller: calCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Calories'),
              ),
              TextField(
                controller: carbsCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Carbs (g)'),
              ),
              TextField(
                controller: proteinCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Protein (g)'),
              ),
              TextField(
                controller: fatCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Fat (g)'),
              ),
              TextField(
                controller: fiberCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Fiber (g)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Log'),
          ),
        ],
      ),
    );

    if (ok != true || !mounted) return;

    final name = nameCtrl.text.trim();
    final calories = int.tryParse(calCtrl.text) ?? 0;
    if (name.isEmpty || calories <= 0) return;

    await MealIntakeService.logManualFood(
      name: name,
      calories: calories,
      carbsG: int.tryParse(carbsCtrl.text) ?? 0,
      proteinG: int.tryParse(proteinCtrl.text) ?? 0,
      fatG: int.tryParse(fatCtrl.text) ?? 0,
      fiberG: int.tryParse(fiberCtrl.text) ?? 0,
    );
    _refreshGoals();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Logged $name ($calories kcal)')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final llm = ref.watch(llmProvider);
    final user = ref.watch(userProfileProvider);
    final eaten = DailyGoalsService.getCaloriesEaten();
    final target = NutritionTargetsService.targetCalories(user);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.lightbulb_outline, color: Color(0xFF2D3748)),
            tooltip: 'Recommendations',
            onPressed: () =>
                Navigation.instance.navigateTo(RecommendationsScreen.id.path),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Color(0xFF2D3748)),
            tooltip: 'Profile & goals',
            onPressed: () async {
              await Navigation.instance.navigateTo(EditProfileScreen.id.path);
              if (mounted) {
                _loadUserData();
                _refreshGoals();
              }
            },
          ),
        ],
      ),
      floatingActionButton: llm.isLoaded
          ? FloatingActionButton.extended(
              onPressed: _openAiChat,
              backgroundColor: const Color(0xFF9947EB),
              icon: const Icon(Icons.chat_bubble_outline, color: Colors.white),
              label: const Text(
                'AI Chat',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            )
          : null,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                          Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'Your Meal plan',
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF2D3748),
                                  ),
                                ),
                              ),
                              if (llm.isLoaded)
                                IconButton(
                                  icon: const Icon(Icons.refresh),
                                  tooltip: 'Regenerate plan',
                                  onPressed: () =>
                                      _loadMealPlanIfReady(regenerate: true),
                                ),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline),
                                tooltip: 'Log food manually',
                                onPressed: _showManualFoodDialog,
                              ),
                            ],
                          ),
                          Text(
                            'Intake today: $eaten / $target kcal',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                      child: ProgresssOfUSer(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildMealSection(llm),
                const SizedBox(height: 24),
                DailyGoalsSection(),
                const SizedBox(height: 24),
                WorkoutsSection(onWorkoutCompleted: _refreshGoals),
                const SizedBox(height: 24),
                const VitalsSection(),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMealSection(LlamaState llm) {
    if (llm.isLoading || _mealLoading) {
      return _buildLoadingWidget('Loading meal plan…');
    }

    if (!llm.isLoaded) {
      return Column(
        children: [
          if (_meals != null)
            MealCarousel(
              meals: _meals!,
              loggedMealNames: _loggedMealNameKeys,
              onMealLog: _handleMealLog,
            ),
          const SizedBox(height: 12),
          ModelDownloadWidget(onModelAvailable: _onModelReady),
        ],
      );
    }

    if (_mealError != null && _meals == null) {
      return _buildErrorWidget(_mealError!);
    }

    if (_meals != null && _meals!.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_usingFallbackMeals)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                _mealError ?? 'Sample meals — regenerate for AI personalization.',
                style: TextStyle(fontSize: 12, color: Colors.orange.shade800),
              ),
            ),
          MealCarousel(
            meals: _meals!,
            loggedMealNames: _loggedMealNameKeys,
            onMealLog: _handleMealLog,
          ),
        ],
      );
    }

    return Column(
      children: [
        _buildErrorWidget('No meal plan yet.'),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: () => _loadMealPlanIfReady(),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF8A50),
            foregroundColor: Colors.white,
          ),
          child: const Text('Generate meal plan'),
        ),
      ],
    );
  }

  Widget _buildErrorWidget(String error) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(error, textAlign: TextAlign.center),
        ),
      ),
    );
  }

  Widget _buildLoadingWidget(String message) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF8A50)),
            ),
            const SizedBox(height: 16),
            Text(message, style: const TextStyle(color: Color(0xFF64748B))),
          ],
        ),
      ),
    );
  }
}
