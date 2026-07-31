
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:upgrade/models/user_profile.dart';
import 'package:upgrade/services/user_data_service.dart';


final userProfileProvider = NotifierProvider<UserNotifier, UserProfile?>(
  () => UserNotifier(),
);

class UserNotifier extends Notifier<UserProfile?> {
  UserProfile? userProfile;

  @override
  UserProfile? build() {
    if (userProfile != null) {
      return userProfile;
    } else {
      final user = UserDataService.getCurrentUser();
      userProfile = user;
      return user;
    }
  }

  Map<String, Object>? userJson() {
    if (userProfile != null) {
      final userProfileData = {
        "name": userProfile!.name ?? "User",
        "age": userProfile!.age ?? 25,
        "gender": userProfile!.gender ?? "unknown",
        "weight": userProfile!.weight ?? 70,
        "height": userProfile!.height ?? 170,
        "activityLevel": userProfile!.activityLevel ?? "moderate",
        "dietaryTypes": userProfile!.dietaryTypes.isNotEmpty
            ? userProfile!.dietaryTypes
            : ["balanced"],
        "dietaryRestrictions": userProfile!.dietaryRestrictions.isNotEmpty
            ? userProfile!.dietaryRestrictions
            : ["none"],
        "allergies": userProfile!.allergies ?? "none",
        "medicalConditions": userProfile!.medicalConditions.isNotEmpty
            ? userProfile!.medicalConditions
            : ["none"],
        "bmi": userProfile!.bmi?.toStringAsFixed(1) ?? "unknown",
        "bmiCategory": userProfile!.bmiCategory,
      };

      return userProfileData;
    } else {
      return null;
    }
  }

  void refresh() {
    userProfile = UserDataService.getCurrentUser();
    state = userProfile;
  }
}
