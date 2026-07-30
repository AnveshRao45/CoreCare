import 'package:flutter/material.dart';

class HealthWellnessStep extends StatelessWidget {
  final String sittingTime;
  final String activityLevel;
  final String stressLevel;
  final String smokingHabit;
  final Function(String) onSittingTimeChanged;
  final Function(String) onActivityLevelChanged;
  final Function(String) onStressLevelChanged;
  final Function(String) onSmokingHabitChanged;

  const HealthWellnessStep({
    super.key,
    required this.sittingTime,
    required this.activityLevel,
    required this.stressLevel,
    required this.smokingHabit,
    required this.onSittingTimeChanged,
    required this.onActivityLevelChanged,
    required this.onStressLevelChanged,
    required this.onSmokingHabitChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          // Title
          const Text(
            "Your Lifestyle & Wellness",
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            "Tell us about your daily habits.",
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
          const SizedBox(height: 32),
          // Questions
          _buildQuestionCard(
            "How much time do you spend sitting daily?",
            ["<4 hrs", "4–8 hrs", "8–11 hrs", "12+ hrs"],
            sittingTime,
            onSittingTimeChanged,
            Icons.chair,
          ),
          const SizedBox(height: 20),
          _buildQuestionCard(
            "How physically active are you?",
            ["Sedentary", "Somewhat Active", "Active", "Very Active"],
            activityLevel,
            onActivityLevelChanged,
            Icons.fitness_center,
          ),
          const SizedBox(height: 20),
          _buildQuestionCard(
            "How stressed do you feel daily?",
            ["Not stressed", "Slightly", "Moderately", "Highly stressed"],
            stressLevel,
            onStressLevelChanged,
            Icons.psychology,
          ),
          const SizedBox(height: 20),
          _buildQuestionCard(
            "Do you smoke?",
            ["No", "Occasionally", "Regularly"],
            smokingHabit,
            onSmokingHabitChanged,
            Icons.smoke_free,
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(
    String question,
    List<String> options,
    String selectedValue,
    Function(String) onChanged,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF9947EB).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: const Color(0xFF9947EB), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  question,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D2D2D),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: options.map((option) {
              final isSelected = selectedValue == option;
              return GestureDetector(
                onTap: () => onChanged(option),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF9947EB)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF9947EB)
                          : Colors.grey.shade300,
                    ),
                  ),
                  child: Text(
                    option,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isSelected ? Colors.white : Colors.grey.shade700,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
