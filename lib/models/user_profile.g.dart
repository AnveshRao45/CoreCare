// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_profile.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserProfileAdapter extends TypeAdapter<UserProfile> {
  @override
  final int typeId = 0;

  @override
  UserProfile read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserProfile(
      name: fields[0] as String?,
      age: fields[1] as int?,
      gender: fields[2] as String?,
      height: fields[3] as double?,
      weight: fields[4] as double?,
      dietaryTypes: (fields[5] as List).cast<String>(),
      dietaryRestrictions: (fields[6] as List).cast<String>(),
      allergies: fields[7] as String?,
      hasDigestiveIssues: fields[8] as bool,
      digestiveIssuesDescription: fields[9] as String?,
      medicalConditions: (fields[10] as List).cast<String>(),
      sittingTime: fields[11] as String?,
      activityLevel: fields[12] as String?,
      stressLevel: fields[13] as String?,
      smokingHabit: fields[14] as String?,
      createdAt: fields[15] as DateTime?,
      updatedAt: fields[16] as DateTime?,
      isOnboardingComplete: fields[17] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, UserProfile obj) {
    writer
      ..writeByte(18)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.age)
      ..writeByte(2)
      ..write(obj.gender)
      ..writeByte(3)
      ..write(obj.height)
      ..writeByte(4)
      ..write(obj.weight)
      ..writeByte(5)
      ..write(obj.dietaryTypes)
      ..writeByte(6)
      ..write(obj.dietaryRestrictions)
      ..writeByte(7)
      ..write(obj.allergies)
      ..writeByte(8)
      ..write(obj.hasDigestiveIssues)
      ..writeByte(9)
      ..write(obj.digestiveIssuesDescription)
      ..writeByte(10)
      ..write(obj.medicalConditions)
      ..writeByte(11)
      ..write(obj.sittingTime)
      ..writeByte(12)
      ..write(obj.activityLevel)
      ..writeByte(13)
      ..write(obj.stressLevel)
      ..writeByte(14)
      ..write(obj.smokingHabit)
      ..writeByte(15)
      ..write(obj.createdAt)
      ..writeByte(16)
      ..write(obj.updatedAt)
      ..writeByte(17)
      ..write(obj.isOnboardingComplete);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserProfileAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
