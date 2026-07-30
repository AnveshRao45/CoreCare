import 'dart:convert';
import 'dart:io';

import 'package:ddgs/ddgs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:llama_flutter_android/llama_flutter_android.dart';
import 'package:path_provider/path_provider.dart';

import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart';
import 'package:upgrade/models/meal.dart';
import 'package:upgrade/providers/user_provider.dart';
import 'package:upgrade/services/hive_service.dart';

class LlamaState {
  final String? modelPath;
  final bool isLoaded;
  final bool isGenerating;

  const LlamaState({
    this.isLoaded = false,
    this.isGenerating = false,
    this.modelPath,
  });

  LlamaState copyWith({
    bool? isAvailable,
    // bool? isChecking,
    bool? isLoaded,
    bool? isGenerating,
    String? modelPath,
    // String? error,
    // String? generatedText,
  }) {
    return LlamaState(
      isLoaded: isLoaded ?? this.isLoaded,
      isGenerating: isGenerating ?? this.isGenerating,
      modelPath: modelPath ?? this.modelPath,
    );
  }
}

class LlamaNotifier extends Notifier<LlamaState> {
  @override
  LlamaState build() {
    return LlamaState();
  }

  LlamaController? _controller;

  final ddgs = DDGS();

  Future checkAvailability() async {
    final path = await _findDownloadedModel();
    if (path != null) {
      _controller = LlamaController();

      await _controller!.loadModel(modelPath: path);

      state = state.copyWith(isLoaded: true, modelPath: path);
    } else {
      state = state.copyWith(isLoaded: false);
    }
  }

  Future<List<Meal>> generateMealPlan({bool isRegenerate = false}) async {
    if (_controller == null) {
      return [];
    }

    // If regenerate is requested, clear the cache first
    if (isRegenerate) {
      await HiveService.clearTodaysMealPlan();
      print("🗑️ Cleared cached meal plan, generating new one...");
    }

    // Check if we already have today's meal plan
    if (HiveService.hasTodaysMealPlan()) {
      try {
        final cachedMealPlan = HiveService.getTodaysMealPlan();
        if (cachedMealPlan != null) {
          final meals = <Meal>[];
          for (final mealJson in cachedMealPlan) {
            try {
              // Ensure we have the correct type
              final Map<String, dynamic> cleanJson = Map<String, dynamic>.from(
                mealJson,
              );
              meals.add(Meal.fromJson(cleanJson));
            } catch (e) {
              print("❌ Error parsing cached meal: $e");
              print("🔍 Meal data: $mealJson");
            }
          }

          if (meals.isNotEmpty) {
            final generatedTime = HiveService.getMealPlanGeneratedTime();
            print("📱 Using cached meal plan generated at: $generatedTime");
            return meals;
          } else {
            print("❌ No valid meals in cache, clearing...");
            await HiveService.clearTodaysMealPlan();
          }
        }
      } catch (e) {
        print("❌ Error loading cached meal plan: $e");
        print("🧹 Clearing corrupted cache...");
        await HiveService.clearTodaysMealPlan();
      }
    } else {
      print("🔄 Generating new meal plan for today...");
      final userProfile = ref.read(userProfileProvider.notifier).userJson();
      final dataFromWeb = await textSearch();

      // 🧠 Prompt for LLaMA
      final prompt =
          """
You are a certified nutritionist. Create a complete daily meal plan based on:

User Profile: ${jsonEncode(userProfile)}
Information from web: $dataFromWeb

Create exactly 4 meals: Breakfast, Lunch, Dinner, and Snacks.
Return ONLY valid JSON array with this exact structure:

[
  {"name":"Breakfast","totalCalories":,"items":[{"name":"","calories":},{"name":"","calories":},{"name":"","calories":}]},
  {"name":"Lunch","totalCalories":,"items":[{"name":"","calories":},{"name":"","calories":},{"name":"","calories":}]},
  {"name":"Dinner","totalCalories":,"items":[{"name":"","calories":},{"name":"","calories":},{"name":"","calories":}]},
  {"name":"Snacks","totalCalories":,"items":[{"name":"","calories":},{"name":"","calories":},{"name":"","calories":}]}
]

Return only the JSON array, no markdown, no explanations.
""";

      print(
        "⏳ Generating complete daily meal plan (Breakfast, Lunch, Dinner, Snacks)...",
      );

      final output = StringBuffer();
      final stream = _controller!.generate(
        prompt: prompt,
        maxTokens: 800,
        temperature: 0.3,
      );

      await for (final token in stream) {
        output.write(token);
      }

      final rawOutput = output.toString().trim();
      print("\n✅ Raw LLaMA Output:\n$rawOutput");

      try {
        // 🧹 Clean output (remove markdown formatting)
        String cleaned = rawOutput;

        // Remove markdown code blocks
        if (cleaned.contains('```json')) {
          final startIndex = cleaned.indexOf('```json') + 7;
          final endIndex = cleaned.indexOf('```', startIndex);
          if (endIndex != -1) {
            cleaned = cleaned.substring(startIndex, endIndex);
          } else {
            cleaned = cleaned.substring(startIndex);
          }
        } else if (cleaned.contains('```')) {
          final startIndex = cleaned.indexOf('```') + 3;
          final endIndex = cleaned.indexOf('```', startIndex);
          if (endIndex != -1) {
            cleaned = cleaned.substring(startIndex, endIndex);
          } else {
            cleaned = cleaned.substring(startIndex);
          }
        }

        cleaned = cleaned.trim();

        // 🔍 Extract JSON array - find the most complete array
        int start = cleaned.indexOf('[');
        int end = -1;

        if (start != -1) {
          int bracketCount = 0;
          for (int i = start; i < cleaned.length; i++) {
            if (cleaned[i] == '[') bracketCount++;
            if (cleaned[i] == ']') {
              bracketCount--;
              if (bracketCount == 0) {
                end = i;
                break;
              }
            }
          }
        }

        if (start == -1 || end == -1) {
          print("⚠️ No complete JSON array found in output");
          print(
            "🔍 Cleaned text: ${cleaned.substring(0, cleaned.length.clamp(0, 200))}...",
          );
          return [];
        }

        final jsonString = cleaned.substring(start, end + 1);
        print("\n🧹 Cleaned JSON:\n$jsonString");

        final parsed = jsonDecode(jsonString);

        if (parsed is! List) {
          print(
            "⚠️ Invalid format — expected a List, got ${parsed.runtimeType}",
          );
          return [];
        }

        // ✅ Convert parsed data → List<Meal>
        final meals = <Meal>[];
        for (final mealData in parsed) {
          try {
            if (mealData is Map<String, dynamic>) {
              meals.add(Meal.fromJson(mealData));
            } else {
              print("⚠️ Invalid meal data format: ${mealData.runtimeType}");
            }
          } catch (e) {
            print("⚠️ Error parsing meal: $e");
            print("🔍 Meal data: $mealData");
          }
        }

        if (meals.isEmpty) {
          print("⚠️ No valid meals parsed from JSON");
          return [];
        }

        // 🍱 Print structured data
        int totalCalories = 0;
        print("\n🍱 Daily Meal Plan");
        print("=" * 50);
        for (final meal in meals) {
          print("${meal.name} (${meal.totalCalories} kcal)");
          for (final item in meal.items) {
            print("   • ${item.name} - ${item.calories} kcal");
          }
          totalCalories += meal.totalCalories;
        }
        print("=" * 50);
        print("📊 Total Calories: $totalCalories kcal\n");

        // 👤 User target calories (optional)
        final targetCalories = _calculateTargetCalories(userProfile);
        print(
          "👤 Target for ${userProfile!['name']}: ~$targetCalories kcal (${userProfile['activityLevel']} activity)",
        );

        // 💾 Save meal plan to cache
        try {
          final mealPlanJson = meals.map((meal) => meal.toJson()).toList();
          await HiveService.saveTodaysMealPlan(mealPlanJson);
          print("💾 Meal plan saved to cache for today");
        } catch (e) {
          print("⚠️ Failed to save meal plan to cache: $e");
        }

        return meals;
      } catch (e) {
        print("⚠️ JSON parse error: $e");
        print(
          "🔍 Raw output (first 200 chars): ${rawOutput.substring(0, rawOutput.length.clamp(0, 200))}",
        );
        return [];
      }
    }

    // ✅ Default return in case no condition above triggers
    return [];
  }

  String _calculateTargetCalories(Map<String, dynamic>? userProfile) {
    if (userProfile == null ||
        userProfile['age'] == null ||
        userProfile['weight'] == null ||
        userProfile['height'] == null ||
        userProfile['gender'] == null) {
      return "2000-2200"; // Default range
    }

    // Calculate BMR using Mifflin-St Jeor Equation
    double bmr;
    if (userProfile['gender']?.toString().toLowerCase() == 'male') {
      bmr =
          88.362 +
          (13.397 * (userProfile['weight'] as num).toDouble()) +
          (4.799 * (userProfile['height'] as num).toDouble()) -
          (5.677 * (userProfile['age'] as num).toDouble());
    } else {
      bmr =
          447.593 +
          (9.247 * (userProfile['weight'] as num).toDouble()) +
          (3.098 * (userProfile['height'] as num).toDouble()) -
          (4.330 * (userProfile['age'] as num).toDouble());
    }

    // Apply activity factor
    double activityFactor;
    switch (userProfile['activityLevel']?.toString().toLowerCase()) {
      case 'sedentary':
      case 'low':
        activityFactor = 1.2;
        break;
      case 'light':
      case 'lightly active':
        activityFactor = 1.375;
        break;
      case 'moderate':
      case 'moderately active':
        activityFactor = 1.55;
        break;
      case 'high':
      case 'very active':
        activityFactor = 1.725;
        break;
      case 'extremely active':
        activityFactor = 1.9;
        break;
      default:
        activityFactor = 1.55; // Default to moderate
    }

    final tdee = bmr * activityFactor;
    final lowerRange = (tdee - 100).round();
    final upperRange = (tdee + 100).round();

    return "$lowerRange-$upperRange";
  }

  Future<String?> _findDownloadedModel() async {
    try {
      // Check download tasks first
      final tasks = await FlutterDownloader.loadTasks();
      if (tasks != null &&
          tasks.isNotEmpty &&
          tasks.last.status == DownloadTaskStatus.complete) {
        for (final task in tasks) {
          if (task.status == DownloadTaskStatus.complete &&
              (task.filename?.contains('gemma') ?? false) &&
              (task.filename?.endsWith('.gguf') ?? false)) {
            final modelPath = '${task.savedDir}/${task.filename}';
            final file = File(modelPath);
            if (await file.exists()) {
              final fileSize = await file.length();
              final fileSizeMB = (fileSize / (1024 * 1024)).toStringAsFixed(1);
              debugPrint("✅ Found model file: $modelPath (${fileSizeMB}MB)");
              return modelPath;
            }
          }
        }
      }

      // Fallback: check documents directory
      final dir = await getApplicationDocumentsDirectory();
      debugPrint("🔍 Checking directory: ${dir.path}");

      final dirContents = await dir.list().toList();
      for (final item in dirContents) {
        if (item is File) {
          final fileName = item.path.split('/').last.split('\\').last;
          if (fileName.contains('gemma') && fileName.endsWith('.gguf')) {
            final fileSize = await item.length();
            final fileSizeMB = (fileSize / (1024 * 1024)).toStringAsFixed(1);
            debugPrint("✅ Found model file: ${item.path} (${fileSizeMB}MB)");
            return item.path;
          }
        }
      }

      return null;
    } catch (e) {
      debugPrint("Error finding model: $e");
      return null;
    }
  }

  Future<String?> textSearch() async {
    try {
      final userProfile = ref.read(userProfileProvider);

      final queryParts = <String>[
        if (userProfile!.dietaryTypes?.isNotEmpty ?? false)
          "diet type ${userProfile.dietaryTypes!.join(', ')}",
        if (userProfile.dietaryRestrictions?.isNotEmpty ?? false)
          "diet restrictions ${userProfile.dietaryRestrictions!.join(', ')}",
        if (userProfile.allergies != null && userProfile.allergies!.isNotEmpty)
          "allergies ${userProfile.allergies}",
        if (userProfile.medicalConditions?.isNotEmpty ?? false)
          "medical conditions ${userProfile.medicalConditions!.join(', ')}",
        if (userProfile.activityLevel != null)
          "activity level ${userProfile.activityLevel}",
        if (userProfile.stressLevel != null)
          "stress level ${userProfile.stressLevel}",
        if (userProfile.smokingHabit != null)
          "smoking habit ${userProfile.smokingHabit}",
        if (userProfile.hasDigestiveIssues)
          "digestive issues ${userProfile.digestiveIssuesDescription ?? ''}",
      ];

      final query = queryParts.isEmpty
          ? "healthy lifestyle and nutrition advice"
          : queryParts.join(' ') + " health recommendations";

      print("🟢 Query: $query");

      final textResults = await ddgs.text(
        query,
        maxResults: 5,
        backend: 'duckduckgo',
      );

      if (textResults.isEmpty) {
        print("❌ No search results found");
        ddgs.close();
        return null;
      }

      var firstUrl = textResults.first['href'];
      print("🔗 Fetching: $firstUrl");

      if (!firstUrl.startsWith('http')) {
        firstUrl = 'https://$firstUrl';
      }

      final response = await http.get(Uri.parse(firstUrl));

      if (response.statusCode != 200) {
        print("❌ Failed to fetch page: ${response.statusCode}");
        ddgs.close();
        return null;
      }

      // ✅ Parse HTML properly
      final document = html_parser.parse(response.body);

      // ✅ Remove unwanted elements
      document
          .querySelectorAll(
            'script, style, nav, header, footer, aside, .ad, .advertisement, .social-share, .comments, .cookie-banner',
          )
          .forEach((element) {
            element.remove();
          });

      // ✅ Try to find main content area
      final mainContent =
          document.querySelector('article') ??
          document.querySelector('main') ??
          document.querySelector('[role="main"]') ??
          document.querySelector('.content') ??
          document.querySelector('.article') ??
          document.querySelector('#content') ??
          document.body;

      if (mainContent == null) {
        print("⚠️ No content found");
        ddgs.close();
        return null;
      }

      // ✅ Extract text from paragraphs and headings only
      final contentParts = <String>[];
      for (var element in mainContent.querySelectorAll(
        'p, h1, h2, h3, h4, h5, h6, li',
      )) {
        final text = element.text.trim();
        if (text.isNotEmpty && text.length > 20) {
          // Skip tiny fragments
          contentParts.add(text);
        }
      }

      if (contentParts.isEmpty) {
        print("⚠️ No readable content found");
        ddgs.close();
        return null;
      }

      // ✅ Join and limit
      final extractedText = contentParts.join('\n\n');
      final finalText = extractedText.length > 3000
          ? '${extractedText.substring(0, 3000)}...'
          : extractedText;

      print("📄 EXTRACTED CONTENT (${finalText.length} chars):\n$finalText");

      ddgs.close();
      return finalText;
    } catch (e) {
      print("❌ Error: $e");
      ddgs.close();
      return null;
    }
  }
}

final llmProvider = NotifierProvider<LlamaNotifier, LlamaState>(() {
  return LlamaNotifier();
});
