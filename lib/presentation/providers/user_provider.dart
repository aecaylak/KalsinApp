import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/user_profile.dart';
import '../../data/repositories/savings_repository.dart';
import 'goal_provider.dart';
import 'savings_provider.dart';

class UserNotifier extends StateNotifier<UserProfile?> {
  UserNotifier(this._repo, this._ref) : super(_repo.getUserProfile());

  final SavingsRepository _repo;
  final Ref<UserProfile?> _ref;

  Future<void> saveProfile(UserProfile profile) async {
    await _repo.saveUserProfile(profile);
    state = profile;
  }

  Future<void> markTrainerAsSeen() async {
    if (state != null) {
      final updated = state!.copyWith(hasSeenTrainer: true);
      await saveProfile(updated);
    }
  }

  Future<void> resetProfile() async {
    // Önce Hive kutularını temizle
    await _repo.clearAllSavings();
    await _repo.clearGoal();
    await _repo.clearUserProfile();
    // Hive temizlendikten SONRA provider'ları invalidate et — boş Hive'dan okurlar
    _ref.invalidate(savingsProvider);
    _ref.invalidate(goalsProvider);
    // Son olarak user state'i null yap → uygulama OnboardingScreen'e geçer
    state = null;
  }

  bool get hasCompletedOnboarding => _repo.hasCompletedOnboarding();
}

final userProvider = StateNotifierProvider<UserNotifier, UserProfile?>((ref) {
  final repo = ref.watch(repositoryProvider);
  return UserNotifier(repo, ref);
});
