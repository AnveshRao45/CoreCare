import 'package:hive/hive.dart';

part 'user_profile.g.dart';

@HiveType(typeId: 0)
class UserProfile extends HiveObject {
  @HiveField(0)
  String? name;

  @HiveField(1)
  int? age;

  @HiveField(2)
  String? gender;

  @HiveField(3)
  double? height; // in cm

  @HiveField(4)
  double? weight; // in kg

  @HiveField(5)
  List<String> dietaryTypes;

  @HiveField(6)
  List<String> dietaryRestrictions;

  @HiveField(7)
  String? allergies;

  @HiveField(8)
  bool hasDigestiveIssues;

  @HiveField(9)
  String? digestiveIssuesDescription;

  @HiveField(10)
  List<String> medicalConditions;

  @HiveField(11)
  String? sittingTime;

  @HiveField(12)
  String? activityLevel;

  @HiveField(13)
  String? stressLevel;

  @HiveField(14)
  String? smokingHabit;

  @HiveField(15)
  DateTime? createdAt;

  @HiveField(16)
  DateTime? updatedAt;

  @HiveField(17)
  bool isOnboardingComplete;

  UserProfile({
    this.name,
    this.age,
    this.gender,
    this.height,
    this.weight,
    this.dietaryTypes = const [],
    this.dietaryRestrictions = const [],
    this.allergies,
    this.hasDigestiveIssues = false,
    this.digestiveIssuesDescription,
    this.medicalConditions = const [],
    this.sittingTime,
    this.activityLevel,
    this.stressLevel,
    this.smokingHabit,
    this.createdAt,
    this.updatedAt,
    this.isOnboardingComplete = false,
  });

  // Calculate BMI
  double? get bmi {
    if (height != null && weight != null && height! > 0) {
      double heightInMeters = height! / 100;
      return weight! / (heightInMeters * heightInMeters);
    }
    return null;
  }

  // Get BMI category
  String get bmiCategory {
    final bmiValue = bmi;
    if (bmiValue == null) return 'Unknown';

    if (bmiValue < 18.5) return 'Underweight';
    if (bmiValue < 25) return 'Normal';
    if (bmiValue < 30) return 'Overweight';
    return 'Obese';
  }

  // Update timestamp
  void updateTimestamp() {
    updatedAt = DateTime.now();
  }

  // Convert to Map for easy serialization
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'age': age,
      'gender': gender,
      'height': height,
      'weight': weight,
      'dietaryTypes': dietaryTypes,
      'dietaryRestrictions': dietaryRestrictions,
      'allergies': allergies,
      'hasDigestiveIssues': hasDigestiveIssues,
      'digestiveIssuesDescription': digestiveIssuesDescription,
      'medicalConditions': medicalConditions,
      'sittingTime': sittingTime,
      'activityLevel': activityLevel,
      'stressLevel': stressLevel,
      'smokingHabit': smokingHabit,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'isOnboardingComplete': isOnboardingComplete,
      'bmi': bmi,
      'bmiCategory': bmiCategory,
    };
  }
}
