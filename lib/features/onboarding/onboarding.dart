import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'steps/personal_information_step.dart';
import 'steps/dietary_preferences_step.dart';
import 'steps/medical_conditions_step.dart';
import 'steps/health_wellness_step.dart';
import '../../models/user_profile.dart';
import '../../services/hive_service.dart';
import '../home.dart';
import '../../routes/routes.dart';

class OnboardingFlow extends StatefulWidget {
  static const id = AppRoutes.onboardingScreen;
  const OnboardingFlow({super.key});

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow>
    with TickerProviderStateMixin {
  int currentStep = 0;
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;

  // Step 1 - Personal Information
  final TextEditingController nameController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  final TextEditingController heightController = TextEditingController();
  final TextEditingController weightController = TextEditingController();
  String selectedGender = "Female";

  // Step 2 - Dietary Preferences
  List<String> selectedDietaryTypes = [];
  List<String> selectedRestrictions = [];
  final TextEditingController allergiesController = TextEditingController();
  bool hasDigestiveIssues = false;
  final TextEditingController digestiveIssuesController =
      TextEditingController();

  // Step 3 - Medical Conditions
  final TextEditingController conditionSearchController =
      TextEditingController();
  List<String> selectedConditions = [];

  // Step 4 - Health & Wellness
  String sittingTime = "";
  String activityLevel = "";
  String stressLevel = "";
  String smokingHabit = "";

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _progressAnimation = Tween<double>(begin: 0.0, end: 0.25).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );
    _progressController.forward();
  }

  @override
  void dispose() {
    _progressController.dispose();
    nameController.dispose();
    ageController.dispose();
    heightController.dispose();
    weightController.dispose();
    allergiesController.dispose();
    digestiveIssuesController.dispose();
    conditionSearchController.dispose();
    super.dispose();
  }

  void _nextStep() {
    final error = _validateStep(currentStep);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.orange),
      );
      return;
    }
    if (currentStep < 3) {
      setState(() => currentStep++);
      _updateProgress();
    } else {
      _completeOnboarding();
    }
  }

  String? _validateStep(int step) {
    switch (step) {
      case 0:
        if (nameController.text.trim().isEmpty) return 'Please enter your name';
        if (int.tryParse(ageController.text) == null) return 'Enter a valid age';
        if (double.tryParse(heightController.text) == null) {
          return 'Enter a valid height (cm)';
        }
        if (double.tryParse(weightController.text) == null) {
          return 'Enter a valid weight (kg)';
        }
        return null;
      case 1:
        if (selectedDietaryTypes.isEmpty) {
          return 'Select at least one diet type';
        }
        return null;
      case 2:
        return null;
      case 3:
        if (activityLevel.isEmpty) return 'Select your activity level';
        return null;
      default:
        return null;
    }
  }

  void _previousStep() {
    if (currentStep > 0) {
      setState(() {
        currentStep--;
      });
      _updateProgress();
    }
  }

  void _updateProgress() {
    double targetProgress = (currentStep + 1) * 0.25;
    _progressAnimation =
        Tween<double>(
          begin: _progressAnimation.value,
          end: targetProgress,
        ).animate(
          CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
        );
    _progressController.reset();
    _progressController.forward();
  }

  void _completeOnboarding() async {
    // Create user profile from collected data
    final userProfile = UserProfile(
      name: nameController.text.trim(),
      age: int.tryParse(ageController.text),
      gender: selectedGender,
      height: double.tryParse(heightController.text),
      weight: double.tryParse(weightController.text),
      dietaryTypes: selectedDietaryTypes,
      dietaryRestrictions: selectedRestrictions,
      allergies: allergiesController.text.trim().isEmpty
          ? null
          : allergiesController.text.trim(),
      hasDigestiveIssues: hasDigestiveIssues,
      digestiveIssuesDescription: hasDigestiveIssues
          ? digestiveIssuesController.text.trim()
          : null,
      medicalConditions: selectedConditions,
      sittingTime: sittingTime,
      activityLevel: activityLevel,
      stressLevel: stressLevel,
      smokingHabit: smokingHabit,
      isOnboardingComplete: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    try {
      // Save to Hive
      await HiveService.saveUserProfile(userProfile);

      // Show completion animation and navigate to home
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => CompletionDialog(
          onComplete: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const HomeScreen()),
            );
          },
        ),
      );
    } catch (e) {
      // Handle error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F6F8),
      body: SafeArea(
        child: Column(
          children: [
            // Progress Header
            _buildProgressHeader(),
            // Content
            Expanded(child: _buildCurrentStep()),
            // Navigation Buttons
            _buildNavigationButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Step ${currentStep + 1} of 4",
                style: TextStyle(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                "${((currentStep + 1) * 25)}% Complete",
                style: TextStyle(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AnimatedBuilder(
            animation: _progressAnimation,
            builder: (context, child) {
              return LinearProgressIndicator(
                value: _progressAnimation.value,
                backgroundColor: Colors.grey[300],
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFF9947EB),
                ),
                minHeight: 6,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (currentStep) {
      case 0:
        return PersonalInformationStep(
          nameController: nameController,
          ageController: ageController,
          heightController: heightController,
          weightController: weightController,
          selectedGender: selectedGender,
          onGenderChanged: (gender) => setState(() => selectedGender = gender),
        );
      case 1:
        return DietaryPreferencesStep(
          selectedDietaryTypes: selectedDietaryTypes,
          selectedRestrictions: selectedRestrictions,
          allergiesController: allergiesController,
          hasDigestiveIssues: hasDigestiveIssues,
          digestiveIssuesController: digestiveIssuesController,
          onDietaryTypesChanged: (types) =>
              setState(() => selectedDietaryTypes = types),
          onRestrictionsChanged: (restrictions) =>
              setState(() => selectedRestrictions = restrictions),
          onDigestiveIssuesChanged: (value) =>
              setState(() => hasDigestiveIssues = value),
        );
      case 2:
        return MedicalConditionsStep(
          searchController: conditionSearchController,
          selectedConditions: selectedConditions,
          onConditionsChanged: (conditions) =>
              setState(() => selectedConditions = conditions),
        );
      case 3:
        return HealthWellnessStep(
          sittingTime: sittingTime,
          activityLevel: activityLevel,
          stressLevel: stressLevel,
          smokingHabit: smokingHabit,
          onSittingTimeChanged: (value) => setState(() => sittingTime = value),
          onActivityLevelChanged: (value) =>
              setState(() => activityLevel = value),
          onStressLevelChanged: (value) => setState(() => stressLevel = value),
          onSmokingHabitChanged: (value) =>
              setState(() => smokingHabit = value),
        );
      default:
        return Container();
    }
  }

  Widget _buildNavigationButtons() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          if (currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _previousStep,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  side: const BorderSide(color: Color(0xFF9947EB)),
                ),
                child: const Text(
                  "Back",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF9947EB),
                  ),
                ),
              ),
            ),
          if (currentStep > 0) const SizedBox(width: 16),
          Expanded(
            flex: currentStep == 0 ? 1 : 1,
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF9947EB), Color(0xFFB565F2)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: ElevatedButton(
                onPressed: _nextStep,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  minimumSize: const Size.fromHeight(56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  currentStep == 3 ? "Save" : "Next →",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CompletionDialog extends StatefulWidget {
  final VoidCallback onComplete;

  const CompletionDialog({super.key, required this.onComplete});

  @override
  State<CompletionDialog> createState() => _CompletionDialogState();
}

class _CompletionDialogState extends State<CompletionDialog>
    with TickerProviderStateMixin {
  late AnimationController _checkController;
  late AnimationController _confettiController;

  @override
  void initState() {
    super.initState();
    _checkController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _confettiController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _checkController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      _confettiController.forward();
    });

    Future.delayed(const Duration(milliseconds: 2500), () {
      Navigator.of(context).pop();
      widget.onComplete();
    });
  }

  @override
  void dispose() {
    _checkController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _checkController,
              builder: (context, child) {
                return Transform.scale(
                  scale: _checkController.value,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: const BoxDecoration(
                      color: Color(0xFF4CAF50),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            const Text(
              "Welcome Aboard!",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              "Your personalized meal plan is ready!",
              style: TextStyle(color: Colors.grey, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
