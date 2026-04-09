import 'package:hive/hive.dart';

part 'user_profile_model.g.dart';

/// User Profile model for storing user information
@HiveType(typeId: 3)
class UserProfile extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  String location;

  @HiveField(2)
  String activities;

  @HiveField(3)
  double? weight; // in kg

  @HiveField(4)
  double? height; // in cm

  UserProfile({
    required this.name,
    required this.location,
    required this.activities,
    this.weight,
    this.height,
  });

  /// Create a default profile
  factory UserProfile.defaultProfile() {
    return UserProfile(
      name: 'Christian Paul',
      location: 'Bali, Indonesia',
      activities: '🏃 Runner | 🚴 Cyclist | 🧗 Climber',
      weight: 70.0,
      height: 170.0,
    );
  }

  /// Create a copy with updated fields
  UserProfile copyWith({
    String? name,
    String? location,
    String? activities,
    double? weight,
    double? height,
  }) {
    return UserProfile(
      name: name ?? this.name,
      location: location ?? this.location,
      activities: activities ?? this.activities,
      weight: weight ?? this.weight,
      height: height ?? this.height,
    );
  }
}