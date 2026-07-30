import 'package:flutter/material.dart';

class MedicalConditionsStep extends StatelessWidget {
  final TextEditingController searchController;
  final List<String> selectedConditions;
  final Function(List<String>) onConditionsChanged;

  const MedicalConditionsStep({
    super.key,
    required this.searchController,
    required this.selectedConditions,
    required this.onConditionsChanged,
  });

  final List<String> commonConditions = const [
    "Diabetes",
    "PCOS",
    "Thyroid",
    "Hypertension",
    "Asthma",
    "GERD",
    "Anxiety",
    "Arthritis",
    "High Cholesterol",
    "Heart Disease",
    "Kidney Disease",
    "Liver Disease",
    "Osteoporosis",
    "Depression",
    "Migraine",
    "IBS",
    "Celiac Disease",
    "Food Intolerance",
  ];

  @override
  Widget build(BuildContext context) {
    List<String> filteredConditions = commonConditions
        .where(
          (condition) => condition.toLowerCase().contains(
            searchController.text.toLowerCase(),
          ),
        )
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          // Title
          const Text(
            "Medical Conditions",
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            "We'll tailor your plan to your health needs.",
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
          const SizedBox(height: 32),
          // Search Bar
          TextField(
            controller: searchController,
            decoration: InputDecoration(
              hintText: "Search or select your conditions...",
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
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
                borderSide: const BorderSide(
                  color: Color(0xFF9947EB),
                  width: 2,
                ),
              ),
            ),
            onChanged: (value) {
              // Trigger rebuild to filter conditions
              (context as Element).markNeedsBuild();
            },
          ),
          const SizedBox(height: 24),
          // Selected Conditions
          if (selectedConditions.isNotEmpty) ...[
            const Text(
              "Selected Conditions",
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
              children: selectedConditions.map((condition) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF9947EB),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        condition,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          List<String> updated = List.from(selectedConditions);
                          updated.remove(condition);
                          onConditionsChanged(updated);
                        },
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
          ],
          // Available Conditions
          const Text(
            "Common Conditions",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2D2D2D),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            constraints: const BoxConstraints(maxHeight: 300),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: filteredConditions.length,
              itemBuilder: (context, index) {
                final condition = filteredConditions[index];
                final isSelected = selectedConditions.contains(condition);

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF9947EB)
                          : Colors.grey.shade300,
                    ),
                  ),
                  child: CheckboxListTile(
                    title: Text(
                      condition,
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: isSelected
                            ? const Color(0xFF9947EB)
                            : Colors.grey.shade700,
                      ),
                    ),
                    value: isSelected,
                    activeColor: const Color(0xFF9947EB),
                    onChanged: (bool? value) {
                      List<String> updated = List.from(selectedConditions);
                      if (value == true) {
                        updated.add(condition);
                      } else {
                        updated.remove(condition);
                      }
                      onConditionsChanged(updated);
                    },
                    controlAffinity: ListTileControlAffinity.trailing,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          // Skip suggestion
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade600),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    "Not sure? You can skip this step and add conditions later.",
                    style: TextStyle(
                      color: Color(0xFF1976D2),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
