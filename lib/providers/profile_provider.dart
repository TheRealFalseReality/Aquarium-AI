import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../models/tank.dart';
import '../models/user_profile.dart';
import '../services/profile_service.dart';
import 'community_provider.dart';

// ─── Current user profile stream ─────────────────────────────────────────────

/// Streams the currently signed-in user's [UserProfile] from Firestore.
/// Emits null when the user is not signed in or no profile document exists yet.
final currentUserProfileProvider = StreamProvider<UserProfile?>((ref) {
  // Re-subscribe whenever the auth state changes
  final authAsync = ref.watch(authStateProvider);
  final user = authAsync.asData?.value;
  if (user == null) return Stream.value(null);
  return ProfileService.currentUserProfileStream();
});

/// Streams any user's profile by uid.
final userProfileProvider = StreamProvider.family<UserProfile?, String>((
  ref,
  uid,
) {
  return ProfileService.userProfileStream(uid);
});

// ─── Save profile state ───────────────────────────────────────────────────────

class SaveProfileState {
  final bool isSaving;
  final String? error;
  final bool success;

  const SaveProfileState({
    this.isSaving = false,
    this.error,
    this.success = false,
  });

  SaveProfileState copyWith({
    bool? isSaving,
    String? error,
    bool clearError = false,
    bool? success,
  }) {
    return SaveProfileState(
      isSaving: isSaving ?? this.isSaving,
      error: clearError ? null : error ?? this.error,
      success: success ?? this.success,
    );
  }
}

class SaveProfileNotifier extends StateNotifier<SaveProfileState> {
  SaveProfileNotifier() : super(const SaveProfileState());

  Future<bool> save(UserProfile profile) async {
    state = state.copyWith(isSaving: true, clearError: true, success: false);
    final ok = await ProfileService.saveProfile(profile);
    state = state.copyWith(
      isSaving: false,
      success: ok,
      error: ok ? null : 'save_failed',
    );
    return ok;
  }

  Future<bool> updateFields(Map<String, dynamic> data) async {
    state = state.copyWith(isSaving: true, clearError: true, success: false);
    final ok = await ProfileService.updateProfile(data);
    state = state.copyWith(
      isSaving: false,
      success: ok,
      error: ok ? null : 'save_failed',
    );
    return ok;
  }

  Future<void> syncTanks(List<Tank> tanks) async {
    await ProfileService.syncTanks(tanks);
  }

  void reset() {
    state = const SaveProfileState();
  }
}

final saveProfileProvider =
    StateNotifierProvider<SaveProfileNotifier, SaveProfileState>(
      (_) => SaveProfileNotifier(),
    );
