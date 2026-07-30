import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_profile.dart';
import 'hive_service.dart';

final userDataServiceProvider = Provider((ref) => UserDataService);

class UserDataService {
  // Save complete onboarding data
  static Future<bool> saveOnboardingData({
    required String? name,
    required int? age,
    required String gender,
    required double? height,
    required double? weight,
    required List<String> dietaryTypes,
    required List<String> dietaryRestrictions,
    required String? allergies,
    required bool hasDigestiveIssues,
    required String? digestiveIssuesDescription,
    required List<String> medicalConditions,
    required String sittingTime,
    required String activityLevel,
    required String stressLevel,
    required String smokingHabit,
  }) async {
    try {
      final userProfile = UserProfile(
        name: name,
        age: age,
        gender: gender,
        height: height,
        weight: weight,
        dietaryTypes: dietaryTypes,
        dietaryRestrictions: dietaryRestrictions,
        allergies: allergies?.isEmpty == true ? null : allergies,
        hasDigestiveIssues: hasDigestiveIssues,
        digestiveIssuesDescription: hasDigestiveIssues
            ? digestiveIssuesDescription
            : null,
        medicalConditions: medicalConditions,
        sittingTime: sittingTime,
        activityLevel: activityLevel,
        stressLevel: stressLevel,
        smokingHabit: smokingHabit,
        isOnboardingComplete: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await HiveService.saveUserProfile(userProfile);
      return true;
    } catch (e) {
      print('Error saving onboarding data: $e');
      return false;
    }
  }

  // Get user profile
  static UserProfile? getCurrentUser() {
    return HiveService.getUserProfile();
  }

  // Update specific user data
  static Future<bool> updatePersonalInfo({
    String? name,
    int? age,
    String? gender,
    double? height,
    double? weight,
  }) async {
    try {
      final currentProfile = HiveService.getUserProfile();
      if (currentProfile == null) return false;

      if (name != null) currentProfile.name = name;
      if (age != null) currentProfile.age = age;
      if (gender != null) currentProfile.gender = gender;
      if (height != null) currentProfile.height = height;
      if (weight != null) currentProfile.weight = weight;

      await HiveService.updateUserProfile(currentProfile);
      return true;
    } catch (e) {
      print('Error updating personal info: $e');
      return false;
    }
  }

  // Update dietary preferences
  static Future<bool> updateDietaryPreferences({
    List<String>? dietaryTypes,
    List<String>? dietaryRestrictions,
    String? allergies,
    bool? hasDigestiveIssues,
    String? digestiveIssuesDescription,
  }) async {
    try {
      final currentProfile = HiveService.getUserProfile();
      if (currentProfile == null) return false;

      if (dietaryTypes != null) currentProfile.dietaryTypes = dietaryTypes;
      if (dietaryRestrictions != null)
        currentProfile.dietaryRestrictions = dietaryRestrictions;
      if (allergies != null) currentProfile.allergies = allergies;
      if (hasDigestiveIssues != null)
        currentProfile.hasDigestiveIssues = hasDigestiveIssues;
      if (digestiveIssuesDescription != null) {
        currentProfile.digestiveIssuesDescription = digestiveIssuesDescription;
      }

      await HiveService.updateUserProfile(currentProfile);
      return true;
    } catch (e) {
      print('Error updating dietary preferences: $e');
      return false;
    }
  }

  // Update medical conditions
  static Future<bool> updateMedicalConditions(List<String> conditions) async {
    try {
      final currentProfile = HiveService.getUserProfile();
      if (currentProfile == null) return false;

      currentProfile.medicalConditions = conditions;
      await HiveService.updateUserProfile(currentProfile);
      return true;
    } catch (e) {
      print('Error updating medical conditions: $e');
      return false;
    }
  }

  // Update lifestyle data
  static Future<bool> updateLifestyleData({
    String? sittingTime,
    String? activityLevel,
    String? stressLevel,
    String? smokingHabit,
  }) async {
    try {
      final currentProfile = HiveService.getUserProfile();
      if (currentProfile == null) return false;

      if (sittingTime != null) currentProfile.sittingTime = sittingTime;
      if (activityLevel != null) currentProfile.activityLevel = activityLevel;
      if (stressLevel != null) currentProfile.stressLevel = stressLevel;
      if (smokingHabit != null) currentProfile.smokingHabit = smokingHabit;

      await HiveService.updateUserProfile(currentProfile);
      return true;
    } catch (e) {
      print('Error updating lifestyle data: $e');
      return false;
    }
  }

  // Get user stats
  static Map<String, dynamic> getUserStats() {
    final profile = getCurrentUser();
    if (profile == null) return {};

    return {
      'name': profile.name ?? 'User',
      'age': profile.age,
      'bmi': profile.bmi?.toStringAsFixed(1),
      'bmiCategory': profile.bmiCategory,
      'dietaryTypes': profile.dietaryTypes,
      'medicalConditions': profile.medicalConditions,
      'activityLevel': profile.activityLevel,
      'onboardingDate': profile.createdAt?.toIso8601String(),
    };
  }

  // Reset onboarding (for testing)
  static Future<void> resetOnboarding() async {
    await HiveService.deleteUserProfile();
  }
}
