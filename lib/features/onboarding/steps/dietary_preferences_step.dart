import 'package:flutter/material.dart';

class DietaryPreferencesStep extends StatelessWidget {
  final List<String> selectedDietaryTypes;
  final List<String> selectedRestrictions;
  final TextEditingController allergiesController;
  final bool hasDigestiveIssues;
  final TextEditingController digestiveIssuesController;
  final Function(List<String>) onDietaryTypesChanged;
  final Function(List<String>) onRestrictionsChanged;
  final Function(bool) onDigestiveIssuesChanged;

  const DietaryPreferencesStep({
    super.key,
    required this.selectedDietaryTypes,
    required this.selectedRestrictions,
    required this.allergiesController,
    required this.hasDigestiveIssues,
    required this.digestiveIssuesController,
    required this.onDietaryTypesChanged,
    required this.onRestrictionsChanged,
    required this.onDigestiveIssuesChanged,
  });

  final List<String> dietaryTypes = const [
    "Vegetarian",
    "Vegan",
    "Keto",
    "Halal",
    "Paleo",
    "Mediterranean",
    "Low-Carb",
    "Intermittent Fasting",
  ];

  final List<String> restrictions = const [
    "Dairy-free",
    "Gluten-free",
    "Low-sodium",
    "Nut-free",
    "Soy-free",
    "Sugar-free",
    "Low-fat",
    "Organic only",
  ];

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
            "Your Food Preferences",
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            "We'll make sure your plan fits your lifestyle.",
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
          const SizedBox(height: 32),
          // Dietary Types
          const Text(
            "Dietary Type",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2D2D2D),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: dietaryTypes.map((type) {
              final isSelected = selectedDietaryTypes.contains(type);
              return GestureDetector(
                onTap: () {
                  List<String> updated = List.from(selectedDietaryTypes);
                  if (isSelected) {
                    updated.remove(type);
                  } else {
                    updated.add(type);
                  }
                  onDietaryTypesChanged(updated);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF9947EB) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF9947EB)
                          : Colors.grey.shade300,
                    ),
                  ),
                  child: Text(
                    type,
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
          const SizedBox(height: 24),
          // Restrictions
          const Text(
            "Dietary Restrictions",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2D2D2D),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: restrictions.map((restriction) {
              final isSelected = selectedRestrictions.contains(restriction);
              return GestureDetector(
                onTap: () {
                  List<String> updated = List.from(selectedRestrictions);
                  if (isSelected) {
                    updated.remove(restriction);
                  } else {
                    updated.add(restriction);
                  }
                  onRestrictionsChanged(updated);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFE3F2FD) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF2196F3)
                          : Colors.grey.shade300,
                    ),
                  ),
                  child: Text(
                    restriction,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isSelected
                          ? const Color(0xFF2196F3)
                          : Colors.grey.shade700,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          // Allergies
          _buildInputField(
            allergiesController,
            "Food Allergies",
            "List any food allergies (optional)",
          ),
          const SizedBox(height: 24),
          // Digestive Issues
          const Text(
            "Digestive Issues",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2D2D2D),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text(
                "Do you have any digestive issues?",
                style: TextStyle(fontSize: 16),
              ),
              const Spacer(),
              Switch(
                value: hasDigestiveIssues,
                activeColor: const Color(0xFF9947EB),
                onChanged: onDigestiveIssuesChanged,
              ),
            ],
          ),
          if (hasDigestiveIssues) ...[
            const SizedBox(height: 12),
            _buildInputField(
              digestiveIssuesController,
              "Please specify",
              "Describe your digestive issues",
            ),
          ],
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildInputField(
    TextEditingController controller,
    String label,
    String hint,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2D2D2D),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF9947EB), width: 2),
            ),
          ),
        ),
      ],
    );
  }
}
