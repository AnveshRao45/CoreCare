import 'package:hive_flutter/hive_flutter.dart';
import '../models/user_profile.dart';

class HiveService {
  static const String userProfileBoxName = 'userProfile';
  static const String settingsBoxName = 'settings';
  static const String dailyDataBoxName = 'dailyData';

  // Initialize Hive
  static Future<void> init() async {
    await Hive.initFlutter();

    // Register adapters
    Hive.registerAdapter(UserProfileAdapter());

    // Open boxes
    await Hive.openBox<UserProfile>(userProfileBoxName);
    await Hive.openBox(settingsBoxName);
    await Hive.openBox(dailyDataBoxName);
  }

  // User Profile Operations
  static Box<UserProfile> get _userProfileBox =>
      Hive.box<UserProfile>(userProfileBoxName);

  static Future<void> saveUserProfile(UserProfile profile) async {
    profile.updatedAt = DateTime.now();
    profile.createdAt ??= DateTime.now();
    await _userProfileBox.put('current_user', profile);
  }

  static UserProfile? getUserProfile() {
    return _userProfileBox.get('current_user');
  }

  static Future<void> updateUserProfile(UserProfile profile) async {
    profile.updateTimestamp();
    await _userProfileBox.put('current_user', profile);
  }

  static Future<void> deleteUserProfile() async {
    await _userProfileBox.delete('current_user');
  }

  static bool get hasUserProfile => _userProfileBox.containsKey('current_user');

  static bool get isOnboardingComplete {
    final profile = getUserProfile();
    return profile?.isOnboardingComplete ?? false;
  }

  // Settings Operations
  static Box get _settingsBox => Hive.box(settingsBoxName);

  static Future<void> saveSetting(String key, dynamic value) async {
    await _settingsBox.put(key, value);
  }

  static T? getSetting<T>(String key, {T? defaultValue}) {
    return _settingsBox.get(key, defaultValue: defaultValue) as T?;
  }

  static Future<void> deleteSetting(String key) async {
    await _settingsBox.delete(key);
  }

  // Daily Data Operations (for goals, meals, etc.)
  static Box get _dailyDataBox => Hive.box(dailyDataBoxName);

  static Future<void> saveDailyData(String key, dynamic value) async {
    final today = DateTime.now().toIso8601String().split('T')[0];
    await _dailyDataBox.put('${today}_$key', value);
  }

  static T? getDailyData<T>(String key, {T? defaultValue}) {
    final today = DateTime.now().toIso8601String().split('T')[0];
    return _dailyDataBox.get('${today}_$key', defaultValue: defaultValue) as T?;
  }

  // Meal Plan Operations
  static Future<void> saveTodaysMealPlan(
    List<Map<String, dynamic>> mealPlanJson,
  ) async {
    final today = DateTime.now().toIso8601String().split('T')[0];
    try {
      // Ensure we're storing the data in the correct format
      final List<Map<String, dynamic>> cleanedData = mealPlanJson.map((meal) {
        return Map<String, dynamic>.from(meal);
      }).toList();

      await _dailyDataBox.put('${today}_meal_plan', cleanedData);
      await _dailyDataBox.put(
        '${today}_meal_plan_generated_at',
        DateTime.now().toIso8601String(),
      );
      print("💾 Meal plan saved successfully for $today");
    } catch (e) {
      print("❌ Error saving meal plan: $e");
      throw e;
    }
  }

  static List<Map<String, dynamic>>? getTodaysMealPlan() {
    final today = DateTime.now().toIso8601String().split('T')[0];
    final mealPlan = _dailyDataBox.get('${today}_meal_plan');
    if (mealPlan != null) {
      print("📱 Retrieved cached meal plan for $today");
      print("🔍 Meal plan type: ${mealPlan.runtimeType}");
      if (mealPlan is List && mealPlan.isNotEmpty) {
        print("🔍 First item type: ${mealPlan.first.runtimeType}");
      }

      try {
        // Validate data structure first
        if (!isValidMealPlanData(mealPlan)) {
          print("❌ Invalid meal plan data structure, clearing cache");
          clearTodaysMealPlan();
          return null;
        }

        // Convert List<dynamic> to List<Map<String, dynamic>>
        final List<dynamic> dynamicList = List<dynamic>.from(mealPlan);
        final List<Map<String, dynamic>> result = [];

        for (final item in dynamicList) {
          if (item is Map<dynamic, dynamic>) {
            // Recursively convert all nested maps
            final Map<String, dynamic> convertedMap = _convertMapRecursively(
              item,
            );
            result.add(convertedMap);
          } else if (item is Map<String, dynamic>) {
            // Already correct type
            result.add(item);
          } else if (item is Map) {
            // Generic Map, convert to Map<dynamic, dynamic> first
            final Map<dynamic, dynamic> dynamicMap = Map<dynamic, dynamic>.from(
              item,
            );
            final Map<String, dynamic> convertedMap = _convertMapRecursively(
              dynamicMap,
            );
            result.add(convertedMap);
          } else {
            throw Exception('Invalid meal plan item type: ${item.runtimeType}');
          }
        }
        return result;
      } catch (e) {
        print("❌ Error converting cached meal plan: $e");
        print("🧹 Clearing corrupted cache...");
        clearTodaysMealPlan();
        return null;
      }
    }
    print("❌ No cached meal plan found for $today");
    return null;
  }

  // Recursively convert Map<dynamic, dynamic> to Map<String, dynamic>
  static Map<String, dynamic> _convertMapRecursively(
    Map<dynamic, dynamic> map,
  ) {
    final Map<String, dynamic> result = {};

    for (final entry in map.entries) {
      final String key = entry.key.toString();
      final dynamic value = entry.value;

      if (value is Map<dynamic, dynamic>) {
        result[key] = _convertMapRecursively(value);
      } else if (value is List) {
        result[key] = value.map((item) {
          if (item is Map<dynamic, dynamic>) {
            return _convertMapRecursively(item);
          }
          return item;
        }).toList();
      } else {
        result[key] = value;
      }
    }

    return result;
  }

  // Validate meal plan data structure
  static bool isValidMealPlanData(dynamic data) {
    try {
      if (data is! List) return false;

      for (final item in data) {
        if (item is! Map) return false;

        // Try to convert and check required fields
        final Map<String, dynamic> meal = _convertMapRecursively(
          item as Map<dynamic, dynamic>,
        );

        // Check required fields
        if (!meal.containsKey('name') ||
            !meal.containsKey('totalCalories') ||
            !meal.containsKey('items')) {
          return false;
        }

        // Check items structure
        if (meal['items'] is! List) return false;
        for (final foodItem in meal['items']) {
          if (foodItem is! Map) return false;
          if (!foodItem.containsKey('name') ||
              !foodItem.containsKey('calories')) {
            return false;
          }
        }
      }
      return true;
    } catch (e) {
      print("❌ Validation error: $e");
      return false;
    }
  }

  static bool hasTodaysMealPlan() {
    final today = DateTime.now().toIso8601String().split('T')[0];
    final hasData = _dailyDataBox.containsKey('${today}_meal_plan');
    print("🔍 Checking for meal plan on $today: $hasData");
    return hasData;
  }

  static DateTime? getMealPlanGeneratedTime() {
    final today = DateTime.now().toIso8601String().split('T')[0];
    final timeString = _dailyDataBox.get('${today}_meal_plan_generated_at');
    if (timeString != null) {
      return DateTime.parse(timeString);
    }
    return null;
  }

  static Future<void> clearTodaysMealPlan() async {
    final today = DateTime.now().toIso8601String().split('T')[0];
    await _dailyDataBox.delete('${today}_meal_plan');
    await _dailyDataBox.delete('${today}_meal_plan_generated_at');
    print("🗑️ Cleared meal plan cache for $today");
  }

  // Clear corrupted meal plan data
  static Future<void> clearCorruptedMealPlan() async {
    try {
      final today = DateTime.now().toIso8601String().split('T')[0];
      final keys = _dailyDataBox.keys
          .where((key) => key.toString().contains('meal_plan'))
          .toList();

      for (final key in keys) {
        await _dailyDataBox.delete(key);
      }
      print("🧹 Cleared all meal plan cache data");
    } catch (e) {
      print("❌ Error clearing corrupted data: $e");
    }
  }

  static Future<void> saveHistoricalData(
    String date,
    String key,
    dynamic value,
  ) async {
    await _dailyDataBox.put('${date}_$key', value);
  }

  static T? getHistoricalData<T>(String date, String key, {T? defaultValue}) {
    return _dailyDataBox.get('${date}_$key', defaultValue: defaultValue) as T?;
  }

  // Utility Methods
  static Future<void> clearAllData() async {
    await _userProfileBox.clear();
    await _settingsBox.clear();
    await _dailyDataBox.clear();
  }

  static Future<void> closeBoxes() async {
    await Hive.close();
  }

  // Export user data (for backup/sharing)
  static Map<String, dynamic> exportUserData() {
    final profile = getUserProfile();
    if (profile == null) return {};

    return {
      'profile': profile.toMap(),
      'settings': _settingsBox.toMap(),
      'exportDate': DateTime.now().toIso8601String(),
    };
  }

  // Get storage info
  static Map<String, dynamic> getStorageInfo() {
    return {
      'userProfileCount': _userProfileBox.length,
      'settingsCount': _settingsBox.length,
      'dailyDataCount': _dailyDataBox.length,
      'hasUserProfile': hasUserProfile,
      'isOnboardingComplete': isOnboardingComplete,
    };
  }
}
