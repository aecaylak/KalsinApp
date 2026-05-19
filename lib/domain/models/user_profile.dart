import 'package:hive/hive.dart';

part 'user_profile.g.dart';

/// Kullanıcının profil bilgilerini tutan model (Onboarding için).
@HiveType(typeId: 2)
class UserProfile extends HiveObject {
  @HiveField(0)
  final String name;

  @HiveField(1)
  final String avatarEmoji;

  @HiveField(2)
  final bool hasCompletedOnboarding;

  @HiveField(3)
  final bool hasSeenTrainer;

  @HiveField(4)
  final String currencyCode;

  UserProfile({
    required this.name,
    required this.avatarEmoji,
    required this.hasCompletedOnboarding,
    this.hasSeenTrainer = false,
    this.currencyCode = 'TRY',
  });

  UserProfile copyWith({
    String? name,
    String? avatarEmoji,
    bool? hasCompletedOnboarding,
    bool? hasSeenTrainer,
    String? currencyCode,
  }) {
    return UserProfile(
      name: name ?? this.name,
      avatarEmoji: avatarEmoji ?? this.avatarEmoji,
      hasCompletedOnboarding: hasCompletedOnboarding ?? this.hasCompletedOnboarding,
      hasSeenTrainer: hasSeenTrainer ?? this.hasSeenTrainer,
      currencyCode: currencyCode ?? this.currencyCode,
    );
  }
}
