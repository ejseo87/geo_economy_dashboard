import 'dart:async';

import 'package:geo_economy_dashboard/features/authentication/repos/authentication_repo.dart';
import 'package:geo_economy_dashboard/features/users/models/user_profile_model.dart';
import 'package:geo_economy_dashboard/features/users/repos/user_repo.dart';
import 'package:geo_economy_dashboard/common/utils.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class UsersViewModel extends AsyncNotifier<UserProfileModel> {
  late final UserRepository _usersRepository;
  late final AuthenticationRepository _authenticationRepository;

  @override
  FutureOr<UserProfileModel> build() async {
    _usersRepository = ref.read(userRepo);
    _authenticationRepository = ref.read(authRepo);

    if (_authenticationRepository.isLoggedIn) {
      final profile = await _usersRepository.findProfile(
        _authenticationRepository.user!.uid,
      );
      if (profile != null) {
        return UserProfileModel.fromJson(profile);
      }
    }
    return UserProfileModel.empty();
  }

  Future<void> createProfile({
    required User user,
    required BuildContext context,
  }) async {
    if (user.uid.isEmpty) {
      throw Exception("Account not created");
    }
    state = AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final profile = UserProfileModel(
        uid: user.uid,
        email: user.email ?? "anon@anon.com",
        name: "Anonymous",
        bio: "No bio",
        link: "",
        hasAvatar: false,
      );
      await _usersRepository.createUserProfile(profile);
      return profile;
    });
    if (state.hasError && context.mounted) {
      showFirebaseErrorSnack(
        context: context,
        error: state.error ?? '알 수 없는 오류가 발생했습니다.',
      );
    }
  }

  Future<void> onAvatarUpload() async {
    if (state.value == null) return;
    state = AsyncValue.data(state.value!.copyWith(hasAvatar: true));
    await _usersRepository.updateUser(state.value!.uid, {"hasAvatar": true});
  }
}

final userProvider = AsyncNotifierProvider<UsersViewModel, UserProfileModel>(
  () => UsersViewModel(),
);
