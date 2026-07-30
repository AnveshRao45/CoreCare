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
    if (profile.createdAt == null) {
      profile.createdAt = DateTime.now();
    }
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
