import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../repositories/profile_repository.dart';
import '../../../services/storage_service.dart';

class ProfileEditState {
  const ProfileEditState({this.saving = false, this.error, this.saved = false});

  final bool saving;
  final AppException? error;
  final bool saved;

  ProfileEditState copyWith({bool? saving, AppException? error, bool clearError = false, bool? saved}) {
    return ProfileEditState(
      saving: saving ?? this.saving,
      error: clearError ? null : (error ?? this.error),
      saved: saved ?? this.saved,
    );
  }
}

/// Only ever writes the fields spec §28 says a student may change:
/// full name, age, phone, avatar. Role, group memberships, teacher
/// permissions, grades, and attendance are not settable from this
/// screen at all — and even if they were, the `enforce_profile_update_rules`
/// trigger (schema.sql) silently discards a role change from anyone
/// but the teacher.
class ProfileEditController extends StateNotifier<ProfileEditState> {
  ProfileEditController(this._profileRepository, this._storageService)
      : super(const ProfileEditState());

  final ProfileRepository _profileRepository;
  final StorageService _storageService;

  Future<bool> save({
    required String fullName,
    int? age,
    String? phone,
    File? newAvatar,
  }) async {
    state = state.copyWith(saving: true, clearError: true, saved: false);
    try {
      String? avatarUrl;
      if (newAvatar != null) {
        final path = await _storageService.uploadAvatar(newAvatar);
        avatarUrl = _storageService.getPublicUrl(bucket: 'avatars', path: path);
      }
      await _profileRepository.updateMyProfile(
        fullName: fullName,
        age: age,
        phone: phone,
        avatarUrl: avatarUrl,
      );
      state = state.copyWith(saving: false, saved: true);
      return true;
    } on AppException catch (e) {
      state = state.copyWith(saving: false, error: e);
      return false;
    }
  }

  void clearError() => state = state.copyWith(clearError: true);
}

final profileEditControllerProvider =
    StateNotifierProvider.autoDispose<ProfileEditController, ProfileEditState>((ref) {
  return ProfileEditController(
    ref.read(profileRepositoryProvider),
    ref.read(storageServiceProvider),
  );
});
