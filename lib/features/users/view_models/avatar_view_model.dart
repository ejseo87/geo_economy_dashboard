import 'dart:async';
import 'dart:io';
import 'package:geo_economy_dashboard/features/authentication/repos/authentication_repo.dart';
import 'package:geo_economy_dashboard/features/users/repos/user_repo.dart';
import 'package:geo_economy_dashboard/features/users/view_models/users_view_model.dart';
import 'package:geo_economy_dashboard/common/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AvatarViewModel extends AsyncNotifier<void> {
  late final UserRepository _repository;

  @override
  FutureOr build() {
    _repository = ref.read(userRepo);
  }

  Future<void> uploadAvatar(BuildContext context, File file) async {
    state = const AsyncValue.loading();
    final fileName = ref.read(authRepo).user!.uid;
    state = await AsyncValue.guard(() async {
      await _repository.uploadAvatar(file, fileName);
      await ref.read(userProvider.notifier).onAvatarUpload();
    });
    if (state.hasError && context.mounted) {
      showFirebaseErrorSnack(
        context: context,
        error: state.error ?? '알 수 없는 오류가 발생했습니다.',
      );
    }
  }
}

final avatarProvider = AsyncNotifierProvider<AvatarViewModel, void>(
  () => AvatarViewModel(),
);
