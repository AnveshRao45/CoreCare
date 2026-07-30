import 'dart:async';
import 'dart:convert';

import 'package:ddgs/ddgs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:llama_flutter_android/llama_flutter_android.dart';

import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart';
import 'package:upgrade/models/meal.dart';
import 'package:upgrade/models/user_profile.dart';
import 'package:upgrade/providers/user_provider.dart';
import 'package:upgrade/services/hive_service.dart';
import 'package:upgrade/services/model_storage_service.dart';

class LlamaState {
  final String? modelPath;
  final bool isLoaded;
  final bool isLoading;
  final bool isGenerating;
  final String? error;

  const LlamaState({
    this.isLoaded = false,
    this.isLoading = false,
    this.isGenerating = false,
    this.modelPath,
    this.error,
  });

  LlamaState copyWith({
    bool? isLoaded,
    bool? isLoading,
    bool? isGenerating,
    String? modelPath,
    String? error,
    bool clearError = false,
  }) {
    return LlamaState(
      isLoaded: isLoaded ?? this.isLoaded,
      isLoading: isLoading ?? this.isLoading,
      isGenerating: isGenerating ?? this.isGenerating,
      modelPath: modelPath ?? this.modelPath,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class LlamaNotifier extends Notifier<LlamaState> {
  @override
  LlamaState build() {
    return LlamaState();
  }

  LlamaController? _controller;
  final List<ChatMessage> _chatHistory = [];
  static const int _maxChatHistoryMessages = 8;

  final ddgs = DDGS();

  static const String _chatSystemPrompt =
      'You are CoreCare, a friendly on-device health and fitness coach. '
      'Give clear, practical answers in 2-6 sentences. '
      'Do not add disclaimer notes such as "I am not a professional". '
      'Answer the user\'s question directly. '
      'Use the user profile below when the question is about their diet, '
      'goals, or health.';

  String _chatSystemPromptWithProfile() {
    final user = ref.read(userProfileProvider);
    if (user == null) return _chatSystemPrompt;

    final summary = _profileSummary(user);
    if (summary.isEmpty) return _chatSystemPrompt;
    return '$_chatSystemPrompt\n\nUser profile:\n$summary';
  }

  String _profileSummary(UserProfile user) {
    final lines = <String>[
      if (user.name != null && user.name!.trim().isNotEmpty)
        'Name: ${user.name}',
      if (user.age != null) 'Age: ${user.age}',
      if (user.gender != null) 'Gender: ${user.gender}',
      if (user.height != null && user.weight != null)
        'Height/weight: ${user.height!.round()} cm, ${user.weight!.round()} kg',
      if (user.bmi != null)
        'BMI: ${user.bmi!.toStringAsFixed(1)} (${user.bmiCategory})',
      if (user.activityLevel != null) 'Activity: ${user.activityLevel}',
      if (user.dietaryTypes.isNotEmpty)
        'Diet: ${user.dietaryTypes.join(', ')}',
      if (user.dietaryRestrictions.isNotEmpty)
        'Restrictions: ${user.dietaryRestrictions.join(', ')}',
      if (user.allergies != null && user.allergies!.trim().isNotEmpty)
        'Allergies: ${user.allergies}',
      if (user.medicalConditions.isNotEmpty)
        'Medical conditions: ${user.medicalConditions.join(', ')}',
    ];
    return lines.join('\n');
  }

  Future<void> checkAvailability() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final path = await ModelStorageService.findGgufModel();
      if (path == null) {
        debugPrint('[LLM] No GGUF model on device');
        state = state.copyWith(
          isLoaded: false,
          isLoading: false,
          modelPath: null,
        );
        return;
      }

      debugPrint('[LLM] Loading model from $path');
      _controller ??= LlamaController();
      await _controller!.loadModel(modelPath: path);

      state = state.copyWith(
        isLoaded: true,
        isLoading: false,
        modelPath: path,
        clearError: true,
      );
      debugPrint('[LLM] Model loaded successfully');
    } catch (e, st) {
      debugPrint('[LLM] Failed to load model: $e\n$st');
      state = state.copyWith(
        isLoaded: false,
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  void clearChatHistory() {
    _chatHistory.clear();
    if (_controller != null) {
      unawaited(_controller!.clearContext());
    }
  }

  Stream<String> generateChatStream(String userMessage) async* {
    if (!state.isLoaded || _controller == null) {
      await checkAvailability();
    }
    if (!state.isLoaded || _controller == null) {
      throw StateError(state.error ?? 'AI model is not loaded');
    }

    state = state.copyWith(isGenerating: true, clearError: true);

    final systemPrompt = _chatSystemPromptWithProfile();
    final messages = <ChatMessage>[
      ChatMessage(role: 'system', content: systemPrompt),
      ..._chatHistory,
      ChatMessage(role: 'user', content: userMessage),
    ];

    final buffer = StringBuffer();
    try {
      await for (final token in _controller!.generateChat(
        messages: messages,
        maxTokens: 400,
        temperature: 0.75,
        repeatPenalty: 1.15,
      )) {
        buffer.write(token);
        yield token;
      }

      var reply = _stripDisclaimerOnly(buffer.toString().trim());

      if (reply.isEmpty) {
        buffer.clear();
        await for (final token in _controller!.generateChat(
          messages: [
            ChatMessage(role: 'system', content: systemPrompt),
            ChatMessage(
              role: 'user',
              content:
                  'Answer directly with practical tips. No disclaimer notes. '
                  'Question: $userMessage',
            ),
          ],
          maxTokens: 400,
          temperature: 0.75,
          repeatPenalty: 1.15,
        )) {
          buffer.write(token);
          yield token;
        }
        reply = _stripDisclaimerOnly(buffer.toString().trim());
      }

      if (reply.isEmpty) {
        reply =
            'I had trouble answering that. Try asking about meals, workouts, '
            'sleep, hydration, or your daily goals.';
        yield reply;
      }

      _chatHistory.add(ChatMessage(role: 'user', content: userMessage));
      _chatHistory.add(ChatMessage(role: 'assistant', content: reply));
      while (_chatHistory.length > _maxChatHistoryMessages) {
        _chatHistory.removeAt(0);
      }
    } finally {
      state = state.copyWith(isGenerating: false);
    }
  }

  String _stripDisclaimerOnly(String text) {
    final lower = text.toLowerCase();
    if (lower.startsWith('note:') &&
        (lower.contains('not a professional') ||
            lower.contains('not a medical') ||
            lower.contains('not medical advice'))) {
      final afterParagraph = text.split(RegExp(r'\n\s*\n')).skip(1).join('\n\n');
      return afterParagraph.trim();
    }
    return text;
  }

  Future<void> stopGeneration() async {
    if (_controller != null) {
      await _controller!.stop();
    }
    state = state.copyWith(isGenerating: false);
  }

  Future<List<Meal>> generateMealPlan({
    bool isRegenerate = false,
    bool useWebEnrichment = false,
  }) async {
    if (_controller == null || !state.isLoaded) {
      await checkAvailability();
    }
    if (_controller == null || !state.isLoaded) {
      return [];
    }

    if (isRegenerate) {
      await HiveService.clearTodaysMealPlan();
      debugPrint('[LLM] Cleared cached meal plan for regeneration');
    }

    if (!isRegenerate && HiveService.hasTodaysMealPlan()) {
      final cached = _loadCachedMeals();
      if (cached.isNotEmpty) return cached;
    }

    final userProfile = ref.read(userProfileProvider.notifier).userJson();
    final webContext = useWebEnrichment ? await textSearch() : null;

    final prompt = '''
You are a certified nutritionist. Create a complete daily meal plan based on:

User Profile: ${jsonEncode(userProfile)}
${webContext != null ? 'Reference notes: $webContext' : 'Use only the user profile — no external data.'}

Create exactly 4 meals: Breakfast, Lunch, Dinner, and Snacks.
Each food item must include calories and macros in grams.

Return ONLY a valid JSON array with this structure:

[
  {"name":"Breakfast","totalCalories":500,"items":[
    {"name":"Food name","calories":200,"carbsG":30,"proteinG":12,"fatG":8,"fiberG":4}
  ]},
  {"name":"Lunch","totalCalories":600,"items":[...]},
  {"name":"Dinner","totalCalories":600,"items":[...]},
  {"name":"Snacks","totalCalories":200,"items":[...]}
]

Return only the JSON array, no markdown, no explanations.
''';

    debugPrint('[LLM] Generating meal plan (web=$useWebEnrichment)...');

    final output = StringBuffer();
    await for (final token in _controller!.generate(
      prompt: prompt,
      maxTokens: 900,
      temperature: 0.3,
    )) {
      output.write(token);
    }

    final meals = _parseMealPlanJson(output.toString().trim());
    if (meals.isEmpty) return [];

    try {
      final mealPlanJson = meals.map((meal) => meal.toJson()).toList();
      await HiveService.saveTodaysMealPlan(mealPlanJson);
    } catch (e) {
      debugPrint('[LLM] Failed to cache meal plan: $e');
    }

    return meals;
  }

  List<Meal> _loadCachedMeals() {
    try {
      final cachedMealPlan = HiveService.getTodaysMealPlan();
      if (cachedMealPlan == null) return [];
      final meals = <Meal>[];
      for (final mealJson in cachedMealPlan) {
        meals.add(Meal.fromJson(Map<String, dynamic>.from(mealJson)));
      }
      return meals;
    } catch (e) {
      debugPrint('[LLM] Cache load error: $e');
      return [];
    }
  }

  List<Meal> _parseMealPlanJson(String rawOutput) {
    try {
      String cleaned = rawOutput;
      if (cleaned.contains('```json')) {
        final startIndex = cleaned.indexOf('```json') + 7;
        final endIndex = cleaned.indexOf('```', startIndex);
        cleaned = endIndex != -1
            ? cleaned.substring(startIndex, endIndex)
            : cleaned.substring(startIndex);
      } else if (cleaned.contains('```')) {
        final startIndex = cleaned.indexOf('```') + 3;
        final endIndex = cleaned.indexOf('```', startIndex);
        cleaned = endIndex != -1
            ? cleaned.substring(startIndex, endIndex)
            : cleaned.substring(startIndex);
      }
      cleaned = cleaned.trim();

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
      if (start == -1 || end == -1) return [];

      final parsed = jsonDecode(cleaned.substring(start, end + 1));
      if (parsed is! List) return [];

      final meals = <Meal>[];
      for (final mealData in parsed) {
        if (mealData is Map<String, dynamic>) {
          meals.add(Meal.fromJson(mealData));
        }
      }
      return meals;
    } catch (e) {
      debugPrint('[LLM] Meal JSON parse error: $e');
      return [];
    }
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

      // Parse HTML properly
      final document = html_parser.parse(response.body);

      // Remove unwanted elements
      document
          .querySelectorAll(
            'script, style, nav, header, footer, aside, .ad, .advertisement, .social-share, .comments, .cookie-banner',
          )
          .forEach((element) {
            element.remove();
          });

      // Try to find main content area
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

      // Extract text from paragraphs and headings only
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

      // Join and limit
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
